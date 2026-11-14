import { connectDb } from './db.js';
import { config } from './config.js';
import { Role } from './models/Role.js';
import { Store } from './models/Store.js';
import { hashPassword } from './security.js';
import {
  assignRole,
  createUser,
  userExists,
} from './services/authService.js';

const ROLE_DEFS = [
  { code: 'admin', name: 'Administrador' },
  { code: 'fiscal', name: 'Fiscal de Caixa' },
  { code: 'tesouraria', name: 'Tesouraria' },
  { code: 'gerencia', name: 'Gerencia' },
  { code: 'supervisao', name: 'Supervisao' },
  { code: 'controladoria', name: 'Controladoria' },
  { code: 'rh', name: 'Recursos Humanos' },
  { code: 'financeiro', name: 'Financeiro' },
];

const ALL_PERMS = [
  'home.view',
  'closings.view',
  'closings.fiscal',
  'closings.treasury',
  'closings.manager',
  'closings.supervisor',
  'closings.audit',
  'vouchers.view',
  'hr.view',
  'finance.view',
  'users.manage',
];

const ROLE_PERMS = {
  admin: ALL_PERMS,
  fiscal: ['home.view', 'closings.view', 'closings.fiscal'],
  tesouraria: ['home.view', 'closings.view', 'closings.treasury'],
  gerencia: ['home.view', 'closings.view', 'closings.manager', 'vouchers.view'],
  supervisao: ['home.view', 'closings.view', 'closings.supervisor'],
  controladoria: ['home.view', 'closings.view', 'closings.audit'],
  rh: ['home.view', 'hr.view', 'vouchers.view'],
  financeiro: ['home.view', 'closings.view', 'finance.view'],
};

async function ensureRoles() {
  for (const r of ROLE_DEFS) {
    await Role.findOneAndUpdate(
      { code: r.code },
      { name: r.name, permissions: ROLE_PERMS[r.code] || [] },
      { upsert: true },
    );
  }
}

async function ensureStore() {
  let store = await Store.findOne({ code: '01' });
  if (!store) {
    store = await Store.create({
      code: '01',
      name: 'Loja 01 - Centro',
      connector: 'manual',
      active: true,
    });
  }
  return store;
}

async function ensureUser({ email, name, password, role, registration, storeId }) {
  if (await userExists(email)) return;
  const id = await createUser({
    email,
    name,
    registration,
    passwordHash: hashPassword(password),
  });
  await assignRole(id, role, storeId ?? null);
  console.log(`usuario criado: ${email} (${role})`);
}

export async function runSeed() {
  await ensureRoles();
  const store = await ensureStore();

  const email = config.seedAdminEmail;
  const password = config.seedAdminPassword;
  if (!email || !password) return;

  await ensureUser({
    email,
    name: 'Administrador',
    password,
    role: 'admin',
  });

  if (config.seedDemoUsers) {
    await ensureUser({
      email: 'fiscal@conferencia.local',
      name: 'Maria Silva',
      registration: '4587',
      password,
      role: 'fiscal',
      storeId: store.id,
    });
    await ensureUser({
      email: 'tesouraria@conferencia.local',
      name: 'João Torres',
      registration: '3300',
      password,
      role: 'tesouraria',
      storeId: store.id,
    });
  }
}

const isMain = process.argv[1] && process.argv[1].replace(/\\/g, '/').endsWith('/seed.js');
if (isMain) {
  connectDb()
    .then(runSeed)
    .then(() => {
      console.log('seed ok');
      process.exit(0);
    })
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
