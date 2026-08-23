# Agentes — Kodingo School Agentic

Índice de agentes. **Framework CLI:** [`docs/FRAMEWORK.md`](docs/FRAMEWORK.md) · **Inventario:** [`docs/ARCHIVOS.md`](docs/ARCHIVOS.md)

```bash
cd framework && pip install -e . && kodingo-agent list
```

---

## Code Review Kodingo (`kodingo-code-review`)

**Rol:** Revisor senior del ecosistema Kodingo School. Analiza diffs y código en busca de bugs, seguridad, regresiones de arquitectura y deuda evitable. **Solo reporta; no modifica archivos** salvo que el usuario lo pida explícitamente después.

**Cuándo usarlo:**
- Antes de abrir o mergear un PR
- Tras un refactor grande (extractor loader, Discord store, Azure)
- Cuando quieras una segunda opinión estructurada sobre un módulo

**Cómo invocarlo en Cursor:**
- Menciona *code review*, *revisar PR*, *revisar diff* o el nombre del agente
- Indica repo y scope: `git diff main...HEAD`, carpeta (`loader/`, `src/`), o archivos concretos

**Salida:** reporte Markdown con hallazgos `CR-NNN`, severidad, causa, consecuencia y corrección sugerida.

| Recurso | Ruta |
|---------|------|
| Skill (definición) | [`.cursor/skills/kodingo-code-review/SKILL.md`](.cursor/skills/kodingo-code-review/SKILL.md) |
| Checklist por repo | [`.cursor/skills/kodingo-code-review/checklist.md`](.cursor/skills/kodingo-code-review/checklist.md) |
| Regla Cursor | [`.cursor/rules/code-review.mdc`](.cursor/rules/code-review.mdc) |
| Guía humana | [`code-review/README.md`](code-review/README.md) |
| Prompt Copilot | [`code-review/github-prompts/kodingo-code-review.prompt.md`](code-review/github-prompts/kodingo-code-review.prompt.md) |
| Plantilla reporte | [`code-review/templates/reporte-code-review.md`](code-review/templates/reporte-code-review.md) |
| Helper diff | [`scripts/collect-diff.sh`](scripts/collect-diff.sh) |

---

## Quality Gate Java (agentes 00–04)

Para proyectos **Java / Quarkus / Spring**, no para repos Kodingo School habituales.

| Agente | Archivo referencia | Prompt Copilot |
|--------|-------------------|----------------|
| 00 Orquestador | [`quality-gate/agente-00-orquestador.md`](quality-gate/agente-00-orquestador.md) | [`agente-00-orquestador.prompt.md`](quality-gate/github-prompts/agente-00-orquestador.prompt.md) |
| 01 Code review | [`quality-gate/agente-01-code-review.md`](quality-gate/agente-01-code-review.md) | [`agente-01-code-review.prompt.md`](quality-gate/github-prompts/agente-01-code-review.prompt.md) |
| 02 Deuda técnica | [`quality-gate/agente-02-refactorizacion-deuda-tecnica.md`](quality-gate/agente-02-refactorizacion-deuda-tecnica.md) | [`agente-02-deuda-tecnica.prompt.md`](quality-gate/github-prompts/agente-02-deuda-tecnica.prompt.md) |
| 03 Pruebas unitarias | [`quality-gate/agente-03-validacion-pruebas-unitarias.md`](quality-gate/agente-03-validacion-pruebas-unitarias.md) | [`agente-03-pruebas-unitarias.prompt.md`](quality-gate/github-prompts/agente-03-pruebas-unitarias.prompt.md) |
| 04 Migración Quarkus | [`quality-gate/agente-04-validacion-springboot-quarkus.md`](quality-gate/agente-04-validacion-springboot-quarkus.md) | [`agente-04-migracion-quarkus.prompt.md`](quality-gate/github-prompts/agente-04-migracion-quarkus.prompt.md) |

Documentación general: [`quality-gate/README.md`](quality-gate/README.md)
