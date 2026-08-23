# Agente — Code Review Kodingo School

## Propósito

Revisar código del ecosistema Kodingo School antes de merge: calidad, seguridad, contratos entre repos y reglas de arquitectura documentadas. Genera un reporte Markdown con hallazgos priorizados.

---

## Activar en Cursor

1. Workspace con `kodingo-school-agentic` (skill auto-cargada).
2. Chat: *"Code review de [repo/PR/archivos]"*.
3. Opcional: pega el diff o indica `git diff main...HEAD`.

Definición: [`.cursor/skills/kodingo-code-review/SKILL.md`](../.cursor/skills/kodingo-code-review/SKILL.md)

---

## Activar en Copilot Chat

1. Instala `code-review/github-prompts/kodingo-code-review.prompt.md` en `.github/prompts/`.
2. `/` → `kodingo-code-review`.
3. Completa el bloque **Contexto** y envía.

---

## Prompt manual (copiar/pegar)

```
Eres revisor senior de Kodingo School. Analiza el código indicado y produce un reporte de code review.

### Contexto
- Repo: [kodingo-school-extractor | -web | -bot | -infra]
- Scope: [git diff main...HEAD | carpeta src/ | archivos listados]
- Tipo de cambio: [feature | bugfix | refactor]
- PR / rama: [opcional]

### Proceso
1. Lee el diff o los archivos del scope; no inventes líneas.
2. Aplica el checklist Kodingo (Azure manifiesto 1+1, capture-index, Discord store, sin secretos, límites por repo).
3. Clasifica: 🔴 Bloqueante | 🟠 Importante | 🟡 Sugerencia | 🔵 Estilo.
4. Por hallazgo: CR-NNN, archivo+línea, causa, consecuencia, código observado, corrección.
5. Resumen: conteos, top 3, veredicto APROBADO / APROBADO CON CAMBIOS MENORES / RECHAZADO.

### Restricciones
- No modifiques archivos; solo reporta.
- Respuesta en español.
- Prioriza seguridad y regresiones de arquitectura sobre estilo.

### Salida
Markdown listo para guardar como docs/quality-gate/reporte-code-review-YYYY-MM-DD.md
```

---

## Ejemplo de salida

```markdown
# Reporte de Code Review
**Proyecto:** kodingo-school-bot | **Fecha:** 2026-05-30
**Scope:** `src/checklist.py`, `config/protocolos.yaml`
**Revisado por:** Agente Code Review Kodingo

---

## Resumen ejecutivo

| Categoría | Total |
|-----------|-------|
| 🔴 Bloqueante | 0 |
| 🟠 Importante | 1 |
| 🟡 Sugerencia | 2 |
| 🔵 Estilo | 0 |

**Veredicto:** 🟡 APROBADO CON CAMBIOS MENORES

**Top 3:** CR-001, CR-002, CR-003

---

## Hallazgos

#### 🟠 CR-001 — Slug de evidencia inconsistente con protocolo unificado

| Campo | Detalle |
|-------|---------|
| **Archivo** | `src/evidencias.py` |
| **Línea(s)** | 112–115 |
| **Categoría** | 🟠 Importante |

**Causa**
> El resolver aún acepta `beeverso:foto` aunque el protocolo pasó a un solo paso `beeverso:beeverso`.

**Consecuencia de no corregir**
> Evidencias huérfanas o mensajes confusos en `/evidencia` tras el cambio de protocolo.

**Código observado**
```python
# línea 112
match = next((i for i in pendientes if i.slug == item_slug), None)
```

**Cómo debe implementarse**
> Documentar slugs legacy o normalizar en `resolver_item()` al cargar checklist.
```
