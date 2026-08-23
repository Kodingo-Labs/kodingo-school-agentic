# kodingo-agents — framework

Biblioteca Python que convierte los **prompts Markdown** del repo en agentes ejecutables: registro YAML, contexto git, ensamblado de prompt y ejecución opcional vía **Cursor SDK**.

Los `.md` siguen siendo la fuente de verdad del comportamiento; el framework los **carga, combina y orquesta**.

## Instalación

```bash
cd framework
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

# Ejecución automática con LLM (opcional)
pip install -e ".[cursor]"
export CURSOR_API_KEY=...
```

## CLI

```bash
# Listar agentes y pipelines
kodingo-agent list

# Ensamblar prompt (sin API) — escribe en <repo>/.runtime/kodingo-agent/
kodingo-agent run kodingo-code-review \
  --repo ../kodingo-school-extractor \
  --base main \
  --print-prompt

# Ejecutar con Cursor SDK y guardar reporte en el repo objetivo
kodingo-agent run kodingo-code-review \
  --repo ../kodingo-school-extractor \
  --execute

# Pipeline (varios agentes en secuencia)
kodingo-agent pipeline quality-gate-java --repo ../mi-app-java --execute
```

## Arquitectura

```
agents/registry.yaml          ← definición de agentes y pipelines
        │
        ▼
kodingo_agents/registry.py    ← carga YAML
kodingo_agents/context.py     ← git diff del repo objetivo
kodingo_agents/prompt_builder.py  ← une MD + contexto + plantilla
kodingo_agents/runner.py        ← ensamblar | Cursor SDK
kodingo_agents/orchestrator.py  ← pipelines
kodingo_agents/cli.py           ← kodingo-agent
```

## Añadir un agente

1. Crea o reutiliza archivos `.md` con el prompt.
2. Regístralo en [`../agents/registry.yaml`](../agents/registry.yaml).
3. `kodingo-agent list` debe mostrarlo.

## Modos de ejecución

| Modo | Flag | Requiere API | Resultado |
|------|------|--------------|-----------|
| Ensamblar | (default) | No | `prompt-*.md` en `.runtime/kodingo-agent/` |
| Cursor SDK | `--execute` | `CURSOR_API_KEY` | Reporte en `docs/quality-gate/` del repo objetivo |
| Cursor IDE | manual | No | Pega el prompt ensamblado en el chat |

## Tests

```bash
pytest
```
