# Inventario de archivos — kodingo-school-agentic

Referencia de **todos los archivos versionados** del repositorio (excluye `.git/`).

```
kodingo-school-agentic/
├── README.md
├── AGENTS.md
├── .gitignore
├── agents/
│   └── registry.yaml            ← registro YAML (framework)
├── framework/                   ← paquete Python kodingo-agents
│   ├── pyproject.toml
│   ├── README.md
│   ├── kodingo_agents/
│   │   ├── cli.py
│   │   ├── context.py
│   │   ├── orchestrator.py
│   │   ├── prompt_builder.py
│   │   ├── registry.py
│   │   └── runner.py
│   └── tests/
├── docs/
│   ├── ARCHIVOS.md              ← este documento
│   └── FRAMEWORK.md             ← arquitectura del framework
├── .cursor/
│   ├── rules/
│   │   └── code-review.mdc
│   └── skills/
│       └── kodingo-code-review/
│           ├── SKILL.md
│           └── checklist.md
├── code-review/
│   ├── README.md
│   ├── agente.md
│   ├── templates/
│   │   └── reporte-code-review.md
│   └── github-prompts/
│       └── kodingo-code-review.prompt.md
├── quality-gate/
│   ├── README.md
│   ├── agente-00-orquestador.md
│   ├── agente-01-code-review.md
│   ├── agente-02-refactorizacion-deuda-tecnica.md
│   ├── agente-03-validacion-pruebas-unitarias.md
│   ├── agente-04-validacion-springboot-quarkus.md
│   └── github-prompts/
│       ├── agente-00-orquestador.prompt.md
│       ├── agente-01-code-review.prompt.md
│       ├── agente-02-deuda-tecnica.prompt.md
│       ├── agente-03-pruebas-unitarias.prompt.md
│       └── agente-04-migracion-quarkus.prompt.md
└── scripts/
    └── collect-diff.sh
```

---

## Raíz

| Archivo | Propósito |
|---------|-----------|
| [`README.md`](../README.md) | Entrada al repo: framework CLI + Cursor, estructura, agentes. |
| [`AGENTS.md`](../AGENTS.md) | Índice de agentes para Cursor: rol, cuándo usarlos, enlaces a skill y plantillas. |
| [`.gitignore`](../.gitignore) | Ignora `.venv/`, `__pycache__/`, `.runtime/`. |

---

## `agents/`

| Archivo | Propósito |
|---------|-----------|
| [`registry.yaml`](../agents/registry.yaml) | **Registro machine-readable**: IDs de agentes, rutas a `.md`, plantillas de salida, pipelines. Lo consume `kodingo-agent`. |

---

## `framework/` — paquete `kodingo-agents`

CLI y librería Python. Ver [`FRAMEWORK.md`](FRAMEWORK.md) y [`framework/README.md`](../framework/README.md).

| Archivo | Propósito |
|---------|-----------|
| [`pyproject.toml`](../framework/pyproject.toml) | Metadatos pip, entry point `kodingo-agent`, extras `[cursor]` y `[dev]`. |
| [`kodingo_agents/registry.py`](../framework/kodingo_agents/registry.py) | Carga `agents/registry.yaml`, tipos `AgentDef` / `PipelineDef`. |
| [`kodingo_agents/context.py`](../framework/kodingo_agents/context.py) | `git diff` del repo objetivo. |
| [`kodingo_agents/prompt_builder.py`](../framework/kodingo_agents/prompt_builder.py) | Ensambla prompt: MD + contexto + plantilla + ruta de salida. |
| [`kodingo_agents/runner.py`](../framework/kodingo_agents/runner.py) | Modo ensamblar (archivo) o `--execute` (Cursor SDK). |
| [`kodingo_agents/orchestrator.py`](../framework/kodingo_agents/orchestrator.py) | Ejecuta pipelines secuenciales. |
| [`kodingo_agents/cli.py`](../framework/kodingo_agents/cli.py) | Comandos `list`, `run`, `pipeline`. |
| [`tests/`](../framework/tests/) | Tests pytest del registry y prompt builder. |

---

## `docs/`

| Archivo | Propósito |
|---------|-----------|
| [`ARCHIVOS.md`](ARCHIVOS.md) | Inventario y descripción de cada archivo del repositorio. |
| [`FRAMEWORK.md`](FRAMEWORK.md) | Arquitectura del framework, flujos, extensión. |

---

## `.cursor/` — integración Cursor IDE

Configuración que Cursor carga automáticamente cuando este repo está en el workspace.

| Archivo | Propósito |
|---------|-----------|
| [`rules/code-review.mdc`](../.cursor/rules/code-review.mdc) | Regla contextual: al pedir code review / revisar PR, indica usar la skill `kodingo-code-review` y no mezclar con agentes Java de `quality-gate/`. |
| [`skills/kodingo-code-review/SKILL.md`](../.cursor/skills/kodingo-code-review/SKILL.md) | **Definición principal** del agente de code review Kodingo: proceso, severidades, formato `CR-NNN`, veredicto, restricciones. |
| [`skills/kodingo-code-review/checklist.md`](../.cursor/skills/kodingo-code-review/checklist.md) | Checklist obligatorio por repo (`extractor`, `bot`, `web`, `infra`, `data`) y tabla de severidad mínima. |

---

## `code-review/` — agente Kodingo School

Agente orientado al ecosistema Kodingo (Node, Python, React, Terraform). Es el que debes usar para `kodingo-school-*`.

