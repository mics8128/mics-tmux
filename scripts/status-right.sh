#!/bin/sh

set -u

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cache_dir="${MICS_TMUX_CACHE_DIR:-${TMPDIR:-/tmp}/mics-tmux}"
cache_file="$cache_dir/status-right.cache"
minute=$(date +%Y%m%d%H%M)

if [ -r "$cache_file" ]; then
  cached_minute=$(sed -n '1p' "$cache_file" 2>/dev/null || printf '')
  if [ "$cached_minute" = "$minute" ]; then
    sed -n '2p' "$cache_file" 2>/dev/null || true
    exit 0
  fi
fi

load=$(uptime 2>/dev/null | awk '
{
  for (i = 1; i <= NF; i++) {
    if ($i == "average:" || $i == "averages:") {
      value = $(i + 1)
      gsub(",", "", value)
      print value
      exit
    }
  }
}')
battery=$("$script_dir/battery-icon.sh" 2>/dev/null || true)
clock=$("$script_dir/clock-icon.sh" 2>/dev/null || true)
time=$(date +%H:%M)

output="󰓅 $load #[fg=colour244]$battery #[fg=colour244]$clock $time"

if mkdir -p "$cache_dir" 2>/dev/null; then
  tmp_file="$cache_file.$$"
  {
    printf '%s\n' "$minute"
    printf '%s\n' "$output"
  } > "$tmp_file" 2>/dev/null && mv "$tmp_file" "$cache_file" 2>/dev/null || true
fi

printf '%s' "$output"
