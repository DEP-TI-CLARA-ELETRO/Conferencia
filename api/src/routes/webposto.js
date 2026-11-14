import { Router } from 'express';
import { config } from '../config.js';
import { requireAuth, requirePermission } from '../middleware/auth.js';
import { WebpostoClient } from '../services/webpostoClient.js';
import { syncWebposto } from '../services/webpostoSync.js';

export const webpostoRouter = Router();

webpostoRouter.use(requireAuth);
webpostoRouter.use(requirePermission('closings.view', 'users.manage'));

webpostoRouter.get('/status', (_req, res) => {
  res.json({
    configured: config.webpostoConfigured,
    baseUrl: config.webpostoBaseUrl,
  });
});

webpostoRouter.post('/sync', async (req, res, next) => {
  try {
    if (!config.webpostoConfigured) {
      return res.status(400).json({ error: 'webposto_not_configured' });
    }
    const date = req.body?.date;
    const dateFrom = req.body?.dateFrom || date;
    const dateTo = req.body?.dateTo || date;
    if (!dateFrom || !dateTo) {
      return res.status(400).json({ error: 'invalid_request' });
    }
    const client = new WebpostoClient({
      baseUrl: config.webpostoBaseUrl,
      chave: config.webpostoChave,
    });
    const result = await syncWebposto(client, {
      from: dateFrom,
      to: dateTo,
      empresaCodigo: req.body?.empresaCodigo ?? null,
    });
    res.json(result);
  } catch (err) {
    next(err);
  }
});
