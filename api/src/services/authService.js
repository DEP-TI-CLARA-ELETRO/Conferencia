import { Role } from '../models/Role.js';
import { Store } from '../models/Store.js';
import { User } from '../models/User.js';
import { Session } from '../models/Session.js';
import { AuditLog } from '../models/AuditLog.js';
import { generateToken, hashToken } from '../security.js';
import { config } from '../config.js';

const ROLE_LABELS = {
  admin: 'Administrador',
  fiscal: 'Fiscal de Caixa',
  tesouraria: 'Tesouraria',
  gerencia: 'Gerencia',
  supervisao: 'Supervisao',
  controladoria: 'Controladoria',
  rh: 'Recursos Humanos',
  financeiro: 'Financeiro',
};

export async function findCredentials(email) {
  const user = await User.findOne({ email: email.toLowerCase() });
  if (!user) return null;
  return { id: user._id, passwordHash: user.passwordHash, active: user.active };
}

export async function userExists(email) {
  return Boolean(await User.exists({ email: email.toLowerCase() }));
}

export async function createUser({ email, name, passwordHash, registration }) {
  const user = await User.create({
    email: email.toLowerCase(),
    name,
    registration: registration ?? null,
    passwordHash,
  });
  return user._id;
}

export async function assignRole(userId, roleCode, storeId = null) {
  const user = await User.findById(userId);
  if (!user) return;
  const exists = user.roles.some(
    (r) => r.roleCode === roleCode && (r.storeId ?? null) === (storeId ?? null),
  );
  if (!exists) {
    user.roles.push({ roleCode, storeId });
    await user.save();
  }
}

export async function loadUser(userId) {
  const user = await User.findOne({ _id: userId, active: true });
  if (!user) return null;

  const roleCodes = [...new Set(user.roles.map((r) => r.roleCode))];
  const roleDocs = await Role.find({ code: { $in: roleCodes } });
  const permissions = [
    ...new Set(roleDocs.flatMap((r) => r.permissions || [])),
  ];

  const hasAllStores = user.roles.some((r) => r.storeId == null);
  const scopedIds = user.roles.map((r) => r.storeId).filter((id) => id != null);
  const storeQuery = hasAllStores
    ? { active: true }
    : { active: true, id: { $in: scopedIds } };
  const stores = await Store.find(storeQuery).sort({
    businessUnit: 1,
    name: 1,
    code: 1,
  });

  return {
    id: user._id,
    email: user.email,
    name: user.name,
    registration: user.registration,
    roles: roleCodes,
    permissions,
    stores: stores.map((s) => ({
      id: s.id,
      code: s.code,
      name: s.name,
      businessUnit: s.businessUnit,
    })),
    roleLabel: roleCodes.length ? ROLE_LABELS[roleCodes[0]] || roleCodes[0] : '',
  };
}

export async function createSession(userId, { ip, userAgent } = {}) {
  const token = generateToken();
  const expiresAt = new Date(
    Date.now() + config.sessionTtlHours * 60 * 60 * 1000,
  );
  await Session.create({
    userId,
    tokenHash: hashToken(token),
    expiresAt,
    ip: ip ?? null,
    userAgent: userAgent ?? null,
  });
  await User.updateOne({ _id: userId }, { lastLoginAt: new Date() });
  return { token, expiresAt };
}

export async function findActiveSession(token) {
  const session = await Session.findOne({
    tokenHash: hashToken(token),
    revokedAt: null,
    expiresAt: { $gt: new Date() },
  });
  if (!session) return null;
  return { id: session._id, userId: session.userId };
}

export async function revokeSession(sessionId) {
  await Session.updateOne(
    { _id: sessionId },
    { revokedAt: new Date() },
  );
}

export async function audit(action, { userId, entity, entityId, details, ip } = {}) {
  await AuditLog.create({
    userId: userId ?? null,
    action,
    entity: entity ?? null,
    entityId: entityId ?? null,
    details: details ?? null,
    ip: ip ?? null,
  });
}

export function userCan(user, permission) {
  return Boolean(user?.permissions?.includes(permission));
}

export function userStoreIds(user) {
  return (user?.stores || []).map((s) => s.id);
}

export function canAccessStore(user, storeId) {
  if (userCan(user, 'users.manage')) return true;
  return userStoreIds(user).includes(storeId);
}
