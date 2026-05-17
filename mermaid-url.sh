#!/usr/bin/env bash
# Converts Mermaid code into a shareable URL for mermaid-live-editor.
# Uses pako (zlib deflate) to support long diagrams as well.
#
# Configurable host: set MERMAID_HOST in env. Default = mermaid.live (public).
# For a self-hosted instance: export MERMAID_HOST=mermaid.wisedigital.tech
#
# Configurable theme: set MERMAID_THEME in env. Default = dark.
# Valid values: default, dark, neutral, forest.
#
# Usage:
#   echo 'flowchart LR\n A --> B' | ./mermaid-url.sh
#   ./mermaid-url.sh "$(cat diagram.mmd)"
#   ./mermaid-url.sh < diagram.mmd

set -euo pipefail

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

echo "https://${HOST}/view#pako:${PAKO}"
