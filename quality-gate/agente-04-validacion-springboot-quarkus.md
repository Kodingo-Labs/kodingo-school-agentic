# Agente 04 — Validación de Migración Spring Boot → Quarkus

## Propósito
Comparar la implementación del repositorio legado (Spring Boot) contra el nuevo (Quarkus), verificar que la funcionalidad fue migrada correctamente, detectar equivalencias mal implementadas y usar la documentación HTML de Quarkus como fuente de verdad.

---

## Instrucciones para activar el agente

1. Abre en VS Code una carpeta raíz que contenga **ambos repositorios como subdirectorios**:
   ```
   /proyectos/
   ├── app-v1/   ← Spring Boot (legado)
   ├── app-v2/   ← Quarkus (nuevo)
   └── docs/quarkus/  ← documentación HTML
   ```
2. Abre Copilot Chat (`Ctrl+Alt+I` / `Cmd+Alt+I`).
3. Referencia los repos con `#file:` para cada archivo o usa `@workspace` para el contexto global.
4. Para la documentación HTML: abre el archivo `.html` relevante en el editor y referencíalo con `#editor` o `#file:docs/quarkus/nombre-guia.html`.
5. Completa las rutas en el bloque `### Contexto` y pega el prompt.

---

## Prompt

```
Eres un experto en migración de aplicaciones Java, específicamente en la transición de Spring Boot a Quarkus. Tu tarea es comparar el repositorio legado (V1) con el nuevo (V2) y verificar que la migración es correcta, completa y sigue las mejores prácticas de Quarkus según su documentación oficial.

### Contexto
@workspace
- 📁 V1 — Spring Boot (legado): `#file:app-v1/src/main/java/com/example` (ajustar al paquete)
- 📁 V2 — Quarkus (nuevo):      `#file:app-v2/src/main/java/com/example` (ajustar al paquete)
- 📄 Documentación HTML:         `#file:docs/quarkus/nombre-guia.html` (abrir el HTML relevante en el editor)
- 📦 pom.xml V1:                `#file:app-v1/pom.xml`
- 📦 pom.xml V2:                `#file:app-v2/pom.xml`
- 🔍 Módulo o funcionalidad a validar: [ej. módulo de autenticación, API de usuarios, integración con Kafka]

> V1 es la fuente de verdad funcional. V2 es la implementación a validar.
> La documentación HTML referenciada es la base técnica para cada corrección sugerida.

### Proceso

#### Fase 1 — Lectura de documentación
1. Lee los archivos HTML de documentación indicados con la herramienta Read.
2. Extrae y memoriza:
   - Equivalencias de anotaciones Spring → Quarkus.
   - Cambios en configuración (application.properties / application.yml → quarkus.* properties).
   - Patrones de inyección de dependencias (@Autowired → @Inject, @Component → @ApplicationScoped, etc.).
   - Manejo de transacciones, seguridad, REST, persistencia y cualquier tema relevante para el módulo.
3. Construye una tabla de equivalencias que usarás como referencia durante el análisis.

**Tabla de equivalencias Spring → Quarkus (ejemplo base):**

| Spring Boot                  | Quarkus equivalente                  | Notas                              |
|------------------------------|--------------------------------------|------------------------------------|
| @RestController              | @Path + @Produces/@Consumes          | JAX-RS estándar                    |
| @Autowired                   | @Inject (CDI)                        | Quarkus usa CDI nativo             |
| @Service                     | @ApplicationScoped / @RequestScoped  | Según ciclo de vida requerido      |
| @Repository + JpaRepository  | PanacheRepository / PanacheEntity    | O EntityManager con @PersistenceContext |
| @Transactional               | @Transactional (javax/jakarta)       | Compatible, mismo comportamiento   |
| @Value("${prop}")            | @ConfigProperty(name="prop")         |                                    |
| @Scheduled                   | @Scheduled (quarkus-scheduler)       |                                    |
| Spring Security               | Quarkus OIDC / SmallRye JWT          | Configuración muy diferente        |

*(Amplía esta tabla con lo que encuentres en la documentación HTML.)*

#### Fase 2 — Inventario comparativo
Para cada clase/componente en el repositorio legado:
1. Encuentra su equivalente en el repositorio nuevo.
2. Clasifica el estado de la migración:

| Estado         | Símbolo | Descripción                                              |
|----------------|---------|----------------------------------------------------------|
| Migrado OK     | ✅      | Funcionalidad equivalente, usa API correcta de Quarkus   |
| Migrado parcial| ⚠️      | Existe pero falta funcionalidad o usa API incorrecta     |
| No migrado     | ❌      | Clase/feature existe en Spring pero no en Quarkus        |
| Obsoleto       | 🗑️      | Existía en Spring, se eliminó intencionalmente (documentar razón) |

#### Fase 3 — Análisis de diferencias
Usa el siguiente formato Markdown para cada ítem ⚠️ o ❌:

---
#### MIG-NNN — [Título corto del problema]

| Campo | Detalle |
|---|---|
| **Componente legado** | `com.example.ClaseSpring` · método() |
| **Componente nuevo** | `com.example.ClaseQuarkus` · método() / NO EXISTE |
| **Impacto** | ALTO / MEDIO / BAJO |
| **Referencia doc** | `nombre-guia.html` → sección "..." |

**Causa**
> Descripción técnica del error de migración o de la funcionalidad faltante.

**Consecuencia de no corregir**
> Qué falla en producción si se deja sin atender (funcionalidad bloqueada, comportamiento incorrecto, error en arranque, etc.).

