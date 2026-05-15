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

## Contract

Editorul accepta starea diagramei encodata in fragmentul URL. Format minim:

```
https://mermaid.wisedigital.tech/view#base64:<base64url(JSON state)>
```

Unde `JSON state` e:

```json
{"code":"<cod mermaid>","mermaid":"{\"theme\":\"default\"}","autoSync":true,"updateDiagram":true}
```

`base64url` = base64 standard cu `+/` inlocuit cu `-_`, fara padding `=`.

`/view` e public. `/edit` e in spatele Cloudflare Access (doar florin@wisedigital.tech). Linkurile generate aici se deschid in modul view, oricine cu URL-ul le vede.

## Optiunea 1 — script (recomandat daca esti pe Mac-ul florin, sau ai sincronizat folderul)

```bash
echo 'flowchart LR
  A --> B' | ./mermaid-url.sh
```

Iesire: URL gata de copy/paste.

## Optiunea 2 — shell one-liner (oriunde, doar `jq` + `base64`)

```bash
CODE='flowchart LR
  A --> B'
jq -cjn --arg c "$CODE" '{code:$c,mermaid:"{\"theme\":\"default\"}",autoSync:true,updateDiagram:true}' \
  | base64 | tr '+/' '-_' | tr -d '=\n' \
  | awk '{print "https://mermaid.wisedigital.tech/view#base64:" $0}'
```

## Optiunea 3 — python (pentru agenti cu code-exec)

```python
import json, base64
state = {"code": code, "mermaid": '{"theme":"default"}', "autoSync": True, "updateDiagram": True}
b64 = base64.urlsafe_b64encode(json.dumps(state).encode()).decode().rstrip("=")
url = f"https://mermaid.wisedigital.tech/view#base64:{b64}"
```

## Verificare

Dupa generare, valideaza ca URL-ul raspunde:

```bash
curl -sI -o /dev/null -w "%{http_code}\n" "$URL"
```

Asteapta `200`. Daca primesti `503` instanta e jos — anunta-l pe florin.

## Limite & gotchas

- **Diagrama traieste in URL.** Daca o pierzi, nu o recuperezi din server. Salveaza codul Mermaid separat (ex. in Obsidian vault).
- **Pe linkuri foarte lungi** (>2KB) unii clienti (mai ales Slack desktop) pot trunchia. Pentru diagrame mari foloseste prefix `#pako:...` (compresie deflate) — vezi `README.md`.
- **Pentru editare**: linkul de view nu permite editare. Cine vrea sa modifice, paste-uieste codul intr-un nou tab `/edit` (necesita CF Access).
- **Verificare sintaxa Mermaid**: scriptul nu valideaza. Daca codul e gresit, editorul afiseaza eroarea inline cand userul deschide URL-ul.

## Diagram code requirements

- Sintaxa Mermaid 11.x (instanta foloseste imaginea oficiala `latest`)
- Newlines `\n` real, nu literal `\\n`
- Ghilimele duble in label-uri escape-uite daca treci codul prin JSON (scriptul si one-liner-ul fac asta automat cu `jq --arg`)

## Pentru distributie la alti agenti

Acest folder (`wise-infra/mermaid/`) e self-contained. Pentru a transfera skill-ul:

- **Pe alt agent local (ex. Hermes pe Legion):** copiaza `SKILL.md` + `mermaid-url.sh` in folderul de skills al agentului. Necesar pe sistem: `bash`, `jq`, `base64`, `curl`.
- **Pentru agent fara filesystem:** paste-uieste continutul `SKILL.md` direct in context-ul lui ca system/tool description.
- **Update-uri:** orice schimbare de domeniu sau policy se face aici; sincronizarea la Hermes se face prin pull manual sau sync explicit.
