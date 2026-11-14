import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import { api, getToken } from '../api';
import { useFilters } from '../filters';
import { Page } from '../components/Shell';
import { isPostoLabel } from '../components/FilterSelect';
import {
  IconFuel,
  IconRefresh,
  IconRegister,
  IconSync,
} from '../components/icons';
import type { Closing, ClosingCoupon } from '../types';
import { PAYMENT_LABELS } from '../types';
import './closings.css';

const COUPON_STATUS: Record<string, string> = {
  uploaded: 'Enviado',
  ocr_pending: 'Lendo cupom…',
  ocr_ready: 'OCR pronto',
  confirmed: 'Conferido',
  failed: 'Falha no OCR',
};

function money(v?: number | null) {
  if (v == null) return '—';
  return v.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

function dateBr(iso?: string | null) {
  if (!iso) return '—';
  const [y, m, d] = iso.slice(0, 10).split('-');
  if (!y || !m || !d) return iso;
  return `${d}/${m}/${y}`;
}

function kind(c: Closing) {
  if (!c.closed) return 'open';
  if ((c.diferenca ?? 0) !== 0) return 'divergent';
  if (c.consolidated) return 'consolidated';
  return 'closed';
}

const KIND_LABEL: Record<string, string> = {
  open: 'Aberto',
  divergent: 'Divergente',
  consolidated: 'Consolidado',
  closed: 'Fechado',
};

export function ClosingsPage() {
  const filters = useFilters();
  const qc = useQueryClient();
  const [selected, setSelected] = useState<Closing | null>(null);

  const listQuery = useQuery({
    queryKey: [
      'closings',
      filters.dateFrom,
      filters.dateTo,
      filters.storeId,
      filters.businessUnit,
    ],
    queryFn: () =>
      api.closings({
        dateFrom: filters.dateFrom,
        dateTo: filters.dateTo,
        storeId: filters.storeId,
        businessUnit: filters.businessUnit,
      }),
  });

  const statusQuery = useQuery({
    queryKey: ['webposto-status'],
    queryFn: () => api.webpostoStatus(),
  });

  const syncMut = useMutation({
    mutationFn: () =>
      api.webpostoSync({
        dateFrom: filters.dateFrom,
        dateTo: filters.dateTo,
      }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['closings'] }),
  });

  const rows = listQuery.data || [];

  return (
    <Page
      title="Caixas"
      subtitle={`${rows.length} registro(s) no período`}
      actions={
        <div className="actions">
          <button
            type="button"
            className="btn ghost"
            onClick={() => listQuery.refetch()}
          >
            <IconRefresh />
            Atualizar
          </button>
          {statusQuery.data?.configured ? (
            <button
              type="button"
              className="btn"
              disabled={syncMut.isPending}
              onClick={() => syncMut.mutate()}
            >
              <IconSync />
              {syncMut.isPending ? 'Sincronizando…' : 'Sync WebPosto'}
            </button>
          ) : null}
        </div>
      }
    >
      {listQuery.isLoading ? (
        <div className="empty-state glass">
          <div className="spinner" style={{ margin: '0 auto 0.75rem' }} />
          <p className="muted">Carregando caixas…</p>
        </div>
      ) : null}
      {listQuery.error ? (
        <p className="login-error">{(listQuery.error as Error).message}</p>
      ) : null}
      <div className="closing-list">
        {rows.map((c) => {
          const k = kind(c);
          const delta = c.diferenca || 0;
          const hasDelta = delta !== 0;
          return (
            <button
              key={c.id}
              type="button"
              className={`closing-row kind-${k}`}
              onClick={() => setSelected(c)}
            >
              <span className={`closing-ico kind-${k}`} aria-hidden>
                <IconRegister size={20} />
              </span>
              <div className="closing-main">
                <div className="closing-title">
                  <strong>
                    Caixa {c.caixaCodigo}
                    {c.shiftLabel ? ` · ${c.shiftLabel}` : ''}
                  </strong>
                  <span className={`chip ${k}`}>{KIND_LABEL[k]}</span>
                </div>
                <div className="closing-meta">
                  {isPostoLabel(c.storeName) ? (
                    <IconFuel size={13} className="closing-fuel" />
                  ) : null}
                  <span>{c.storeName}</span>
                  <span className="closing-meta-sep" aria-hidden>
                    ·
                  </span>
                  <span>{dateBr(c.movementDate)}</span>
                </div>
              </div>
              <div className="closing-nums">
                <span className="closing-amount">{money(c.apurado)}</span>
                <span
                  className={`closing-delta ${hasDelta ? 'bad' : 'ok'}`}
                >
                  <span className="closing-delta-label">Diferença</span>
                  <span className="closing-delta-value">
                    {hasDelta ? (delta > 0 ? '+' : '') : ''}
                    {money(c.diferenca)}
                  </span>
                </span>
              </div>
            </button>
          );
        })}
        {!listQuery.isLoading && !rows.length ? (
          <div className="empty-state glass">
            <h3>Nenhum caixa neste filtro</h3>
            <p className="muted">
              Ajuste o período ou sincronize o WebPosto para importar o dia.
            </p>
          </div>
        ) : null}
      </div>

      {selected ? (
        <ClosingDialog closing={selected} onClose={() => setSelected(null)} />
      ) : null}
    </Page>
  );
}

