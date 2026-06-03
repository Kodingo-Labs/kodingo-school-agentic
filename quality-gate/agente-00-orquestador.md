# Agente 00 — Orquestador de Quality Gate

## Propósito
Coordinar la ejecución de los 4 agentes de revisión en el orden correcto, evitar trabajo duplicado y consolidar todos los reportes en un único dashboard de decisión para el merge a producción / certificación.

---

## Instrucciones para activar el agente

> **Nota importante:** En GitHub Copilot, el orquestador funciona como un **runbook manual secuencial**, no como un proceso autónomo. Tú ejecutas cada agente en el orden indicado y al final usas el prompt de consolidación para generar el dashboard.

### Preparación del workspace
1. Abre en VS Code una carpeta raíz con esta estructura:
   ```
   /proyectos/
   ├── app-v1/          ← Spring Boot (legado)
   ├── app-v2/          ← Quarkus (nuevo)
   ├── docs/quarkus/    ← documentación HTML
   └── docs/quality-gate/  ← aquí se guardan los reportes generados
   ```
2. Abre Copilot Chat (`Ctrl+Alt+I` / `Cmd+Alt+I`).

### Paso 0 — Diagnóstico inicial
Antes de ejecutar cualquier agente, pega este diagnóstico rápido en Copilot Chat:

```
@workspace Realiza estas verificaciones y responde con SÍ/NO para cada una:

1. ¿Existen imports `org.springframework.*` en archivos .java dentro de app-v2/?
2. ¿Existen dependencias `spring-boot-starter-*` en #file:app-v2/pom.xml?
3. ¿Existe el directorio src/test/java con al menos un archivo de test en app-v2/?
4. ¿Hay reportes previos en docs/quality-gate/?

Con base en las respuestas, indica qué agentes debo ejecutar y en qué orden.
```

### Paso 1 — Ejecutar agentes en orden
Según el resultado del diagnóstico, ejecuta los agentes en esta secuencia:

| Orden | Agente | Condición |
|-------|--------|-----------|
| 1° | Agente 04 — Migración | Si hay Spring en app-v2 (OBLIGATORIO primero) |
| 2° | Agente 01 — Code Review | Solo sobre módulos que el Agente 04 marcó como migrados OK |
| 3° | Agente 02 — Deuda Técnica | Mismo scope que Agente 01 |
| 4° | Agente 03 — Pruebas Unitarias | Siempre, al final |

> Si el Agente 04 devuelve veredicto **INCOMPLETA — BLOQUEADA**, detener. No ejecutar los demás agentes. La migración debe completarse primero.

### Paso 2 — Guardar cada reporte
Después de cada agente, copia la respuesta de Copilot y guárdala como archivo `.md` en `docs/quality-gate/`.

### Paso 3 — Generar el dashboard consolidado
Una vez guardados todos los reportes, pega este prompt en Copilot Chat:

---

## Prompt de consolidación

```
Eres el coordinador del proceso de Quality Gate para aprobación de merge a producción.
Tu tarea es consolidar los reportes individuales en un dashboard final de decisión.

### Contexto
@workspace
- 📋 Reporte Migración:       `#file:docs/quality-gate/reporte-migracion-springboot-quarkus-YYYY-MM-DD.md`
- 📋 Reporte Code Review:     `#file:docs/quality-gate/reporte-code-review-YYYY-MM-DD.md`
- 📋 Reporte Deuda Técnica:   `#file:docs/quality-gate/reporte-deuda-tecnica-YYYY-MM-DD.md`
- 📋 Reporte Pruebas:         `#file:docs/quality-gate/reporte-pruebas-unitarias-YYYY-MM-DD.md`
- 🔍 Módulo / PR evaluado:    [INDICAR]

> Si algún reporte no existe porque ese agente no se ejecutó, indícalo como N/A en el dashboard.

### Regla de veredicto final
El veredicto consolidado es el más restrictivo de los 4:
- Si cualquier agente dice RECHAZADO → veredicto final: 🔴 RECHAZADO
- Si todos dicen APROBADO o N/A → veredicto final: ✅ APROBADO
- Si hay hallazgos importantes pero ningún bloqueante → 🟡 APROBADO CON CAMBIOS MENORES

Genera el contenido del dashboard para que lo guarde como `dashboard-quality-gate-YYYY-MM-DD.md`.

### Formato de salida — Dashboard consolidado

---

