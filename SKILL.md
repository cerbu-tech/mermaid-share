---
name: mermaid-share
description: Generates shareable URLs for Mermaid diagrams via a self-hosted or public mermaid-live-editor instance. Use when the user requests a diagram to share (Slack, email, hand off to another agent) or when you have Mermaid code and want a browser-renderable link.
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
export MERMAID_HOST=mermaid.wisedigital.tech  # example: your own self-hosted instance
```

If nothing is set, URLs point to `mermaid.live` (zero infrastructure dependency).

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
