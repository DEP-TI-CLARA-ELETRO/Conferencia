import {
  findActiveSession,
  loadUser,
  userCan,
} from '../services/authService.js';

export async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const match = header.match(/^Bearer\s+(.+)$/i);
    if (!match) {
      return res.status(401).json({ error: 'unauthenticated' });
    }
    const session = await findActiveSession(match[1]);
    if (!session) {
      return res.status(401).json({ error: 'session_expired' });
    }
    const user = await loadUser(session.userId);
    if (!user) {
      return res.status(401).json({ error: 'unauthenticated' });
    }
    req.user = user;
    req.sessionId = session.id;
    next();
  } catch (err) {
    next(err);
  }
}

export function requirePermission(...perms) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'unauthenticated' });
    }
    if (perms.some((p) => userCan(req.user, p))) return next();
    return res.status(403).json({ error: 'forbidden' });
  };
}
