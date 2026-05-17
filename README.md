# mermaid-share

A skill for AI agents (Claude Code, Codex, Cursor, etc.) that converts Mermaid code into a shareable URL renderable by any [mermaid-live-editor](https://github.com/mermaid-js/mermaid-live-editor) instance. Views are public — the link can be shared with anyone, no auth required.

## How it works

The diagram is encoded as JSON → zlib deflate → base64url → appended to the URL fragment (`#pako:...`). The server stores nothing; everything needed to render the diagram is embedded in the link.

## Host configuration

Set `MERMAID_HOST` in your shell (or the agent's environment):

```bash
export MERMAID_HOST=mermaid.live              # default — official public instance
export MERMAID_HOST=mermaid.wisedigital.tech  # example: your own self-hosted instance
```

If you don't set anything, URLs are generated for `mermaid.live` (no dependency on anyone's infrastructure).

## Install

### Claude Code

```bash
mkdir -p ~/.claude/skills/mermaid-share
git clone https://github.com/wisedigital/mermaid-share.git /tmp/mermaid-share
cp /tmp/mermaid-share/{SKILL.md,mermaid-url.sh} ~/.claude/skills/mermaid-share/
chmod +x ~/.claude/skills/mermaid-share/mermaid-url.sh
rm -rf /tmp/mermaid-share
```

Restart Claude Code. The `mermaid-share` skill becomes available.

### Codex CLI (OpenAI)

```bash
mkdir -p ~/.tools/mermaid-share
git clone https://github.com/wisedigital/mermaid-share.git /tmp/mermaid-share
cp /tmp/mermaid-share/{SKILL.md,mermaid-url.sh} ~/.tools/mermaid-share/
chmod +x ~/.tools/mermaid-share/mermaid-url.sh
rm -rf /tmp/mermaid-share
```

Add the following to `AGENTS.md` at the root of your project:

```markdown
## Mermaid diagrams
For shareable Mermaid diagrams, follow `~/.tools/mermaid-share/SKILL.md`.
Use `~/.tools/mermaid-share/mermaid-url.sh` as the encoder.
```

### Cursor / Continue / other agents

Add `SKILL.md` as a context document in your agent's settings, or paste its contents into the system prompt. Place `mermaid-url.sh` anywhere convenient and invoke it via shell.

## Test

```bash
echo 'flowchart LR
  A --> B' | ./mermaid-url.sh
```

Expected: a URL `https://$MERMAID_HOST/view#pako:...`. Open it in a browser — the diagram renders.

```bash
curl -sI -o /dev/null -w "%{http_code}\n" "$(echo 'flowchart LR; A-->B' | ./mermaid-url.sh)"
```

Expected: `200`.

## Dependencies

- `bash`, `python3` (with `zlib` + `base64` from stdlib), `curl` — all built-in on macOS and most Linux distributions.

## Editing

On `mermaid.live` (default) anyone can edit without auth.

On self-hosted instances (e.g. `mermaid.wisedigital.tech`) editing may be behind SSO. Check your instance's access policy — the maintainer of your deployment can grant edit access. Generating view links never requires auth.

## License

MIT — see `LICENSE`.
