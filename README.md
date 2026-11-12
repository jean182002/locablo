# Locablo — los huesos

Esto es el esqueleto del sistema, no el producto terminado. Aquí está
solo lo que hace falta para que el flujo funcione: un usuario escribe el
nombre de su negocio, consigue su subdominio (por ejemplo
`tienda1.locablo.com`) y entra a su editor.

## El flujo (aprobado)

1. El usuario entra a locablo.com y escribe el nombre de su negocio en un
   solo campo.
2. El sistema le propone su subdominio al instante. Si está ocupado o no le
   gusta, escribe otro y se revisa al momento si está libre.
3. Crea su cuenta con correo y contraseña. En ese momento se aparta su
   subdominio.
4. Entra a su editor: agrega piezas, cambia textos y colores con la mano,
   y publica. Su página ya vive en su subdominio.
5. Para volver, entra a locablo.com con su correo y contraseña, y cae
   directo en su editor.

## Arquitectura

Tres piezas separadas, como debe ser en un SaaS multiempresa:

- **Usuarios (`users`)** — las personas: correo y contraseña. El correo
  siempre se guarda normalizado (sin espacios, en minúsculas).
- **Negocios (`businesses`)** — cada negocio tiene su nombre y su
  subdominio único. No tiene dueño directo.
- **Membresías (`memberships`)** — quién pertenece a cada negocio y con
  qué rol. Un usuario puede administrar varios negocios y un negocio
  puede tener varios usuarios.

Roles:

- **owner (dueño)** — crea el negocio y lo administra. Es el rol que se
  da al registrarse y al crear un negocio nuevo.
- **collaborator (colaborador)** — por ahora solo entra al editor de ese
  negocio. El detalle fino de qué puede tocar cada colaborador es
  trabajo futuro, todavía no está definido.

El aislamiento es estricto: cada lectura o escritura con alcance de
negocio pasa por la membresía. Sin membresía, la respuesta es 403
(prohibido). La página pública de cada negocio, en cambio, la ve todo
el mundo sin entrar con cuenta.

Los subdominios son únicos y normalizados (minúsculas, sin acentos,
espacios a guiones). Hay nombres reservados que nadie puede registrar
(`www`, `api`, `admin`, `editor`, `login` y otros de infraestructura);
viven en la tabla `reserved_subdomains`.

## Qué hay en este repo

- `wrangler.toml` — la configuración para Cloudflare (producción).
- `wrangler.local.toml` — igual, pero sin las rutas, para probar en tu
  computadora.
- `src/worker.js` — el programa pequeño que recibe todas las visitas:
  lee el subdominio de la dirección, busca ese negocio en la base de
  datos y muestra su página. También atiende el registro, el inicio de
  sesión, la revisión de subdominios libres y la lista de negocios.
- `schema.sql` — las tablas de la base de datos D1, esquema completo
  nuevo. Solo para instalaciones desde cero.
- `migrations/` — los cambios de la base en orden (`001_initial.sql`,
  `002_memberships.sql`) y su README con cómo aplicarlos.
- `public/index.html` — la página principal: el campo del nombre, la
  vista previa del subdominio y el registro.
- `public/negocio.html` — la plantilla de la página de cada negocio.
- `public/editor.html` — el esqueleto del editor (agregar, mover y
  recolorear piezas es el siguiente paso).

## Seguridad (los huesos ya lo tienen en cuenta)

- Las contraseñas nunca se guardan como texto: se guardan como un hash
  (una huella que no se puede revertir).
- Cada petición del editor revisa la sesión: un usuario solo ve y cambia
  los negocios de los que es miembro, nunca los de otro.
- El subdominio es único en la base de datos: no se puede crear dos
  veces. Los nombres reservados tampoco se pueden registrar.
- La sesión va en una cookie HttpOnly (el navegador no deja que
  JavaScript la lea) y SameSite=Lax. El atributo Secure solo se pone en
  internet (https); en la computadora (http) no, porque si no el
  navegador ignoraría la cookie y no se podría probar en local.
- Los correos se normalizan al registrarse y al entrar, para que
  "Juan@Ejemplo.com" y "juan@ejemplo.com" sean la misma cuenta.

## Migraciones

