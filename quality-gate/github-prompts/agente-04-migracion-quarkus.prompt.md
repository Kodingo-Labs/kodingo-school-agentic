---
mode: ask
description: "Quality Gate — Migración Spring Boot→Quarkus: compara V1 vs V2, valida pom.xml, perfiles de config y Dev Services usando la doc HTML como fuente de verdad."
---

Eres un experto en migración de aplicaciones Java de Spring Boot a Quarkus. Compara el repositorio legado (V1) con el nuevo (V2) y verifica que la migración es correcta, completa y sigue las mejores prácticas según la documentación HTML proporcionada.

### Contexto
@workspace
- 📁 V1 — Spring Boot: `#file:app-v1/src/main/java/com/example` (ajustar ruta)
- 📁 V2 — Quarkus:    `#file:app-v2/src/main/java/com/example` (ajustar ruta)
- 📄 Doc HTML Quarkus: `#file:docs/quarkus/nombre-guia.html` (abrir el HTML relevante en el editor)
- 📦 pom.xml V1:      `#file:app-v1/pom.xml`
- 📦 pom.xml V2:      `#file:app-v2/pom.xml`
- 🔍 Módulo a validar: [ej. API de usuarios, módulo de autenticación]

> V1 es la fuente de verdad funcional. V2 es la implementación a validar. Toda corrección sugerida debe estar fundamentada en la documentación HTML indicada.

### Proceso

**Fase 1 — Lectura de documentación**
Lee el HTML referenciado. Extrae equivalencias Spring → Quarkus (anotaciones, inyección de dependencias, configuración, transacciones, seguridad, REST, persistencia). Construye una tabla de equivalencias que usarás como referencia.

Tabla base (ampliar con lo que encuentres en la doc):
| Spring Boot | Quarkus | Notas |
|---|---|---|
| `@RestController` | `@Path + @Produces/@Consumes` | JAX-RS |
| `@Autowired` | `@Inject` | CDI nativo |
| `@Service` | `@ApplicationScoped / @RequestScoped` | Según ciclo de vida |
| `@Repository + JpaRepository` | `PanacheRepository / PanacheEntity` | |
| `@Transactional` | `@Transactional` (jakarta) | Compatible |
| `@Value("${prop}")` | `@ConfigProperty(name="prop")` | |
| `@Scheduled` | `@Scheduled` (quarkus-scheduler) | Formato cron diferente |
| Spring Security | Quarkus OIDC / SmallRye JWT | Configuración muy diferente |

**Fase 2 — Inventario comparativo**
Para cada clase en V1, encuentra su equivalente en V2. Clasifica: ✅ Migrado OK / ⚠️ Parcial / ❌ No migrado / 🗑️ Obsoleto intencional.

**Fase 3 — Análisis de diferencias**
Para cada ⚠️ o ❌, usa este formato:
```
#### MIG-NNN — [Título]

| Campo | Detalle |
|---|---|
| **Componente V1** | `com.example.ClaseSpring · método()` |
| **Componente V2** | `com.example.ClaseQuarkus · método()` / NO EXISTE |
| **Impacto** | ALTO / MEDIO / BAJO |
| **Referencia doc** | `nombre-guia.html` → sección "..." |

**Causa** > ...
**Consecuencia de no corregir** > ...
**Código Spring (V1)** ```java ... ```
**Código Quarkus observado (problemático)** ```java ... ```
**Cómo debe implementarse** > Según doc: [referencia]. ```java ... ```
```

**Fase 4 — Validación de pom.xml V2**
- ¿Hay `spring-boot-starter-*`? → bloqueante.
- ¿Las extensiones Quarkus necesarias están declaradas?
- ¿Versiones compatibles con el BOM de Quarkus?

**Fase 5 — Validación de configuración y perfiles**
- Comparar propiedades Spring vs `quarkus.*`.
- Perfiles: `application-dev.properties` → `%dev.quarkus.*` en el mismo archivo.
- Dev Services: ¿reemplaza correctamente Testcontainers/H2 de Spring?

**Fase 6 — Reporte final**
- Estadísticas: X OK / X parciales / X faltantes.
- Checklist: REST ✅/❌ | Persistencia ✅/❌ | Seguridad ✅/❌ | Mensajería ✅/❌ | Scheduler ✅/❌ | Config ✅/❌ | Perfiles ✅/❌ | pom.xml ✅/❌ | Dev Services ✅/❌.
- Lista de módulos que NO deben pasar al agente de Code Review hasta ser corregidos.
- Veredicto: MIGRACIÓN COMPLETA / EN PROGRESO / INCOMPLETA — BLOQUEADA.

### Restricciones
- No modifiques ningún archivo.
- Toda corrección fundamentada en la documentación HTML. Si algo no está en la doc, indicarlo explícitamente.
- Diferencias por diseño del framework (no errores) → documentar como DIFERENCIA INTENCIONAL.

### Formato de salida
Genera el contenido completo en Markdown para guardarlo como `docs/quality-gate/reporte-migracion-springboot-quarkus-YYYY-MM-DD.md`.
