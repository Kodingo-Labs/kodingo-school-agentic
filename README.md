# Kodingo School — Agentic

Repositorio central de **agentes y prompts** para automatizar tareas de ingeniería en el ecosistema Kodingo School.

## Dos capas

| Capa | Qué es | Cuándo |
|------|--------|--------|
| **Markdown** | Skills Cursor, prompts Copilot, checklists | Chat interactivo en el IDE |
| **Framework** | CLI `kodingo-agent` (Python) | Scripts, CI, ejecución con Cursor SDK |

Documentación del framework: [`docs/FRAMEWORK.md`](docs/FRAMEWORK.md)  
Inventario de archivos: [`docs/ARCHIVOS.md`](docs/ARCHIVOS.md)

## Inicio rápido — framework

```bash
cd framework
pip install -e .
kodingo-agent list

kodingo-agent run kodingo-code-review \
  --repo ../kodingo-school-extractor \
  --base main
```

El prompt ensamblado queda en `<repo>/.runtime/kodingo-agent/`. Con `CURSOR_API_KEY` y `--execute` se genera el reporte en `docs/quality-gate/` del repo objetivo.

## Inicio rápido — Cursor (sin CLI)

1. Abre este repo en Cursor.
2. *"Haz code review del diff en kodingo-school-extractor"*
3. Se carga la skill `kodingo-code-review` desde `.cursor/skills/`.

## Estructura

```
├── agents/registry.yaml       ← registro de agentes (framework)
├── framework/                 ← paquete Python kodingo-agents
├── .cursor/                   ← skills y rules Cursor
├── code-review/               ← agente Kodingo (MD + plantillas)
├── quality-gate/              ← agentes Java (legado)
├── scripts/collect-diff.sh    ← helper bash (opcional si usas CLI)
└── docs/
```

## Agentes

| ID | Stack | Uso |
|----|-------|-----|
| `kodingo-code-review` | Kodingo | PRs extractor / web / bot / infra |
| `quality-gate-*` | Java | Quarkus / Spring (ver `quality-gate/`) |

Pipelines: `kodingo-code-review`, `quality-gate-java` — ver `kodingo-agent list`.

## Instalar skill en otro repo

```bash
cp -R .cursor/skills/kodingo-code-review ../kodingo-school-extractor/.cursor/skills/
```
