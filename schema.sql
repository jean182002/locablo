-- Locablo — esquema completo de la base de datos D1 (SQLite).
-- Este archivo es para instalaciones DESDE CERO. Si ya tienes una base
-- con el esquema viejo, NO uses este archivo: aplica las migraciones
-- de la carpeta migrations/ en orden (ver migrations/README.md).
-- Se crea con: npx wrangler d1 execute locablo --file=schema.sql

-- Usuarios. El correo SIEMPRE se guarda normalizado (sin espacios y en
-- minúsculas, ver normalizarEmail en src/worker.js). La contraseña NUNCA
-- se guarda en texto plano, solo su hash.
-- email_verified_at es NULL hasta que el usuario verifique su correo
-- (la verificación está preparada pero el envío de correos no).
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  email_verified_at TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Negocios: cada uno tiene su subdominio, que es único en toda la base.
-- NO tiene owner_id: quién es dueño o colaborador vive en memberships.
CREATE TABLE IF NOT EXISTS businesses (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  subdomain TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_businesses_subdomain ON businesses(subdomain);

-- Membresías: la relación entre usuarios y negocios.
-- Un usuario puede administrar varios negocios y un negocio puede
-- tener varios usuarios. role es 'owner' (dueño) o 'collaborator'.
CREATE TABLE IF NOT EXISTS memberships (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  business_id TEXT NOT NULL REFERENCES businesses(id),
  role TEXT NOT NULL CHECK (role IN ('owner', 'collaborator')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(user_id, business_id)
);
CREATE INDEX IF NOT EXISTS idx_memberships_user ON memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_memberships_business ON memberships(business_id);

-- Piezas de la página de cada negocio: título, texto, foto, botón, etc.
-- content es JSON con los datos de la pieza (por ejemplo {"texto": "Hola"}).
CREATE TABLE IF NOT EXISTS pieces (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL REFERENCES businesses(id),
  type TEXT NOT NULL,
  content TEXT NOT NULL,
  position INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_pieces_business ON pieces(business_id, position);

-- Sesiones: cuando un usuario entra, se le da un token. Cada petición
-- del editor revisa que el token sea válido y de quién es, para que
-- nadie pueda ver ni cambiar el negocio de otro.
CREATE TABLE IF NOT EXISTS sessions (
  token TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  expira TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);

-- Verificación de correo (PREPARACIÓN, sin envío todavía).
-- Cuando se envíe el correo de verificación, aquí se guarda el token
-- (solo su hash, nunca el token en texto plano) y cuándo vence.
CREATE TABLE IF NOT EXISTS email_verifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  token_hash TEXT NOT NULL,
  expira TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_email_verifications_user ON email_verifications(user_id);

-- Recuperación de contraseña (PREPARACIÓN, sin envío todavía).
-- Igual que arriba: solo el hash del token, vencimiento, y si ya se usó.
CREATE TABLE IF NOT EXISTS password_resets (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  token_hash TEXT NOT NULL,
  expira TEXT NOT NULL,
  usado INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_password_resets_user ON password_resets(user_id);

-- Subdominios reservados: nombres que nadie puede registrar como su
-- negocio (www, api, admin, editor...). Son de infraestructura.
CREATE TABLE IF NOT EXISTS reserved_subdomains (
  name TEXT PRIMARY KEY
);
INSERT OR IGNORE INTO reserved_subdomains (name) VALUES
  ('www'), ('api'), ('admin'), ('app'), ('mail'), ('email'),
  ('support'), ('ayuda'), ('blog'), ('help'), ('login'), ('entrar'),
  ('registro'), ('signup'), ('signin'), ('editor'), ('dashboard'),
  ('panel'), ('settings'), ('config'), ('static'), ('assets'),
  ('cdn'), ('locablo'), ('root'), ('test'), ('demo'), ('staging'),
  ('dev'), ('ns1'), ('ns2'), ('ftp'), ('ssh'), ('smtp'), ('imap'),
  ('pop3'), ('webmail'), ('mx');
