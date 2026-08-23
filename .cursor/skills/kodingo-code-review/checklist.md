# Checklist — Code Review Kodingo School

Reglas obligatorias al revisar. Si un cambio las viola, sube la severidad.

---

## Cross-repo

- [ ] Sin credenciales, tokens, `.env`, datos de menores ni `puppeteer-chrome-target*.json` en el diff
- [ ] Sin `console.log` / prints con datos sensibles en rutas de producción
- [ ] Errores con contexto; no tragar excepciones en flujos críticos
- [ ] Cambios acotados al problema; sin refactors colaterales grandes no pedidos
- [ ] Documentación de usuario en **español** cuando aplique

---

## kodingo-school-extractor

**Límites del repo**

- [ ] No genera HTML/UI para alumnos ni publica contenido
- [ ] No reintroduce SQLite ni `legacy/extractor-classic`
- [ ] Lógica nueva de captura en `loader/steps/` y `lib/azure/`, no en código legado

**Azure / storage**

- [ ] `manifiesto.json`: una lectura al inicio del sync, una escritura al final (no por archivo)
- [ ] `capture-index.json` sigue siendo fuente de verdad incremental
- [ ] Si Azure falla al subir un archivo → log y continuar (no abortar todo el sync)
- [ ] Con local + Azure activos, no borrar adjuntos locales tras subir sin revisar `shouldRetainLocalFilesAfterAzureUpload`

**Loader / Puppeteer**

- [ ] Sesiones Chrome por hijo; no mezclar cuentas
- [ ] Variables `CLASSROOM_MVP_*` y `.env` raíz vía `lib/env/load-extractor-env.mjs`
- [ ] Pasos 0–3 y orquestador Python coherentes con `loader/README.md`

**Node / Python**

- [ ] Imports y módulos `.mjs` consistentes con el árbol existente
- [ ] Sin dependencias nuevas sin justificación

---

## kodingo-school-bot

- [ ] Persistencia del día en **Discord** (`discord_store.py`), no SQLite ni `data/` local para estado
- [ ] Canales requeridos: evidencias, exoneraciones, aprobaciones
- [ ] Checklist desde `horario.csv` + matriz + `protocolos.yaml`; slugs estables (`tarea:evidencia`)
- [ ] `/evidencia` y `/listo` respetan `ContextoDia` por fecha (sin arrastrar pendientes entre días salvo diseño explícito)
- [ ] Simulador (`dev_simulator`) no rompe contrato del bot real

---

## kodingo-school-web

- [ ] Serverless / Vercel: sin secretos en cliente
- [ ] APIs que consumen material publicado; no scraping de Classroom desde web
- [ ] React: hooks y estado sin fugas obvias; accesibilidad básica en UI nueva
- [ ] Variables de entorno documentadas; no hardcodear URLs de prod

---

## kodingo-school-infra

- [ ] Terraform: sin secrets en `.tf`; usar variables / Key Vault según patrón del repo
- [ ] Módulos reutilizables; cambios con `terraform plan` razonable
- [ ] Go CLI (`ci/`): errores logueados con contexto; tests en archivos nuevos de lógica

---

## kodingo-school-data

- [ ] Solo datos de ejemplo o estructura; sin PII real en commits
- [ ] Rutas alineadas con `CLASSROOM_SYNC_ROOT` y contrato del processor

---

## Severidad rápida

| Hallazgo | Severidad mínima |
|----------|------------------|
| Secret en commit | 🔴 Bloqueante |
| Manifiesto leído/escrito por archivo | 🔴 Bloqueante |
| Pérdida de evidencias Discord / índice | 🔴 Bloqueante |
| Bug lógico en checklist o sync incremental | 🟠 Importante |
| Falta de test en lógica pura nueva | 🟡 Sugerencia |
| Naming / formato | 🔵 Estilo |
