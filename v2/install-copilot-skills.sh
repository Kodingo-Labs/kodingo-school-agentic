#!/usr/bin/env bash
# =============================================================================
# install-copilot-skills.sh
# Instala las instrucciones y skills de GitHub Copilot para la migración
# Spring Boot -> Quarkus + despliegue en Azure en el repositorio de destino.
#
# Uso:
#   ./install-copilot-skills.sh -d <ruta-repo> [-a aks|containerapps|appservice|por-definir] [-f] [-n]
#
# Opciones:
#   -d  Ruta del repositorio de destino (si se omite, se pregunta)
#   -a  Destino de Azure (por defecto: por-definir)
#   -f  Forzar: sobrescribe archivos existentes (guarda un respaldo .bak-<fecha>)
#   -n  Simulación: muestra lo que haría sin escribir nada
#   -h  Ayuda
# =============================================================================
set -euo pipefail

DEST=""
AZURE="por-definir"
FORCE=0
DRY_RUN=0
STAMP="$(date +%Y%m%d-%H%M%S)"
CREATED=0; OVERWRITTEN=0; SKIPPED=0

usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while getopts ":d:a:fnh" opt; do
  case "$opt" in
    d) DEST="$OPTARG" ;;
    a) AZURE="$OPTARG" ;;
    f) FORCE=1 ;;
    n) DRY_RUN=1 ;;
    h) usage 0 ;;
    :) echo "Error: la opción -$OPTARG requiere un valor." >&2; usage 1 ;;
    \?) echo "Error: opción inválida -$OPTARG" >&2; usage 1 ;;
  esac
done

if [ -z "$DEST" ]; then
  read -r -p "Ruta del repositorio de destino: " DEST
fi
DEST="${DEST/#\~/$HOME}"
if [ -z "$DEST" ] || [ ! -d "$DEST" ]; then
  echo "Error: el directorio de destino no existe: '$DEST'" >&2
  exit 1
fi
DEST="$(cd "$DEST" && pwd)"

case "$AZURE" in
  aks)           AZURE_LABEL="Azure Kubernetes Service (AKS)" ;;
  containerapps) AZURE_LABEL="Azure Container Apps" ;;
  appservice)    AZURE_LABEL="Azure App Service for Containers" ;;
  por-definir)   AZURE_LABEL="por-definir" ;;
  *) echo "Error: destino Azure inválido '$AZURE' (usa aks, containerapps, appservice o por-definir)." >&2; exit 1 ;;
esac

if ! git -C "$DEST" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Aviso: '$DEST' no parece ser un repositorio git. Continúo de todos modos."
fi
if [ ! -f "$DEST/pom.xml" ] && [ ! -f "$DEST/build.gradle" ] && [ ! -f "$DEST/build.gradle.kts" ]; then
  echo "Aviso: no encontré pom.xml ni build.gradle en '$DEST'. ¿Es la raíz del microservicio?"
fi

echo "Destino:        $DEST"
echo "Destino Azure:  $AZURE_LABEL"
[ "$DRY_RUN" -eq 1 ] && echo "Modo:           simulación (no se escribe nada)"
echo

# Lee el contenido desde stdin y lo escribe en DEST/<ruta relativa>
write_file() {
  local rel="$1" target content
  target="$DEST/$rel"
  content="$(cat)"
  content="${content//'{{AZURE_TARGET}}'/$AZURE_LABEL}"

  if [ -e "$target" ]; then
    if [ "$FORCE" -eq 1 ]; then
      if [ "$DRY_RUN" -eq 0 ]; then
        cp "$target" "$target.bak-$STAMP"
        printf '%s\n' "$content" > "$target"
      fi
      echo "  ~ sobrescrito (respaldo .bak-$STAMP): $rel"
      OVERWRITTEN=$((OVERWRITTEN + 1))
    else
      echo "  = omitido (ya existe, usa -f para sobrescribir): $rel"
      SKIPPED=$((SKIPPED + 1))
    fi
  else
    if [ "$DRY_RUN" -eq 0 ]; then
      mkdir -p "$(dirname "$target")"
      printf '%s\n' "$content" > "$target"
    fi
    echo "  + creado: $rel"
    CREATED=$((CREATED + 1))
  fi
}

write_file '.github/copilot-instructions.md' <<'__EOF_COPILOT_KIT__'
# Instrucciones del repositorio para GitHub Copilot

## Contexto

Este repositorio contiene un microservicio Java construido con **Spring Boot** que será **migrado a Quarkus** y **desplegado en Azure** (destino: `{{AZURE_TARGET}}`).
La migración de código la ejecuta un agente migrador; las skills de `.github/skills/` preparan el análisis, la red de seguridad de tests, el plan y la verificación.

## Fases del trabajo

| Fase | Objetivo | Skills | ¿Se modifica `src/main`? |
|---|---|---|---|
| 1. Análisis | Entender arquitectura, API, lógica y deuda | `service-discovery`, `tech-debt-review`, `functional-docs` | **No** |
| 2. Red de seguridad | Congelar el comportamiento actual con tests portables | `characterization-tests` | **No** (solo `src/test`) |
| 3. Plan de migración | Inventario Spring → Quarkus y riesgos | `quarkus-migration-assessment` | **No** |
| 4. Migración | Ejecutada por el agente migrador | — | Sí |
| 5. Verificación | Demostrar equivalencia funcional | `migration-parity-check` | No |
| 6. Despliegue | Preparar y desplegar en Azure | `azure-deploy-readiness` | Solo artefactos de despliegue |

## Reglas generales (aplican siempre)

