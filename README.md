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

## Qué hay en este repo

- `wrangler.toml` — la configuración para Cloudflare.
- `src/worker.js` — el programa pequeño que recibe todas las visitas:
  lee el subdominio de la dirección, busca ese negocio en la base de
  datos y muestra su página. También atiende el registro, el inicio de
  sesión y la revisión de subdominios libres.
- `schema.sql` — las tablas de la base de datos D1.
- `public/index.html` — la página principal: el campo del nombre, la
  vista previa del subdominio y el registro.
- `public/negocio.html` — la plantilla de la página de cada negocio.
- `public/editor.html` — el esqueleto del editor (agregar, mover y
  recolorear piezas es el siguiente paso).

## Seguridad (los huesos ya lo tienen en cuenta)

- Las contraseñas nunca se guardan como texto: se guardan como un hash
  (una huella que no se puede revertir).
- Cada petición del editor revisa la sesión: un usuario solo ve y cambia
  su propio negocio, nunca el de otro.
- El subdominio es único en la base de datos: no se puede crear dos
  veces.

## Probar en tu computadora (sin publicar nada)

Todo esto es local: lo que hagas aquí no sale a internet y no toca el
sitio real. La base local es aparte de la base real.

1. Instalar [Node.js](https://nodejs.org) (versión LTS) y
   [Git](https://git-scm.com).
2. Descargar el repo:
   `git clone https://github.com/jean182002/locablo.git`
3. Entrar a la carpeta e instalar:
   `cd locablo` y `npm install`
4. Crear las tablas en la base local:
   `npx wrangler d1 execute locablo --local --file=schema.sql`
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
3. Crear las tablas:
   `npx wrangler d1 execute locablo --file=schema.sql`
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