function ClosingDialog({
  closing,
  onClose,
}: {
  closing: Closing;
  onClose: () => void;
}) {
  const detailQuery = useQuery({
    queryKey: ['closing-detail', closing.id],
    queryFn: () => api.closingDetail(closing.id),
  });
  const couponsQuery = useQuery({
    queryKey: ['coupons', closing.id],
    queryFn: () => api.coupons(closing.id),
  });
  const qc = useQueryClient();
  const [preview, setPreview] = useState<ClosingCoupon | null>(null);

  const uploadMut = useMutation({
    mutationFn: async (file: File) => {
      const dataUrl = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(String(reader.result || ''));
        reader.onerror = () => reject(reader.error);
        reader.readAsDataURL(file);
      });
      const imageBase64 = dataUrl.includes(',')
        ? dataUrl.slice(dataUrl.indexOf(',') + 1)
        : dataUrl;
      return api.uploadCoupon(closing.id, {
        imageBase64,
        filename: file.name,
        contentType: file.type || 'image/jpeg',
      });
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['coupons', closing.id] });
    },
  });

  const reprocessMut = useMutation({
    mutationFn: () => api.reprocessCoupons(closing.id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['coupons', closing.id] }),
  });

  const deleteMut = useMutation({
    mutationFn: (couponId: string) => api.deleteCoupon(closing.id, couponId),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['coupons', closing.id] }),
  });

  const detail = detailQuery.data;

  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      document.body.style.overflow = prev;
    };
  }, []);

  return createPortal(
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal glass" onClick={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <div>
            <h2>
              Caixa {closing.caixaCodigo} · {closing.storeName}
            </h2>
            <p className="muted" style={{ margin: 0 }}>
              {dateBr(closing.movementDate)}
              {detail?.employeeName ? ` · ${detail.employeeName}` : ''}
            </p>
          </div>
          <button type="button" className="btn ghost" onClick={onClose}>
            Fechar
          </button>
        </div>

        <div className="modal-body">
          {detail?.warning ? <p className="login-error">{detail.warning}</p> : null}

          <div className="detail-grid">
            <section>
              <h3>Pagamentos</h3>
              <ul className="pay-list">
                {(detail?.payments || []).map((p) => (
                  <li key={p.name}>
                    <span>{p.name}</span>
                    <strong>{money(p.amount)}</strong>
                  </li>
                ))}
              </ul>
              <div className="pay-total">
                Total {money(detail?.paymentsTotal)}
              </div>
            </section>
            <section>
              <h3>Vendas ({detail?.salesCount ?? 0})</h3>
              <div className="sales-table">
                {(detail?.sales || []).slice(0, 20).map((s, i) => (
                  <div
                    key={`${s.soldAt}-${i}`}
                    className={s.cancelled ? 'cancelled' : ''}
                  >
                    <span>{s.soldAt}</span>
                    <span>{s.invoiceNumber || '—'}</span>
                    <span>{money(s.total)}</span>
                  </div>
                ))}
              </div>
            </section>
          </div>

          <section className="coupon-panel">
            <div className="modal-head">
              <div>
                <h3>Cupons</h3>
                <p className="muted" style={{ margin: '0.2rem 0 0', fontSize: '0.82rem' }}>
                  Envie a foto — o OCR lê e confere sozinho (sem edição manual).
                </p>
              </div>
              <div className="actions">
                <label className={`btn file-btn${uploadMut.isPending ? ' ghost' : ''}`}>
                  {uploadMut.isPending ? 'Lendo cupom…' : 'Enviar foto'}
                  <input
                    type="file"
                    accept="image/*"
                    capture="environment"
                    hidden
                    disabled={uploadMut.isPending}
                    onChange={(e) => {
                      const f = e.target.files?.[0];
                      if (f) uploadMut.mutate(f);
                      e.target.value = '';
                    }}
                  />
                </label>
                <button
                  type="button"
                  className="btn ghost"
                  disabled={reprocessMut.isPending}
                  onClick={() => reprocessMut.mutate()}
                >
                  {reprocessMut.isPending ? 'Reprocessando…' : 'Reprocessar OCR'}
                </button>
              </div>
            </div>
            {uploadMut.error ? (
              <p className="login-error">
                {(uploadMut.error as Error).message}
              </p>
            ) : null}
            <div className="coupon-list">
              {(couponsQuery.data || []).map((c) => {
                const values = c.confirmedValues || c.proposedValues || {};
                const entries = Object.entries(values);
                return (
                  <div key={c.id} className="coupon-card">
                    <div className="coupon-card-main">
                      <div className="coupon-card-top">
                        <strong>{c.filename}</strong>
                        <span
                          className={`chip ${
                            c.status === 'failed'
                              ? 'divergent'
                              : c.matchResult?.ok
                                ? 'consolidated'
                                : c.status === 'confirmed'
                                  ? 'divergent'
                                  : 'open'
                          }`}
                        >
                          {COUPON_STATUS[c.status] || c.status}
                        </span>
                      </div>
                      {c.ocrWarning ? (
                        <div className="muted">{c.ocrWarning}</div>
                      ) : null}
                      {c.matchResult ? (
                        <div className={c.matchResult.ok ? 'ok' : 'bad'}>
                          {c.matchResult.ok ? 'Match OK' : 'Divergente'} · lido{' '}
                          {money(c.matchResult.scannedTotal)}
                          {c.matchResult.expectedTotal != null
                            ? ` · esperado ${money(c.matchResult.expectedTotal)}`
                            : ''}
                        </div>
                      ) : null}
                      {entries.length ? (
                        <ul className="coupon-values">
                          {entries.map(([k, v]) => (
                            <li key={k}>
                              <span>{PAYMENT_LABELS[k] || k}</span>
                              <strong>{money(v)}</strong>
                            </li>
                          ))}
                        </ul>
                      ) : c.status === 'failed' ? (
                        <div className="bad">Nenhum valor identificado no cupom</div>
                      ) : null}
                    </div>
                    <div className="actions">
                      <button
                        type="button"
                        className="btn ghost"
                        onClick={() => setPreview(c)}
                      >
                        Ver foto
                      </button>
                      <button
                        type="button"
                        className="btn ghost"
                        onClick={() => deleteMut.mutate(c.id)}
                      >
                        Excluir
                      </button>
                    </div>
                  </div>
                );
              })}
              {!couponsQuery.isLoading && !(couponsQuery.data || []).length ? (
                <p className="muted" style={{ margin: 0 }}>
                  Nenhum cupom anexado ainda.
                </p>
              ) : null}
            </div>
          </section>
        </div>

        {preview ? (
          <CouponPhotoPreview
            closingId={closing.id}
            coupon={preview}
            onClose={() => setPreview(null)}
          />
        ) : null}
      </div>
    </div>,
    document.body,
  );
}

