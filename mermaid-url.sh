#!/usr/bin/env bash
# Converts Mermaid code into a shareable URL for mermaid-live-editor.
# Uses pako (zlib deflate) to support long diagrams as well.
#
# Configurable host: set MERMAID_HOST in env. Default = mermaid.live (public).
# For a self-hosted instance: export MERMAID_HOST=mermaid.example.com
#
# Configurable theme: set MERMAID_THEME in env. Default = dark.
# Valid values: default, dark, neutral, forest.
#
# Usage:
#   echo 'flowchart LR\n A --> B' | ./mermaid-url.sh
#   ./mermaid-url.sh "$(cat diagram.mmd)"
#   ./mermaid-url.sh < diagram.mmd
#   ./mermaid-url.sh --open  < diagram.mmd    # open in browser + copy to clipboard, suppress stdout
#   ./mermaid-url.sh --short < diagram.mmd    # shorten via SHORTENER_URL + SHORTENER_TOKEN, output short URL
#   MERMAID_OPEN=1 ./mermaid-url.sh < diagram.mmd
#
# Shortener env vars (optional):
#   SHORTENER_URL      e.g. https://s.example.com/create  (POST endpoint that accepts {"url": "..."})
#   SHORTENER_TOKEN    bearer token for the shortener
# Response is expected to be JSON {"short": "https://s.example.com/abc"} or {"slug": "abc"}.

set -euo pipefail

OPEN_MODE=0
SHORT_MODE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --open)  OPEN_MODE=1; shift ;;
    --short) SHORT_MODE=1; shift ;;
    *) break ;;
  esac
done
[[ "${MERMAID_OPEN:-0}" == "1" ]] && OPEN_MODE=1

HOST="${MERMAID_HOST:-mermaid.live}"
THEME="${MERMAID_THEME:-dark}"
CODE="${1:-$(cat)}"

PAKO=$(CODE_INPUT="$CODE" THEME="$THEME" python3 - <<'PY'
import os, json, zlib, base64
state = {
    "code": os.environ["CODE_INPUT"],
    "mermaid": json.dumps({"theme": os.environ["THEME"]}),
    "autoSync": True,
    "updateDiagram": True,
}
compressed = zlib.compress(json.dumps(state).encode(), 9)
print(base64.urlsafe_b64encode(compressed).decode().rstrip("="))
PY
)

URL="https://${HOST}/view#pako:${PAKO}"

if [[ "$SHORT_MODE" == "1" ]]; then
  : "${SHORTENER_URL:?--short requires SHORTENER_URL env var}"
  : "${SHORTENER_TOKEN:?--short requires SHORTENER_TOKEN env var}"
  RESPONSE=$(curl -fsS -X POST \
    -H "Authorization: Bearer $SHORTENER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$(URL_INPUT="$URL" python3 -c 'import os,json; print(json.dumps({"url": os.environ["URL_INPUT"]}))')" \
    "$SHORTENER_URL")
  URL=$(echo "$RESPONSE" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("short") or d["slug"])')
fi

if [[ "$OPEN_MODE" == "1" ]]; then
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$URL" | pbcopy
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$URL" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$URL" | xclip -selection clipboard
  fi

  if command -v open >/dev/null 2>&1; then
    open "$URL"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$URL" >/dev/null 2>&1 &
  fi

  echo "Opened in browser, URL copied to clipboard (length: ${#URL})"
else
  echo "$URL"
fi
