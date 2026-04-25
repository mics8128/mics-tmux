#!/bin/sh

line=$(pmset -g batt 2>/dev/null | awk 'NR == 2')

if [ -z "$line" ]; then
  exit 0
fi

percent=$(printf '%s\n' "$line" | sed -n 's/.*[[:space:]]\([0-9][0-9]*\)%;.*/\1/p')

case "$percent" in
  ''|*[!0-9]*) exit 0 ;;
esac

if [ "$percent" -ge 100 ]; then
  icon="󰁹"
elif [ "$percent" -ge 90 ]; then
  icon="󰂂"
elif [ "$percent" -ge 80 ]; then
  icon="󰂁"
elif [ "$percent" -ge 70 ]; then
  icon="󰂀"
elif [ "$percent" -ge 60 ]; then
  icon="󰁿"
elif [ "$percent" -ge 50 ]; then
  icon="󰁾"
elif [ "$percent" -ge 40 ]; then
  icon="󰁽"
elif [ "$percent" -ge 30 ]; then
  icon="󰁼"
elif [ "$percent" -ge 20 ]; then
  icon="󰁻"
elif [ "$percent" -ge 10 ]; then
  icon="󰁺"
else
  icon="󰂃"
fi

if [ "$percent" -le 20 ]; then
  printf '#[fg=colour203]%s %s%%#[fg=colour244]' "$icon" "$percent"
else
  printf '%s %s%%' "$icon" "$percent"
fi
