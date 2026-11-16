# DeepSeek en Locablo — ¿se puede? Sí, y sale casi gratis

> **Veredicto (16 nov 2026):** sí se puede integrar. DeepSeek tiene una
> API barata, compatible con OpenAI, que se llama desde el Worker de
> Cloudflare con un simple `fetch()`. Con el diseño de abajo, cada página
> que un cliente genere le cuesta a Locablo **menos de 2 centavos de
> peso**. La IA es solo una ayuda al inicio: si falla, si no hay saldo
> o si no hay clave, Locablo sigue funcionando igual, a mano, como
> siempre (Principio 1: el producto no depende de la IA).

## Qué es DeepSeek (la API)

DeepSeek es una empresa china de IA. Su chat web es gratis; lo que se
paga es su **API** (el servicio para que un programa le pida cosas),
que se cobra por uso, con saldo prepagado, **sin suscripción mensual**.

- **Modelos actuales (nov 2026):** `deepseek-flash` (V4.1 Flash, el
  barato, es el que usaríamos) y `deepseek-v4-pro` (el caro y potente).
  Los nombres viejos `deepseek-chat` y `deepseek-reasoner` ya no
  existen: se retiraron en julio de 2026. Hay que usar `deepseek-flash`.
- **Cómo se llama:** igual que OpenAI. Dirección
  `https://api.deepseek.com`, llamada `POST /chat/completions`, con la
  clave en el encabezado `Authorization: Bearer TU-CLAVE`.
- **Sabe devolver JSON:** sí, tiene modo `response_format:
  { type: "json_object" }`. Eso es clave para nuestro diseño: la IA no
  devuelve una página, devuelve una **instrucción en JSON**.
- **Caché automático:** si le mandamos el mismo texto al inicio de
  cada llamada (nuestro catálogo de piezas), DeepSeek lo guarda en
  caché y las siguientes veces cobra ese texto casi gratis.
- **Saldo:** se recarga en `platform.deepseek.com` (PayPal, tarjeta,
  Alipay o WeChat Pay). El saldo recargado **no vence**. Cuando se
  acaba, la API responde error 402 (sin saldo). Se puede revisar el
  saldo en la página de Billing o con la API:
  `GET https://api.deepseek.com/user/balance` con la clave.

## Precios oficiales (verificado 16 nov 2026)

Fuente: la página oficial de DeepSeek, Models & Pricing
(`https://api-docs.deepseek.com/quick_start/pricing`). Precios por
1 millón de tokens. Un token es más o menos una palabra corta.

**Modelo `deepseek-flash` (el que usaríamos):**

| | Fuera de hora pico | Hora pico |
| --- | --- | --- |
| Entrada (texto repetido, en caché) | $0.003 | $0.006 |
| Entrada (texto nuevo) | $0.15 | $0.30 |
| Salida (lo que responde) | $0.60 | $1.20 |

Hora pico: lunes a viernes de 01:00–04:00 y 06:00–10:00 UTC. Todo lo
demás es fuera de pico, incluidos fines de semana. En horario de México
(CST, UTC−6) casi todo el día es fuera de pico.

`deepseek-v4-pro` cuesta unas 4 veces más. No lo necesitamos.

## Cuánto cuesta cada uso en Locablo

El diseño es lo que hace que salga casi gratis. La IA **no escribe la
página**: solo lee lo que el cliente quiere y devuelve una instrucción
chica en JSON, usando **nuestras piezas**. El Worker arma la página
con esas piezas, como siempre.

Una generación típica:

- **Entrada (~2,100 tokens):** nuestro catálogo de piezas (fijo, se
  guarda en caché tras la primera vez) + lo que escribió el cliente
  (~100 tokens).
- **Salida (~400 tokens):** el JSON con la instrucción.

| Caso | Costo por generación | En pesos (~$17 MXN por USD) |
| --- | --- | --- |
| Normal (caché + fuera de pico) | ~$0.00025 USD | ~$0.004 MXN (menos de medio centavo) |
| Primera vez (sin caché) | ~$0.0006 USD | ~$0.01 MXN (1 centavo) |
| Peor caso (pico + sin caché) | ~$0.0011 USD | ~$0.019 MXN (2 centavos) |

## Qué rinde su saldo

Si Jean recargó 20 o 50 pesos (unos $1.20 o $2.90 USD), a ~$0.0005 USD
por generación:

| Saldo | Generaciones aprox. |
| --- | --- |
| 20 MXN (~$1.20 USD) | ~2,400 |
| 50 MXN (~$2.90 USD) | ~5,800 |
| $20 USD (~340 MXN) | ~40,000 |
| $50 USD (~850 MXN) | ~100,000 |

Incluso si cada generación gastara 10 veces más, 50 pesos darían para
cientos de páginas. Mil negocios generando su página inicial costarían
en total unos $0.50 USD. El gasto real solo crecería si los clientes
regeneraran muchas veces seguidas, por eso el diseño incluye un límite
por negocio (ver abajo).