- **Evidencia obligatoria**: todo hallazgo o afirmación sobre el código debe citar `ruta/Archivo.java:línea`.
- **No inventar**: si algo no se puede verificar en el código, márcalo como `[SUPUESTO]` y agrégalo a "Preguntas abiertas".
- **Posibles bugs**: si el comportamiento actual parece incorrecto, documéntalo como `[BUG?]`; no lo corrijas durante las fases 1-3.
- **Secretos**: nunca copies valores de contraseñas, tokens o cadenas de conexión en la documentación; referencia solo el nombre de la propiedad.
- **Entregables**: todos los documentos se guardan en `docs/migracion/` con el prefijo numérico indicado en cada skill.
- **Idioma**: documentación en español; identificadores de código, nombres de tests y commits en inglés.
- **Diagramas**: usar Mermaid (`flowchart`, `sequenceDiagram`, `classDiagram`, `erDiagram`).
- Antes de ejecutar una skill, lee los entregables previos de `docs/migracion/` de los que depende.

## Estándares de código

- Clean Code: nombres expresivos, funciones pequeñas con una sola responsabilidad, sin números mágicos, sin código muerto ni comentarios que repiten el código.
- SOLID, con especial atención a SRP y DIP (el dominio no depende de frameworks).
- Inyección por **constructor**; evitar la inyección por campo.
- El dominio y los servicios no deben usar tipos web (`ResponseEntity`, `HttpServletRequest`) ni tipos del framework cuando no sea necesario.
- Aplicar un patrón solo si resuelve un problema concreto; explicar siempre cuál.

## Estándares de tests

- JUnit 5 + AssertJ + Mockito.
- Nombre: `metodo_escenario_resultadoEsperado` (por ejemplo, `calculateFee_whenAmountIsZero_returnsZero`).
- Estructura `// given` / `// when` / `// then`.
- Los tests unitarios **no levantan contexto de framework**: prohibidos `@SpringBootTest`, `@WebMvcTest`, `@DataJpaTest`, `@MockBean` y `SpringExtension` en tests nuevos.
- Los tests de contrato son de caja negra (RestAssured) con la URL base configurable, para ejecutarse contra la versión Spring y la versión Quarkus.
__EOF_COPILOT_KIT__

write_file '.github/skills/azure-deploy-readiness/SKILL.md' <<'__EOF_COPILOT_KIT__'
---
name: azure-deploy-readiness
description: Prepara y verifica el despliegue del microservicio Quarkus en Azure (imagen de contenedor, health probes, configuración y secretos, identidad administrada, observabilidad, recursos, escalado, CI/CD y rollback). Úsala cuando se pida desplegar en Azure, preparar la infraestructura, el Dockerfile o el pipeline, o revisar si el servicio está listo para producción.
---

# Azure deploy readiness

## Objetivo

Dejar el servicio listo para producción en Azure con un checklist verificable y los artefactos de despliegue necesarios.

**Destino Azure configurado: `{{AZURE_TARGET}}`**

Si el destino es `por-definir`, empieza con la sección "Selección de destino" y pide confirmación antes de generar artefactos.

## Entradas

- `docs/migracion/01-arquitectura.md` (integraciones y configuración), `05-migracion-quarkus.md` y `07-paridad.md`.

## Restricciones

- No escribir secretos en el repositorio ni en los artefactos.
- Preferir autenticación sin contraseña (Managed Identity / Workload Identity).
- Los artefactos que se generen (Dockerfile, manifiestos, IaC, pipeline) se proponen primero y se aplican con confirmación.

## Selección de destino (si no está definido)

Compara para este servicio: **Azure Container Apps** (serverless, revisiones y escalado KEDA, menor operación), **AKS** (máximo control, requiere equipo de plataforma) y **App Service for Containers** (simple, menos flexible). Criterios: operación, costo, escalado, networking privado, estándares de la organización.

## Checklist

1. **Imagen de contenedor**
   - Dockerfile basado en los generados por Quarkus (`src/main/docker/Dockerfile.jvm` o `.native`), usuario no root, imagen base soportada.
   - Decisión **JVM vs nativo** justificada (tiempo de build, compatibilidad de librerías, arranque, memoria).
   - Publicación en Azure Container Registry con tags inmutables (commit SHA).
2. **Health probes**: liveness → `/q/health/live`, readiness → `/q/health/ready`, startup probe si el arranque es lento; health checks de BD y dependencias críticas en readiness.
3. **Configuración y secretos**
   - Configuración por variables de entorno (convención de Quarkus: `QUARKUS_DATASOURCE_USERNAME`...).
   - Secretos en **Azure Key Vault** (referencias de Key Vault, CSI Secrets Store en AKS o extensión de Quarkiverse `[VERIFICAR]`).
   - Configuración compartida en Azure App Configuration, si aplica.
