#!/usr/bin/env bash
set -euo pipefail

CITY=""  # leave empty for IP-based location. Or hardcode e.g. CITY="Kingston,ON"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-weather"
mkdir -p "$CACHE_DIR"

CACHE_JSON="$CACHE_DIR/weather.json"
CACHE_TIME="$CACHE_DIR/last_fetch"
SPIN_STATE="$CACHE_DIR/spin_state"

# cache duration (seconds)
TTL=600

# spinner frames: / | \ -
frames=( "/" "|" "\\" "--" )

next_spinner() {
  local i=0
  if [[ -f "$SPIN_STATE" ]]; then
    i="$(cat "$SPIN_STATE" 2>/dev/null || echo 0)"
  fi
  # ensure numeric
  [[ "$i" =~ ^[0-9]+$ ]] || i=0
  i=$(( (i + 1) % ${#frames[@]} ))
  echo "$i" > "$SPIN_STATE"
  echo "${frames[$i]}"
}

emit_locating() {
  local frame
  frame="$(next_spinner)"
  printf '{"text":"locating %s","tooltip":"Trying to detect your location..."}\n' "$frame"
}

# If we have fresh cached output, return it (so interval=1 is safe)
now="$(date +%s)"
last=0
if [[ -f "$CACHE_TIME" ]]; then
  last="$(cat "$CACHE_TIME" 2>/dev/null || echo 0)"
fi
[[ "$last" =~ ^[0-9]+$ ]] || last=0

if [[ -f "$CACHE_JSON" && $((now - last)) -lt $TTL ]]; then
  cat "$CACHE_JSON"
  exit 0
fi

# Try to fetch condition + feels-like
raw="$(curl -fsS --max-time 4 "https://wttr.in/${CITY}?format=%C|%f" 2>/dev/null || true)"

# If request failed or returned junk, show locating spinner (and don't update cache)
if [[ -z "${raw}" || "${raw}" == *"Unknown location"* || "${raw}" == *"Sorry"* ]]; then
  emit_locating
  exit 0
fi

cond="${raw%%|*}"
feels="${raw##*|}"

# Map condition -> icon (edit these to your taste)
icon="󰖐"
shopt -s nocasematch
case "$cond" in
  *thunder*|*lightning*) icon="󰖓" ;;
  *snow*|*blizzard*|*sleet*|*ice*|*freezing*) icon="󰖘" ;;
  *rain*|*drizzle*|*shower*) icon="󰖖" ;;
  *fog*|*mist*|*haze*|*smoke*) icon="󰖑" ;;
  *overcast*|*cloud*) icon="󰖐" ;;
  *clear*|*sun*) icon="󰖙" ;;
esac
shopt -u nocasematch

tooltip="$(curl -fsS --max-time 4 "https://wttr.in/${CITY}?format=4" 2>/dev/null || echo "Weather unavailable")"
tooltip_escaped="$(echo "$tooltip" | sed 's/"/\\"/g')"

json="$(printf '{"text":"%s %s","tooltip":"%s"}\n' \
  "$icon" "$(echo "$feels" | tr -d ' ')" "$tooltip_escaped")"

# Save cache (so subsequent 1-second updates don't refetch)
echo "$json" > "$CACHE_JSON"
echo "$now" > "$CACHE_TIME"

echo "$json"

