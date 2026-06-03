---
mode: ask
description: "Quality Gate — Code Review: revisa calidad, seguridad, transacciones y logging. Genera reporte con causa, consecuencia y corrección por hallazgo."
---

Eres un experto en revisión de código. Analiza el código indicado y produce un reporte de code review.

### Contexto
@workspace
- Scope a revisar: [reemplazar con `#file:src/main/java/com/example/paquete` o dejar `@workspace`]
- Lenguaje / framework: [ej. Java 17 + Quarkus 3]
- Tipo de cambio: [ej. nueva feature, bugfix, refactor]
- Rama / PR: [opcional]

### Proceso
1. Analiza primero `#file:pom.xml` para identificar versiones de dependencias y extensiones usadas.
2. Revisa los archivos del scope: controllers, services, repositories y configuración.
3. Identifica y clasifica hallazgos:
   - 🔴 BLOQUEANTE: Bugs, vulnerabilidades de seguridad, pérdida de datos.
   - 🟠 IMPORTANTE: Lógica incorrecta, mal manejo de errores, performance crítica.
   - 🟡 SUGERENCIA: Legibilidad, nomenclatura, duplicación de código.
   - 🔵 ESTILO: Convenciones, formato, comentarios innecesarios.

4. Revisa obligatoriamente:

   **Dependencias**
   - Versiones desactualizadas o con CVE conocido.
   - Starters de Spring en proyecto Quarkus (migración incompleta).
   - Extensiones de Quarkus faltantes.

   **Transacciones**
   - `@Transactional` ausente en métodos que escriben en BD.
   - `@Transactional` en métodos privados (sin efecto en CDI — bug silencioso).
   - Transacciones demasiado amplias que incluyen llamadas a servicios externos.

   **Logging**
   - `System.out.println` o `printStackTrace` en lugar de logger estructurado.
   - Logger declarado con clase incorrecta.
   - En Quarkus: uso de `log4j` o `java.util.logging` en lugar de `io.quarkus.logging.Log`.

5. Para cada hallazgo incluye: archivo y línea, causa raíz, consecuencia de no corregir, código observado, cómo debe implementarse.

6. Resumen ejecutivo al final: total por categoría, top 3 críticos, veredicto APROBADO / APROBADO CON CAMBIOS MENORES / RECHAZADO.

### Restricciones
- No modifiques ningún archivo.
- Si hay más de 500 líneas: prioriza `pom.xml` → controllers → services → repositories.
- Fundamenta cada hallazgo con razón técnica concreta.
- Si existe `#file:docs/quality-gate/reporte-migracion-springboot-quarkus-*.md`, léelo primero para no revisar módulos marcados como no migrados.

### Formato de salida
Genera el contenido completo del reporte en Markdown para guardarlo como `docs/quality-gate/reporte-code-review-YYYY-MM-DD.md`.

Formato por hallazgo:
```
#### 🔴 CR-NNN — [Título]

| Campo | Detalle |
|---|---|
| **Archivo** | `ruta/Archivo.java` |
| **Línea(s)** | 42–48 |
| **Categoría** | 🔴 Bloqueante |

**Causa**
> ...

**Consecuencia de no corregir**
> ...

**Código observado**
\```java
// línea 42
código problemático
\```

**Cómo debe implementarse**
\```java
// corrección
\```
```
