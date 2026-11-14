import { Router } from 'express';
import { config } from '../config.js';
import {
  audit,
  createSession,
  findCredentials,
  loadUser,
  revokeSession,
} from '../services/authService.js';
import {
  dummyPasswordHash,
  verifyPassword,
} from '../security.js';
import { requireAuth } from '../middleware/auth.js';

const failCounts = new Map();

function rateLimited(key) {
  const now = Date.now();
  const entry = failCounts.get(key) || { count: 0, resetAt: now + 10 * 60 * 1000 };
  if (now > entry.resetAt) {
    entry.count = 0;
    entry.resetAt = now + 10 * 60 * 1000;
  }
  if (entry.count >= 5) {
    failCounts.set(key, entry);
    return true;
  }
  return false;
}

function bumpFail(key) {
  const now = Date.now();
  const entry = failCounts.get(key) || { count: 0, resetAt: now + 10 * 60 * 1000 };
  if (now > entry.resetAt) {
    entry.count = 0;
    entry.resetAt = now + 10 * 60 * 1000;
  }
  entry.count += 1;
  failCounts.set(key, entry);
}

export const authRouter = Router();

authRouter.post('/login', async (req, res, next) => {
  try {
    const email = String(req.body?.email || '').trim();
    const password = String(req.body?.password || '');
    const ip = req.ip;
    const key = `${ip}|${email.toLowerCase()}`;
    if (!email || !password) {
      return res.status(400).json({ error: 'invalid_request' });
    }
    if (rateLimited(key)) {
      return res.status(429).json({ error: 'too_many_attempts' });
    }

    const creds = await findCredentials(email);
    const hash = creds?.passwordHash || dummyPasswordHash;
    const ok = verifyPassword(password, hash);
    if (!creds || !creds.active || !ok) {
      bumpFail(key);
      await audit('login_failed', { details: { email }, ip });
      return res.status(401).json({ error: 'invalid_credentials' });
    }

    failCounts.delete(key);
    const { token, expiresAt } = await createSession(creds.id, {
      ip,
      userAgent: req.get('user-agent'),
    });
    const user = await loadUser(creds.id);
    await audit('login', { userId: creds.id, ip });
    res.json({
      token,
      expiresAt: expiresAt.toISOString(),
      user,
    });
  } catch (err) {
    next(err);
  }
});

authRouter.post('/logout', requireAuth, async (req, res, next) => {
  try {
    await revokeSession(req.sessionId);
    await audit('logout', { userId: req.user.id, ip: req.ip });
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});

authRouter.get('/me', requireAuth, async (req, res) => {
  res.json(req.user);
});

// silence unused
void config;
