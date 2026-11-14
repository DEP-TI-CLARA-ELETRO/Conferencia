import path from 'node:path';
import { fileURLToPath } from 'node:url';
import dotenv from 'dotenv';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config({ path: path.resolve(__dirname, '../../infra/.env') });

function env(key, fallback = '') {
  const v = process.env[key];
  return v === undefined || v === '' ? fallback : v;
}

export const config = {
  port: Number(env('SERVER_PORT', '8080')),
  mongoUri: env('MONGODB_URI', 'mongodb://127.0.0.1:27017/conferencia'),
  corsOrigin: env('CORS_ORIGIN', '*'),
  sessionTtlHours: Number(env('SESSION_TTL_HOURS', '12')),
  seedAdminEmail: env('SEED_ADMIN_EMAIL', ''),
  seedAdminPassword: env('SEED_ADMIN_PASSWORD', ''),
  seedDemoUsers: env('SEED_DEMO_USERS', 'false').toLowerCase() === 'true',
  webpostoBaseUrl: env('WEBPOSTO_BASE_URL', 'https://web.qualityautomacao.com.br'),
  webpostoChave: env('WEBPOSTO_CHAVE', ''),
  get webpostoConfigured() {
    return Boolean(this.webpostoChave);
  },
  couponsUploadDir: path.resolve(
    process.cwd(),
    env('COUPONS_UPLOAD_DIR', 'uploads/coupons'),
  ),
  googleVisionApiKey: env('GOOGLE_VISION_API_KEY', ''),
  tesseractBin: env('TESSERACT_BIN', 'tesseract'),
  tessdataPrefix: env('TESSDATA_PREFIX', ''),
  clientDist: path.resolve(__dirname, '../../client/dist'),
};