# Dashboard Quality Gate
**Proyecto:** [nombre] | **Módulo:** [módulo] | **Fecha:** [fecha]
**PR / Rama:** [referencia] | **Evaluado por:** Agente 00 — Orquestador

---

## Veredicto Final

> ### [VEREDICTO EN GRANDE]
> **APROBADO PARA PRODUCCIÓN** ✅
> — o —
> **APROBADO CON CAMBIOS MENORES** 🟡 — puede mergearse si se resuelven los ítems marcados
> — o —
> **RECHAZADO** 🔴 — no mergear hasta resolver hallazgos bloqueantes

---

## Resumen por agente

| Agente | Ejecutado | Veredicto | Bloqueantes | Importantes | Sugerencias |
|--------|-----------|-----------|-------------|-------------|-------------|
| 04 — Migración | ✅/❌/N/A | COMPLETA/EN PROGRESO/BLOQUEADA | X | X | X |
| 01 — Code Review | ✅/❌ | APROBADO/RECHAZADO | X | X | X |
| 02 — Deuda Técnica | ✅/❌ | BAJO/MEDIO/ALTO/CRÍTICO | — | X | X |
| 03 — Pruebas Unitarias | ✅/❌ | % estimado | — | X | X |

---

## Hallazgos bloqueantes (deben resolverse antes del merge)

Lista consolidada de todos los hallazgos 🔴 de todos los agentes, sin duplicados, ordenados por impacto.

| ID | Agente | Descripción | Archivo | Línea |
|----|--------|-------------|---------|-------|
| CR-001 | Code Review | ... | ... | ... |
| MIG-003 | Migración | ... | ... | ... |

---

## Hallazgos importantes (resolver antes de certificación)

Lista consolidada de hallazgos 🟠 de todos los agentes.

| ID | Agente | Descripción | Archivo | Esfuerzo |
|----|--------|-------------|---------|----------|

---

## Estado de pruebas

| Métrica | Valor |
|---------|-------|
| Clases con test | X / Y |
| Cobertura estimada | X% |
| Tests con tipo incorrecto (@QuarkusTest en unitarios) | X |
| Tests urgentes faltantes | X |

---

## Índice de deuda técnica

| Tipo SQALE | Ítems | Esfuerzo total estimado |
|------------|-------|------------------------|
| Mantenibilidad | X | Xd |
| Fiabilidad | X | Xd |
| Seguridad | X | Xd |
| Rendimiento | X | Xd |
| Testeabilidad | X | Xd |
| **TOTAL** | **X** | **Xd** |

---

## Reportes detallados
- [reporte-migracion-springboot-quarkus-YYYY-MM-DD.md](./reporte-migracion-springboot-quarkus-YYYY-MM-DD.md)
- [reporte-code-review-YYYY-MM-DD.md](./reporte-code-review-YYYY-MM-DD.md)
- [reporte-deuda-tecnica-YYYY-MM-DD.md](./reporte-deuda-tecnica-YYYY-MM-DD.md)
- [reporte-pruebas-unitarias-YYYY-MM-DD.md](./reporte-pruebas-unitarias-YYYY-MM-DD.md)

---

### Restricciones
- No ejecutes el Agente 01 sobre módulos que el Agente 04 marcó como no migrados — el review sería sobre código obsoleto.
- No modifiques ningún archivo de código fuente.
- Si un agente falla o no puede completar su análisis, documenta el motivo en el dashboard y continúa con los demás.
- El veredicto final es el más restrictivo de los 4 agentes: si cualquiera dice RECHAZADO, el veredicto consolidado es RECHAZADO.
```

---

## Orden de ejecución visual

```
┌─────────────────────────────────────────────────────────┐
│                  QUALITY GATE — BLOQUE 1                │
│                                                         │
│  [Agente 00 — Orquestador]                              │
│         │                                               │
│         ▼                                               │
│  [Agente 04 — Migración]  ──BLOQUEADA──▶  🛑 STOP      │
│         │ EN PROGRESO / COMPLETA                        │
│         ▼                                               │
│  [Agente 01 — Code Review]  (solo módulos migrados OK)  │
│         │                                               │
│         ▼                                               │
│  [Agente 02 — Deuda Técnica]                            │
│         │                                               │
│         ▼                                               │
│  [Agente 03 — Pruebas Unitarias]                        │
│         │                                               │
│         ▼                                               │
│  [Dashboard Consolidado] ──▶ APROBADO / RECHAZADO       │
└─────────────────────────────────────────────────────────┘
```
