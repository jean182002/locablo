# Migraciones de la base de datos

Las migraciones son cambios a la base de datos en orden, cada una en su
archivo. Se aplican UNA SOLA VEZ: wrangler anota cada migración
aplicada en la tabla `d1_migrations` y no la vuelve a aplicar.

## Qué hace cada archivo

- `001_initial.sql` — el esquema original (los huesos): usuarios,
  negocios con `owner_id`, piezas y sesiones. Es el historial, no se toca.
- `002_memberships.sql` — convierte una base vieja (001) al esquema
  nuevo SIN borrar datos:
  - Agrega `email_verified_at` a los usuarios y normaliza los correos
    que ya existen (sin espacios, en minúsculas).
  - Crea la tabla `memberships` y convierte cada `owner_id` en una
    membresía con rol `owner`.
  - Quita la columna `owner_id` de los negocios.
  - Crea las tablas `email_verifications`, `password_resets` y
    `reserved_subdomains` (con la lista de nombres reservados).
  - Crea los índices nuevos.

El archivo `schema.sql` de la raíz es el esquema completo NUEVO, solo
para instalaciones desde cero. Si ya tienes una base, usa las
migraciones, no `schema.sql`.

## Aplicar en local (tu computadora)

Con el servidor apagado, desde la carpeta del repo:

```bash
npx wrangler d1 migrations apply locablo --local
```

Wrangler te muestra qué migraciones va a aplicar y te pide confirmar.
Después, la base local ya tiene el esquema nuevo.

## Aplicar en producción (cuando la base real exista)

```bash
npx wrangler d1 migrations apply locablo
```

Sin `--local`, se aplica a la base real de Cloudflare. Es el mismo
comando y las mismas migraciones; no hay que hacer nada a mano.

## Ver las migraciones pendientes

```bash
npx wrangler d1 migrations list locablo --local   # en local
npx wrangler d1 migrations list locablo            # en producción
```

## Verificar que los datos se conservaron

Después de aplicar la 002, revisa que nada se perdió:

```bash
# Cuántos usuarios y negocios hay (deben ser los mismos que antes)
npx wrangler d1 execute locablo --local --command "SELECT count(*) AS usuarios FROM users;"
npx wrangler d1 execute locablo --local --command "SELECT count(*) AS negocios FROM businesses;"

# Cada negocio debe tener su membresía 'owner'
npx wrangler d1 execute locablo --local --command "SELECT b.subdomain, m.role FROM businesses b JOIN memberships m ON m.business_id = b.id;"

# Los correos deben estar normalizados (sin espacios ni mayúsculas)
npx wrangler d1 execute locablo --local --command "SELECT email FROM users;"

# businesses ya no debe tener la columna owner_id
npx wrangler d1 execute locablo --local --command "PRAGMA table_info(businesses);"
```

En producción, quita `--local` de esos comandos.
