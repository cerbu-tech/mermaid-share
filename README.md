# mermaid-share

Skill pentru agenți AI (Claude Code, Codex, Cursor, etc.) care convertește cod Mermaid într-un URL partajabil rendabil de orice instanță [mermaid-live-editor](https://github.com/mermaid-js/mermaid-live-editor). View-urile sunt publice — linkul poate fi dat oricui, fără auth.

## Cum funcționează

Diagrama e encodată JSON → zlib deflate → base64url → atașată la fragmentul URL (`#pako:...`). Server-ul nu stochează nimic; tot ce trebuie pentru render e în link.

## Configurare host

Setezi `MERMAID_HOST` în shell-ul tău (sau env-ul agentului):

```bash
export MERMAID_HOST=mermaid.live              # default — instanța oficială publică
export MERMAID_HOST=mermaid.wisedigital.tech  # instanța internă Wise Digital
```

Dacă nu setezi nimic, URL-urile sunt generate pentru `mermaid.live` (zero dependență de infra a cuiva).

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

Așteptat: un URL `https://$MERMAID_HOST/view#pako:...`. Deschide-l în browser → randează diagrama.

```bash
curl -sI -o /dev/null -w "%{http_code}\n" "$(echo 'flowchart LR; A-->B' | ./mermaid-url.sh)"
```

Așteptat: `200`.

## Dependențe

- `bash`, `python3` (cu `zlib` + `base64` din stdlib), `curl` — toate built-in pe macOS și majoritatea distribuțiilor Linux.

## Editare

Pe `mermaid.live` (default) oricine poate edita fără auth.

Pe instanțe self-hostate (ex. `mermaid.wisedigital.tech`) editarea poate fi în spatele unui SSO. Pentru instanța Wise Digital: contactează `florin@wisedigital.tech` ca să fii adăugat la policy-ul Cloudflare Access. Generarea linkurilor de view nu necesită niciodată auth.

## Licență

MIT — vezi `LICENSE`.
