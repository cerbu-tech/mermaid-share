#!/usr/bin/env bash
# Converteste cod Mermaid in URL partajabil pentru mermaid.wisedigital.tech.
# Stare diagrama = JSON encodat base64url in fragment-ul URL.
#
# Usage:
#   echo 'flowchart LR\n A --> B' | ./mermaid-url.sh
#   ./mermaid-url.sh "$(cat diagram.mmd)"
#   ./mermaid-url.sh < diagram.mmd

set -euo pipefail

CODE="${1:-$(cat)}"

STATE=$(jq -cn --arg code "$CODE" '{
  code: $code,
  mermaid: "{\"theme\":\"default\"}",
  autoSync: true,
  updateDiagram: true
}')

B64=$(printf '%s' "$STATE" | base64 | tr '+/' '-_' | tr -d '=\n')

echo "https://mermaid.wisedigital.tech/view#base64:${B64}"
