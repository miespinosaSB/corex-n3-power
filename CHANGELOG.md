# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/)
y este proyecto adhiere a [Versionamiento Semántico](https://semver.org/lang/es/).

## [No publicado]

### Corregido
- Se reescribió `update.sh` — ahora copia dinámicamente TODOS los agentes, scripts y steering globales (antes solo copiaba el agente de diagnóstico hardcoded)

### Agregado
- Se creó steering `owasp-top10-seguridad.md` — reglas de seguridad OWASP Top 10 (2021) adaptadas al stack Corex: Spring Boot 3, Adaptador V3, Oracle/PL-SQL, API Gateway. Incluye ejemplos de código, checklist de code review y sección específica para PL/SQL
- Se agregó sub-agente `corex-emission-builder` (Ctrl+Shift+E) — generador de JSON para API Liviano de Emisión con consulta Oracle en tiempo real, memoria en Confluence, y modo cotización (proceso 241/240)
- Se agregó script `build-emision-json.js` — ensamblador de JSON de emisión con validaciones de negocio, soporte de templates, metadata y exclusión automática de campos innecesarios (MrcCtzcn)
- Se creó página de memoria "450 - CUMPLIMIENTO PARTICULARES" en Confluence (espacio BDCT) con valores validados, restricciones y NR_UNC de referencia
- Se creó steering `publicacion-librerias-jfrog.md` — guía completa para publicar librerías Gradle en JFrog Artifactory usando el template de DevOps (`devops-actions-library-templates`)

### Cambiado
- Se actualizó `publicacion-librerias-jfrog.md` con aprendizajes reales de la publicación de bff-common: Bearer token vs user/password, `framework_version` obligatorio para Java 21, y detalle de autenticación pipeline vs local
- Se agregó referencia cruzada en `scaffolding-microservicio.md` apuntando al steering de publicación en JFrog
- Se reescribió `engram-sync.sh` — ahora exporta TODOS los proyectos (Engram es a nivel usuario, no proyecto), usa Python+sqlite3 directo (sin depender de CLI), genera markdown categorizado, y funciona desde cualquier directorio
- Se agregó Fase 5 "Backup de conocimiento" al agente de retrospectiva — ejecuta `engram-sync.sh export` y commitea `shared-knowledge/` automáticamente al final de cada retrospectiva

### Cambiado
- Se actualizó configuración de `mcp-atlassian` para soportar credenciales separadas de Confluence (`CONFLUENCE_USERNAME`, `CONFLUENCE_API_TOKEN`) requeridas por nueva versión del servidor MCP
- Se actualizaron scripts de instalación (`install.sh`, `install.ps1`) para solicitar credenciales de Confluence de forma independiente (con fallback al mismo token de Jira)

### Corregido
- Se corrigió instalación de agentes — ahora `install.sh` e `install.ps1` copian todos los agentes disponibles (diagnóstico, implementación, retrospectiva) en vez de solo el de diagnóstico

### Cambiado
- Se reescribió el prompt del agente de diagnóstico para hacer el trazado de código fuente (debug paso a paso) el paso central y obligatorio — gate de calidad impide reportar sin evidencia de código leído

### Agregado
- Se exportó conocimiento Engram a `shared-knowledge/` — 4 archivos con decisiones, arquitectura de facturación, patrones/bugfixes y resúmenes de sesión (65 observaciones, 17 sesiones)
- Se agregó Estrategia 8 "Buscar UPDATEs Post-INSERT" en `diagnostico-eficiente.md` — regla crítica para casos de facturación donde CB100270 modifica imp_prima después del INSERT (aprendizaje MDSB-992543)
- Se agregó tabla C1000270 (diferidos) en `oracle-consultas.md` como tabla crítica para diagnóstico de facturación en autos

### Cambiado
- Se optimizaron 6 steering files de reglas (tech-stack, libraries, security, code-style, architecture, ai-generated-code) de `inclusion: always` a `inclusion: fileMatch` para reducir consumo de contexto en sesiones de soporte N3
- Se simplificó steering de Engram para no activarse automáticamente al inicio de cada sesión, solo cuando hay trabajo significativo
- Se estableció regla de prioridad "repo primero, Oracle después" en `diagnostico-eficiente.md` y `fuentes-codigo-repositorios.md` — leer packages del repositorio local (rama master) antes de usar `get_source` del MCP Oracle, evitando truncamiento por tamaño y ahorrando créditos
- Se reestructuró Fase 1 de `atencion-incidente-autonomo.md` con flujo obligatorio: Engram → Confluence/Jira → Repo Oracle DB → Repo COBOL → Repo Forms → Oracle (solo datos), eliminando suposiciones previas a la lectura de código fuente
- Se agregó regla de precisión absoluta "CERO SUPOSICIONES" en `diagnostico-eficiente.md` — toda afirmación debe estar respaldada por código fuente leído o datos verificados, nunca por inferencia
- Se actualizó scoring de confianza en `atencion-incidente-autonomo.md` para exigir evidencia citada (archivo + línea + query) y sección "No Verificado" obligatoria en el reporte final

### Corregido
- Se corrigió `consulta-produccion-mdsb.md` — las credenciales se leen de `~/.kiro/settings/.env` (no de variables de entorno del shell que no existen). Script Python autocontenido que hace upload + create request en un solo paso

### Agregado
- Se migró el power corex-n3 a repositorio dedicado (antes vivía en rama de tronador-oracle-db)
- Se incluyeron 3 sub-agentes: diagnóstico, implementación, retrospectiva
- Se incluyeron 4 skills globales: oracle-diagnostics, jira-workflow, confluence-docs, adapter-v3
- Se incluyeron 17 hooks de protección y automatización
- Se incluyeron 3 scripts: engram-sync, metrics-report, generate-source-index
- Se integró Engram (memoria persistente) como MCP del power
- Se integró Context7 (documentación actualizada) como MCP del power
- Se creó steering `diagnostico-eficiente.md` con árboles de decisión y templates SQL
- Se creó steering `context7-microservices.md` para consulta automática de docs
- Se creó GUIA-USO.md para onboarding del equipo
- Se creó update.sh para actualización sin reinstalar
