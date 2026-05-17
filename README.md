# mermaid-share

A skill for AI agents (Claude Code, Codex, Cursor, etc.) that converts Mermaid code into a shareable URL renderable by any [mermaid-live-editor](https://github.com/mermaid-js/mermaid-live-editor) instance. Views are public — the link can be shared with anyone, no auth required.

## How it works

The diagram is encoded as JSON → zlib deflate → base64url → appended to the URL fragment (`#pako:...`). The server stores nothing; everything needed to render the diagram is embedded in the link.

## Host configuration

Set `MERMAID_HOST` in your shell (or the agent's environment):

```bash
export MERMAID_HOST=mermaid.live              # default — official public instance
export MERMAID_HOST=mermaid.example.com       # example: your own self-hosted instance
```

If you don't set anything, URLs are generated for `mermaid.live` (no dependency on anyone's infrastructure).

## Theme

Default theme is `dark`. Override via `MERMAID_THEME` env var (`default`, `dark`, `neutral`, `forest`).

```bash
export MERMAID_THEME=default   # classic light theme
```

For category-coded diagrams on dark theme, see `SKILL.md` for a recommended low-contrast palette (VS Code dark inspired) — bright pastel fills clash with the dark theme's default text color.

## Install — instructions for the AI agent

If a user gave you this repo URL and asked you to install the skill, do the following yourself:

1. Detect the host agent by environment markers:
   - **Claude Code** → `~/.claude/skills/mermaid-share/`
   - **Codex CLI** (OpenAI) → `~/.tools/mermaid-share/` plus an entry in the project's `AGENTS.md`
   - **Cursor / Continue / Aider / other** → any stable path you can reference; add a pointer in the project's agent config or system prompt
   - Unknown → ask the user where their agent loads skills from

2. Download `SKILL.md` and `mermaid-url.sh`:
   ```bash
   DEST=~/.claude/skills/mermaid-share        # adjust per agent
   mkdir -p "$DEST"
   curl -fsSL https://raw.githubusercontent.com/cerbu-tech/mermaid-share/main/SKILL.md       -o "$DEST/SKILL.md"
   curl -fsSL https://raw.githubusercontent.com/cerbu-tech/mermaid-share/main/mermaid-url.sh -o "$DEST/mermaid-url.sh"
   chmod +x "$DEST/mermaid-url.sh"
   ```

3. Smoke-test:
   ```bash
   echo 'flowchart LR; A-->B' | "$DEST/mermaid-url.sh"
   ```
   Expect a `https://...#pako:...` URL on stdout.

4. Tell the user it is installed and what to set if they want a self-hosted instance or shortener (`MERMAID_HOST`, `SHORTENER_URL`, `SHORTENER_TOKEN`). After the install you may need a restart of the agent for it to pick up the new skill.

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

On self-hosted instances editing may be behind SSO or another access gate. Check your instance's policy — the maintainer of your deployment can grant edit access. Generating view links never requires auth.

## License

MIT — see `LICENSE`.
