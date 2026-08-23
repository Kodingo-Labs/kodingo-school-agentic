# Quality Gate — Agentes de Revisión de Código

Prompts para GitHub Copilot Chat que implementan un proceso de Quality Gate antes de merge a producción o certificación. Cada agente analiza el código y genera un reporte `.md` estructurado.

**Inventario de todos los archivos del repo:** [`../docs/ARCHIVOS.md`](../docs/ARCHIVOS.md)

> **Kodingo School (Node / Python / React):** usa el agente dedicado en [`../code-review/`](../code-review/) y la skill Cursor en [`.cursor/skills/kodingo-code-review/`](../.cursor/skills/kodingo-code-review/). Esta carpeta `quality-gate/` está orientada a **Java / Quarkus / Spring**.

---

## Estructura de archivos

```
quality-gate/
├── README.md                                    ← este archivo
├── agente-00-orquestador.md                     ← referencia completa con ejemplos
├── agente-01-code-review.md                     ← referencia completa con ejemplos
├── agente-02-refactorizacion-deuda-tecnica.md   ← referencia completa con ejemplos
├── agente-03-validacion-pruebas-unitarias.md    ← referencia completa con ejemplos
├── agente-04-validacion-springboot-quarkus.md   ← referencia completa con ejemplos
└── github-prompts/                              ← archivos listos para .github/prompts/
    ├── agente-00-orquestador.prompt.md
    ├── agente-01-code-review.prompt.md
    ├── agente-02-deuda-tecnica.prompt.md
    ├── agente-03-pruebas-unitarias.prompt.md
    └── agente-04-migracion-quarkus.prompt.md
```

---

## Forma recomendada de uso — `.github/prompts/`

En lugar de copiar y pegar el prompt manualmente cada vez, puedes instalar los agentes directamente en el repositorio usando la carpeta `.github/prompts/`. Esto hace que los prompts aparezcan **como comandos disponibles en Copilot Chat** sin ninguna fricción.

### Cómo instalar (una sola vez por repo)

1. Copia la carpeta `github-prompts/` de este repositorio al repo que vas a analizar.
2. Renómbrala a `.github/prompts/`:
   ```
   app-v2/
   └── .github/
       └── prompts/
           ├── agente-00-orquestador.prompt.md
           ├── agente-01-code-review.prompt.md
           ├── agente-02-deuda-tecnica.prompt.md
           ├── agente-03-pruebas-unitarias.prompt.md
           └── agente-04-migracion-quarkus.prompt.md
   ```
3. Abre el repo en VS Code. Los prompts quedan disponibles de inmediato en Copilot Chat.

### Cómo invocar un agente desde Copilot Chat

1. Abre Copilot Chat (`Ctrl+Alt+I` / `Cmd+Alt+I`).
2. Escribe `/` — aparece un listado con todos los prompts disponibles.
3. Selecciona el agente (ej. `agente-01-code-review`).
4. Antes de enviar, edita los valores entre corchetes `[...]` en el bloque `### Contexto`.
5. Envía. Copilot ejecuta el análisis y genera el reporte.
6. Copia la respuesta y guárdala en `docs/quality-gate/`.

> **No necesitas copiar el contenido del prompt** — Copilot lo carga automáticamente desde `.github/prompts/`.

### ¿Necesito copiar los prompts a cada repo que analice?

Solo una vez por repo. Una vez instalados en `.github/prompts/`, quedan disponibles para todo el equipo que clone ese repositorio. Si mantienes los agentes actualizados en este repositorio central (`quality-gate/`), solo necesitas volver a copiar la carpeta `github-prompts/` cuando haya cambios.

**Recomendación para múltiples repos:**
- Instala los prompts en el **repo V2 (Quarkus)** — es el que revisarás con más frecuencia.
- Para analizar V1 con el Agente 04, ábrelo como subcarpeta dentro del mismo workspace de V2 y referencíalo con `#file:app-v1/...`.
- No es necesario instalar los prompts en V1 ya que ese repo es de solo lectura (legado).

---

## Prerrequisitos

- **VS Code** con la extensión **GitHub Copilot** y **GitHub Copilot Chat** instaladas y activas.
- Acceso al repositorio(s) de código abierto como workspace en VS Code.
- Para el Agente 04: tener los dos repositorios (V1 y V2) y la documentación HTML de Quarkus accesibles localmente.

