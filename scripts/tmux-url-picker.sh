#!/usr/bin/env bash
set -euo pipefail

urls=$(
  python3 -c '
import os, re, sys

lines = [line.rstrip("\n") for line in sys.stdin]
try:
    width = int(os.environ.get("TMUX_PANE_WIDTH", "0"))
except ValueError:
    width = 0
if width <= 0:
    width = max((len(line) for line in lines), default=0)

text_lines = []
current = ""
current_line_was_full_width = False
url_tail = re.compile(r"(?:https?|ftp|file)://\S*$|www\.\S*$", re.I)
url_continuation = re.compile(r"^[A-Za-z0-9._~:/?#\[\]@!$&()*+,;=%-]")

for line in lines:
    if "(timeout " in line or line.lstrip().startswith(("$ ", "+", "++")):
        if current:
            text_lines.append(current)
            current = ""
            current_line_was_full_width = False
        continue

    stripped = line.strip()
    if current:
        # Prefer tmux capture-pane -J, but keep fallback for non-joined input.
        # Join only when previous physical line filled pane and ended inside URL.
        if (
            current_line_was_full_width
            and stripped
            and url_tail.search(current)
            and url_continuation.match(stripped)
        ):
            current += stripped
            current_line_was_full_width = bool(width and len(line) >= width)
            continue
        text_lines.append(current)
        current = ""
        current_line_was_full_width = False

    if stripped:
        current = stripped
        current_line_was_full_width = bool(width and len(line) >= width)

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

if [[ "${MICS_TMUX_URL_PICKER_PRINT_ONLY:-}" == 1 ]]; then
  printf '%s\n' "$urls"
  exit 0
fi

url=$(printf '%s\n' "$urls" | fzf-tmux -p 90%,70% --prompt='Open URL> ' --layout=reverse --border) || exit 0
[[ -n "${url:-}" ]] || exit 0
[[ "$url" == www.* ]] && url="https://$url"
open "$url"
tmux display-message "Opening $url"