Los cambios de la base de datos van en orden en la carpeta
`migrations/`, y se aplican una sola vez (wrangler anota cada una en la
tabla `d1_migrations`).

- `001_initial.sql` — el esquema original (los huesos). Es el historial.
- `002_memberships.sql` — convierte una base vieja al esquema nuevo sin
  borrar datos: normaliza los correos, crea `memberships` con rol
  `owner` para cada dueño anterior, quita `owner_id` de los negocios y
  crea `email_verifications`, `password_resets` y
  `reserved_subdomains`.

Aplicar en local:

```bash
npx wrangler d1 migrations apply locablo --local
```

Aplicar en producción (cuando la base real exista):

```bash
npx wrangler d1 migrations apply locablo
```

Ver qué falta por aplicar:

```bash
npx wrangler d1 migrations list locablo --local
```

Verificar que los datos se conservaron (después de la 002):

```bash
npx wrangler d1 execute locablo --local --command "SELECT count(*) AS negocios FROM businesses;"
npx wrangler d1 execute locablo --local --command "SELECT b.subdomain, m.role FROM businesses b JOIN memberships m ON m.business_id = b.id;"
```

El detalle completo está en `migrations/README.md`.

## Probar en tu computadora (sin publicar nada)

Todo esto es local: lo que hagas aquí no sale a internet y no toca el
sitio real. La base local es aparte de la base real.

1. Instalar [Node.js](https://nodejs.org) (versión LTS) y
   [Git](https://git-scm.com).
2. Descargar el repo:
   `git clone https://github.com/jean182002/locablo.git`
3. Entrar a la carpeta e instalar:
   `cd locablo` y `npm install`
4. Crear las tablas en la base local.
   Si es la primera vez (base vacía):
   `npx wrangler d1 execute locablo --local --file=schema.sql`
   Si ya tenías una base local del esquema viejo:
   `npx wrangler d1 migrations apply locablo --local`
5. Prender el servidor:
   `npm run dev`
   (usa `wrangler.local.toml`, que es igual pero sin las rutas: con las
   rutas puestas, el servidor local reescribe la dirección y no deja
   probar los subdominios. El archivo que se despliega es
   `wrangler.toml`, con las rutas, y ese no se toca.)
6. Abrir http://localhost:8787 en el navegador: escribe un nombre,
   revisa que el subdominio esté libre, regístrate y entra al editor.
7. Para ver la página del negocio que creaste:
   http://taqueria-el-guero.localhost:8787 (cambia el nombre por el tuyo).
   Si tu computadora no abre esa dirección, es porque no resuelve
   subdominios de localhost; el resto de la prueba igual funciona.

Para apagar el servidor: Ctrl + C en la terminal.

## Cómo desplegar (se hace el viernes/sábado, con la cuenta de Jean)

1. Crear una cuenta gratis en Cloudflare (no pide tarjeta).
2. Crear la base de datos D1:
   `npx wrangler d1 create locablo`
   Copiar el ID que devuelva en `wrangler.toml`, donde dice
   `database_id`.
3. Crear las tablas con las migraciones:
   `npx wrangler d1 migrations apply locablo`
4. Publicar el Worker:
   `npx wrangler deploy`
5. En Hostinger, cambiar los nameservers del dominio locablo.com a los
   de Cloudflare. El dominio sigue siendo de Hostinger, solo cambia
   quién responde por las direcciones. Es gratis.
6. El Worker ya tiene la ruta `*.locablo.com`, así que todos los
   subdominios llegan a la aplicación.

## Qué falta (viernes/sábado)

- Crear la cuenta de Cloudflare y la base D1.
- Desplegar y probar con un negocio de ejemplo.
- El editor completo: agregar, mover y recolorear piezas con la mano.
- Mover los nameservers desde Hostinger.

## Pendiente (no implementado)

- **Verificación de correo y recuperación de contraseña:** las tablas ya
  están listas (`email_verifications` y `password_resets`, con el token
  guardado solo como hash). Lo que falta es el envío de los correos, y
  eso necesita un proveedor de correo: no está implementado ni elegido
  todavía. Elegirlo después no cuesta nada, pero hay que elegirlo antes
  de activar la verificación.
