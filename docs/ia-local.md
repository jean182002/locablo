# IA local (y gratis en la nube) para prototipar Locablo en tu laptop

> **Para qué es esta guía:** tener una IA en tu computadora que te ayude a
> hacer prototipos en HTML, CSS y JavaScript para Locablo, sin pagar nada.
> Está escrita para que **ChatGPT te ayude paso a paso** en tu computadora:
> pásale este archivo y dile en qué paso vas y qué error te salió, si sale uno.
>
> **Tu máquina (13 nov 2026):** laptop con AMD A4-7210 APU con Radeon R3
> Graphics, 4 núcleos, 8 GB de RAM (un solo módulo, no es dual), SSD de
> 240 GB, Linux Mint. Todo lo de aquí está elegido para que funcione en
> esa máquina, sin que explote.
>
> **Costo total: $0.** Nada de esto pide tarjeta.

## Qué vas a instalar (resumen)

Hay 3 opciones. No tienes que instalar las 3 hoy; la recomendación es la
**A + B**:

| Opción | Qué es | Velocidad en tu laptop | Internet |
| --- | --- | --- | --- |
| **A. Local: Ollama + Qwen2.5-Coder 1.5B** | La IA vive en tu computadora | Lenta (30–60 s por prototipo chico) | No hace falta |
| **B. Groq gratis** | IA en la nube, plan gratis sin tarjeta | Muy rápida (2–3 s) | Sí |
| **C. Gemini gratis en AI Studio** | IA de Google, plan gratis sin tarjeta | Rápida | Sí |

**Recomendación:** usa la **A** para ideas rápidas sin internet y sin
depender de nadie, y la **B** para los prototipos grandes, donde quieras
velocidad de verdad. La **C** es un respaldo más.

---

## Parte 1 — Ollama + Qwen2.5-Coder 1.5B (IA local)

### Paso 1: instalar Ollama

Ollama es el programa que corre la IA en tu computadora. Es lo más
liviano que hay: en reposo apenas usa memoria.

1. Abre una terminal en Linux Mint.
2. Revisa que tengas `curl` (casi siempre ya viene):
   ```bash
   curl --version
   ```
   Si dice que no existe el comando, instálalo:
   ```bash
   sudo apt install curl -y
   ```
