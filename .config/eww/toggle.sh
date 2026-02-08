#!/usr/bin/env bash
set -euo pipefail

CFG="$HOME/.config/eww"

# start daemon if needed
pgrep -x eww >/dev/null 2>&1 || eww -c "$CFG" daemon &
disown

# ensure window exists (so animation works)
if ! eww -c "$CFG" windows | grep -qx "calendar"; then
  eww -c "$CFG" open calendar
fi

state="$(eww -c "$CFG" get cal_open || echo "false")"
if [[ "$state" == "true" ]]; then
  eww -c "$CFG" update cal_open=false
else
  eww -c "$CFG" update cal_open=true
fi
