// Locablo — los huesos.
// Este Worker recibe todas las visitas de locablo.com y de *.locablo.com.
// Lee el subdominio de la dirección, busca ese negocio en la base D1
// y muestra su página. Cada negocio solo ve lo suyo.

// ---------- Ayudas ----------

// Convierte un nombre de negocio en un subdominio válido:
// minúsculas, sin acentos, espacios a guiones, solo letras, números y guiones.
function aSubdominio(nombre) {
  return (nombre || "")
    .toLowerCase()
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "") // quita los acentos
    .replace(/[^a-z0-9]+/g, "-") // lo demás se vuelve guion
    .replace(/^-+|-+$/g, "") // sin guiones al inicio ni al final
    .slice(0, 63); // un subdominio no pasa de 63 letras
}

// Escapa texto para ponerlo en HTML sin romper la página.
function escapar(texto) {
  return String(texto ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// ID único para usuarios, negocios, piezas y sesiones.
function nuevoId() {
  return crypto.randomUUID();
}

function aBase64(buf) {
  return btoa(String.fromCharCode(...new Uint8Array(buf)));
}

// Guarda la contraseña como hash (una huella que no se puede revertir).
// Nunca se guarda la contraseña en texto plano.
async function hashContrasena(contrasena) {
  const sal = crypto.getRandomValues(new Uint8Array(16));
  const llave = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(contrasena), "PBKDF2", false, ["deriveBits"]);
  const hash = await crypto.subtle.deriveBits(
    { name: "PBKDF2", salt: sal, iterations: 100000, hash: "SHA-256" }, llave, 256);
  return aBase64(sal) + ":" + aBase64(hash);
}

// Revisa si una contraseña coincide con el hash guardado.
async function verificaContrasena(contrasena, guardado) {
  const partes = guardado.split(":");
  if (partes.length !== 2) return false;
  const [salB64, hashB64] = partes;
  const sal = Uint8Array.from(atob(salB64), (c) => c.charCodeAt(0));
  const llave = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(contrasena), "PBKDF2", false, ["deriveBits"]);
  const hash = await crypto.subtle.deriveBits(
    { name: "PBKDF2", salt: sal, iterations: 100000, hash: "SHA-256" }, llave, 256);
  return aBase64(hash) === hashB64;
}

// Crea una sesión para un usuario y la guarda. Dura 7 días.
async function crearSesion(env, userId) {
  const token = nuevoId();
  const expira = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
  await env.DB.prepare(
    "INSERT INTO sessions (token, user_id, expira) VALUES (?, ?, ?)"
  ).bind(token, userId, expira).run();
  return token;
}

// Lee la sesión de la cookie. Devuelve el id del usuario o nada.
// Cada petición del editor pasa por aquí: nadie ve lo de otro.
async function usuarioDeSesion(peticion, env) {
  const cookie = peticion.headers.get("Cookie") || "";
  const token = (cookie.match(/(?:^|;\s*)sesion=([^;]+)/) || [])[1];
  if (!token) return null;
  const fila = await env.DB.prepare(
    "SELECT user_id, expira FROM sessions WHERE token = ?"
  ).bind(token).first();
  if (!fila) return null;
  if (new Date(fila.expira).getTime() < Date.now()) return null; // vencida
  return fila.user_id;
}

// Convierte las piezas de un negocio en HTML sencillo.
function piezasAHtml(piezas) {
  if (!piezas || piezas.length === 0) {
    // Negocio nuevo, sin piezas todavía: ejemplos para que no se vea vacío.
    piezas = [
      { type: "titulo", content: JSON.stringify({ texto: "¡Bienvenido a mi negocio!" }) },
      { type: "texto", content: JSON.stringify({ texto: "Aquí va la descripción de tu negocio. Edítala desde tu editor." }) },
      { type: "whatsapp", content: JSON.stringify({ telefono: "520000000000", texto: "Escríbeme por WhatsApp" }) },
    ];
  }
  return piezas.map((pieza) => {
    let datos = {};
    try { datos = JSON.parse(pieza.content || "{}"); } catch { datos = {}; }
    if (pieza.type === "titulo") return `<h2>${escapar(datos.texto || "")}</h2>`;
    if (pieza.type === "texto") return `<p>${escapar(datos.texto || "")}</p>`;
    if (pieza.type === "foto") return `<img src="${escapar(datos.url || "")}" alt="${escapar(datos.texto || "")}">`;
    if (pieza.type === "whatsapp") {
      const tel = escapar(datos.telefono || "");
      return `<a class="boton" href="https://wa.me/${tel}">${escapar(datos.texto || "WhatsApp")}</a>`;
    }
    return "";
  }).join("\n");
}

