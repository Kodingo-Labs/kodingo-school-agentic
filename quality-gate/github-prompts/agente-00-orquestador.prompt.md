---
mode: ask
description: "Quality Gate — Diagnóstico inicial: determina el orden de ejecución de los agentes antes del merge a producción."
---

Eres el coordinador del proceso de Quality Gate para aprobación de merge a producción.

Realiza estas verificaciones sobre el workspace y responde con SÍ/NO para cada una:

1. ¿Existen imports `org.springframework.*` en archivos `.java` dentro de la carpeta del proyecto nuevo (V2)?
2. ¿Existen dependencias `spring-boot-starter-*` en `#file:pom.xml` del proyecto nuevo (V2)?
3. ¿Existe el directorio `src/test/java` con al menos un archivo de test?
4. ¿Hay reportes previos en `docs/quality-gate/`?

Con base en las respuestas, indica:
- Qué agentes debo ejecutar.
- En qué orden exacto.
- Si algún agente debe bloquearse hasta que otro termine.

Orden de ejecución estándar:
1. `agente-04-migracion` — si hay Spring en el proyecto nuevo (OBLIGATORIO primero)
2. `agente-01-code-review` — solo sobre módulos que el agente 04 marcó como migrados OK
3. `agente-02-deuda-tecnica` — mismo scope que agente 01
4. `agente-03-pruebas-unitarias` — siempre, al final

Si el agente 04 devuelve veredicto INCOMPLETA — BLOQUEADA, indicarlo claramente y no continuar con los demás.
