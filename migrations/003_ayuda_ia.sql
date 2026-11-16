-- 003_ayuda_ia.sql — uso de la ayuda inicial con IA (DeepSeek).
-- Una fila por negocio y por día: cuántas ayudas pidió y cuántos
-- tokens gastó. El Worker la usa para el límite de 3 ayudas por
-- negocio al día (ver LIMITE_AYUDA_IA_POR_DIA en src/worker.js).
-- No borra ni cambia nada de lo que ya existe.
CREATE TABLE IF NOT EXISTS ayuda_ia_uso (
  business_id TEXT NOT NULL,
  fecha TEXT NOT NULL,
  cantidad INTEGER NOT NULL DEFAULT 0,
  tokens_entrada INTEGER NOT NULL DEFAULT 0,
  tokens_salida INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (business_id, fecha)
);