> **El saldo de Jean no está verificado:** no se puede saber si puso
> 20 o 50 pesos (ni en qué moneda quedó) sin entrar a su cuenta. Se
> revisa en `platform.deepseek.com` → Billing, o pasándole la clave a
> Muse por el flujo seguro y revisándolo con `GET /user/balance`.

## Cómo se integraría (diseño de mínimo gasto)

```
Cliente escribe lo que quiere ("taquería en Reynosa, vendo tacos al pastor")
   → Worker de Cloudflare
   → DeepSeek (deepseek-flash): descripción + catálogo de piezas
   → DeepSeek devuelve solo un JSON chico: qué piezas, qué textos, qué colores
   → Worker revisa el JSON contra nuestro catálogo (si la IA inventa una
     pieza, se ignora) y arma la página con nuestras piezas
   → El cliente ve su página inicial y la sigue editando a mano
```

Reglas del diseño:

1. **La IA solo genera la instrucción, nunca la página.** Así el
   resultado siempre usa nuestros recursos, bien hechos, y no sale una
   página distinta cada vez.
2. **El catálogo es fijo** (las piezas que ya tenemos), así DeepSeek lo
   guarda en caché y la entrada sale casi gratis.
3. **Modelo barato, respuesta corta:** `deepseek-flash`, sin modo de
   razonamiento, `max_tokens: 500`, temperatura baja (0.2) para que el
   JSON salga igual cada vez.
4. **Límite por negocio:** por ejemplo 3 generaciones con IA por
   negocio al día, y un tope mensual en el servidor. Así nadie puede
   gastar el saldo regenerando sin parar.
5. **Si algo falla, no pasa nada:** sin clave, sin saldo, sin internet
   o error de DeepSeek, Locablo sigue igual y el cliente arma su página
   a mano. La IA es un atajo al inicio, no un requisito.
6. **La clave nunca va en el código ni en el navegador.** Se guarda
   como secreto de Cloudflare: `npx wrangler secret put
   DEEPSEEK_API_KEY`. El navegador del cliente nunca la ve.

Ejemplo de la llamada desde el Worker (así de simple es):

```js
const resp = await fetch("https://api.deepseek.com/chat/completions", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Authorization": "Bearer " + env.DEEPSEEK_API_KEY
  },
  body: JSON.stringify({
    model: "deepseek-flash",
    response_format: { type: "json_object" },
    max_tokens: 500,
    temperature: 0.2,
    messages: [
      { role: "system", content: "Eres el ayudante de Locablo. Responde solo con JSON: ..." },
      { role: "user", content: "Taquería en Reynosa, vendo tacos al pastor..." }
    ]
  })
});
const datos = await resp.json();
const instruccion = JSON.parse(datos.choices[0].message.content);
```

(Para el modo JSON, el mensaje del sistema debe decir que responda en
JSON; así lo pide DeepSeek.)

## Cuidados

- **La clave es dinero:** quien tenga la clave gasta el saldo. No va
  en GitHub, no va en el chat, no va en el navegador del cliente. Solo
  como secreto del Worker.
- **Lo que el cliente escribe viaja a los servidores de DeepSeek**
  (empresa china). Son descripciones de negocios, nada delicado, pero
  hay que saberlo.
- **DeepSeek puede caerse o ir lento en hora pico.** El Worker debe
  tener tiempo límite y, si falla, decirle al cliente que lo arme a
  mano. Nunca dejar la página colgada esperando a la IA.
- **Los precios cambian.** Los de arriba son del 16 nov 2026; antes
  de gastar en serio hay que revisar la página oficial.
- **No es gratis del todo:** la app de chat de DeepSeek sí es gratis,
  la API no. Pero a estos precios, el costo por cliente es de
  centavos.

## Estado (16 nov 2026)

El endpoint ya está en el Worker (`POST /api/ayuda-inicio`, migración
`003_ayuda_ia.sql`, tabla `ayuda_ia_uso` para el límite de 3 ayudas
por negocio al día). Todavía NO está activo para los clientes: falta
poner la clave como secreto (`npx wrangler secret put
DEEPSEEK_API_KEY`), probar la llamada real con el saldo de Jean y
poner el botón en el editor. Sin clave, el endpoint responde
`sin_ia` y el cliente sigue armando su página a mano.

## Siguiente paso (cuando Jean quiera)

1. Revisar el saldo: entrar a `platform.deepseek.com` → Billing, o
   pasarle la clave a Muse por el flujo seguro para revisarlo con la
   API (sin guardarla en el repo).
2. Probar con una llamada real desde la terminal (con la clave, sin
   subir nada) para ver que responde y cuánto cobra.
3. Cablear el endpoint en el Worker (`POST /api/ayuda-inicio`) con el
   diseño de arriba, con su límite por negocio y su mensaje si falla.
4. Probarlo con un negocio de ejemplo antes de ofrecérselo a los
   clientes.
