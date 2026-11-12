-- Locablo — tablas de la base de datos D1 (SQLite).
-- Se crean con: npx wrangler d1 execute locablo --file=schema.sql

-- Usuarios: dueños de negocios. La contraseña NUNCA se guarda en texto
-- plano, solo su hash (ver src/worker.js).
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Negocios: cada uno tiene su subdominio, que es único en toda la base.
CREATE TABLE IF NOT EXISTS businesses (
  id TEXT PRIMARY KEY,
  owner_id TEXT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  subdomain TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_businesses_subdomain ON businesses(subdomain);
CREATE INDEX IF NOT EXISTS idx_businesses_owner ON businesses(owner_id);

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

-- Sesiones: cuando un usuario entra, se le da un token. Cada petición del
-- editor revisa que el token sea válido y de quién es, para que nadie
-- pueda ver ni cambiar el negocio de otro.
CREATE TABLE IF NOT EXISTS sessions (
  token TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  expira TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