function paginaNoEncontrada(subdominio) {
  const html = `<!doctype html><html lang="es"><head><meta charset="utf-8"><title>No encontrado — Locablo</title></head><body><h1>Este negocio no existe</h1><p>No hay ningún negocio con el subdominio <b>${escapar(subdominio)}</b>. Revisa la dirección o crea tu negocio en <a href="https://locablo.com">locablo.com</a>.</p></body></html>`;
  return new Response(html, { status: 404, headers: { "Content-Type": "text/html; charset=utf-8" } });
}

// ---------- API ----------

function json(obj, status = 200, headers = {}) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json", ...headers },
  });
}

function cookieSesion(token) {
  return `sesion=${token}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=604800`;
}

async function api(peticion, env, url) {
  // ¿Está libre este subdominio?
  if (url.pathname === "/api/disponible" && peticion.method === "POST") {
    const { subdomain } = await peticion.json();
    const limpio = aSubdominio(subdomain || "");
    if (!limpio) return json({ libre: false, motivo: "Escribe un nombre válido." });
    const fila = await env.DB.prepare(
      "SELECT id FROM businesses WHERE subdomain = ?"
    ).bind(limpio).first();
    return json({ libre: !fila, subdomain: limpio });
  }

  // Crear cuenta + negocio y apartar el subdominio. Todo junto o nada.
  if (url.pathname === "/api/registro" && peticion.method === "POST") {
    const { email, password, name } = await peticion.json();
    const subdomain = aSubdominio(name || "");
    if (!email || !password || password.length < 8) {
      return json({ error: "Falta el correo o la contraseña (mínimo 8 caracteres)." }, 400);
    }
    if (!subdomain) return json({ error: "Ese nombre no sirve para subdominio." }, 400);
    const ocupado = await env.DB.prepare(
      "SELECT id FROM businesses WHERE subdomain = ?"
    ).bind(subdomain).first();
    if (ocupado) return json({ error: "Ese subdominio ya está ocupado. Elige otro." }, 409);
    const existe = await env.DB.prepare(
      "SELECT id FROM users WHERE email = ?"
    ).bind(email).first();
    if (existe) return json({ error: "Ese correo ya tiene cuenta. Entra con tu contraseña." }, 409);

    const userId = nuevoId();
    const negocioId = nuevoId();
    const hash = await hashContrasena(password);
    await env.DB.batch([
      env.DB.prepare("INSERT INTO users (id, email, password_hash) VALUES (?, ?, ?)")
        .bind(userId, email, hash),
      env.DB.prepare("INSERT INTO businesses (id, owner_id, name, subdomain) VALUES (?, ?, ?, ?)")
        .bind(negocioId, userId, name, subdomain),
    ]);
    const token = await crearSesion(env, userId);
    return json({ ok: true, subdomain }, 201, { "Set-Cookie": cookieSesion(token) });
  }

  // Entrar con correo y contraseña.
  if (url.pathname === "/api/login" && peticion.method === "POST") {
    const { email, password } = await peticion.json();
    const user = await env.DB.prepare(
      "SELECT id, password_hash FROM users WHERE email = ?"
    ).bind(email).first();
    if (!user) return json({ error: "Correo o contraseña incorrectos." }, 401);
    const ok = await verificaContrasena(password, user.password_hash);
    if (!ok) return json({ error: "Correo o contraseña incorrectos." }, 401);
    const token = await crearSesion(env, user.id);
    const negocio = await env.DB.prepare(
      "SELECT subdomain FROM businesses WHERE owner_id = ?"
    ).bind(user.id).first();
    return json({ ok: true, subdomain: negocio ? negocio.subdomain : null }, 200, {
      "Set-Cookie": cookieSesion(token),
    });
  }

  // El negocio del dueño que está dentro. Sin sesión, no se muestra nada.
  if (url.pathname === "/api/mi-negocio" && peticion.method === "GET") {
    const userId = await usuarioDeSesion(peticion, env);
    if (!userId) return json({ error: "Entra primero con tu cuenta." }, 401);
    const negocio = await env.DB.prepare(
      "SELECT id, name, subdomain FROM businesses WHERE owner_id = ?"
    ).bind(userId).first();
    if (!negocio) return json({ error: "No tienes negocio todavía." }, 404);
    const piezas = await env.DB.prepare(
      "SELECT id, type, content, position FROM pieces WHERE business_id = ? ORDER BY position ASC"
    ).bind(negocio.id).all();
    return json({ negocio, piezas: piezas.results || [] });
  }

  // Salir: se borra la sesión.
  if (url.pathname === "/api/salir" && peticion.method === "POST") {
    const cookie = peticion.headers.get("Cookie") || "";
    const token = (cookie.match(/(?:^|;\s*)sesion=([^;]+)/) || [])[1];
    if (token) {
      await env.DB.prepare("DELETE FROM sessions WHERE token = ?").bind(token).run();
    }
    return json({ ok: true }, 200, {
      "Set-Cookie": "sesion=; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=0",
    });
  }

  return json({ error: "No existe esa acción." }, 404);
}