3. Instala Ollama con el comando oficial:
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ```
   Te va a pedir tu contraseña (es el `sudo`). Deja que termine sin
   cerrar la terminal. **Qué deberías ver:** descarga e instalación sin
   errores al final.
4. Comprueba que quedó instalado:
   ```bash
   ollama --version
   ```
   Debería mostrarte un número de versión, por ejemplo `ollama version
   is 0.x.x`.
5. Comprueba que el servicio está corriendo:
   ```bash
   curl http://localhost:11434
   ```
   **Qué deberías ver:** `Ollama is running`.
   Si en vez de eso sale un error de conexión, prende el servicio a mano
   en una terminal aparte (déjala abierta mientras uses la IA):
   ```bash
   ollama serve
   ```

### Paso 2: descargar el modelo

El modelo es la IA en sí. Para tu máquina el correcto es
**Qwen2.5-Coder 1.5B**, hecho para código y de solo ~986 MB:

```bash
ollama pull qwen2.5-coder:1.5b
```

Tarda unos minutos según tu internet. **Qué deberías ver:** la descarga
llegando al 100% y el mensaje de que el modelo quedó listo.

Comprueba que está descargado:

```bash
ollama list
```

Debe aparecer `qwen2.5-coder:1.5b` en la lista.

> **No descargues modelos más grandes.** El 3B va al doble de lento y
> el 7B te deja la máquina en swap (usando el disco como memoria, todo
> se arrastra). Con 8 GB de RAM y un solo canal, el 1.5B es el punto
> correcto.

### Paso 3: primera prueba

```bash
ollama run qwen2.5-coder:1.5b "dame un botón en HTML y CSS que diga 'Pedir tacos', color naranja"
```

La primera respuesta tarda un poco más porque carga el modelo en memoria.
Para salir del chat escribe:

```
/bye
```

### Qué esperar de la IA local (honesto)

- **Velocidad:** en tu APU, calcula unos 5 a 10 tokens por segundo
  (un token es más o menos una palabra corta). Un prototipo chico te
  toma 30 a 60 segundos.
- **Para qué sirve:** piezas pequeñas, una por una: un menú, un
  formulario, una tarjeta, un botón. No le pidas la página completa de
  una vez, los modelos chicos se pierden con peticiones enormes.
- **El ventilador a tope es normal.** El CPU va al 100% unos segundos
  mientras genera. Pon la laptop sobre una mesa dura, no sobre la cama
  ni el sillón.
- **Cierra el navegador mientras genera.** Chrome se come tu RAM y la
  IA necesita esa memoria.

---

## Parte 2 — VS Code + Continue (la IA dentro del editor)

Continue es una extensión gratis de VS Code que se conecta a tu Ollama
local. Así le pides código sin salir del editor.

### Paso 1: instalar la extensión

1. Abre VS Code.
2. Ve a Extensiones (`Ctrl + Shift + X`).
3. Busca **Continue** e instala la extensión de Continue (la del logo
   de Continue).
4. Si te pide crear cuenta o iniciar sesión, puedes saltarlo: para
   usarlo con Ollama local no hace falta cuenta.

### Paso 2: crear el archivo de configuración

Continue se configura con un archivo llamado `config.yaml` en tu carpeta
personal, en `~/.continue/config.yaml`.

1. Crea la carpeta (si no existe):
   ```bash
   mkdir -p ~/.continue
   ```
2. Crea el archivo con este contenido **exacto**. Desde la terminal:
   ```bash
   cat > ~/.continue/config.yaml << 'EOF'
   name: Locablo Local
   version: 1.0.0
   schema: v1
   models:
     - name: Qwen2.5-Coder 1.5B Local
       provider: ollama
       model: qwen2.5-coder:1.5b
       apiBase: http://localhost:11434
       roles:
         - chat
         - edit
         - apply
         - autocomplete
   EOF
   ```
3. Comprueba que quedó bien escrito:
   ```bash
   cat ~/.continue/config.yaml
   ```
   Debe mostrar exactamente lo de arriba.

> El nombre del modelo (`qwen2.5-coder:1.5b`) debe ser **exactamente**
> el que muestra `ollama list`. Si no coincide, Continue no lo encuentra.
>
> Atajo: Continue también puede detectar tus modelos solo. En el
> selector de modelo de Continue busca la opción **Autodetect** y te
> lista lo que tengas descargado en Ollama.

### Paso 3: usarlo

1. Recarga la ventana de VS Code (`Ctrl + Shift + P` → escribe
   `Reload Window` → Enter).
2. Abre Continue con su icono en la barra lateral de VS Code.
3. En el selector de modelo elige **Qwen2.5-Coder 1.5B Local**.
4. Ya puedes usarlo de 3 formas:
   - **Chat:** le escribes lo que quieres, como en el Paso 3 de la
     Parte 1.
   - **Editar:** seleccionas un pedazo de código en el editor y le
     pides que lo cambie.
   - **Autocompletar:** mientras escribes código te sugiere cómo
     seguir (con el modelo chico las sugerencias son simples, pero
     ayudan).

---

## Parte 3 — Groq gratis (rápido, en la nube)

Groq corre modelos grandes en sus propios servidores y responde rapidísimo
(300 a 800 tokens por segundo). El plan gratis no pide tarjeta.

### Paso 1: cuenta y clave

1. Entra a https://console.groq.com y crea una cuenta (con Google o
   con tu correo). **No pide tarjeta.**
2. Ve a **API Keys** → **Create API Key**.
3. Copia la clave y guárdala en un archivo aparte, solo para ti.
   **Solo se muestra una vez** y nunca la pegues en un chat público ni
   la subas al repo.

### Paso 2: probarlo sin código (lo más fácil)

1. Entra a https://console.groq.com/playground
2. Elige el modelo `openai/gpt-oss-120b`.
3. Escribe tu prompt, por ejemplo: *“Dame un menú de navegación en
   HTML y CSS para una taquería”*.
4. Te responde en 2 o 3 segundos.

### Paso 3 (opcional): probarlo con curl desde la terminal

```bash
export GROQ_API_KEY="tu-clave-aqui"
curl https://api.groq.com/openai/v1/chat/completions \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"openai/gpt-oss-120b","messages":[{"role":"user","content":"Dame un menú de navegación en HTML y CSS para una taquería"}]}'
```

### Límites del plan gratis (verificado en nov 2026)

- 30 peticiones por minuto, 1,000 al día y 200,000 tokens al día por
  modelo (en `gpt-oss-120b` y `qwen3.8-27b`).
- Si te sale error **429**, llegaste al límite: espera unos minutos o
  hasta mañana.
- Los límites y los modelos cambian con el tiempo; los valores actuales
  están en https://console.groq.com/docs/rate-limits

---

## Parte 4 — Gemini gratis en AI Studio (rápido, en la nube)

1. Entra a https://aistudio.google.com con tu cuenta de Google.
2. Chatea con **Gemini 2.5 Flash** gratis, sin tarjeta. Son cientos de
   peticiones al día; tus límites exactos se ven en
   https://aistudio.google.com/rate-limit
3. Si quieres usarlo con clave API: **Get API Key** → **Create API key**.

> En el plan gratis, Google puede usar lo que escribes para mejorar sus
> modelos. **No pegues contraseñas, claves ni datos privados** en ningún
> chat de IA, ni en Gemini, ni en Groq, ni en ChatGPT.

---

## Parte 5 — Cómo pedir prototipos para Locablo

La regla de oro con modelos chicos: **pieza por pieza, no la página
completa.** Primero el menú, luego el formulario, luego la tarjeta.

### Prompts listos para copiar

**Un menú de navegación:**
> Dame un menú de navegación en HTML y CSS para una taquería: logo a la
> izquierda, enlaces Inicio, Menú y Contacto, y un botón naranja de
> WhatsApp a la derecha. Que se vea bien en celular.

**Una tarjeta de producto:**
> Dame una tarjeta de producto en HTML y CSS: foto, nombre "Tacos al
> pastor", precio $25 y botón "Agregar".

**Un formulario de registro:**
> Dame un formulario de registro en HTML y CSS: nombre del negocio,
> correo y contraseña, con un botón verde.

**Una página de negocio (solo cuando ya domines las piezas):**
> Dame una página simple en HTML y CSS para una papelería: encabezado
> con el nombre, una sección de productos con 3 tarjetas y un pie con el
> teléfono. Todo en un solo archivo HTML.

### Cómo guardar y probar lo que te dé

1. Copia el código que te dio la IA.
2. Guárdalo en un archivo, por ejemplo `prueba-menu.html`, en una
   carpeta de pruebas (no dentro del repo de Locablo hasta que te guste).
3. Ábrelo con doble clic: se abre en el navegador y ves el resultado.
4. Si algo no se ve bien, cópiale el error o descríbele qué se ve mal y
   pídele que lo arregle. Así se itera: pedir, ver, corregir.
5. Si le pides CSS o JavaScript aparte, dile *"en archivos separados"*
   y guarda cada uno con su nombre (`estilo.css`, `app.js`).

### Revisar el código

Los modelos chicos se equivocan: a veces inventan clases, olvidan
cerrar etiquetas o ponen colores raros. **Siempre abre el archivo en el
navegador y míralo antes de usarlo en Locablo.** Si algo falla, la
misma IA te lo puede arreglar si le copias el error.

---

## Problemas comunes

| Problema | Qué hacer |
| --- | --- |
| `curl: (7) Failed to connect to localhost port 11434` | Ollama no está corriendo. En una terminal aparte ejecuta `ollama serve` y déjala abierta, o `sudo systemctl start ollama`. |
| `Error: model not found` o 404 en Continue | El modelo no se descargó o el nombre no coincide. Corre `ollama pull qwen2.5-coder:1.5b` y revisa `ollama list`. |
| Va muy lento o se traba todo | Cierra el navegador y otras apps. No uses modelos 3B o 7B. Pide cosas cortas, pieza por pieza. |
| Groq da error 429 | Llegaste al límite gratis. Espera unos minutos o hasta mañana. |
| La laptop se calienta mucho | Normal con el CPU al 100%. Mesa dura, no cama ni sillón. Si se apaga sola, deja que se enfríe y no le pidas cosas largas seguidas. |
| Continue no muestra el modelo | Recarga la ventana de VS Code (`Reload Window`). Revisa que `~/.continue/config.yaml` tenga el modelo exacto de `ollama list`. |
| Ollama no se instala | Revisa que tengas internet y `curl`. Si el instalador falla, copia el mensaje de error completo y pásaselo a ChatGPT. |

---

## Checklist final

- [ ] Ollama instalado y `curl http://localhost:11434` responde `Ollama is running`
- [ ] Modelo `qwen2.5-coder:1.5b` descargado (`ollama list` lo muestra)
- [ ] Primera respuesta local generada con `ollama run`
- [ ] Continue instalado en VS Code y conectado al modelo local
- [ ] Cuenta de Groq creada y el playground probado
- [ ] (Opcional) Gemini probado en AI Studio

---

## Notas

- **Fecha de la guía:** 13 de noviembre de 2026. Los límites gratis y
  los modelos cambian con el tiempo; si algo no coincide, revisa las
  páginas oficiales enlazadas arriba.
- **Enlaces oficiales:** https://ollama.com ·
  https://console.groq.com · https://aistudio.google.com ·
  https://continue.dev
- **Seguridad:** nunca pegues contraseñas, claves de API ni datos
  privados en un chat de IA. La clave de Groq se guarda solo en tu
  computadora, nunca en el repo ni en un mensaje.
