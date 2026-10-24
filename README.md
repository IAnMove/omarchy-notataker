# Notataker

Plugin de [Omarchy](https://omarchy.org) para hablar con tu agente sobre lo que
ves en pantalla. Captura una zona (como Imprimir pantalla), escribe qué quieres
y **tu agente por defecto de Omarchy** recibe la imagen y la petición:
*transcríbelo y guárdalo en mis notas*, *tradúcelo*, *crea esto*…

## Instalar

```bash
omarchy plugin add https://github.com/IAnMove/omarchy-notataker.git --enable
~/.config/omarchy/plugins/io.github.ianmove.notataker/setup.sh
```

La primera línea añade el icono a la barra y el panel. La segunda crea el
comando `notataker` y el atajo **`Mayús + Imprimir`** en `~/.config/hypr/bindings.lua`
(con copia de seguridad). Necesitas un agente por defecto:
`omarchy default agent <claude|codex|grok|…>`.

Actualizar: `omarchy plugin update io.github.ianmove.notataker`.
Quitar: `~/.config/omarchy/plugins/io.github.ianmove.notataker/setup.sh --uninstall`
y después `omarchy plugin remove io.github.ianmove.notataker`.

> Los plugins de Omarchy se ejecutan sin sandbox dentro del shell. El código de
> este es corto (`bin/notataker`, `Overlay.qml`, `BarWidget.qml`): léelo antes de activarlo.

## Cómo se usa

1. `Mayús + Imprimir`, o clic en el icono de la barra, o `notataker`.
2. Arrastra una zona o haz clic en una ventana. Con teclado: `Tab` cambia de
   ventana y `Enter` captura la resaltada (es el selector de Omarchy).
3. Sale un panel con la miniatura, una caja de texto y atajos de un clic
   (*Transcribir a mis notas*, *Traducir*, *Explicar*, *Resumir*, *Crear esto*).
   `Enter` envía, `Mayús + Enter` salta de línea, `Esc` cancela.
4. Se abre tu agente con la captura y tu petición ya puestas.

Como los agentes leen imágenes por ruta de archivo, el prompt incluye la ruta de
la captura: no hace falta que tu agente tenga una opción especial para imágenes
(probado con grok).

## Ajustes

`~/.config/notataker/config` (lo crea `setup.sh`, con todo comentado):

| Variable | Por defecto | Para qué |
|---|---|---|
| `NOTATAKER_NOTES_DIR` | `~/Documents/Obsidian Vault` | Carpeta de tus notas. Se le dice al agente para cuando le pidas «guárdalo en mis notas». |
| `NOTATAKER_CAPTURE_DIR` | `~/Pictures/Notataker` | Dónde se guardan las capturas. |

Si cancelas el panel, la captura se borra. Si la envías, se queda en esa carpeta.
Otro atajo: `NOTATAKER_KEY="SUPER + SHIFT + S" ./setup.sh`.

Si quitas el icono de la barra, Omarchy da el plugin por desactivado y el panel
deja de abrirse: el atajo sigue funcionando pero pregunta con la caja de texto
simple del menú de Omarchy (sin miniatura ni atajos). Para volver al panel:
`omarchy plugin enable io.github.ianmove.notataker --section right`.

## Seguridad

El agente por defecto de Omarchy se lanza **sin pedir permisos** (así lo
configura `omarchy agent`). Todo lo que salga en la captura le llega al agente, y
una web o un documento malicioso puede traer texto pensado para manipularlo. El
prompt le dice que el texto de la imagen son datos y no instrucciones, pero no
es una garantía: con contenido en el que no confíes, pide cosas inocuas
(*transcribe*, *traduce*) y no que cree o ejecute algo.

## Cómo está hecho

- `bin/notataker`: captura con `omarchy-capture-screenshot`, abre el panel, compone
  el prompt y lanza `omarchy-agent-prompt`.
- `Overlay.qml` / `BarWidget.qml`: el panel y el icono (`overlay` + `bar-widget`).
- `setup.sh`: comando, ajustes y atajo.

MIT, [IAnMove](https://github.com/IAnMove).