// ---------- El Worker ----------

export default {
  async fetch(peticion, env) {
    const url = new URL(peticion.url);
    const host = url.hostname.toLowerCase();

    // Las acciones de la API.
    if (url.pathname.startsWith("/api/")) {
      return await api(peticion, env, url);
    }

    // En la computadora, localhost funciona igual que locablo.com:
    // localhost es la página principal y tienda1.localhost es un negocio.
    const esLocal = host === "localhost" || host.endsWith(".localhost");
    const dominio = esLocal ? "localhost" : "locablo.com";

    // La página principal: locablo.com
    if (host === dominio || host === "www." + dominio) {
      // El editor pide sesión; sin ella, vuelve a la página principal.
      if (url.pathname === "/editor") {
        const userId = await usuarioDeSesion(peticion, env);
        if (!userId) return Response.redirect(new URL("/", peticion.url), 302);
        return env.ASSETS.fetch(new Request(url.origin + "/editor.html"));
      }
      return env.ASSETS.fetch(peticion);
    }

    // Un subdominio: tienda1.locablo.com
    if (host.endsWith("." + dominio)) {
      const subdominio = host.slice(0, -("." + dominio).length);
      const negocio = await env.DB.prepare(
        "SELECT id, name, subdomain FROM businesses WHERE subdomain = ?"
      ).bind(subdominio).first();
      if (!negocio) return paginaNoEncontrada(subdominio);

      // La plantilla de la página del negocio, con sus datos puestos.
      const plantilla = await env.ASSETS.fetch(new Request(url.origin + "/negocio.html"));
      let html = await plantilla.text();
      html = html.replaceAll("{{NOMBRE_NEGOCIO}}", escapar(negocio.name));
      html = html.replaceAll("{{SUBDOMINIO}}", escapar(negocio.subdomain));
      const piezas = await env.DB.prepare(
        "SELECT type, content FROM pieces WHERE business_id = ? ORDER BY position ASC"
      ).bind(negocio.id).all();
      html = html.replaceAll("{{PIEZAS}}", piezasAHtml(piezas.results || []));
      return new Response(html, {
        headers: { "Content-Type": "text/html; charset=utf-8" },
      });
    }

    return new Response("No encontrado", { status: 404 });
  },
};
