#!/bin/sh

path=$1
cmd=$2
status=$3

short_path=$(printf '%s\n' "$path" | awk '
{
  path = $0
  home = ENVIRON["HOME"]

  if (path == home) {
    print "~"
    exit
  }

  if (index(path, home "/") == 1) {
    path = "~/" substr(path, length(home) + 2)
  }

  n = split(path, parts, "/")
  out = ""

  for (i = 1; i <= n; i++) {
    part = parts[i]

    if (part == "") {
      if (i == 1) out = "/"
      continue
    }

    if (i == 1 && part == "~") {
      out = "~"
      continue
    }

    if (i < n) {
      part = substr(part, 1, 1)
    }

    if (out == "" || out == "/") {
      out = out part
    } else {
      out = out "/" part
    }
  }

  print out
}')

case "$cmd" in
  codex*) cmd=codex ;;
  zsh|bash|fish|sh) cmd= ;;
esac

label=$short_path

if [ -n "$cmd" ]; then
  label="$label:$cmd"
fi

if [ -n "$status" ]; then
  label="$label($status)"
fi

printf '%s' "$label"