---

## Cómo referenciar el código en Copilot Chat

Copilot Chat no accede automáticamente a tus archivos — debes indicarle qué leer usando estas referencias dentro del prompt:

| Referencia | Qué hace | Ejemplo |
|------------|----------|---------|
| `@workspace` | Da contexto de todo el workspace abierto en VS Code | `@workspace analiza las clases de servicio` |
| `#file:ruta` | Referencia un archivo específico | `#file:src/main/java/com/example/UserService.java` |
| `#editor` | Referencia el archivo actualmente abierto en el editor | `#editor revisa este archivo` |
| `#selection` | Referencia el texto seleccionado en el editor | Selecciona código → `#selection explica este método` |

> **Regla práctica:** Usa `@workspace` cuando quieras que Copilot explore el proyecto completo. Usa `#file:` cuando el análisis debe limitarse a archivos o carpetas específicas.

---

## Cómo preparar el workspace

### Para Agentes 01, 02 y 03 (un solo repositorio)
```
Abrir en VS Code:
└── app-v2/              ← repositorio Quarkus (nuevo)
    ├── pom.xml
    ├── src/
    │   ├── main/java/com/example/
    │   └── test/java/com/example/
    └── target/site/jacoco/   ← reporte de cobertura (si existe)
```

### Para Agente 04 (dos repositorios + documentación)
```
Abrir en VS Code una carpeta raíz que contenga:
└── proyectos/
    ├── app-v1/              ← Spring Boot (legado)
    │   ├── pom.xml
    │   └── src/main/java/com/example/
    ├── app-v2/              ← Quarkus (nuevo)
    │   ├── pom.xml
    │   └── src/main/java/com/example/
    └── docs/quarkus/        ← archivos HTML de documentación
        ├── quarkus-rest.html
        ├── quarkus-hibernate-orm-panache.html
        └── ...
```

> Abre la carpeta **raíz** (`proyectos/`) en VS Code, no una subcarpeta. De esta manera `@workspace` y `#file:` tienen acceso a ambos repositorios y a la documentación.

---

## Cómo gatillar cada agente

### Agente 00 — Orquestador (empezar siempre aquí)
El orquestador decide el orden de ejecución y consolida los reportes al final.

1. Abre `agente-00-orquestador.md`.
2. Copia el **Prompt de diagnóstico inicial** (Paso 0) y pégalo en Copilot Chat.
3. Según la respuesta, sigue el orden de agentes indicado.
4. Al terminar todos los agentes, copia el **Prompt de consolidación** (Paso 3) para generar el dashboard.

### Agente 01 — Code Review
```
1. Abre Copilot Chat  (Ctrl+Alt+I  /  Cmd+Alt+I)
2. Abre agente-01-code-review.md
3. Copia el bloque entre las marcas ``` del prompt
4. Reemplaza los valores entre corchetes []:
   - Scope: escribe  @workspace  o  #file:ruta/al/paquete
   - Lenguaje / framework: ej. Java 17 + Quarkus 3
   - Tipo de cambio: ej. nueva feature
5. Pega en Copilot Chat y envía
6. Copia la respuesta y guárdala como:
   docs/quality-gate/reporte-code-review-YYYY-MM-DD.md
```

**Ejemplo de prompt listo para pegar:**
```
Eres un experto en revisión de código...

### Contexto
@workspace
- Scope a revisar: #file:src/main/java/com/example/service
- Lenguaje / framework: Java 17 + Quarkus 3.8
- Tipo de cambio: nueva feature — módulo de pagos
- Rama / PR: feature/payments-module
```

---

### Agente 02 — Deuda Técnica
```
1. Abre Copilot Chat
2. Abre agente-02-refactorizacion-deuda-tecnica.md
3. Copia el bloque del prompt y reemplaza:
   - Módulo a auditar: @workspace o #file:ruta
   - Objetivo de negocio: ej. migración en curso
4. Pega en Copilot Chat y envía
5. Guarda la respuesta como:
   docs/quality-gate/reporte-deuda-tecnica-YYYY-MM-DD.md