4. **Identidad**: Managed Identity (Workload Identity en AKS) para BD, Key Vault, Storage y Service Bus. Roles con mínimo privilegio.
5. **Datos**: Azure SQL / PostgreSQL Flexible Server, conexión passwordless si es posible, pool de conexiones dimensionado, migraciones (Flyway/Liquibase) ejecutadas de forma controlada.
6. **Observabilidad**: OpenTelemetry → Azure Monitor / Application Insights (validar compatibilidad del agente Java de App Insights con Quarkus `[VERIFICAR]`), logs en JSON con traceId, métricas, dashboards y alertas (errores 5xx, latencia p95, reinicios).
7. **Recursos y JVM**: requests/limits de CPU y memoria, `-XX:MaxRAMPercentage`, pruebas de carga básicas.
8. **Escalado**: reglas (HTTP concurrency, CPU, KEDA por cola), mínimo de réplicas para alta disponibilidad.
9. **Red y seguridad**: ingress/HTTPS, private endpoints, CORS, escaneo de vulnerabilidades de la imagen y dependencias.
10. **CI/CD** (GitHub Actions o Azure DevOps): build → tests unitarios → tests de contrato → análisis estático → build de imagen → escaneo → push a ACR → deploy por ambiente (dev → qa → prod) con aprobaciones.
11. **Estrategia de liberación y rollback**: blue/green, canary o revisiones con división de tráfico; criterios de rollback definidos y probados.
12. **Convivencia y corte**: plan para ejecutar la versión Spring y la Quarkus en paralelo, redirección de tráfico y retiro del servicio anterior.

## Entregables

- `docs/migracion/08-despliegue-azure.md`: destino elegido y justificación, checklist con estado (✅ / ⚠️ / ❌), artefactos propuestos, variables y secretos requeridos (solo nombres), plan de liberación y rollback, runbook básico de operación.
- Artefactos propuestos (con confirmación): Dockerfile, manifiestos o IaC (Bicep/Terraform), pipeline.

## Checklist de salida

- [ ] Ningún secreto en el repositorio.
- [ ] Probes configuradas y probadas.
- [ ] Rollback definido y probado en un ambiente no productivo.
__EOF_COPILOT_KIT__

write_file '.github/skills/characterization-tests/SKILL.md' <<'__EOF_COPILOT_KIT__'
---
name: characterization-tests
description: Incrementa los tests unitarios y crea tests de caracterización/contrato que congelan el comportamiento actual del servicio antes de migrarlo a Quarkus, usando tests portables sin contexto de Spring. Úsala cuando se pida aumentar cobertura, escribir unit tests o crear una red de seguridad para la migración.
---

# Characterization tests

## Objetivo

Crear una red de seguridad que **sobreviva a la migración**: los mismos tests deben pasar en la versión Spring y en la versión Quarkus. No se trata de subir cobertura por subirla, sino de fijar el comportamiento observable actual.

## Entradas

- `docs/migracion/01-arquitectura.md` y `docs/migracion/02-api-y-logica.md` (si no existen, ejecuta primero `service-discovery`).

## Principios

1. **Portabilidad**: un test que depende del contexto de Spring se pierde al migrar. No escribirlo.
2. **Caracterizar, no corregir**: el test afirma lo que el código hace hoy. Si parece un bug, el test lo refleja, se marca con `// [BUG?]` y se registra en el plan; no se corrige.
3. **Priorizar por riesgo**: primero la lógica de negocio y lo que más cambia en la migración.
4. **No modificar `src/main`**. Si una clase no es testeable sin cambiarla, se registra como deuda para `tech-debt-review`.

## Pasos

1. **Línea base**
   - Ejecuta la suite actual y registra resultados y cobertura (JaCoCo: línea y rama, por paquete).
   - Si JaCoCo no está configurado, **propón** el cambio al `pom.xml`/`build.gradle` y pide confirmación antes de aplicarlo.
   - Clasifica los tests existentes: portables / dependientes de Spring (se perderán al migrar).
2. **Priorización**: arma una matriz de clases con criticidad de negocio, complejidad y cobertura actual. Orden sugerido:
   1. Servicios con reglas de negocio.
   2. Validadores y reglas de cálculo.
   3. Mappers (entidad ↔ DTO).
   4. Traducción de excepciones a respuestas de error.
   5. Utilidades con lógica.
3. **Tipo A: tests unitarios puros** (`src/test/java/.../unit` o junto a la clase)
   - `@ExtendWith(MockitoExtension.class)`, `@Mock` e instanciación por constructor.
   - Si la clase usa inyección por campo, usa `@InjectMocks` y regístralo como deuda.
   - Cubrir: camino feliz, límites, nulos/vacíos, cada rama de error y cada regla de negocio de `02-api-y-logica.md`.
   - Test data builders o fixtures reutilizables; nada de datos mágicos repetidos.
4. **Tipo B: tests de contrato de caja negra** (paquete `contract`, `@Tag("contract")`)
   - RestAssured contra el servicio en ejecución.
   - URL base configurable: `-Dcontract.baseUrl=http://localhost:8080` (por defecto localhost).
   - Por endpoint: status code, headers relevantes, estructura y valores del body, formato de fechas y nulos, y **cuerpo de error** en cada caso de fallo.
   - Dependencias externas simuladas con WireMock; base de datos con Testcontainers o datos semilla documentados.
   - Estos tests se ejecutarán contra la versión Quarkus en `migration-parity-check`.
5. **Medición final**: cobertura antes y después, y lista de brechas pendientes.

## Prohibido en tests nuevos

`@SpringBootTest`, `@WebMvcTest`, `@DataJpaTest`, `@MockBean`, `@SpyBean`, `SpringExtension`, `MockMvc`, `TestRestTemplate`, `ReflectionTestUtils` (salvo justificación escrita).

## Convenciones

- Nombre: `metodo_escenario_resultadoEsperado`.
- `// given` / `// when` / `// then`.
- Un comportamiento por test; aserciones con AssertJ.

## Entregables

- Tests en `src/test/java`.
- `docs/migracion/03-plan-tests.md`: línea base, matriz de priorización, tests creados por clase/endpoint, cobertura antes/después, tests existentes no portables, lista `[BUG?]`, clases no testeables (enlazadas a deuda) y cómo ejecutar cada suite.

## Checklist de salida