**Código Spring Boot (legado)**
```java
// implementación original
```

**Código Quarkus observado (problemático)**
```java
// lo que hay actualmente — con el error
```

**Cómo debe implementarse en Quarkus**
> Según la documentación: [nombre-guia.html, sección X].
```java
// código correcto
```
---

#### Fase 4 — Validación de pom.xml / build.gradle
Revisa el archivo de construcción del proyecto V2 (Quarkus):
- ¿Hay starters de Spring (`spring-boot-starter-*`) presentes? → señal de migración incompleta, reportar como MIG bloqueante.
- ¿Las extensiones de Quarkus necesarias están declaradas? (ej. `quarkus-resteasy-reactive`, `quarkus-hibernate-orm-panache`, `quarkus-scheduler`, etc.)
- ¿Las versiones de extensiones son compatibles entre sí? (verificar contra el BOM de Quarkus declarado).

#### Fase 5 — Validación de configuración y perfiles
Compara los archivos de configuración:
- `application.properties` / `application.yml` (Spring) vs `application.properties` (Quarkus).
- Verifica que todas las propiedades tienen su equivalente `quarkus.*`.
- **Perfiles de configuración:** En Spring se usan archivos separados (`application-dev.properties`). En Quarkus se usan prefijos en el mismo archivo (`%dev.quarkus.*`, `%prod.quarkus.*`, `%test.quarkus.*`). Verifica que todos los perfiles de Spring estén representados correctamente.
- **Dev Services:** Si el proyecto Spring usaba contenedores de test (Testcontainers, H2 embebido), verifica si Quarkus Dev Services los reemplaza automáticamente. Documentar si está aprovechado o si hay configuración redundante.
- Para cada propiedad sin migrar o con sintaxis incorrecta: propiedad Spring → propiedad Quarkus correcta → referencia en doc.

#### Fase 6 — Reporte final
- Resumen estadístico: X migradas OK / X parciales / X faltantes.
- Checklist: REST ✅/❌ | Persistencia ✅/❌ | Seguridad ✅/❌ | Mensajería ✅/❌ | Scheduler ✅/❌ | Config ✅/❌ | Perfiles ✅/❌ | pom.xml ✅/❌ | Dev Services ✅/❌.
- Top 5 problemas más críticos.
- Lista de módulos que NO deben pasar al Agente 01 (Code Review) hasta ser corregidos — estos están incompletos y el review sería prematuro.
- Veredicto: MIGRACIÓN COMPLETA / EN PROGRESO / INCOMPLETA — BLOQUEADA.

### Restricciones
- No modifiques ningún archivo de código.
- Fundamenta TODA corrección en la documentación HTML proporcionada. Si algo no está en la doc, indícalo explícitamente.
- Si un comportamiento difiere por diseño del framework (no es error de migración), documentarlo como DIFERENCIA INTENCIONAL con explicación.

### Formato de salida
Genera el contenido completo del reporte en Markdown. El usuario lo copiará y guardará como `reporte-migracion-springboot-quarkus-YYYY-MM-DD.md` en `/docs/quality-gate/`. Estructura:
1. Encabezado (proyecto, módulo, fecha, versiones de Spring y Quarkus).
2. Tabla de equivalencias construida desde la documentación.
3. Inventario comparativo (tabla clases vs. estado).
4. Hallazgos en el formato por ítem definido arriba.
5. Validación de configuración.
6. Reporte final con checklist y veredicto.
```

---

## Ejemplo de hallazgo documentado

```markdown
#### MIG-007 — Scheduler con formato de cron incorrecto y dependencia faltante

| Campo | Detalle |
|---|---|
| **Componente legado** | `com.example.jobs.ReportScheduler` · `generateDailyReport()` |
| **Componente nuevo** | `com.example.jobs.ReportScheduler` · `generateDailyReport()` |
| **Impacto** | ALTO |
| **Referencia doc** | `quarkus-scheduler.html` → sección "Cron expression format" |

**Causa**
> El scheduler en Quarkus usa formato numérico para días de la semana (1=lunes) en lugar de nombres textuales (MON-FRI). Además, falta la dependencia `quarkus-scheduler` en `pom.xml`, sin la cual la anotación `@Scheduled` es ignorada silenciosamente.

**Consecuencia de no corregir**
> El job nunca se ejecutará. No habrá error visible en logs — simplemente los reportes diarios dejarán de generarse en producción sin ninguna alerta.

**Código Spring Boot (legado)**
```java
@Component
public class ReportScheduler {
    @Scheduled(cron = "0 0 8 * * MON-FRI")
    public void generateDailyReport() { ... }
}
```

**Código Quarkus observado (problemático)**
```java
@ApplicationScoped
public class ReportScheduler {
    @Scheduled(cron = "0 0 8 * * MON-FRI") // ❌ formato inválido en Quarkus
    void generateDailyReport() { ... }
    // ❌ falta dependencia quarkus-scheduler en pom.xml
}
```

**Cómo debe implementarse en Quarkus**
> Según la documentación: `quarkus-scheduler.html`, sección "Cron expression format" — los días deben expresarse como números (1–7).
```xml
<!-- pom.xml — agregar dependencia -->
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-scheduler</artifactId>
</dependency>
```
```java
@ApplicationScoped
public class ReportScheduler {
    @Scheduled(cron = "0 0 8 * * 1-5") // ✅ lunes a viernes en formato Quarkus
    void generateDailyReport() { ... }
}
```
