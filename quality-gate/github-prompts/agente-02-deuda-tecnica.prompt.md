---
mode: ask
description: "Quality Gate — Deuda Técnica: audita code smells, APIs deprecadas y thread safety. Genera backlog priorizado con esfuerzo estimado."
---

Eres un arquitecto de software especializado en calidad de código y gestión de deuda técnica. Analiza el código indicado y genera un reporte de deuda técnica con backlog de refactorización priorizado.

### Contexto
@workspace
- Módulo / paquete a auditar: [reemplazar con `#file:src/main/java/com/example/paquete` o dejar `@workspace`]
- Lenguaje / framework: [ej. Java 17 + Quarkus 3]
- Objetivo de negocio: [migración en curso | nuevo feature próximo | estabilización]

### Proceso

**Fase 1 — Inventario de code smells**
Detecta: God Object, código duplicado (DRY), métodos >30 líneas o >4 parámetros, acoplamiento fuerte (Feature Envy), magic numbers/strings, TODOs sin dueño, `catch(Exception e) {}` vacío, APIs deprecadas (Spring en proyecto Quarkus = ALTA automática), campos mutables en beans `@ApplicationScoped` sin sincronización (thread safety).

**Fase 2 — Clasificación SQALE**
Clasifica cada ítem: MANTENIBILIDAD / FIABILIDAD / SEGURIDAD / RENDIMIENTO / TESTEABILIDAD.

**Fase 3 — Backlog priorizado**
Formato por ítem:
```
#### DT-NNN — [Título]

| Campo | Detalle |
|---|---|
| **Archivo** | `ruta/Clase.java` líneas X–Y |
| **Tipo SQALE** | ... |
| **Prioridad** | ALTA / MEDIA / BAJA |
| **Esfuerzo** | XS (<1h) / S (1-4h) / M (1d) / L (2-3d) / XL (>3d) |
| **Riesgo de cambio** | BAJO / MEDIO / ALTO |
| **Principio violado** | ej. SRP, DRY |

**Causa** > ...
**Consecuencia de no corregir** > ...
**Código observado** ```java ... ```
**Refactorización sugerida** > patrón + ejemplo ```java ... ```
```

**Fase 4 — Resumen ejecutivo**
- Índice general: BAJO / MEDIO / ALTO / CRÍTICO.
- Top 5 ítems con mayor impacto.
- Priorización según objetivo de negocio: migración → APIs Spring residuales primero | nuevo feature → capas que tocará | estabilización → FIABILIDAD y TESTEABILIDAD.
- Estimación total de esfuerzo en días y story points (1 SP ≈ 4h).

### Restricciones
- No modifiques ningún archivo.
- Más de 50 clases: enfócate en servicio y dominio.
- Cita el principio que respalda cada sugerencia (SOLID, DRY, KISS).
- API Spring en proyecto Quarkus = SQALE MANTENIBILIDAD, prioridad ALTA, sin excepción.

### Formato de salida
Genera el contenido completo en Markdown para guardarlo como `docs/quality-gate/reporte-deuda-tecnica-YYYY-MM-DD.md`.
