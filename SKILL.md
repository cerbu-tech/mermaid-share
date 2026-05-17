---
name: mermaid-share
description: Genereaza URL-uri partajabile pentru diagrame Mermaid prin instanta self-hostata mermaid.wisedigital.tech. Folosit cand userul cere o diagrama de partajat (Slack, email, dat altui agent) sau cand ai un cod Mermaid si vrei un link rendabil in browser.
---

# Mermaid Share

Toolkit pentru generat link-uri Mermaid partajabile public, fara auth, fara storage.

## Cand folosesti

- User cere o diagrama vizuala si vrei sa-i dai link, nu cod
- Trimit un schema unui coleg/client pe Slack/email
- Pasi unui alt agent (Hermes, Claude, etc.) referinta vizuala la o diagrama deja generata
- Embed intr-o nota Obsidian sub forma de link in afara de blocul ` ```mermaid `

## Configurare host

Skill-ul scoate URL-uri spre orice instanta de mermaid-live-editor. Setat via env var:

```bash
export MERMAID_HOST=mermaid.live              # default — instanta publica oficiala
export MERMAID_HOST=mermaid.wisedigital.tech  # instanta wisedigital (intern firma)
```

Daca nu setezi nimic, URL-urile pleaca spre `mermaid.live` (zero infra dependency).

## Contract

Editorul accepta starea diagramei encodata in fragmentul URL. Doua formate:

- `#base64:<base64url(JSON state)>` — JSON-ul direct base64-encodat. Merge la diagrame mici, dar **esueaza la diagrame lungi** (Loading URL failed). Suportat doar pentru retro-compat.
- `#pako:<base64url(zlib.compress(JSON state))>` — JSON-ul zlib-comprimat apoi base64. **Recomandat** — URL-uri ~3-5x mai scurte si suporta diagrame mari.

`JSON state`:

```json
{"code":"<cod mermaid>","mermaid":"{\"theme\":\"default\"}","autoSync":true,"updateDiagram":true}
```

`base64url` = base64 standard cu `+/` inlocuit cu `-_`, fara padding `=`.

`/view` e public. `/edit` (pe instanta wisedigital) e in spatele Cloudflare Access — `@wisedigital.tech`. Linkurile generate aici se deschid in modul view, oricine cu URL-ul le vede.

## Optiunea 1 — script (recomandat)

```bash
echo 'flowchart LR
  A --> B' | ./mermaid-url.sh
```

Iesire: URL `https://$MERMAID_HOST/view#pako:...` gata de copy/paste.

## Optiunea 2 — python one-liner (oriunde python3 e disponibil)

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

## Optiunea 3 — python inline (agenti cu code-exec direct)

```python
import os, json, zlib, base64
state = {"code": code, "mermaid": '{"theme":"default"}', "autoSync": True, "updateDiagram": True}
compressed = zlib.compress(json.dumps(state).encode(), 9)
b64 = base64.urlsafe_b64encode(compressed).decode().rstrip("=")
url = f"https://{os.environ.get('MERMAID_HOST', 'mermaid.live')}/view#pako:{b64}"
```

## Verificare

Dupa generare, valideaza ca URL-ul raspunde:

```bash
curl -sI -o /dev/null -w "%{http_code}\n" "$URL"
```

Asteapta `200`. Daca primesti `503` instanta e jos — anunta-l pe florin.

## Limite & gotchas

- **Diagrama traieste in URL.** Daca o pierzi, nu o recuperezi din server. Salveaza codul Mermaid separat (ex. in Obsidian vault).
- **Linkuri foarte lungi** (>4-8KB chiar si dupa pako) — unii clienti (Slack desktop, anumite gateway-uri email) pot trunchia. Pentru diagrame extreme, salveaza codul si trimite cod + screenshot in loc de URL.
- **URL lung in markdown link `[text](url)`** — render-ul / parsing-ul intermediar poate corupe URL-uri >1-2KB (caractere `-_` din base64url, paranteze imbricate). Pentru diagrame mari, posteaza URL-ul ca **code block** (` ``` `) sau text simplu, nu ca markdown link.
- **Pentru editare**: linkul de view nu permite editare. Cine vrea sa modifice, paste-uieste codul intr-un nou tab `/edit` (necesita CF Access pe instanta wisedigital).
- **Verificare sintaxa Mermaid**: scriptul nu valideaza. Daca codul e gresit, editorul afiseaza eroarea inline cand userul deschide URL-ul.

## Diagram code requirements

- Sintaxa Mermaid 11.x (instanta wisedigital foloseste imaginea oficiala `latest`)
- Newlines `\n` real, nu literal `\\n`
- Ghilimele duble in label-uri escape-uite daca treci codul prin JSON (scriptul si python one-liner-ul fac asta automat prin `json.dumps`)

## Dependente sistem

- `bash`, `python3` (cu `zlib` si `base64` din stdlib — ambele built-in), `curl` pentru verificare. Pe macOS / Linux toate sunt prezente by default.

## Pentru distributie la alti agenti

Acest folder (`wise-infra/mermaid/`) e self-contained. Pentru a transfera skill-ul:

- **Pe alt agent local (ex. Hermes pe Legion):** copiaza `SKILL.md` + `mermaid-url.sh` in folderul de skills al agentului. Necesar pe sistem: `bash`, `jq`, `base64`, `curl`.
- **Pentru agent fara filesystem:** paste-uieste continutul `SKILL.md` direct in context-ul lui ca system/tool description.
- **Update-uri:** orice schimbare de domeniu sau policy se face aici; sincronizarea la Hermes se face prin pull manual sau sync explicit.