- [ ] Todos los tests nuevos pasan en la versión actual.
- [ ] Ningún test nuevo usa anotaciones prohibidas.
- [ ] Cada endpoint de `02-api-y-logica.md` tiene al menos un test de contrato de éxito y uno por cada error documentado.
- [ ] La suite de contrato corre cambiando solo `contract.baseUrl`.
__EOF_COPILOT_KIT__

write_file '.github/skills/functional-docs/SKILL.md' <<'__EOF_COPILOT_KIT__'
---
name: functional-docs
description: Genera documentación funcional del microservicio para negocio, Product Owner y QA (propósito, actores, casos de uso, reglas de negocio, datos, integraciones, errores visibles y glosario) sin jerga técnica. Úsala cuando se pida documentación funcional, de negocio o casos de uso del servicio.
---

# Functional docs

## Objetivo

Explicar **qué hace el servicio y por qué**, en lenguaje de negocio, para que personas no técnicas lo entiendan y QA pueda derivar casos de prueba.

## Entradas

- `docs/migracion/02-api-y-logica.md` (fuente principal) y `01-arquitectura.md`.
- Si no existen, ejecuta primero `service-discovery`.

## Restricciones

- **Sin nombres de clases, anotaciones ni código** en el cuerpo del documento. La trazabilidad técnica va solo en el anexo.
- No inventar reglas: toda regla debe derivar del código o de `02-api-y-logica.md`. Lo inferido se marca como `[SUPUESTO]` y va a "Preguntas para negocio".

## Estructura del documento

1. **Propósito del servicio**: qué problema de negocio resuelve (3-5 líneas).
2. **Actores y consumidores**: quién usa el servicio (sistemas, canales, usuarios) y para qué.
3. **Capacidades**: lista de lo que el servicio permite hacer.
4. **Casos de uso**: uno por capacidad, con este formato:
   - `CU-01 – Nombre`
   - Actor, disparador, precondiciones.
   - Flujo principal (pasos numerados).
   - Flujos alternativos y de excepción.
   - Reglas de negocio aplicadas (referencias `RN-xx`).
   - Resultado / postcondiciones.
   - Diagrama `flowchart` si el flujo tiene más de 3 decisiones.
5. **Catálogo de reglas de negocio**: `RN-01`, descripción, ejemplo concreto y casos de uso donde aplica.
6. **Información que maneja**: entidades de negocio y sus datos en lenguaje de negocio (no tablas).
7. **Integraciones**: con qué sistemas se comunica, qué intercambia y qué pasa si el otro sistema falla.
8. **Mensajes y errores visibles**: qué situaciones de error puede recibir un consumidor y qué significan.
9. **Glosario** de términos de negocio.
10. **Preguntas para negocio**: supuestos por confirmar.
11. **Anexo de trazabilidad**: caso de uso → endpoint(s) → regla(s).

## Entregables

- `docs/migracion/06-documentacion-funcional.md`.

## Checklist de salida

- [ ] Cada endpoint de `02-api-y-logica.md` está cubierto por al menos un caso de uso.
- [ ] Cada regla de negocio tiene un ejemplo concreto.
- [ ] Un lector sin conocimientos técnicos entiende el documento.
__EOF_COPILOT_KIT__

write_file '.github/skills/migration-parity-check/SKILL.md' <<'__EOF_COPILOT_KIT__'
---
name: migration-parity-check
description: Verifica que el servicio migrado a Quarkus sea funcionalmente equivalente al original en Spring Boot, comparando tests de contrato, OpenAPI, respuestas de error, configuración y observabilidad, y emite un veredicto de paridad. Úsala después de la migración o cuando se pida validar, comparar o certificar la versión Quarkus.
---

# Migration parity check

## Objetivo

Demostrar con evidencia objetiva que la versión Quarkus se comporta igual que la versión Spring, o listar exactamente dónde difiere.

## Entradas

- `docs/migracion/02-api-y-logica.md`, `openapi-actual.yaml`, `03-plan-tests.md` y `05-migracion-quarkus.md`.
- La suite de contrato (`@Tag("contract")`) creada por `characterization-tests`.
- Ambas versiones del servicio ejecutándose (o instrucciones para levantarlas).

## Pasos

1. **Build y tests unitarios** de la versión Quarkus: todos deben pasar. Lista los que se portaron o reescribieron.
2. **Suite de contrato contra ambas versiones**:
   - `-Dcontract.baseUrl=<url-spring>` y `-Dcontract.baseUrl=<url-quarkus>`.
   - Compara resultados test por test; cualquier diferencia es un hallazgo.
3. **Diff de contrato OpenAPI**: exporta el OpenAPI de Quarkus (`/q/openapi`) y compáralo con `openapi-actual.yaml` (por ejemplo con `oasdiff`). Clasifica los cambios como breaking o no breaking.
4. **Paridad de respuestas**: status codes, headers (Content-Type, CORS, cache), formato de fechas y números, campos nulos u omitidos, orden y paginación, y **cuerpo de error** en cada caso.
5. **Paridad de configuración**: cada propiedad y variable de entorno del original tiene equivalente y el mismo valor efectivo por perfil.
6. **Paridad de integraciones**: los mismos timeouts, reintentos y comportamiento ante fallos de dependencias externas.
7. **Seguridad**: los mismos endpoints protegidos, roles y respuestas 401/403.
8. **Observabilidad**: health (`/q/health/live`, `/q/health/ready`), métricas, trazas y logs con correlación.
9. **Smoke de rendimiento** (orientativo): tiempo de arranque, memoria en reposo y latencia p95 de los endpoints principales en ambas versiones.

