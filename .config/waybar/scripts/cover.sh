#!/usr/bin/env bash
set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
COVER="${CACHE_DIR}/cover.png"
TMP="${CACHE_DIR}/cover.tmp"
mkdir -p "$CACHE_DIR"

# Find a player (spotify, ncspot, firefox, etc.)
PLAYER="$(playerctl -l 2>/dev/null | head -n1 || true)"
if [[ -z "${PLAYER}" ]]; then
  echo '{"text":"", "tooltip":"No player"}'
  exit 0
fi

TITLE="$(playerctl -p "$PLAYER" metadata title 2>/dev/null || true)"
ARTIST="$(playerctl -p "$PLAYER" metadata artist 2>/dev/null || true)"
ARTURL="$(playerctl -p "$PLAYER" metadata mpris:artUrl 2>/dev/null || true)"

# Tooltip content
TIP="${ARTIST}${ARTIST:+ — }${TITLE}"
[[ -z "$TIP" ]] && TIP="$ hooking to $PLAYER"

# If no art, keep last image if it exists
if [[ -z "${ARTURL}" ]]; then
  echo "{\"text\":\"\", \"tooltip\":\"${TIP}\"}"
  exit 0
fi

# Pull cover art
if [[ "$ARTURL" == file://* ]]; then
  SRC="${ARTURL#file://}"
  if [[ -f "$SRC" ]]; then
    cp -f "$SRC" "$TMP" || true
  fi
else
  curl -fsSL "$ARTURL" -o "$TMP" || true
fi

# Convert/resize if ImageMagick is available (best quality)
if command -v magick >/dev/null 2>&1; then
  magick "$TMP" -resize 160x160^ -gravity center -extent 160x160 "$COVER" 2>/dev/null || true
elif command -v convert >/dev/null 2>&1; then
  convert "$TMP" -resize 160x160^ -gravity center -extent 160x160 "$COVER" 2>/dev/null || true
else
  # Fallback: just save whatever we got
  mv -f "$TMP" "$COVER" 2>/dev/null || true
fi

# Output JSON. We don't put text; we style background image in CSS.
echo "{\"text\":\"\", \"tooltip\":\"${TIP}\"}"

