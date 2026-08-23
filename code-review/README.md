# Agente — Code Review Kodingo School

Revisión estructurada de PRs y cambios locales en el ecosistema Kodingo School (Node, Python, React, Terraform).

**Inventario completo del repo:** [`../docs/ARCHIVOS.md`](../docs/ARCHIVOS.md)

## Archivos

```
code-review/
├── README.md                          ← este archivo
├── agente.md                          ← referencia completa + ejemplo de salida
├── templates/
│   └── reporte-code-review.md         ← plantilla del reporte
└── github-prompts/
    └── kodingo-code-review.prompt.md  ← para Copilot Chat (.github/prompts/)
```

La definición operativa para **Cursor** está en:

```
.cursor/skills/kodingo-code-review/
├── SKILL.md
└── checklist.md
```

## Uso en Cursor

1. Abre un workspace que incluya `kodingo-school-agentic` y el repo a revisar.
2. En el chat:

```
Haz code review del diff contra main en kodingo-school-bot.
Scope: src/checklist.py y src/evidencias.py
Tipo: refactor Beeverso
```

3. Copia el reporte generado a `docs/quality-gate/reporte-code-review-YYYY-MM-DD.md` del repo revisado (crea la carpeta si no existe).

**Opcional — recopilar diff:**

```bash
./scripts/collect-diff.sh ../kodingo-school-bot main
```

Pega la salida en el chat junto con la petición de review.

## Instalación en otro repo

**Cursor (recomendado)**

```bash
REPO=../kodingo-school-extractor   # ajustar
mkdir -p "$REPO/.cursor/skills"
cp -R .cursor/skills/kodingo-code-review "$REPO/.cursor/skills/"
```

**GitHub Copilot**

```bash
REPO=../kodingo-school-extractor
mkdir -p "$REPO/.github/prompts"
cp code-review/github-prompts/kodingo-code-review.prompt.md "$REPO/.github/prompts/"
```

En Copilot Chat: `/` → `kodingo-code-review` → editar el bloque Contexto → enviar.

## Scope recomendado por tipo de cambio

| Cambio | Dónde mirar primero |
|--------|---------------------|
| Sync Classroom | `loader/steps/`, `lib/azure/`, `capture-index` |
| Discord bot | `src/bot.py`, `discord_store.py`, `checklist.py` |
| Frontend quiz | `kodingo-school-web/src/` |
| Infra Azure | `terraform/`, `ci/validate.go` |

## Veredictos

| Veredicto | Significado |
|-----------|-------------|
| **APROBADO** | Sin bloqueantes ni importantes abiertos |
| **APROBADO CON CAMBIOS MENORES** | Solo sugerencias/estilo; merge posible con follow-up |
| **RECHAZADO** | Al menos un 🔴 bloqueante o 🟠 importante sin mitigar |

## Relación con `quality-gate/`

La carpeta [`quality-gate/`](../quality-gate/) contiene agentes orientados a **Java / Quarkus / Spring**. No aplica directamente a Kodingo School; usa este agente (`code-review/`) para los repos del ecosistema.
