import { Router } from 'express';
import path from 'node:path';
import fs from 'node:fs/promises';
import { config } from '../config.js';
import { requireAuth, requirePermission } from '../middleware/auth.js';
import { CashClosing } from '../models/CashClosing.js';
import { ClosingCoupon } from '../models/ClosingCoupon.js';
import { Store } from '../models/Store.js';
import {
  canAccessStore,
  userCan,
  userStoreIds,
} from '../services/authService.js';
import { WebpostoClient } from '../services/webpostoClient.js';
import { loadClosingDetail } from '../services/closingDetail.js';
import { runDualOcr } from '../services/couponOcr.js';
import { matchCouponValues } from '../services/couponMatch.js';

export const closingsRouter = Router();

closingsRouter.use(requireAuth);
closingsRouter.use(requirePermission('closings.view'));

function serializeClosing(c, storeName) {
  return {
    id: c._id,
    storeId: c.storeId,
    storeName: storeName || '',
    connector: c.connector,
    caixaCodigo: c.externalCaixaCodigo,
    movementDate: c.movementDate,
    shiftLabel: c.shiftLabel,
    pdvCode: c.pdvCode,
    employeeCode: c.employeeCode,
    openedAt: c.openedAt?.toISOString?.() ?? c.openedAt,
    closedAt: c.closedAt?.toISOString?.() ?? c.closedAt,
    closed: c.closed,
    consolidated: c.consolidated,
    apurado: c.apurado,
    diferenca: c.diferenca,
    stage: c.stage,
    paymentBreakdown: c.paymentBreakdown || {},
  };
}

function serializeCoupon(c) {
  return {
    id: c._id,
    closingId: c.closingId,
    filename: c.filename,
    contentType: c.contentType,
    status: c.status,
    proposedValues: c.proposedValues || {},
    confirmedValues: c.confirmedValues,
    matchResult: c.matchResult,
    ocrWarning: c.ocrWarning,
    ocrRuns: (c.ocrRuns || []).map((r) => ({
      engine: r.engine,
      rawText: r.rawText,
      parsed: r.parsed || {},
      confidence: r.confidence,
      error: r.error,
    })),
    createdAt: c.createdAt?.toISOString?.() ?? c.createdAt,
    confirmedAt: c.confirmedAt?.toISOString?.() ?? c.confirmedAt,
  };
}

async function getClosingForUser(req, closingId) {
  const closing = await CashClosing.findById(closingId);
  if (!closing) return { error: 404 };
  if (!canAccessStore(req.user, closing.storeId)) return { error: 403 };
  return { closing };
}

closingsRouter.get('/', async (req, res, next) => {
  try {
    const dateFrom = req.query.dateFrom || req.query.date;
    const dateTo = req.query.dateTo || req.query.date;
    if (!dateFrom || !dateTo) {
      return res.status(400).json({ error: 'invalid_request' });
    }
    const filter = {
      movementDate: { $gte: String(dateFrom), $lte: String(dateTo) },
    };

    let allowedStoreIds = null;
    if (!userCan(req.user, 'users.manage')) {
      allowedStoreIds = userStoreIds(req.user);
    }
    if (req.query.businessUnit) {
      const unitStores = await Store.find({
        active: true,
        businessUnit: String(req.query.businessUnit),
      });
      const unitIds = unitStores.map((s) => s.id);
      allowedStoreIds =
        allowedStoreIds == null
          ? unitIds
          : allowedStoreIds.filter((id) => unitIds.includes(id));
    }
    if (req.query.storeId) {
      const sid = Number(req.query.storeId);
      if (allowedStoreIds != null && !allowedStoreIds.includes(sid)) {
        return res.json([]);
      }
      filter.storeId = sid;
    } else if (allowedStoreIds != null) {
      filter.storeId = { $in: allowedStoreIds };
    }

    const rows = await CashClosing.find(filter).sort({
      movementDate: -1,
      storeId: 1,
      externalCaixaCodigo: 1,
    });
    const storeIds = [...new Set(rows.map((r) => r.storeId))];
    const stores = await Store.find({ id: { $in: storeIds } });
    const nameById = new Map(stores.map((s) => [s.id, s.name]));
    res.json(rows.map((r) => serializeClosing(r, nameById.get(r.storeId))));
  } catch (err) {
    next(err);
  }
});