| Archivo | Propósito |
|---------|-----------|
| [`README.md`](../code-review/README.md) | Guía de uso: Cursor, Copilot, instalación, veredictos, relación con `quality-gate/`. |
| [`agente.md`](../code-review/agente.md) | Referencia humana: prompts manuales, activación en Cursor/Copilot, ejemplo de reporte. |
| [`templates/reporte-code-review.md`](../code-review/templates/reporte-code-review.md) | Plantilla Markdown del reporte de salida (`CR-NNN`, resumen ejecutivo, hallazgos). |
| [`github-prompts/kodingo-code-review.prompt.md`](../code-review/github-prompts/kodingo-code-review.prompt.md) | Prompt para **GitHub Copilot Chat** (copiar a `.github/prompts/` del repo destino). Frontmatter `mode: ask`. |

**Salida esperada en repos revisados:** `docs/quality-gate/reporte-code-review-YYYY-MM-DD.md` (carpeta en el repo destino, no en agentic).

---

## `quality-gate/` — Quality Gate Java (legado)

Conjunto de agentes para proyectos **Java / Quarkus / Spring Boot**. No aplica directamente a Kodingo School; se mantiene como referencia reutilizable.

| Archivo | Propósito |
|---------|-----------|
| [`README.md`](../quality-gate/README.md) | Documentación completa: estructura, instalación en `.github/prompts/`, workspace, orden de ejecución, limitaciones de Copilot. |
| [`agente-00-orquestador.md`](../quality-gate/agente-00-orquestador.md) | Orquestador: diagnóstico inicial, orden de agentes 01–04, prompt de consolidación → dashboard. |
| [`agente-01-code-review.md`](../quality-gate/agente-01-code-review.md) | Code review Java: dependencias, `@Transactional`, logging, ejemplo de hallazgo `CR-NNN`. |
| [`agente-02-refactorizacion-deuda-tecnica.md`](../quality-gate/agente-02-refactorizacion-deuda-tecnica.md) | Deuda técnica y code smells; backlog priorizado. |
| [`agente-03-validacion-pruebas-unitarias.md`](../quality-gate/agente-03-validacion-pruebas-unitarias.md) | Cobertura y calidad de tests (JaCoCo). |
| [`agente-04-validacion-springboot-quarkus.md`](../quality-gate/agente-04-validacion-springboot-quarkus.md) | Comparación migración V1 Spring vs V2 Quarkus. |

### `quality-gate/github-prompts/`

Versiones listas para instalar en `.github/prompts/` del repo Java. Nombres en Copilot Chat al escribir `/`.

| Archivo | Equivalente | Descripción breve |
|---------|-------------|------------------|
| [`agente-00-orquestador.prompt.md`](../quality-gate/github-prompts/agente-00-orquestador.prompt.md) | agente-00 | Orquestación y dashboard |
| [`agente-01-code-review.prompt.md`](../quality-gate/github-prompts/agente-01-code-review.prompt.md) | agente-01 | Code review Java |
| [`agente-02-deuda-tecnica.prompt.md`](../quality-gate/github-prompts/agente-02-deuda-tecnica.prompt.md) | agente-02 | Deuda técnica |
| [`agente-03-pruebas-unitarias.prompt.md`](../quality-gate/github-prompts/agente-03-pruebas-unitarias.prompt.md) | agente-03 | Pruebas unitarias |
| [`agente-04-migracion-quarkus.prompt.md`](../quality-gate/github-prompts/agente-04-migracion-quarkus.prompt.md) | agente-04 | Migración Quarkus |

Los `.prompt.md` son versiones condensadas de los `agente-NN-*.md` de la misma carpeta.

---

## `scripts/`

| Archivo | Propósito |
|---------|-----------|
| [`collect-diff.sh`](../scripts/collect-diff.sh) | Script bash: imprime repo, rama, `git diff --stat` y diff (truncado a 400 líneas) para pegar en Cursor/Copilot antes del review. Uso: `./scripts/collect-diff.sh [ruta-repo] [rama-base]`. |

---

## Qué archivo usar según el caso

| Necesidad | Archivo |
|-----------|---------|
| Ejecutar agente desde terminal / CI | `kodingo-agent run …` — ver `framework/README.md` |
| Registrar un agente nuevo | `agents/registry.yaml` |
| Revisar un PR de `kodingo-school-bot` en Cursor | Skill `.cursor/skills/kodingo-code-review/SKILL.md` (automática) |
| Copiar prompt a Copilot en extractor | `code-review/github-prompts/kodingo-code-review.prompt.md` |
| Ver reglas por repo (Azure, Discord, etc.) | `.cursor/skills/kodingo-code-review/checklist.md` |
| Plantilla del reporte | `code-review/templates/reporte-code-review.md` |
| Quality Gate Java completo | `quality-gate/README.md` → agente 00 primero |
| Recopilar diff local | `scripts/collect-diff.sh` |

---

## Instalación en repos hijos

| Origen | Destino en repo hijo |
|--------|----------------------|
| `.cursor/skills/kodingo-code-review/` | `.cursor/skills/kodingo-code-review/` |
| `code-review/github-prompts/*.prompt.md` | `.github/prompts/` |
| `quality-gate/github-prompts/*.prompt.md` | `.github/prompts/` (proyectos Java) |

Los reportes generados **no** se guardan en `kodingo-school-agentic`; van en `docs/quality-gate/` del repo que se revisó.
