# Framework de agentes

Hasta ahora los agentes vivían solo en **Markdown** (skills Cursor, prompts Copilot). El framework **`kodingo-agents`** añade una capa ejecutable sin duplicar el contenido.

## Capas

```
┌─────────────────────────────────────────────────────────┐
│  IDE (Cursor skill / Copilot prompt)  ← uso interactivo │
├─────────────────────────────────────────────────────────┤
│  kodingo-agent CLI                    ← scripts / CI    │
├─────────────────────────────────────────────────────────┤
│  agents/registry.yaml                 ← registro          │
├─────────────────────────────────────────────────────────┤
│  *.md (SKILL, checklist, prompts)     ← fuente de verdad│
└─────────────────────────────────────────────────────────┘
```

## Qué resuelve el framework

| Solo MD | Con framework |
|---------|----------------|
| Copiar/pegar prompts | `kodingo-agent run` ensambla todo |
| Contexto git manual (`collect-diff.sh`) | Diff inyectado automáticamente |
| Sin catálogo machine-readable | `registry.yaml` + `kodingo-agent list` |
| Pipelines en documentación | `kodingo-agent pipeline quality-gate-java` |
| Ejecución solo en IDE | `--execute` con Cursor SDK (opcional) |

## Componentes

| Ruta | Rol |
|------|-----|
| [`agents/registry.yaml`](../agents/registry.yaml) | IDs, archivos prompt, plantillas, pipelines |
| [`framework/kodingo_agents/`](../framework/kodingo_agents/) | Código Python del framework |
| [`framework/README.md`](../framework/README.md) | Instalación y CLI |

## Flujo típico — code review

```bash
cd kodingo-school-agentic/framework
pip install -e .

kodingo-agent run kodingo-code-review \
  --repo ../../kodingo-school-extractor \
  --base main
```

1. Lee `registry.yaml` → agente `kodingo-code-review`
2. Carga `SKILL.md` + `checklist.md`
3. Ejecuta `git diff main...HEAD` en el extractor
4. Escribe prompt completo en `kodingo-school-extractor/.runtime/kodingo-agent/prompt-*.md`
5. Con `--execute`: llama Cursor SDK y guarda `docs/quality-gate/reporte-code-review-YYYY-MM-DD.md`

## Extender

Nuevo agente = entrada en `registry.yaml` + archivos `.md`. No hace falta tocar Python salvo lógica transversal nueva (p. ej. otro tipo de contexto).

## Relación con `.cursor/skills/`

La skill Cursor y el registry **apuntan a los mismos MD**. Mantén un solo lugar para el texto del prompt; el registry solo referencia rutas.