closingsRouter.get('/:id/detail', async (req, res, next) => {
  try {
    const { closing, error } = await getClosingForUser(req, req.params.id);
    if (error === 404) return res.status(404).json({ error: 'not_found' });
    if (error === 403) return res.status(403).json({ error: 'forbidden' });

    if (!config.webpostoConfigured) {
      return res.json({
        warning: 'WebPosto nao configurado',
        payments: [],
        paymentsTotal: 0,
        salesCount: 0,
        sales: [],
      });
    }

    const store = await Store.findOne({ id: closing.storeId });
    const empresaCodigo = Number.parseInt(store?.externalCode || '', 10);
    if (!empresaCodigo) {
      return res.json({
        warning: 'Loja sem codigo WebPosto',
        payments: [],
        paymentsTotal: 0,
        salesCount: 0,
        sales: [],
      });
    }

    const client = new WebpostoClient({
      baseUrl: config.webpostoBaseUrl,
      chave: config.webpostoChave,
    });
    const detail = await loadClosingDetail(client, {
      caixaCodigo: closing.externalCaixaCodigo,
      movementDate: closing.movementDate,
      empresaCodigo,
      employeeCode: closing.employeeCode,
    });
    res.json(detail);
  } catch (err) {
    next(err);
  }
});

async function applyOcrMatch(coupon, closing, scanned, userId) {
  const siblings = await ClosingCoupon.find({
    closingId: closing._id,
    status: 'confirmed',
    _id: { $ne: coupon._id },
  });
  const aggregated = { ...scanned };
  for (const s of siblings) {
    for (const [k, v] of Object.entries(s.confirmedValues || {})) {
      aggregated[k] = (aggregated[k] || 0) + Number(v);
    }
  }
  coupon.confirmedValues = scanned;
  coupon.matchResult = matchCouponValues({
    paymentBreakdown: closing.paymentBreakdown || {},
    scanned: aggregated,
    closingApurado: closing.apurado,
  });
  coupon.status = 'confirmed';
  coupon.confirmedBy = userId || coupon.createdBy || 'ocr';
  coupon.confirmedAt = new Date();
  await coupon.save();
  return coupon;
}

/** OCR automático — operador não edita valores. */
async function processOcr(coupon, closing, userId) {
  const abs = path.join(config.couponsUploadDir, coupon.storagePath);
  coupon.status = 'ocr_pending';
  coupon.confirmedValues = null;
  coupon.matchResult = null;
  coupon.confirmedAt = null;
  coupon.confirmedBy = null;
  await coupon.save();
  const { runs, proposed, warning, ok } = await runDualOcr(abs);
  coupon.ocrRuns = runs;
  coupon.proposedValues = proposed;
  coupon.ocrWarning = warning;
  if (!ok) {
    coupon.status = 'failed';
    await coupon.save();
    return coupon;
  }
  return applyOcrMatch(coupon, closing, proposed, userId);
}

closingsRouter.get('/:closingId/coupons', async (req, res, next) => {
  try {
    const { closing, error } = await getClosingForUser(req, req.params.closingId);
    if (error === 404) return res.status(404).json({ error: 'not_found' });
    if (error === 403) return res.status(403).json({ error: 'forbidden' });
    void closing;
    const list = await ClosingCoupon.find({ closingId: req.params.closingId }).sort({
      createdAt: -1,
    });
    res.json(list.map(serializeCoupon));
  } catch (err) {
    next(err);
  }
});

closingsRouter.post('/:closingId/coupons', async (req, res, next) => {
  try {
    const { closing, error } = await getClosingForUser(req, req.params.closingId);
    if (error === 404) return res.status(404).json({ error: 'not_found' });
    if (error === 403) return res.status(403).json({ error: 'forbidden' });

    let buffer;
    let filename = req.body?.filename || `cupom-${Date.now()}.jpg`;
    let contentType = req.body?.contentType || 'image/jpeg';

    if (req.body?.imageBase64) {
      const raw = String(req.body.imageBase64).replace(/^data:[^;]+;base64,/, '');
      buffer = Buffer.from(raw, 'base64');
    } else {
      return res.status(400).json({ error: 'invalid_request' });
    }
    if (!buffer.length || buffer.length > 12 * 1024 * 1024) {
      return res.status(400).json({ error: 'invalid_image' });
    }

    const dir = path.join(config.couponsUploadDir, closing._id);
    await fs.mkdir(dir, { recursive: true });
    const ext = path.extname(filename) || '.jpg';
    const storedName = `${Date.now()}${ext}`;
    const storagePath = path.join(closing._id, storedName).replace(/\\/g, '/');
    await fs.writeFile(path.join(config.couponsUploadDir, storagePath), buffer);

    let coupon = await ClosingCoupon.create({
      closingId: closing._id,
      storagePath,
      filename,
      contentType,
      status: 'uploaded',
      createdBy: req.user.id,
    });
    coupon = await processOcr(coupon, closing, req.user.id);
    res.status(201).json(serializeCoupon(coupon));
  } catch (err) {
    next(err);
  }
});