```

---

### Agente 03 — Pruebas Unitarias
```
1. (Opcional) Genera el reporte JaCoCo: mvn test jacoco:report
   El reporte queda en target/site/jacoco/index.html
2. Abre Copilot Chat
3. Abre agente-03-validacion-pruebas-unitarias.md
4. Copia el bloque del prompt y reemplaza:
   - Código fuente: #file:src/main/java/com/example
   - Tests: #file:src/test/java/com/example
   - JaCoCo: #file:target/site/jacoco/index.html  (o NO si no existe)
   - Cobertura mínima objetivo: ej. 80%
5. Pega en Copilot Chat y envía
6. Guarda la respuesta como:
   docs/quality-gate/reporte-pruebas-unitarias-YYYY-MM-DD.md
```

---

### Agente 04 — Migración Spring Boot → Quarkus
```
1. Abre VS Code con la carpeta raíz que contiene app-v1/, app-v2/ y docs/quarkus/
2. Abre en el editor el HTML de documentación relevante para el módulo
   (ej. docs/quarkus/quarkus-rest.html)
3. Abre Copilot Chat
4. Abre agente-04-validacion-springboot-quarkus.md
5. Copia el bloque del prompt y reemplaza:
   - V1: #file:app-v1/src/main/java/com/example/[módulo]
   - V2: #file:app-v2/src/main/java/com/example/[módulo]
   - Doc HTML: #file:docs/quarkus/nombre-guia.html
   - pom.xml V1: #file:app-v1/pom.xml
   - pom.xml V2: #file:app-v2/pom.xml
   - Módulo a validar: ej. API de usuarios
6. Pega en Copilot Chat y envía
7. Guarda la respuesta como:
   docs/quality-gate/reporte-migracion-springboot-quarkus-YYYY-MM-DD.md
```

---

## Dónde guardar los reportes generados

Todos los reportes deben guardarse en la carpeta `docs/quality-gate/` del repositorio V2:

```
app-v2/
└── docs/
    └── quality-gate/
        ├── dashboard-quality-gate-2026-06-03.md        ← generado por Agente 00
        ├── reporte-migracion-springboot-quarkus-2026-06-03.md
        ├── reporte-code-review-2026-06-03.md
        ├── reporte-deuda-tecnica-2026-06-03.md
        └── reporte-pruebas-unitarias-2026-06-03.md
```

> Commitear los reportes junto al PR permite tener trazabilidad histórica de cada revisión.

---

## Orden recomendado de ejecución

```
┌──────────────────────────────────────────────────────┐
│              QUALITY GATE — Bloque 1                 │
│                                                      │
│  INICIO: Agente 00 → Diagnóstico inicial             │
│              │                                       │
│              ▼                                       │
│  ¿Hay Spring en V2?                                  │
│    SÍ → Agente 04 (Migración)                        │
│           │                                          │
│           ├─ BLOQUEADA → 🛑 STOP. No continuar.      │
│           └─ OK / EN PROGRESO → continuar            │
│              │                                       │
│              ▼                                       │
│         Agente 01 (Code Review)                      │
│              │                                       │
│              ▼                                       │
│         Agente 02 (Deuda Técnica)                    │
│              │                                       │
│              ▼                                       │
│         Agente 03 (Pruebas Unitarias)                │
│              │                                       │
│              ▼                                       │
│  FIN: Agente 00 → Dashboard consolidado              │
│        ✅ APROBADO / 🟡 CON CAMBIOS / 🔴 RECHAZADO  │
└──────────────────────────────────────────────────────┘
```

---

## Limitaciones conocidas de Copilot Chat

| Limitación | Impacto | Solución |
|------------|---------|----------|
| No guarda archivos automáticamente | Los reportes deben copiarse y guardarse manualmente | Copiar respuesta → crear archivo `.md` → guardar en `docs/quality-gate/` |
| Contexto limitado en repos grandes | Puede no leer todos los archivos de `@workspace` | Usar `#file:` con rutas específicas a los paquetes relevantes |
| No encadena agentes automáticamente | Cada agente se ejecuta manualmente | Seguir el orden del Agente 00 como checklist |
| No lee archivos binarios | No puede analizar JARs ni reportes XML binarios | Generar reporte JaCoCo en HTML (`mvn jacoco:report`) antes de ejecutar el Agente 03 |
