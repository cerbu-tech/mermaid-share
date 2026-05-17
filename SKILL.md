---
name: mermaid-share
description: |
  Generate a shareable, browser-renderable URL for any Mermaid diagram (flowchart, sequence, class, ER, state, gantt, mindmap, architecture, etc.) instead of returning raw Mermaid code blocks. INVOKE WHENEVER the user asks to see, draw, visualize, sketch, render, share, or hand off a diagram in any form — including phrases like "draw a flow", "show me a diagram", "make a flowchart", "visualize this", "architecture diagram", "sequence diagram", "fa o diagrama", "deseneaza", "vizualizeaza", "schita", "arata-mi grafic". Also invoke when you were about to output a ` ```mermaid ` code block — render it via this skill so the user gets a clickable link, not raw text. The skill works with the public mermaid.live by default or any self-hosted mermaid-live-editor instance via MERMAID_HOST.
---

# Mermaid Share

Toolkit for generating publicly shareable Mermaid links — no auth, no storage.

## When to use

- User requests a visual diagram and you want to give them a link, not raw code
- Sending a diagram to a colleague/client over Slack/email
- Passing a visual reference to another agent (Claude, Hermes, etc.) for a diagram you already generated
- Embedding in an Obsidian note as a link outside a ` ```mermaid ` block

## Host configuration

The skill outputs URLs pointing to any mermaid-live-editor instance. Set via env var:

```bash
export MERMAID_HOST=mermaid.live              # default — official public instance
export MERMAID_HOST=mermaid.example.com       # example: your own self-hosted instance
```

If nothing is set, URLs point to `mermaid.live` (zero infrastructure dependency).

## Theme configuration

Default theme is `dark` (legible on dark backgrounds, the most common reader context today). Override via env var:

```bash
export MERMAID_THEME=dark      # default
export MERMAID_THEME=default   # classic light theme
export MERMAID_THEME=neutral
export MERMAID_THEME=forest
```

### Recommended dark palette for category-coded diagrams

When using `style <node> fill:#hex` overrides inside a `dark` theme, use **muted, low-saturation tints** (VS Code dark inspired). Bright pastel fills (`#ffe0e0`, `#e0f0ff`) clash with dark text rendered by the dark theme. Suggested categories:

| Category    | Fill        | Stroke      | Use case                |
|-------------|-------------|-------------|-------------------------|
| Neutral/current | `#2d2d2d` | `#5a5a5a` | Baseline, "as-is" state |
| Info/option-A | `#1e3a52` | `#3a6a8a`   | Cool/blue alternative   |
| Success/option-B | `#1f3a2a` | `#3a6a4a` | Green alternative       |
| Warning/decision | `#3d3019` | `#7a5a2a` | Highlight / decision    |
| Danger      | `#3a1e1e`   | `#6a3a3a`   | Removed / problem       |

Example:

```
style Current fill:#2d2d2d,stroke:#5a5a5a,color:#d4d4d4
style OptionA fill:#1e3a52,stroke:#3a6a8a,color:#d4d4d4
style OptionB fill:#1f3a2a,stroke:#3a6a4a,color:#d4d4d4
style Decision fill:#3d3019,stroke:#7a5a2a,color:#e6c074
```

Always pair `fill` with an explicit `color:` so the label stays legible regardless of the theme's default text color.

## Contract

The editor accepts diagram state encoded in the URL fragment. Two formats:

- `#base64:<base64url(JSON state)>` — JSON directly base64-encoded. Works for small diagrams, but **fails for long ones** (Loading URL failed). Supported for backwards compatibility only.
- `#pako:<base64url(zlib.compress(JSON state))>` — JSON zlib-compressed then base64-encoded. **Recommended** — URLs are ~3-5x shorter and support large diagrams.

`JSON state`:

```json
{"code":"<mermaid code>","mermaid":"{\"theme\":\"default\"}","autoSync":true,"updateDiagram":true}
```

`base64url` = standard base64 with `+/` replaced by `-_`, no `=` padding.

`/view` is public. `/edit` (on a self-hosted instance protected by Cloudflare Access) requires authentication. Links generated here open in view mode — anyone with the URL can see them.

## Option 1 — shell script (recommended)

```bash
echo 'flowchart LR
  A --> B' | ./mermaid-url.sh
```

Output: URL `https://$MERMAID_HOST/view#pako:...` ready to copy/paste.

### `--short` mode (recommended for agents posting URLs back to users)