## Formato de diferencias

| ID | Área | Endpoint / propiedad | Spring | Quarkus | Breaking | Acción |
|---|---|---|---|---|---|---|

## Veredicto

- **APTO**: sin diferencias breaking.
- **APTO CON OBSERVACIONES**: diferencias no breaking documentadas y aceptadas.
- **NO APTO**: al menos una diferencia breaking sin resolver.

## Entregables

- `docs/migracion/07-paridad.md`: resumen y veredicto, resultados por paso, tabla de diferencias, comparación de rendimiento y acciones pendientes.

## Checklist de salida

- [ ] La suite de contrato se ejecutó contra ambas versiones.
- [ ] El diff de OpenAPI está adjunto y clasificado.
- [ ] El veredicto está justificado con evidencia.
__EOF_COPILOT_KIT__

write_file '.github/skills/quarkus-migration-assessment/SKILL.md' <<'__EOF_COPILOT_KIT__'
---
name: quarkus-migration-assessment
description: Genera el inventario de librerías, anotaciones, objetos y configuración que deben migrarse de Spring Boot a Quarkus, con su equivalente, los riesgos de la migración y un plan por fases para el agente migrador. Úsala cuando se pida evaluar, planificar o estimar la migración a Quarkus.
---

# Quarkus migration assessment

## Objetivo

Construir el plan de migración que consumirá el agente migrador: qué cambia, por qué, con qué riesgo y en qué orden.

## Entradas

- `docs/migracion/01-arquitectura.md`, `02-api-y-logica.md`, `03-plan-tests.md` y `04-deuda-tecnica.md`.

## Restricciones

- Solo análisis: no modificar código.
- Versión objetivo: la **LTS vigente de Quarkus**. Verifica la versión actual y las extensiones en la documentación oficial (quarkus.io/extensions) antes de afirmar nombres o disponibilidad; márcalo `[VERIFICAR]` si no puedes confirmarlo.

## Pasos

1. **Decisión de estrategia** (documentar pros y contras):
   - **APIs nativas de Quarkus** (JAX-RS, CDI, MicroProfile, Panache): recomendado a mediano plazo.
   - **Extensiones de compatibilidad Spring** (`quarkus-spring-web`, `quarkus-spring-di`, `quarkus-spring-data-jpa`, `quarkus-spring-boot-properties`, `quarkus-spring-security`, `quarkus-spring-cache`, `quarkus-spring-scheduled`): migración más rápida, pero cubren un subconjunto de funcionalidad y dejan deuda. Verifica su vigencia actual.
2. **Inventario de dependencias**: tabla dependencia actual → extensión Quarkus → notas → riesgo.
3. **Inventario de código**: busca cada patrón de la tabla de mapeo y lista **cada ocurrencia** con `archivo:línea`, agrupada por tipo.
4. **Configuración**: mapear cada propiedad de `application*.yml` a su equivalente en `application.properties` de Quarkus, y perfiles a `%dev`, `%test` y `%prod`.
5. **Impacto en tests**: qué tests de `03-plan-tests.md` son portables y cuáles deben reescribirse (`@QuarkusTest`, `@InjectMock`).
6. **Registro de riesgos**.
7. **Plan por fases para el agente migrador**.

## Tabla de mapeo de referencia

### Dependencias

| Spring | Quarkus |
|---|---|
| `spring-boot-starter-web` | `quarkus-rest` + `quarkus-rest-jackson` |
| `spring-boot-starter-validation` | `quarkus-hibernate-validator` |
| `spring-boot-starter-data-jpa` | `quarkus-hibernate-orm-panache` (o `quarkus-spring-data-jpa`) + driver `quarkus-jdbc-*` |
| Flyway / Liquibase | `quarkus-flyway` / `quarkus-liquibase` |
| `spring-boot-starter-security` / OAuth2 Resource Server | `quarkus-oidc` / `quarkus-smallrye-jwt` |
| `spring-boot-starter-actuator` | `quarkus-smallrye-health` + `quarkus-micrometer-registry-prometheus` |
| springdoc-openapi | `quarkus-smallrye-openapi` |
| RestTemplate / WebClient / OpenFeign | `quarkus-rest-client` + `quarkus-rest-client-jackson` |
| Spring Kafka / Spring AMQP | `quarkus-messaging-kafka` / `quarkus-messaging-rabbitmq` |
| SDKs de Azure (Service Bus, Blob, Key Vault, App Configuration) | Extensiones de Quarkiverse Azure `[VERIFICAR]` o SDK directo |
| `spring-boot-starter-cache` / Redis | `quarkus-cache` / `quarkus-redis-client` |
| Resilience4j | `quarkus-smallrye-fault-tolerance` |
| Micrometer Tracing / Sleuth | `quarkus-opentelemetry` |
| Logback / Log4j2 config | Logging de Quarkus (JBoss LogManager), `quarkus-logging-json` |
| `spring-boot-starter-test` | `quarkus-junit5`, `quarkus-junit5-mockito`, `rest-assured` |
| MapStruct | Compatible; usar `componentModel = "cdi"` / `jakarta-cdi` |
| Lombok | Compatible (revisar `@SneakyThrows` y builders en entidades) |

### Anotaciones y objetos

