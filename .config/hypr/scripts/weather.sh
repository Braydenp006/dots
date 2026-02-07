#!/usr/bin/env bash

CITY="Kingston,ON"
OUT="$HOME/.cache/hyprlock-weather.txt"
URL="https://wttr.in/${CITY}?format=%l|%t|%C"

mkdir -p "$(dirname "$OUT")"

RAW="$(curl -fsS --max-time 3 "$URL" 2>/dev/null | sed 's/+//g')"

WEATHER="$(
  echo "$RAW" | awk -F'|' '
    {
      loc=$1; temp=$2; cond=$3;

      # clean location: keep city only (before first comma), and trim spaces
      sub(/,.*/, "", loc); gsub(/^ +| +$/, "", loc);

      # trim spaces
      gsub(/^ +| +$/, "", temp);
      gsub(/^ +| +$/, "", cond);

      # condition: keep only first phrase before comma
      sub(/,.*/, "", cond);

      # optional: remove "shower" for cleaner wording
      gsub(/shower/i, "", cond);
      gsub(/^ +| +$/, "", cond);

      print loc " • " temp " • " cond;
    }
  '
)"

if [ -n "$WEATHER" ]; then
  printf '%s\n' "$WEATHER" >"$OUT"
else
  # keep last known value if available
  if [ -s "$OUT" ]; then exit 0; fi
  printf '%s\n' "Weather unavailable" >"$OUT"
fi