If a shortener service is available, the agent can hand off a small URL the user can paste without risk of corruption:

```bash
export SHORTENER_URL=https://s.example.com/create   # POST endpoint
export SHORTENER_TOKEN=<bearer token>
echo '...' | ./mermaid-url.sh --short
# → https://s.example.com/abc123
```

The shortener must accept a POST `{"url": "..."}` body with `Authorization: Bearer $TOKEN` and return JSON `{"short": "https://..."}` or `{"slug": "abc"}`. A reference implementation (Cloudflare Worker + KV) ships in this repo's sibling `shortener-worker/` folder, or you can use any existing shortener API that fits this contract.

**Why it matters for agents**: long pako-encoded URLs (>1 KB) printed back into chat risk being reproduced verbatim by the LLM in later responses — a single character drift corrupts the diagram. A 30-char short URL is reliably reproducible and survives every markdown renderer.

### `--open` mode (alternative for desktop sessions)

```bash
echo '...' | ./mermaid-url.sh --open
# or: MERMAID_OPEN=1 ./mermaid-url.sh < diagram.mmd
```

Opens the URL in the user's default browser and copies it to the clipboard (`pbcopy` on macOS, `wl-copy` / `xclip` on Linux). The script prints only a confirmation, not the URL itself. Useful when no shortener is set up but the user is on the same desktop as the agent.

## Option 2 — python one-liner (wherever python3 is available)

```bash
CODE='flowchart LR
  A --> B'

CODE_INPUT="$CODE" python3 -c '
import os, json, zlib, base64
host = os.environ.get("MERMAID_HOST", "mermaid.live")
state = {"code": os.environ["CODE_INPUT"], "mermaid": "{\"theme\":\"default\"}", "autoSync": True, "updateDiagram": True}
b64 = base64.urlsafe_b64encode(zlib.compress(json.dumps(state).encode(), 9)).decode().rstrip("=")
print(f"https://{host}/view#pako:{b64}")
'
```

## Option 3 — python inline (agents with direct code execution)

```python
import os, json, zlib, base64
state = {"code": code, "mermaid": '{"theme":"default"}', "autoSync": True, "updateDiagram": True}
compressed = zlib.compress(json.dumps(state).encode(), 9)
b64 = base64.urlsafe_b64encode(compressed).decode().rstrip("=")
url = f"https://{os.environ.get('MERMAID_HOST', 'mermaid.live')}/view#pako:{b64}"
```

## Verification

After generating, validate that the URL responds:

```bash
curl -sI -o /dev/null -w "%{http_code}\n" "$URL"
```

Expect `200`. If you get `503`, the instance is down — notify the maintainer.

## Limits & gotchas

- **The diagram lives in the URL.** If you lose it, there is nothing to recover from the server. Save the Mermaid source separately (e.g. in your Obsidian vault or a local file).
- **Very long links** (>4-8 KB even after pako) — some clients (Slack desktop, certain email gateways) may truncate. For extremely large diagrams, save the source and send code + screenshot instead of a URL.
- **Long URL inside a markdown link `[text](url)`** — intermediate renderers / parsers can corrupt URLs >1-2 KB (the `-_` characters from base64url, nested parentheses). For large diagrams, post the URL as a **code block** (` ``` `) or plain text, not as a markdown link.
- **For editing**: the view link does not allow editing. Anyone who wants to modify the diagram should paste the code into a new `/edit` tab (requires CF Access on self-hosted instances).
- **Mermaid syntax validation**: the script does not validate syntax. If the code is malformed, the editor displays the error inline when the user opens the URL.

## Diagram code requirements

- Mermaid 11.x syntax (the official `latest` Docker image)
- Real newlines `\n`, not the literal string `\\n`
- Double quotes inside labels must be escaped if the code is passed through JSON (the shell script and python one-liner handle this automatically via `json.dumps`)

## System dependencies

- `bash`, `python3` (with `zlib` and `base64` from stdlib — both built-in), `curl` for verification. All are present by default on macOS / Linux.

## Distributing to other agents

This folder (`wise-infra/mermaid/`) is self-contained. To transfer the skill:

- **To another local agent:** copy `SKILL.md` + `mermaid-url.sh` into that agent's skills folder. Required on the target system: `bash`, `jq`, `base64`, `curl`.
- **For an agent without filesystem access:** paste the contents of `SKILL.md` directly into its context as a system/tool description.
- **Updates:** any domain or policy changes are made here; sync to your agents via a manual pull or explicit sync step.