| Spring | Quarkus |
|---|---|
| `@RestController`, `@RequestMapping`, `@GetMapping`... | `@Path`, `@GET`, `@POST`, `@Produces`, `@Consumes` |
| `@PathVariable`, `@RequestParam`, `@RequestHeader` | `@PathParam`/`@RestPath`, `@QueryParam`/`@RestQuery`, `@HeaderParam`/`@RestHeader` |
| `ResponseEntity<T>` | `Response` / `RestResponse<T>` |
| `@Service`, `@Component` | `@ApplicationScoped` |
| `@Repository` (Spring Data) | `PanacheRepository<T>` + `@ApplicationScoped` |
| `@Configuration` + `@Bean` | Bean CDI con métodos `@Produces` |
| `@Autowired` | `@Inject` o constructor |
| `@Value` | `@ConfigProperty` |
| `@ConfigurationProperties` | `@ConfigMapping` |
| `@Profile` | Perfiles `%dev/%prod`, `@IfBuildProfile` |
| `@ConditionalOnProperty` y demás `@Conditional*` | `@IfBuildProperty`/`@LookupIfProperty` (**se resuelve en build time**) |
| `@ControllerAdvice` + `@ExceptionHandler` | `ExceptionMapper<T>` / `@ServerExceptionMapper` |
| `@Transactional` (Spring) | `jakarta.transaction.Transactional` (sin `readOnly`; revisar propagación y rollback) |
| `@Async` | `ManagedExecutor`, `Uni`/`CompletionStage` |
| `@Scheduled` | `io.quarkus.scheduler.Scheduled` |
| `ApplicationEvent` / `@EventListener` | Eventos CDI (`Event<T>`, `@Observes`) |
| `CommandLineRunner` / `ApplicationRunner` | `@Observes StartupEvent` |
| `Filter`, `HandlerInterceptor` | `ContainerRequestFilter` / `@ServerRequestFilter` |
| `@Aspect` (Spring AOP) | Interceptores CDI (`@InterceptorBinding`) |
| `@PreAuthorize`, `@Secured` | `@RolesAllowed`, `@PermissionsAllowed` |
| Derived queries, `Pageable`, `Specification` | Métodos Panache, `Page`, Criteria API (riesgo si hay Specifications complejas) |
| `javax.*` (Boot 2) | `jakarta.*` |
| `@MockBean` en tests | `@InjectMock` |

## Riesgos que se deben buscar activamente

1. **Librerías internas/corporativas** construidas sobre Spring (starters, auto-configuración): sin equivalente directo. Suele ser el riesgo principal.
2. **Spring Boot 2 → `javax` a `jakarta`**: cambio de namespace en todo el código.
3. **Build time vs runtime**: CDI de Quarkus resuelve beans al compilar. `@Conditional`, registro dinámico de beans y `getBean` en runtime no funcionan igual.
4. **Semántica de transacciones** diferente (propagación, `readOnly`, rollback con checked exceptions).
5. **Formato de respuestas de error** y serialización Jackson (fechas, nulos, propiedades desconocidas, naming): los consumidores pueden romperse.
6. **Hibernate**: diferencias de versión en JPQL, tipos y generadores de ID.
7. **Seguridad**: expresiones SpEL de `@PreAuthorize` sin equivalente directo.
8. **Imagen nativa (si se evalúa)**: reflexión, proxies dinámicos y recursos requieren registro explícito.
9. **Hilos**: en Quarkus REST, los métodos que devuelven `Uni`/`Multi` se ejecutan en el event loop; el código bloqueante debe ir en worker threads (`@Blocking`).
10. **Tests dependientes de Spring**, que se pierden al migrar.
11. **Nombres de propiedades de configuración** y variables de entorno ya usadas en los despliegues.

## Formato del registro de riesgos

| ID | Riesgo | Evidencia (`archivo:línea`) | Probabilidad | Impacto | Mitigación | Responsable |
|---|---|---|---|---|---|---|

## Plan por fases (para el agente migrador)

1. Preparación: deuda técnica marcada ANTES y red de tests en verde.
2. Build: nuevo `pom.xml` con BOM de Quarkus, extensiones y plugin.
3. Configuración: `application.properties` y perfiles.
4. Capa de datos: entidades y repositorios.
5. Servicios y DI.
6. Capa REST, manejo de errores y seguridad.
7. Integraciones (clientes REST, mensajería, caché, scheduler).
8. Observabilidad (health, métricas, trazas, logs).
9. Tests: portar tests dependientes de Spring y ejecutar la suite de contrato.

Cada fase indica archivos afectados, criterio de terminado y validación.

## Entregables

- `docs/migracion/05-migracion-quarkus.md`: resumen ejecutivo, estrategia elegida, versión objetivo, inventario de dependencias, inventario de código con ocurrencias, mapeo de configuración, impacto en tests, registro de riesgos, plan por fases, estimación (S/M/L por fase) y preguntas abiertas.

## Checklist de salida

- [ ] Cada dependencia tiene destino o está marcada como "sin equivalente" con plan.
- [ ] Cada ocurrencia de anotación Spring está inventariada.
- [ ] Las librerías internas tienen análisis propio.
- [ ] Riesgos con evidencia y mitigación.
__EOF_COPILOT_KIT__

write_file '.github/skills/service-discovery/SKILL.md' <<'__EOF_COPILOT_KIT__'
---
name: service-discovery
description: Analiza el microservicio Spring Boot actual y documenta arquitectura, dependencias, configuración, integraciones, endpoints expuestos, contratos request/response y la lógica interna de cada endpoint con explicación técnica y funcional. Úsala cuando se pida entender el repositorio, qué servicios expone, qué responde o cómo funciona un flujo.
---

# Service discovery

## Objetivo

Producir la radiografía técnica del servicio. Es la base de todas las demás skills, así que debe ser completa y trazable al código.

## Restricciones

