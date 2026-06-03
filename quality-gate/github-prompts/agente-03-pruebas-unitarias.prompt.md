---
mode: ask
description: "Quality Gate — Pruebas Unitarias: mapea cobertura, detecta @QuarkusTest mal usado y genera tests faltantes compilables."
---

Eres un experto en testing de software. Audita las pruebas unitarias del proyecto, identifica brechas de cobertura y genera un plan de acción con los tests faltantes.

### Contexto
@workspace
- Código fuente: `#file:src/main/java/com/example` (ajustar al paquete)
- Tests existentes: `#file:src/test/java/com/example`
- Reporte JaCoCo: [SÍ → `#file:target/site/jacoco/index.html` | NO]
- Framework de testing: [ej. JUnit 5 + Mockito + QuarkusTest]
- Cobertura mínima objetivo: [ej. 80%]

### Proceso

**Fase 1 — Mapeo clases vs. tests**
Construye tabla: Clase fuente | Clase de test | Estado (✅ Existe / ❌ Sin test / ⚠️ Incompleto).

**Fase 2 — Calidad de tests existentes**
Verifica: happy path, casos límite (null, lista vacía, valores extremos), casos de error/excepción, mocks bien configurados, asserts específicos, nomenclatura `shouldDoX_whenY`, `@ParameterizedTest` donde aplique.

**Distinción crítica en Quarkus:**
- Sin `@QuarkusTest` (JUnit 5 + Mockito) → test unitario ✅ — usar para lógica de negocio.
- Con `@QuarkusTest` → test de integración ⚠️ — levanta CDI completo, lento. Solo para endpoints REST o flujos multi-bean.
- Con `@QuarkusUnitTest` → verifica bootstrap del contenedor.

Marca cada test: ✅ Completo / ⚠️ Parcial / ❌ Deficiente / ⚠️ Tipo incorrecto.

**Fase 3 — Plan de acción**
Formato por brecha:
```
#### UT-NNN — [Clase] · [método/escenario]

| Campo | Detalle |
|---|---|
| **Clase** | `com.example.Clase` |
| **Método(s)** | `metodo()` |
| **Tipo de test** | Happy path / Edge case / Excepción / Integración |
| **Prioridad** | ALTA / MEDIA / BAJA |

**Causa de la brecha** > ...
**Consecuencia de no tener este test** > ...
**Test sugerido** ```java ... ```
```

**Fase 4 — Resumen**
Total clases / con test / sin test / parciales. Estimación de cobertura actual. Esfuerzo para llegar al objetivo. Top 5 urgentes.

### Restricciones
- No modifiques tests existentes.
- Tests compilables siguiendo convenciones del proyecto.
- Lógica de negocio: siempre JUnit 5 + Mockito puro, nunca `@QuarkusTest`.
- Endpoints REST: `@QuarkusTest` marcado explícitamente como integración.

### Formato de salida
Genera el contenido completo en Markdown para guardarlo como `docs/quality-gate/reporte-pruebas-unitarias-YYYY-MM-DD.md`.
