-- Migración 002 — de un dueño por negocio a membresías.
-- Convierte una base con el esquema 001 al esquema nuevo SIN borrar
-- ningún dato: cada negocio que tenía owner_id se convierte en una
-- membresía con rol 'owner' para ese usuario.
-- Se aplica UNA SOLA VEZ: wrangler la registra en la tabla
-- d1_migrations y no la vuelve a aplicar (ver migrations/README.md).

-- (a) La columna para saber cuándo se verificó el correo.
-- (Si la columna ya existe, wrangler no llega aquí porque la migración
-- ya quedó registrada como aplicada.)
ALTER TABLE users ADD COLUMN email_verified_at TEXT;

-- (a) Normalizar los correos que ya existen: sin espacios, en minúsculas.
-- OR IGNORE por si dos cuentas se volvieran el mismo correo al
-- normalizar: esa fila se queda como estaba y no se rompe nada.
UPDATE OR IGNORE users SET email = lower(trim(email));

-- (b) La tabla de membresías (quién pertenece a cada negocio y con qué rol).
CREATE TABLE IF NOT EXISTS memberships (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  business_id TEXT NOT NULL REFERENCES businesses(id),
  role TEXT NOT NULL CHECK (role IN ('owner', 'collaborator')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(user_id, business_id)
);

-- (b) Cada negocio que tenía dueño pasa a tener una membresía 'owner'.
-- OR IGNORE por si la membresía ya existe.
INSERT OR IGNORE INTO memberships (id, user_id, business_id, role)
  SELECT hex(randomblob(16)), owner_id, id, 'owner' FROM businesses;

-- (c) El dueño ya no vive en businesses: ahora vive en memberships.
-- OJO: primero se borra el índice sobre owner_id, porque SQLite no
-- deja soltar la columna mientras el índice existe.
DROP INDEX IF EXISTS idx_businesses_owner;
ALTER TABLE businesses DROP COLUMN owner_id;

-- (d) Tablas nuevas, solo preparación (sin envío de correo todavía).
CREATE TABLE IF NOT EXISTS email_verifications (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  token_hash TEXT NOT NULL,
  expira TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_email_verifications_user ON email_verifications(user_id);

CREATE TABLE IF NOT EXISTS password_resets (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  token_hash TEXT NOT NULL,
  expira TEXT NOT NULL,
  usado INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_password_resets_user ON password_resets(user_id);

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

-- (e) Índices nuevos (los que ya existían se quedan como estaban).
CREATE INDEX IF NOT EXISTS idx_businesses_subdomain ON businesses(subdomain);
CREATE INDEX IF NOT EXISTS idx_memberships_user ON memberships(user_id);
CREATE INDEX IF NOT EXISTS idx_memberships_business ON memberships(business_id);
CREATE INDEX IF NOT EXISTS idx_pieces_business ON pieces(business_id, position);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