- Solo lectura: **no modificar ningún archivo** fuera de `docs/migracion/`.
- Cada afirmación cita `ruta/Archivo.java:línea`.
- Lo no verificable se marca como `[SUPUESTO]`.

## Pasos

1. **Build y dependencias** (`pom.xml` / `build.gradle`)
   - Versión de Java, Spring Boot y Spring Cloud.
   - Dependencias directas agrupadas por tipo: web, datos, mensajería, seguridad, observabilidad, utilidades y **librerías internas/corporativas** (groupId propio de la empresa). Resalta estas últimas: son el mayor riesgo de migración.
   - Plugins de build relevantes (JaCoCo, generación de código, OpenAPI, MapStruct, Lombok).
2. **Estructura**
   - Paquetes y capas, clase `@SpringBootApplication`, estilo arquitectónico (capas, hexagonal, mezcla).
   - Diagrama Mermaid de componentes.
3. **Configuración**
   - `application*.yml|properties`, perfiles, variables de entorno y propiedades custom (`@Value`, `@ConfigurationProperties`).
   - Tabla: propiedad, dónde se usa, valor por perfil (sin secretos).
4. **Integraciones salientes**
   - Base de datos: motor, entidades, relaciones (`erDiagram`), repositorios, queries nativas/JPQL, Specifications, migraciones (Flyway/Liquibase).
   - Clientes HTTP (RestTemplate, WebClient, Feign): destino, operaciones, timeouts, reintentos.
   - Mensajería, caché, almacenamiento de archivos, schedulers (`@Scheduled`), tareas asíncronas (`@Async`).
5. **Endpoints expuestos**: por cada `@RestController` / `@Controller`:
   - Tabla resumen: método HTTP, ruta, handler, request, response, códigos HTTP, seguridad requerida.
   - Detalle: headers, path/query params, body (campos, tipos, obligatoriedad, validaciones Bean Validation) y ejemplo JSON de request y response.
6. **Lógica interna por endpoint**
   - **Técnica**: flujo controller → service → repository/cliente, con `sequenceDiagram`; transacciones (`@Transactional`, propagación, readOnly), mapeos (MapStruct/manual), efectos secundarios (escrituras, eventos, llamadas externas).
   - **Funcional**: qué necesidad de negocio resuelve y qué reglas de negocio aplica (en lenguaje no técnico).
   - Casos de error: qué excepción se lanza, cómo se traduce a HTTP y qué cuerpo de error devuelve.
7. **Aspectos transversales**: seguridad (filtros, roles, `@PreAuthorize`), manejo global de errores (`@ControllerAdvice`), filtros e interceptores, AOP, logging y correlación, observabilidad (Actuator, métricas, trazas).
8. **Contrato OpenAPI**
   - Si existe springdoc, indica cómo exportar el contrato (`/v3/api-docs`) y guárdalo.
   - Si no existe, genera `docs/migracion/openapi-actual.yaml` a partir del código y marca como `x-inferido: true` lo deducido.

## Entregables

- `docs/migracion/01-arquitectura.md`: resumen ejecutivo, stack y versiones, dependencias, estructura, configuración, integraciones, transversales, diagramas y preguntas abiertas.
- `docs/migracion/02-api-y-logica.md`: catálogo de endpoints, detalle por endpoint (contrato, lógica técnica, lógica funcional, errores) y preguntas abiertas.
- `docs/migracion/openapi-actual.yaml`.

## Checklist de salida

- [ ] Todos los controllers del proyecto aparecen en el catálogo (verificar con búsqueda de `@RestController`, `@Controller` y `@RequestMapping`).
- [ ] Toda integración externa tiene destino, protocolo y manejo de errores.
- [ ] Las librerías internas están listadas explícitamente.
- [ ] Cada endpoint tiene explicación técnica **y** funcional.
__EOF_COPILOT_KIT__

write_file '.github/skills/tech-debt-review/SKILL.md' <<'__EOF_COPILOT_KIT__'
---
name: tech-debt-review
description: Revisa la deuda técnica del microservicio aplicando Clean Code, SOLID y patrones de diseño (incluidos patrones avanzados cuando apliquen) y clasifica cada hallazgo según convenga resolverlo antes, durante o después de la migración a Quarkus. Úsala cuando se pida revisar deuda técnica, calidad de código, refactors o buenas prácticas.
---

# Tech debt review

## Objetivo

Identificar y priorizar la deuda técnica **en función de la migración**. Una lista infinita de mejoras no sirve; cada hallazgo debe indicar cuándo conviene atacarlo.

## Entradas

- `docs/migracion/01-arquitectura.md` y `docs/migracion/02-api-y-logica.md`.
- `docs/migracion/03-plan-tests.md` (clases no testeables), si existe.

## Restricciones

- Solo análisis: no modificar código.
- No recomendar un patrón sin explicar el problema concreto que resuelve en **este** código. Si la solución simple basta, recomiéndala.

## Categorías a revisar

1. **Clean Code**: nombres, métodos largos (> 30 líneas), clases grandes (> 300 líneas), parámetros excesivos (> 4), duplicación, código muerto, números mágicos, comentarios obsoletos, anidamiento profundo, manejo de excepciones (catch vacíos, `Exception` genérica, excepciones para control de flujo).
2. **SOLID**
   - SRP: servicios "dios" o controllers con lógica.
   - OCP: `switch`/`if` por tipo que crecen con cada caso nuevo.
   - LSP: herencia que rompe contratos.
   - ISP: interfaces enormes.
   - DIP: dominio que depende de infraestructura o del framework.