function CouponPhotoPreview({
  closingId,
  coupon,
  onClose,
}: {
  closingId: string;
  coupon: ClosingCoupon;
  onClose: () => void;
}) {
  const imgUrl = api.couponImageUrl(closingId, coupon.id);
  const values = coupon.confirmedValues || coupon.proposedValues || {};

  return createPortal(
    <div className="review-overlay" onClick={onClose}>
      <div className="review-card glass" onClick={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <div>
            <h3>{coupon.filename}</h3>
            <p className="muted" style={{ margin: 0 }}>
              Somente leitura — valores vindos do OCR
            </p>
          </div>
          <button type="button" className="btn ghost" onClick={onClose}>
            Fechar
          </button>
        </div>
        {coupon.ocrWarning ? (
          <p className="login-error" style={{ margin: '0.75rem 1.25rem 0' }}>
            {coupon.ocrWarning}
          </p>
        ) : null}
        <div className="review-grid">
          <img
            src={imgUrl}
            alt={coupon.filename}
            ref={(el) => {
              if (!el || el.dataset.loaded) return;
              el.dataset.loaded = '1';
              void fetch(imgUrl, {
                headers: { Authorization: `Bearer ${getToken()}` },
              })
                .then((r) => r.blob())
                .then((b) => {
                  el.src = URL.createObjectURL(b);
                })
                .catch(() => undefined);
            }}
          />
          <div className="review-fields">
            {Object.keys(values).length ? (
              <ul className="pay-list">
                {Object.entries(values).map(([k, v]) => (
                  <li key={k}>
                    <span>{PAYMENT_LABELS[k] || k}</span>
                    <strong>{money(v)}</strong>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="muted">Nenhum valor lido neste cupom.</p>
            )}
            {coupon.matchResult ? (
              <div
                className={coupon.matchResult.ok ? 'ok' : 'bad'}
                style={{ marginTop: '0.75rem', fontWeight: 650 }}
              >
                {coupon.matchResult.ok ? 'Conferência OK' : 'Divergente com o caixa'}
              </div>
            ) : null}
          </div>
        </div>
      </div>
    </div>,
    document.body,
  );
}