closingsRouter.post('/:closingId/coupons/reprocess', async (req, res, next) => {
  try {
    const { closing, error } = await getClosingForUser(req, req.params.closingId);
    if (error === 404) return res.status(404).json({ error: 'not_found' });
    if (error === 403) return res.status(403).json({ error: 'forbidden' });
    const list = await ClosingCoupon.find({ closingId: req.params.closingId });
    const out = [];
    for (const c of list) {
      out.push(serializeCoupon(await processOcr(c, closing, req.user.id)));
    }
    res.json(out);
  } catch (err) {
    next(err);
  }
});

closingsRouter.get('/:closingId/coupons/:couponId/image', async (req, res, next) => {
  try {
    const { closing, error } = await getClosingForUser(req, req.params.closingId);
    if (error === 404) return res.status(404).json({ error: 'not_found' });
    if (error === 403) return res.status(403).json({ error: 'forbidden' });
    void closing;
    const coupon = await ClosingCoupon.findOne({
      _id: req.params.couponId,
      closingId: req.params.closingId,
    });
    if (!coupon) return res.status(404).json({ error: 'not_found' });
    const abs = path.join(config.couponsUploadDir, coupon.storagePath);
    res.setHeader('content-type', coupon.contentType || 'image/jpeg');
    res.sendFile(abs);
  } catch (err) {
    next(err);
  }
});

/** Rematch só com valores do OCR — não aceita edição manual. */
closingsRouter.post('/:closingId/coupons/:couponId/confirm', async (req, res, next) => {
  try {
    const { closing, error } = await getClosingForUser(req, req.params.closingId);
    if (error === 404) return res.status(404).json({ error: 'not_found' });
    if (error === 403) return res.status(403).json({ error: 'forbidden' });
    const coupon = await ClosingCoupon.findOne({
      _id: req.params.couponId,
      closingId: req.params.closingId,
    });
    if (!coupon) return res.status(404).json({ error: 'not_found' });
    const proposed = coupon.proposedValues || {};
    if (!Object.keys(proposed).length) {
      return res.status(400).json({ error: 'ocr_empty' });
    }
    res.json(
      serializeCoupon(await applyOcrMatch(coupon, closing, proposed, req.user.id)),
    );
  } catch (err) {
    next(err);
  }
});

closingsRouter.post('/:closingId/coupons/:couponId/reprocess', async (req, res, next) => {
  try {
    const { closing, error } = await getClosingForUser(req, req.params.closingId);
    if (error === 404) return res.status(404).json({ error: 'not_found' });
    if (error === 403) return res.status(403).json({ error: 'forbidden' });
    const coupon = await ClosingCoupon.findOne({
      _id: req.params.couponId,
      closingId: req.params.closingId,
    });
    if (!coupon) return res.status(404).json({ error: 'not_found' });
    res.json(
      serializeCoupon(await processOcr(coupon, closing, req.user.id)),
    );
  } catch (err) {
    next(err);
  }
});

closingsRouter.delete('/:closingId/coupons/:couponId', async (req, res, next) => {
  try {
    const { error } = await getClosingForUser(req, req.params.closingId);
    if (error === 404) return res.status(404).json({ error: 'not_found' });
    if (error === 403) return res.status(403).json({ error: 'forbidden' });
    const coupon = await ClosingCoupon.findOne({
      _id: req.params.couponId,
      closingId: req.params.closingId,
    });
    if (!coupon) return res.status(404).json({ error: 'not_found' });
    try {
      await fs.unlink(path.join(config.couponsUploadDir, coupon.storagePath));
    } catch {
      /* ignore */
    }
    await coupon.deleteOne();
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});
