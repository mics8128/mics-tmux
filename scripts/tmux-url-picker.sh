#!/usr/bin/env bash
set -euo pipefail

urls=$(
  python3 -c '
import re, sys

lines = [line.rstrip("\n") for line in sys.stdin]
width = max((len(line) for line in lines), default=0)
text_lines = []
current = ""

for line in lines:
    if "(timeout " in line or line.lstrip().startswith(("$ ", "+", "++")):
        if current:
            text_lines.append(current)
            current = ""
        continue

    stripped = line.strip()
    if current:
        # tmux history does not always preserve wrap metadata for old output.
        # Treat full-width nonblank lines followed by URL-ish continuations as
        # one logical line.
        if len(line) >= width and stripped and re.match(r"^[A-Za-z0-9._~:/?#\[\]@!$&()*+,;=%-]", stripped):
            current += stripped
            continue
        text_lines.append(current)
        current = ""

    if stripped:
        current = stripped

if current:
    text_lines.append(current)

seen = set()
for text in reversed(text_lines):
    for url in re.findall(r"(?:https?|ftp|file)://\S+|www\.\S+", text, re.I):
        url = url.rstrip(".,;:!?)]}>\"'"'"'")
        if url and url not in seen:
            seen.add(url)
            print(url)
'
)

if [[ -z "$urls" ]]; then
  tmux display-message "No URLs found"
  exit 0
fi

url=$(printf '%s\n' "$urls" | fzf-tmux -p 90%,70% --prompt='Open URL> ' --layout=reverse --border) || exit 0
[[ -n "${url:-}" ]] || exit 0
[[ "$url" == www.* ]] && url="https://$url"
open "$url"
tmux display-message "Opening $url"
