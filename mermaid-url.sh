#!/usr/bin/env bash
# Converteste cod Mermaid in URL partajabil pentru mermaid-live-editor.
# Foloseste pako (zlib deflate) ca sa suporte si diagrame lungi.
#
# Host configurabil: setezi MERMAID_HOST in env. Default = mermaid.live (public).
# Pentru instanta wisedigital: export MERMAID_HOST=mermaid.wisedigital.tech
#
# Usage:
#   echo 'flowchart LR\n A --> B' | ./mermaid-url.sh
#   ./mermaid-url.sh "$(cat diagram.mmd)"
#   ./mermaid-url.sh < diagram.mmd

set -euo pipefail

HOST="${MERMAID_HOST:-mermaid.live}"
CODE="${1:-$(cat)}"

PAKO=$(CODE_INPUT="$CODE" python3 - <<'PY'
import os, json, zlib, base64
state = {
    "code": os.environ["CODE_INPUT"],
    "mermaid": '{"theme":"default"}',
    "autoSync": True,
    "updateDiagram": True,
}
compressed = zlib.compress(json.dumps(state).encode(), 9)
print(base64.urlsafe_b64encode(compressed).decode().rstrip("="))
PY
)

echo "https://${HOST}/view#pako:${PAKO}"
