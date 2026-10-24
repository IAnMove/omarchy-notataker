#!/usr/bin/env bash
# Configura Notataker después de `omarchy plugin add`: el comando `notataker`,
# el fichero de ajustes y el atajo de teclado. El plugin en sí (icono de la
# barra y panel) lo instala y lo quita `omarchy plugin add/remove`.
#   ./setup.sh              configurar (se puede repetir sin duplicar nada)
#   ./setup.sh --uninstall  deshacer el comando y el atajo
# Otro atajo:  NOTATAKER_KEY="SUPER + SHIFT + S" ./setup.sh
set -euo pipefail

DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
BIN="$HOME/.local/bin"
BINDS="$HOME/.config/hypr/bindings.lua"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/notataker"
KEY="${NOTATAKER_KEY:-SHIFT + PRINT}"
MARK="-- Notataker:"

say() { printf '\033[1;34m▸\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*"; }

reload_hypr() {
  command -v hyprctl &>/dev/null || return 0
  hyprctl reload &>/dev/null || true
  local errors
  errors="$(hyprctl configerrors 2>/dev/null || true)"
  if [ -n "${errors//[[:space:]]/}" ]; then
    warn "Hyprland avisa de errores de configuración:"
    printf '%s\n' "$errors"
  fi
}

backup_binds() {
  cp "$BINDS" "$BINDS.bak.$(date +%s)"
}

if [ "${1:-}" = "--uninstall" ]; then
  # Solo se borra el enlace si es el de este plugin, no uno que haya puesto otra persona.
  if [ -L "$BIN/notataker" ] && [ "$(readlink -f "$BIN/notataker")" = "$DIR/bin/notataker" ]; then
    rm -f "$BIN/notataker"
  fi
  if [ -f "$BINDS" ] && grep -qF -- "$MARK" "$BINDS"; then
    backup_binds
    # Quita el comentario y el o.bind(...) que le sigue.
    sed -i "/^$MARK/,/^o\.bind(/d" "$BINDS"
    reload_hypr
  fi
  say "Comando y atajo quitados. Tus capturas y ajustes siguen en su sitio."
  say "Para quitar el plugin:  omarchy plugin remove io.github.ianmove.notataker"
  exit 0
fi

# 1. Dependencias ---------------------------------------------------------------
missing=()
for cmd in omarchy omarchy-shell omarchy-capture-screenshot omarchy-agent-prompt jq grim slurp; do
  command -v "$cmd" &>/dev/null || missing+=("$cmd")
done
if ((${#missing[@]})); then
  warn "Faltan comandos: ${missing[*]}"
  exit 1
fi
if [ -z "$(omarchy-default-agent)" ]; then
  warn "Todavía no has elegido agente por defecto:  omarchy default agent <claude|codex|grok|…>"
fi

# 2. Comando ----------------------------------------------------------------------
say "Instalando el comando «notataker»…"
mkdir -p "$BIN"
chmod +x "$DIR/bin/notataker"
ln -sf "$DIR/bin/notataker" "$BIN/notataker"

mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/config" ]; then
  cat > "$CONFIG_DIR/config" <<'EOF'
# Ajustes de Notataker (se carga como script de bash).
# Dónde están tus notas: es lo que se le dice al agente cuando le pides
# «guárdalo en mis notas».
#NOTATAKER_NOTES_DIR="$HOME/Documents/Obsidian Vault"
# Dónde se guardan las capturas.
#NOTATAKER_CAPTURE_DIR="$HOME/Pictures/Notataker"
EOF
fi

# 3. Atajo de teclado --------------------------------------------------------------
if [ -f "$BINDS" ]; then
  if grep -qF -- "$MARK" "$BINDS"; then
    say "El atajo ya está en $BINDS."
  else
    say "Añadiendo el atajo $KEY en $BINDS…"
    backup_binds
    printf '\n%s captura una zona y pídele algo al agente de Omarchy\no.bind("%s", "Captura + agente", "notataker")\n' "$MARK" "$KEY" >> "$BINDS"
    reload_hypr
  fi
fi

say "¡Listo!  Atajo: $KEY  ·  o el icono de la barra  ·  o el comando: notataker"
