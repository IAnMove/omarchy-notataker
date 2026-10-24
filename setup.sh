#!/usr/bin/env bash
# Set up Notataker after `omarchy plugin add`: the `notataker` command, the
# settings file and the hotkey. The plugin itself (bar icon and panel) is
# installed and removed by `omarchy plugin add/remove`.
#   ./setup.sh              set up (safe to repeat, never duplicates anything)
#   ./setup.sh --uninstall  undo the command and the hotkey
# Different hotkey:  NOTATAKER_KEY="SUPER + SHIFT + S" ./setup.sh
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
    warn "Hyprland reports configuration errors:"
    printf '%s\n' "$errors"
  fi
}

backup_binds() {
  cp "$BINDS" "$BINDS.bak.$(date +%s)"
}

if [ "${1:-}" = "--uninstall" ]; then
  # Only remove the link if it is this plugin's, not one somebody else put there.
  if [ -L "$BIN/notataker" ] && [ "$(readlink -f "$BIN/notataker")" = "$DIR/bin/notataker" ]; then
    rm -f "$BIN/notataker"
  fi
  if [ -f "$BINDS" ] && grep -qF -- "$MARK" "$BINDS"; then
    backup_binds
    # Remove the comment and the o.bind(...) that follows it.
    sed -i "/^$MARK/,/^o\.bind(/d" "$BINDS"
    reload_hypr
  fi
  say "Command and hotkey removed. Your captures and settings are still in place."
  say "To remove the plugin:  omarchy plugin remove io.github.ianmove.notataker"
  exit 0
fi

# 1. Dependencies ----------------------------------------------------------------
missing=()
for cmd in omarchy omarchy-shell omarchy-capture-screenshot omarchy-agent-prompt jq grim slurp; do
  command -v "$cmd" &>/dev/null || missing+=("$cmd")
done
if ((${#missing[@]})); then
  warn "Missing commands: ${missing[*]}"
  exit 1
fi
if [ -z "$(omarchy-default-agent)" ]; then
  warn "You have not chosen a default agent yet:  omarchy default agent <claude|codex|grok|…>"
fi

# 2. Command ------------------------------------------------------------------------
say "Installing the 'notataker' command…"
mkdir -p "$BIN"
chmod +x "$DIR/bin/notataker"
ln -sf "$DIR/bin/notataker" "$BIN/notataker"

mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/config" ]; then
  cat > "$CONFIG_DIR/config" <<'EOF'
# Notataker settings (loaded as a bash script).
# Where your notes live: this is what the agent is told when you ask it to
# "save it to my notes".
#NOTATAKER_NOTES_DIR="$HOME/Documents/Obsidian Vault"
# Where captures are saved.
#NOTATAKER_CAPTURE_DIR="$HOME/Pictures/Notataker"
EOF
fi

# 3. Hotkey ---------------------------------------------------------------------------
if [ -f "$BINDS" ]; then
  if grep -qF -- "$MARK" "$BINDS"; then
    say "The hotkey is already in $BINDS."
  else
    say "Adding the $KEY hotkey to $BINDS…"
    backup_binds
    printf '\n%s capture a region and ask your Omarchy agent about it\no.bind("%s", "Capture + agent", "notataker")\n' "$MARK" "$KEY" >> "$BINDS"
    reload_hypr
  fi
fi

say "Done!  Hotkey: $KEY  ·  or the bar icon  ·  or the command: notataker"
