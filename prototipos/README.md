# Prototipos — dibuja el diseño, la IA lo hace funcional

Esta es la herramienta para crear prototipos de Locablo (y de cualquier
página o función web). Es como dibujar en una libreta el diseño que
quieres, pero digital: pones formas, les pones nombre y dices qué debe
hacer cada cosa. Después descargas el prototipo como un **HTML completo**
y se lo pasas a una IA (ChatGPT, Muse, la IA local, Groq, Gemini) para
que lo construya funcional y puedas probarlo.

## Archivos

- **`app.html`** — la herramienta. Se abre con **doble clic**, no necesita
  servidor ni internet. Todo se guarda solo en tu computadora.
- **`ejemplo-editar-texto.html`** — un prototipo ya exportado de ejemplo:
  cómo se va a editar un texto dentro del editor de Locablo. Ábrelo con
  doble clic para ver cómo queda lo que la IA recibe.

## Cómo se usa (en 5 pasos)

1. **Abre `app.html`** con doble clic. La primera vez se carga el ejemplo
   de editar texto, para que veas cómo funciona.
2. **Dibuja el diseño** con las formas de la izquierda: rectángulo,
   texto, botón, campo (donde se escribe), imagen, círculo y nota.
   Haz clic en una forma y luego haz clic en el lienzo para ponerla.
   Arrástrala para moverla y estira la esquina azul para cambiar su
   tamaño.
3. **Ponle nombre a cada pieza** en la etiqueta (panel de la derecha),
   por ejemplo `boton-guardar` o `campo-texto`. Usa nombres cortos con
   guiones, sin espacios.
4. **Escribe qué debe hacer** cada pieza en el campo "¿Qué debe hacer?
   (función)", por ejemplo: *"Al escribir aquí cambia el título en la
   vista previa"*. Si una pieza es solo visual, déjalo vacío.
5. **Descarga el HTML** con el botón "⬇ Descargar HTML" y pásaselo a
   la IA con el prompt de abajo.

## El proceso completo

```
Dibujar → Poner nombres → Decir qué hace cada cosa
  → Descargar el HTML → Pasárselo a la IA
  → Probar la versión funcional → Corregir el dibujo si hace falta
```

- **Guardar / Abrir:** el botón "💾 Guardar" descarga tu prototipo en
  JSON para seguirlo después con "📂 Abrir". Además se guarda solo en
  el navegador cada vez que cambias algo.
- **Deshacer:** botón "↩ Deshacer" o `Ctrl+Z`.
- **Tamaño del lienzo:** Escritorio (1200×800), Celular (390×844) o
  Tableta (768×1024), arriba a la derecha.
- **Teclas:** `Supr` elimina la pieza seleccionada.

## Qué recibe la IA (y cómo lo lee)

El HTML descargado es un archivo completo y ordenado. Cada elemento
lleva dos cosas:

- **`data-etiqueta`**: el nombre que le pusiste a la pieza
  (por ejemplo `boton-guardar`).
- **`data-funcion`**: lo que debe hacer cuando el usuario interactúa
  con ella (por ejemplo *"Guarda el texto y cierra el panel"*).

El archivo además trae un comentario al inicio que le explica a la IA
cómo leerlo: respetar posiciones y tamaños, usar los nombres de las
etiquetas y preguntar antes de inventar algo que no quede claro.

## Prompt para pasarle el prototipo a la IA

Copia y pega esto junto con el archivo HTML descargado:

> Te paso un prototipo en HTML que dibujé. Cada elemento tiene
> `data-etiqueta` con su nombre y `data-funcion` con lo que debe hacer.
> Hazme la versión funcional en un solo archivo HTML, respetando las
> posiciones y los tamaños del boceto, y pregúntame si algo no queda
> claro antes de inventarlo.

## Formas disponibles

| Forma | Para qué sirve |
| --- | --- |
| Rectángulo | Un bloque o panel, por ejemplo la página o un panel lateral |
| Texto | Un título, un párrafo o una etiqueta de texto |
| Botón | Algo que se presiona, por ejemplo Guardar o Cancelar |
| Campo | Donde el usuario escribe, por ejemplo el nombre del negocio |
| Imagen | Una foto o un dibujo (en el prototipo es solo el lugar que ocupa) |
| Círculo | Un punto, un color o un avatar |
| Nota | Una explicación para la IA; no es un elemento de la página |

## Consejos

- **Pieza por pieza:** primero el diseño general, luego cada función.
- **Nombres claros:** `campo-texto` dice más que `campo1`.
- **Funciones en palabras simples:** escribe lo que debe pasar, no cómo
  se programa. Por ejemplo: *"Al hacer clic abre el panel de editar
  texto"*, no *"onClick abre el modal"*.
- **Revisa el HTML descargado** abriéndolo con doble clic antes de
  pasárselo a la IA: lo que ves ahí es lo que la IA va a ver.
