# mermaid-share

Skill pentru agenți AI (Claude Code, Codex, Cursor, etc.) care convertește cod Mermaid în URL partajabil prin instanța self-hostată `https://mermaid.wisedigital.tech`. View-urile sunt publice — linkul poate fi dat oricui, fără auth.

## Cum funcționează

Diagrama e encodată JSON → base64url → atașată la fragmentul URL. Server-ul nu stochează nimic; tot ce trebuie pentru render e în link.

## Install

### Claude Code

```bash
mkdir -p ~/.claude/skills/mermaid-share
git clone https://github.com/wisedigital/mermaid-share.git /tmp/mermaid-share
cp /tmp/mermaid-share/{SKILL.md,mermaid-url.sh} ~/.claude/skills/mermaid-share/
chmod +x ~/.claude/skills/mermaid-share/mermaid-url.sh
rm -rf /tmp/mermaid-share
```

Restartează Claude Code. Skill-ul `mermaid-share` devine disponibil.

### Codex CLI (OpenAI)

```bash
mkdir -p ~/.tools/mermaid-share
git clone https://github.com/wisedigital/mermaid-share.git /tmp/mermaid-share
cp /tmp/mermaid-share/{SKILL.md,mermaid-url.sh} ~/.tools/mermaid-share/
chmod +x ~/.tools/mermaid-share/mermaid-url.sh
rm -rf /tmp/mermaid-share
```

Adaugă în `AGENTS.md` la rădăcina proiectului:

```markdown
## Mermaid diagrams
Pentru diagrame Mermaid partajabile, urmează `~/.tools/mermaid-share/SKILL.md`.
Folosește `~/.tools/mermaid-share/mermaid-url.sh` ca encoder.
```

### Cursor / Continue / alt agent

Adaugă `SKILL.md` ca document de context în setările agentului, sau paste-uiește conținutul lui în system prompt. Scriptul `mermaid-url.sh` îl pui oriunde și-l invoci prin shell.

## Test

```bash
echo 'flowchart LR
  A --> B' | ./mermaid-url.sh
```

Așteptat: un URL `https://mermaid.wisedigital.tech/view#base64:...`. Deschide-l în browser → randează diagrama.

```bash
curl -sI -o /dev/null -w "%{http_code}\n" "$(echo 'flowchart LR; A-->B' | ./mermaid-url.sh)"
```

Așteptat: `200`.

## Dependențe

- `bash`, `jq`, `base64`, `curl` (toate built-in pe macOS; `apt install jq curl` pe Linux dacă lipsesc)

## Editare

`https://mermaid.wisedigital.tech/edit` cere login Cloudflare Access. Domenii permise: `@wisedigital.tech`. Pentru alți colaboratori, contactați-l pe florin@wisedigital.tech.

## Licență

MIT — vezi `LICENSE`.
