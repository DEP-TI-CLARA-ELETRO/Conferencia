import crypto from 'node:crypto';
import bcrypt from 'bcryptjs';

export function hashPassword(password) {
  return bcrypt.hashSync(password, 10);
}

export function verifyPassword(password, hash) {
  try {
    return bcrypt.compareSync(password, hash);
  } catch {
    return false;
  }
}

export const dummyPasswordHash = hashPassword('nao-existe-esse-usuario');

export function generateToken() {
  return crypto.randomBytes(32).toString('base64url');
}

export function hashToken(token) {
  return crypto.createHash('sha256').update(token, 'utf8').digest('hex');
}
