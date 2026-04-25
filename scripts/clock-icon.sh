#!/bin/sh

hour=$(date +%I)

case "$hour" in
  01) icon="󱑋" ;;
  02) icon="󱑌" ;;
  03) icon="󱑍" ;;
  04) icon="󱑎" ;;
  05) icon="󱑏" ;;
  06) icon="󱑐" ;;
  07) icon="󱑑" ;;
  08) icon="󱑒" ;;
  09) icon="󱑓" ;;
  10) icon="󱑔" ;;
  11) icon="󱑕" ;;
  12) icon="󱑖" ;;
  *) icon="󱑖" ;;
esac

printf '%s' "$icon"
