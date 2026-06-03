# Agente 03 — Validación de Cobertura de Pruebas Unitarias

## Propósito
Analizar el estado actual de las pruebas unitarias: qué está cubierto, qué falta, qué está mal implementado, y generar un plan de acción con las pruebas faltantes ya escritas o esbozadas.

---

## Instrucciones para activar el agente

1. Abre el repositorio en VS Code con el proyecto V2 (Quarkus) como workspace activo.
2. Abre Copilot Chat (`Ctrl+Alt+I` / `Cmd+Alt+I`).
3. Si tienes reporte de cobertura JaCoCo, ábrelo en el editor y referéncialo con `#file:target/site/jacoco/index.html` o adjúntalo al chat.
4. Pega el prompt con las rutas completadas.

---

## Prompt

```
Eres un experto en testing de software. Tu tarea es auditar las pruebas unitarias del proyecto en la carpeta montada, identificar brechas de cobertura y generar un plan de acción con los tests faltantes.

### Contexto
@workspace
- Código fuente: `#file:src/main/java/com/example` (o el paquete específico a auditar)
- Tests existentes: `#file:src/test/java/com/example`
- Reporte JaCoCo: [SÍ → `#file:target/site/jacoco/index.html` | NO]
- Framework de testing: [ej. JUnit 5 + Mockito + Quarkus QuarkusTest]
- Cobertura mínima objetivo: [ej. 80%]

### Proceso

#### Fase 1 — Mapeo de clases vs. tests
1. Lista todas las clases en el directorio fuente.
2. Lista todas las clases de test existentes.
3. Construye una tabla de correspondencia:

| Clase fuente               | Clase de test              | Estado         |
|----------------------------|----------------------------|----------------|
| UserService.java           | UserServiceTest.java       | ✅ Existe       |
| PaymentProcessor.java      | —                          | ❌ Sin test     |
| OrderValidator.java        | OrderValidatorTest.java    | ⚠️ Incompleto  |

#### Fase 2 — Análisis de calidad de tests existentes
Para cada clase de test que sí existe, verifica:
- ¿Cubre el happy path?
- ¿Cubre casos límite (null, lista vacía, valores extremos)?
- ¿Cubre los casos de error / excepciones?
- ¿Los mocks están bien configurados (sin over-mocking)?
- ¿Los asserts son específicos (no solo `assertNotNull`)?
- ¿Los nombres de los tests son descriptivos? (convención recomendada: `shouldDoX_whenY`)
- ¿Hay casos con múltiples inputs similares que deberían usar `@ParameterizedTest` en lugar de métodos duplicados?

**Distinción crítica en Quarkus — leer antes de clasificar:**
- `@QuarkusTest` → **test de integración**: levanta el contexto CDI completo, arranque lento (~5-15s). Válido para probar endpoints REST o interacciones entre beans.
- Test **sin** `@QuarkusTest` (JUnit 5 puro + Mockito) → **test unitario**: rápido, aislado, sin contexto de aplicación. Es el que debe predominar para lógica de negocio.
- `@QuarkusUnitTest` → test de bootstrap que verifica configuración del contenedor.

Clasifica cada test existente según esta distinción y marca si está usando el tipo correcto para lo que pretende probar.

Marca cada test con: ✅ Completo / ⚠️ Parcial / ❌ Deficiente / ⚠️ Tipo incorrecto.

#### Fase 3 — Plan de acción
Usa el siguiente formato Markdown para cada ítem faltante:

---
#### UT-NNN — [NombreClase] · [método o escenario]

| Campo | Detalle |
|---|---|
| **Clase** | `com.example.NombreClase` |
| **Método(s)** | `metodo1()`, `metodo2()` |
| **Tipo de test** | Happy path / Edge case / Excepción / Integración |
| **Prioridad** | ALTA / MEDIA / BAJA |

**Causa de la brecha**
> Por qué este caso no está cubierto y qué riesgo representa en producción.

**Consecuencia de no tener este test**
> Qué tipo de bug podría llegar a producción sin ser detectado.

**Test sugerido**
```java
// código compilable del test
```
---

#### Fase 4 — Resumen
- Total de clases: X | Con test: X | Sin test: X | Parciales: X.
- Estimación de cobertura actual: ALTA / MEDIA / BAJA.
- Estimación de esfuerzo para llegar al objetivo.
- Top 5 tests más urgentes.

### Restricciones
- No modifiques archivos de test existentes; solo analiza y propón.
- Los tests sugeridos deben ser compilables y seguir las convenciones del proyecto.
- Prioriza lógica de negocio sobre DTOs, entidades simples o configuraciones.
- Para lógica de negocio pura: propón siempre tests unitarios (JUnit 5 + Mockito, sin `@QuarkusTest`).
- Para endpoints REST o flujos que cruzan varios beans: propón `@QuarkusTest` y márcalos explícitamente como tests de integración.
- Nunca proponer `@QuarkusTest` para testear un método de servicio de forma aislada — es el error más común y tiene alto impacto en tiempos de CI.

### Formato de salida
Genera el contenido completo del reporte en Markdown. El usuario lo copiará y guardará como `reporte-pruebas-unitarias-YYYY-MM-DD.md` en `/docs/quality-gate/`. Estructura:
1. Encabezado (proyecto, módulo, fecha, framework de testing).
2. Tabla de mapeo clases vs. tests.
3. Resumen de cobertura y top 5 urgentes.
4. Listado completo de brechas con el formato por ítem definido arriba.
```

---

## Ejemplo de esqueleto generado

```java
// UT-005 — PaymentProcessorTest (PRIORIDAD: ALTA)
@QuarkusTest
class PaymentProcessorTest {

    @InjectMock
    PaymentGateway paymentGateway;

    @Inject
    PaymentProcessor processor;

    @Test
    @DisplayName("Debe procesar pago exitoso cuando el gateway responde OK")
    void shouldProcessPaymentSuccessfully() {
        // Arrange
        when(paymentGateway.charge(any())).thenReturn(PaymentResult.success("TXN-123"));
        // Act
        PaymentResult result = processor.process(new PaymentRequest(100.0, "USD"));
        // Assert
        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getTransactionId()).isEqualTo("TXN-123");
    }

    @Test
    @DisplayName("Debe lanzar PaymentException cuando el gateway falla")
    void shouldThrowWhenGatewayFails() {
        when(paymentGateway.charge(any())).thenThrow(new GatewayException("Timeout"));
        assertThrows(PaymentException.class,
            () -> processor.process(new PaymentRequest(100.0, "USD")));
    }
}
```
