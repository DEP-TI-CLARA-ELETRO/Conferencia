import type {
  Closing,
  ClosingCoupon,
  ClosingDetail,
  Session,
  User,
} from './types';

const TOKEN_KEY = 'session_token';

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string | null) {
  if (token) localStorage.setItem(TOKEN_KEY, token);
  else localStorage.removeItem(TOKEN_KEY);
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const headers = new Headers(init.headers);
  if (!headers.has('Content-Type') && init.body) {
    headers.set('Content-Type', 'application/json');
  }
  const token = getToken();
  if (token) headers.set('Authorization', `Bearer ${token}`);

  const res = await fetch(path, { ...init, headers });
  if (res.status === 401) {
    const body = await res.json().catch(() => ({}));
    const err = new Error(body.error || 'unauthenticated') as Error & {
      code?: string;
    };
    err.code = body.error || 'unauthenticated';
    throw err;
  }
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.message || body.error || `HTTP ${res.status}`);
  }
  if (res.status === 204) return undefined as T;
  return res.json() as Promise<T>;
}

export const api = {
  login(email: string, password: string) {
    return request<Session>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
  },
  me() {
    return request<User>('/auth/me');
  },
  logout() {
    return request<{ ok: boolean }>('/auth/logout', { method: 'POST' });
  },
  closings(params: {
    dateFrom: string;
    dateTo: string;
    storeId?: number | null;
    businessUnit?: string | null;
  }) {
    const q = new URLSearchParams({
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
    });
    if (params.storeId != null) q.set('storeId', String(params.storeId));
    if (params.businessUnit) q.set('businessUnit', params.businessUnit);
    return request<Closing[]>(`/closings?${q}`);
  },
  closingDetail(id: string) {
    return request<ClosingDetail>(`/closings/${id}/detail`);
  },
  webpostoStatus() {
    return request<{ configured: boolean; baseUrl: string }>('/webposto/status');
  },
  webpostoSync(body: { dateFrom: string; dateTo: string }) {
    return request<{
      companiesUpserted: number;
      closingsUpserted: number;
      from: string;
      to: string;
    }>('/webposto/sync', { method: 'POST', body: JSON.stringify(body) });
  },
  coupons(closingId: string) {
    return request<ClosingCoupon[]>(`/closings/${closingId}/coupons`);
  },
  uploadCoupon(
    closingId: string,
    payload: { imageBase64: string; filename: string; contentType: string },
  ) {
    return request<ClosingCoupon>(`/closings/${closingId}/coupons`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
  deleteCoupon(closingId: string, couponId: string) {
    return request<{ ok: boolean }>(
      `/closings/${closingId}/coupons/${couponId}`,
      { method: 'DELETE' },
    );
  },
  reprocessCoupons(closingId: string) {
    return request<ClosingCoupon[]>(`/closings/${closingId}/coupons/reprocess`, {
      method: 'POST',
    });
  },
  couponImageUrl(closingId: string, couponId: string) {
    return `/closings/${closingId}/coupons/${couponId}/image`;
  },
};