3. **Diseño y arquitectura**: fuga de capas (entidades JPA expuestas en la API, `ResponseEntity` en servicios), modelo anémico con lógica dispersa, acoplamiento a integraciones externas sin abstracción, transacciones mal delimitadas, dependencias circulares.
4. **Olores que afectan la migración** (prioridad alta):
   - Inyección por campo (`@Autowired` en atributos).
   - Estado estático mutable, `ThreadLocal`, singletons manuales.
   - Beans condicionales en runtime (`@Conditional*`, `@Profile` con lógica).
   - AOP custom (`@Aspect`), `BeanPostProcessor`, `ApplicationContext.getBean`.
   - APIs de Spring dentro del dominio (Spring Data, `Environment`, eventos de Spring).
   - Reflexión o carga dinámica de clases.
   - Uso de `javax.*` (si es Spring Boot 2).
5. **Seguridad y robustez**: validación de entrada, datos sensibles en logs, timeouts y reintentos ausentes en clientes externos, recursos no cerrados.
6. **Rendimiento**: consultas N+1, `FetchType.EAGER` indiscriminado, paginación ausente, llamadas bloqueantes en serie que podrían paralelizarse.

## Patrones a considerar (solo si aplican)

Strategy (reemplazar condicionales por tipo), Specification (reglas de negocio combinables), Template Method / Chain of Responsibility (flujos de validación), Decorator (comportamiento transversal sin AOP), Adapter / Anti-Corruption Layer (aislar integraciones externas), Ports & Adapters / Hexagonal (desacoplar el dominio del framework, que además facilita la migración), Factory / Builder (construcción compleja), Outbox (consistencia entre BD y mensajería).

## Formato de cada hallazgo

| Campo | Contenido |
|---|---|
| ID | `TD-001` |
| Ubicación | `ruta/Archivo.java:línea` |
| Categoría | Clean Code / SOLID-SRP / Migración / ... |
| Descripción | Qué pasa y por qué es un problema |
| Impacto | Mantenibilidad, riesgo de bug, bloqueo de migración, rendimiento |
| Severidad | Crítica / Alta / Media / Baja |
| Esfuerzo | S (< 1 d) / M (1-3 d) / L (> 3 d) |
| **Momento** | **ANTES** (bloquea o encarece la migración) / **DURANTE** (se reescribe igual) / **DESPUÉS** (no afecta la migración) |
| Recomendación | Cambio concreto y patrón, si aplica, con un antes/después breve en pseudocódigo |

## Entregables

- `docs/migracion/04-deuda-tecnica.md`: resumen ejecutivo (conteo por severidad y momento), top 10 priorizado, hallazgos completos agrupados por momento, métricas (tamaño de clases y métodos, complejidad aproximada) y recomendaciones de estándares para el equipo.

## Checklist de salida

- [ ] Todo hallazgo tiene ubicación y momento.
- [ ] Los hallazgos ANTES están justificados por su impacto en la migración.
- [ ] Ningún patrón recomendado sin problema concreto.
__EOF_COPILOT_KIT__

write_file 'docs/migracion/README.md' <<'__EOF_COPILOT_KIT__'
# Migración Spring Boot → Quarkus + despliegue en Azure

Entregables generados por las skills de GitHub Copilot (`.github/skills/`). Destino Azure: `{{AZURE_TARGET}}`.

## Orden de ejecución

```mermaid
flowchart LR
  A[service-discovery] --> B[characterization-tests]
  A --> C[tech-debt-review]
  A --> F[functional-docs]
  B --> D[quarkus-migration-assessment]
  C --> D
  D --> M((Agente migrador))
  M --> P[migration-parity-check]
  P --> Z[azure-deploy-readiness]
```

## Entregables

| # | Documento | Skill | Estado |
|---|---|---|---|
| 01 | `01-arquitectura.md` | service-discovery | ⬜ |
| 02 | `02-api-y-logica.md` + `openapi-actual.yaml` | service-discovery | ⬜ |
| 03 | `03-plan-tests.md` | characterization-tests | ⬜ |
| 04 | `04-deuda-tecnica.md` | tech-debt-review | ⬜ |
| 05 | `05-migracion-quarkus.md` | quarkus-migration-assessment | ⬜ |
| 06 | `06-documentacion-funcional.md` | functional-docs | ⬜ |
| 07 | `07-paridad.md` | migration-parity-check | ⬜ |
| 08 | `08-despliegue-azure.md` | azure-deploy-readiness | ⬜ |

## Cómo invocar una skill

En el chat de Copilot (modo agente), pide la tarea de forma explícita, por ejemplo:

> Usa la skill `service-discovery` para analizar este repositorio.

Copilot también puede cargar la skill automáticamente cuando la petición coincide con su `description`.
__EOF_COPILOT_KIT__

echo
echo "Resumen: $CREATED creados, $OVERWRITTEN sobrescritos, $SKIPPED omitidos."
if [ "$SKIPPED" -gt 0 ]; then
  echo "Nota: si ya tenías .github/copilot-instructions.md, revisa y fusiona su contenido manualmente o vuelve a ejecutar con -f."
fi
cat <<'EOF'

Siguientes pasos:
  1. Revisa y ajusta .github/copilot-instructions.md con el contexto real del servicio.
  2. Haz commit de .github/ y docs/migracion/ para que todo el equipo use las mismas skills.
  3. En VS Code, abre Copilot Chat en modo agente y pide:
       "Usa la skill service-discovery para analizar este repositorio"
     Si VS Code no detecta las skills, verifica que la opción de Agent Skills
     (chat.useAgentSkills) esté habilitada en tu versión.
EOF
