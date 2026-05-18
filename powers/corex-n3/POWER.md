---
name: "corex-n3"
displayName: "Agente N3 - Tribu Corex"
description: "Asistente de soporte nivel 3 para la Tribu Corex. Integra Jira, Confluence y Oracle (Tronador) para análisis de incidentes, gestión de backlog, documentación técnica, registro de tiempos, y generación de microservicios Java/Spring Boot 3 con Adaptador V3 de base de datos."
keywords: ["corex", "tronador", "oracle", "jira", "confluence", "n3", "soporte", "incidentes", "facturación", "pago en línea", "emisión", "indemnizaciones", "reaseguros", "backlog", "recaudo", "comisiones", "adapter-v3", "microservicio", "spring-boot", "java", "adaptador", "pipeline", "ecs", "fargate", "gradle"]
author: "Tribu Corex - Seguros Bolívar"
---

# Agente N3 - Tribu Corex

## Overview

Asistente de soporte nivel 3 para la Tribu Corex en Seguros Bolívar. Combina acceso a:

- **Jira** — gestión de incidentes, historias, subtareas y registro de tiempos
- **Confluence** — documentación técnica con template estándar del equipo
- **Oracle (Tronador)** — consulta de datos en BD de desarrollo y stage
- **Adapter V3** — generación y mantenimiento de microservicios Java/Spring Boot 3 que exponen procedimientos almacenados Oracle vía HTTP

Diseñado para acelerar el ciclo completo de un incidente (análisis → documentación → cierre) y la implementación de nuevos servicios que exponen procedimientos de la base de datos.

## Regla Fundamental: Base de Conocimiento

⚠️ **AL INICIAR CUALQUIER TAREA**, el primer paso SIEMPRE es consultar la Base de Conocimiento en Confluence:

```
confluence_get_page(page_id="1677787138", convert_to_markdown=true)
```

Esta página contiene:
- Diccionario de datos de Tronador (tablas, columnas, descripciones)
- Patrones de problemas conocidos con sus soluciones
- Paquetes y procedimientos documentados con sus dependencias
- Lecciones aprendidas de incidentes anteriores
- Referencias cruzadas para análisis de impacto

**NO iniciar análisis, consultas Oracle, ni modificaciones de código sin antes leer esta página.** La información ahí reduce errores, evita consultas innecesarias y da contexto que de otro modo se pierde entre sesiones.

## Guía de Instalación (para compañeros del equipo)

### Prerrequisitos

1. **uv** instalado (gestor de paquetes Python):
   - **macOS/Linux:** `curl -LsSf https://astral.sh/uv/install.sh | sh`
   - **Windows:** `powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"`
2. **API Token de Atlassian**: [Crear aquí](https://id.atlassian.com/manage-profile/security/api-tokens)
3. **Acceso a BD Oracle** dev (10.1.2.76) con usuario personal
4. **Kiro IDE** instalado

### Paso 1: Instalar el Power

En Kiro: Command Palette → "Install Power from local directory" → seleccionar `powers/corex-n3/`

O si está publicado en un registry: Powers Panel → buscar "corex-n3" → Install

### Paso 2: Configurar credenciales

Después de instalar, Kiro te pedirá las variables de entorno. Completar:

| Variable | Valor | Dónde obtenerlo |
| --- | --- | --- |
| `YOUR_EMAIL` | tu.nombre@segurosbolivar.com | Tu correo corporativo |
| `YOUR_ATLASSIAN_API_TOKEN` | atatt3x... | [Atlassian tokens](https://id.atlassian.com/manage-profile/security/api-tokens) |
| `YOUR_ORACLE_USER` | DEV_XXXXXXXXXX | Solicitar a DBA o líder técnico |
| `YOUR_ORACLE_PASSWORD` | ******** | La que te asignen |

### Eso es todo ✅

No necesitás:
- ❌ Copiar archivos manualmente
- ❌ Ejecutar scripts de certificados
- ❌ Configurar paths absolutos

El Power usa `UV_NATIVE_TLS=true` que le dice a `uv` que use los certificados del sistema operativo (funciona en Mac, Linux y Windows con Netskope instalado). Y el server de Oracle se descarga automáticamente desde el repositorio de GitHub.

### Compatibilidad

| SO | Estado | Notas |
| --- | --- | --- |
| macOS (Apple Silicon) | ✅ | Probado |
| macOS (Intel) | ✅ | Probado |
| Windows 10/11 | ✅ | Requiere uv instalado |
| Linux (Ubuntu/Fedora) | ✅ | Requiere uv instalado |

---

## Comando Rápido: "Atiende el caso MDSB-XXXXX"

Al decir **"atiende el caso MDSB-XXXXX"** (o variantes como "atiende MDSB-XXXXX", "caso MDSB-XXXXX"), el agente ejecuta el **ciclo completo autónomo**:

0. **Preparación** → Carga KB de Confluence + pregunta email y **proyecto/epic** (⚠️ nunca asume — cada dev trabaja en tableros distintos)
1. **Diagnóstico** → Jira completo + Oracle guiado por la KB (no una lista fija de tablas) + búsqueda de patrones conocidos
2. **Confluence** → Crea página de documentación técnica con template estándar
3. **Historia Jira** → Crea HU en el proyecto/epic indicado, vincula todos los MDSB, vincula Confluence
4. **Tiempos** → Crea sub-tarea "Análisis" con estimación y registra worklog
5. **Reporte + Aprendizaje** → Resumen ejecutivo + actualiza la KB con hallazgos nuevos (aprendizaje continuo)

Ver steering `atencion-incidente-autonomo.md` para el detalle completo de cada fase.

## Comando: "Crea una HU" / "Escribe una historia de usuario"

Al decir **"crea una HU"**, **"escribe una historia de usuario"**, **"nueva HU para..."**, o variantes similares, el agente:

1. **Recopila contexto** → Pregunta proyecto/epic, rol del usuario, necesidad y valor de negocio
2. **Redacta la HU** → Estructura BDD: "Como... quiero... para..." + escenarios Dado-Cuando-Entonces (GWT)
3. **Presenta para revisión** → Muestra la HU completa al usuario ANTES de crearla (⚠️ confirmación obligatoria)
4. **Crea en Jira** → Issue tipo Historia con campos obligatorios, criterios de aceptación en formato ADF, y vínculos
5. **Confirma** → Reporta la clave creada con URL directa

La descripción sigue la estructura BDD (Behavior-Driven Development) con mínimo 2 escenarios GWT (camino feliz + caso alternativo/error). Los criterios de aceptación se derivan automáticamente de los escenarios.

Ver steering `escritura-hu.md` para el detalle completo.

## Comando: "Retrospectiva" / "Mejora el power"

Al decir **"retrospectiva"**, **"mejora el power"**, o **"auto-mejora"**, el agente analiza los últimos 30 días de casos atendidos y propone mejoras concretas:

- Patrones de problemas repetidos no documentados en la KB
- Tablas frecuentes que deberían estar en el diccionario de datos
- Consultas SQL candidatas a ser estándar

## Comando: "Genera un JSON de emisión para [producto]"

Al decir **"genera un JSON de emisión"**, **"emisión para cia X secc Y prod Z"**, **"cotiza una póliza de..."**, o usar `Ctrl+Shift+E`, se activa el sub-agente `corex-emission-builder`:

1. **Identifica producto** → Conversacional (guía al usuario) o directo (si da códigos)
2. **Consulta memoria** → Busca en Confluence si ya hay valores validados para ese producto
3. **Consulta Oracle** → G2000020 (campos obligatorios), A1002100 (coberturas), INTERMEDIARIOS
4. **Ensambla JSON** → Genera `datos-emision-<producto>.json` y ejecuta `build-emision-json.js`
5. **Valida** → Pre-flight check de reglas de negocio
6. **Entrega** → JSON listo para `POST /api/v1/expgenerica/procesar`
7. **Actualiza memoria** → Crea/actualiza página en Confluence con valores descubiertos

**Modos:**
- **Conversacional**: Te guía con preguntas en lenguaje de negocio
- **Express**: Proporcionas todos los datos → genera directo
- **Referencia**: "Busca póliza de referencia" → usa datos de una póliza existente
- **Cotización**: Mismo JSON pero con proceso 241/subproceso 240 (en vez de 261/260)

Ver steering `api-liviano-emision.md` para la referencia técnica completa.
- Mejoras a los propios steering files del power

Las mejoras a la KB se aplican directamente. Las mejoras a steering files se proponen y esperan aprobación.

Ver steering `auto-mejora.md` para el detalle completo.

## Comando: "Consulta en prod" / "Lanza esta consulta"

Al decir **"consulta en prod"**, **"ejecuta esto en producción"**, **"crea un MDSB con esta consulta"**, o variantes similares, el agente:

1. **Genera el archivo SQL** con el template obligatorio (ALTER SESSION + SET commands)
2. **Sube el archivo** como temporary attachment a Service Desk
3. **Crea el request MDSB** con formulario ProForma completo (atómico, archivo + formulario en un solo request)
4. **Reporta** la clave MDSB creada con URL directa
5. **Lee el resultado** cuando el usuario confirme que el bot AIOps ya lo procesó

⚠️ El agente NO tiene acceso directo a producción. Usa el bot AIOps de Service Desk como intermediario seguro.

Ver steering `consulta-produccion-mdsb.md` para el detalle completo.

## Protección contra Colisiones

Antes de modificar cualquier objeto de BD (`.pkb`, `.pks`, `.prc`, `.fnc`, `.trg`), el agente verifica automáticamente 4 fuentes de señal:

| Señal | Qué busca |
|---|---|
| **Git** | Ramas activas que tocan el mismo archivo |
| **Jira** | Historias en progreso que mencionan el mismo objeto |
| **Confluence** | Documentación reciente sobre el mismo objeto |
| **Oracle** | DDL reciente en el objeto (alguien lo compiló) |

Si detecta que otro desarrollador está trabajando en el mismo objeto → alerta y detiene antes de sobreescribir trabajo ajeno.

Ver steering `deteccion-colisiones.md` para el detalle completo.

---

## Available Steering Files

| Archivo | Descripción |
| --- | --- |
| `atencion-incidente-autonomo.md` | **(auto)** 🚀 Ciclo completo autónomo de atención de incidentes |
| `auto-mejora.md` | **(auto)** 🧠 Aprendizaje post-caso + retrospectiva periódica |
| `workflow-jira-tiempos.md` | Cómo crear casos en GD986 y registrar tiempos |
| `workflow-git.md` | Convenciones de Git, ramas, commits y PRs |
| `gestion-backlog.md` | Workflow de reducción de backlog y cierre de duplicados |
| `template-confluence.md` | Template estándar para documentar hallazgos técnicos |
| `oracle-consultas.md` | Queries frecuentes y tablas principales de Tronador |
| `oracle-conventions.md` | Convenciones de código Oracle del equipo |
| `dml-policies.md` | Políticas de cambios de datos (scripts DML) |
| `analisis-impacto.md` | **(auto)** Análisis de impacto antes de cualquier cambio |
| `deteccion-colisiones.md` | **(auto)** 🛡️ Verificación de colisiones antes de modificar objetos de BD |
| `base-conocimiento.md` | Contexto persistente y base de conocimiento en Confluence |
| `adapter-v3-conventions.md` | **(auto)** Reglas críticas Jakarta EE, exclusiones javax.*, health check, inyección |
| `adapter-v3-monorepo.md` | **(fileMatch)** Adapter V3 en monorepo existente con Spring Boot 2.x y Cognito |
| `code-quality.md` | **(auto)** Extracción de constantes para literals repetidos |
| `testing-standards.md` | **(auto)** Testing y mocking del Adaptador V3, JaCoCo |
| `testing-obligatorio.md` | **(fileMatch)** Testing obligatorio para microservicios con Adapter V3, checklist pre-commit |
| `sonarcloud-quality-gate.md` | **(fileMatch)** Reglas de SonarCloud: literales duplicados, complejidad cognitiva, cobertura |
| `scaffolding-microservicio.md` | **(manual)** Scaffolding completo de microservicio + WorkflowFile + pipeline |
| `new-feature-guide.md` | **(manual)** Agregar nueva operación/endpoint a un microservicio existente |
| `escritura-hu.md` | **(manual)** ✍️ Escritura y creación de HUs en Jira con estructura BDD (Dado-Cuando-Entonces) |
| `estandares-adapter-v3.md` | **(manual)** Estándares de implementación: Repository, CoreService, DTOs, testing |
| `pull-request-template.md` | **(manual)** 📋 Template para generar `pull_request.md` con orden de ejecución de scripts en tronador-oracle-db |
| `sinonimos-grants-nuevos-objetos.md` | **(auto)** 🔐 Regla obligatoria de sinónimos y grants al crear objetos nuevos en OPS$PUMA |
| `consulta-produccion-mdsb.md` | **(manual)** 🔍 Consulta a producción vía MDSB — crea request Service Desk con SQL para bot AIOps |
| `fuentes-codigo-repositorios.md` | **(auto)** 📂 Integración con repos COBOL, Forms y Oracle DB para diagnóstico con código fuente |
| `diagnostico-eficiente.md` | **(auto)** ⚡ Bloque D: Árboles de decisión, templates SQL, scoring de confianza, Engram-first, feedback loop |

---

## Contexto del Equipo

### Proyecto Jira principal
- **Proyecto por defecto:** GD986 ([GD-986] EO Emisión) — pero el power trabaja con **cualquier proyecto de la tribu**
- **Tablero GD986:** [Board 4660](https://jirasegurosbolivar.atlassian.net/jira/software/c/projects/GD986/boards/4660)
- **Epic ejemplo:** GD986-824 (Disponibilidad y Estabilidad) — **siempre preguntar al usuario qué epic usar**
- **Tipos de issue:** Historia, Error Productivo, Sub-tarea
- **Link type:** "Relacionado" (id: 10003)

### Tableros disponibles - Tribu Corex

| Tablero | ID | Proyecto | Tipo |
|---|---|---|---|
| TableroGD980 | 4524 | GD980 | kanban |
| TableroGD981 | 4525 | GD981 | kanban |
| TableroGD982 | 4526 | GD982 | kanban |
| TableroGD983 | 4527 | GD983 | kanban |
| TableroGD984 | 4626 | GD984 | scrum |
| TableroGD986 | 4660 | GD986 (Emisión) | kanban |
| TableroGD987 | 4661 | GD987 | kanban |
| TableroGD988 | 4793 | GD988 | kanban |
| Tablero GD989 | 5293 | GD989 | kanban |

> **Nota:** El tablero por defecto es GD986 (Emisión), pero el agente puede trabajar con cualquier tablero de la tribu según lo indique el usuario.

### Base de Conocimiento
- **Confluence Page ID:** 1677787138
- **URL:** https://jirasegurosbolivar.atlassian.net/wiki/spaces/BDCT/pages/1677787138
- **Ubicación:** Tribu de CoreX → Base de Conocimiento - Agente N3 Corex
- Se actualiza automáticamente con hallazgos de incidentes resueltos
- Contiene diccionario de datos, patrones de problemas, y referencias cruzadas

#### Módulos documentados (páginas hijas)

| Módulo | Page ID | Prefijo |
|---|---|---|
| Parámetros Generales y Terceros | 1677885457 | A1xxx |
| Emisión | 1679654913 | A2xxx |
| Siniestros e Indemnizaciones | 1678475266 | A4xxx |
| Tesorería y Recaudo | 1678311427 | A5xxx |
| Reaseguros | 1679556610 | A8xxx |
| Fondos Vida | 1677819908 | A9xxx |
| VPA Fondos | 1678311447 | SB_xxx |

Para consultar un módulo específico: `confluence_get_page(page_id="ID", convert_to_markdown=true)`

### Campos obligatorios para crear Historias en GD986

| Campo | ID | Formato |
| --- | --- | --- |
| Tipo trabajo | customfield_13801 | `{"value": "Funcional"}` |
| Criterios aceptación | customfield_10332 | ADF (ver abajo) |
| Aplicación CMDB | customfield_31136 | CMDB object (ver abajo) |
| Parent (Epic) | parent | `"<EPIC_KEY>"` — **preguntar al usuario** |

**Formato ADF para criterios:**
```json
{"version": 1, "type": "doc", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "CA1: ..."}]}]}
```

**CMDB Tronador:**
```json
[{"workspaceId": "07e9b295-4dbf-4d90-a54e-3498d6f16eb4", "id": "07e9b295-4dbf-4d90-a54e-3498d6f16eb4:419497", "objectId": "419497"}]
```

### Confluence
- **Espacio:** BDCT (Vicepresidencia de TI)
- **Página padre para HUs Corex:** ID 1441136649
- **Template:** Ver steering `template-confluence.md`

---

## Agente de Diagnóstico (Sub-agente)

El power incluye un **sub-agente especializado** en diagnóstico profundo de incidentes que se instala globalmente en `~/.kiro/agents/`.

### Uso

Desde cualquier workspace, invocar con:
```
Diagnostica el caso MDSB-XXXXX
```

### Qué hace

1. Busca diagnósticos previos en **Engram** (memoria persistente)
2. Carga la KB de Confluence
3. Obtiene el caso Jira completo
4. Consulta Oracle (datos + código fuente PL/SQL)
5. Verifica dependencias
6. Busca casos relacionados
7. Produce un reporte estructurado con causa raíz

### Archivos

| Archivo | Propósito |
|---|---|
| `agents/corex-incident-diagnostics.json` | Configuración (MCP servers, tools, resources) |
| `agents/corex-incident-diagnostics.md` | Instrucciones completas del agente |
| `agents/corex-incident-diagnostics.prompt.md` | System prompt condensado |

### Diferencia con el power principal

| Aspecto | Sub-agente | Power corex-n3 |
|---|---|---|
| Alcance | Solo diagnóstico | Ciclo completo (diagnóstico + HU + docs + tiempos) |
| Invocación | "Diagnostica el caso..." | "Atiende el caso..." |
| Shortcut | `Ctrl+Shift+D` | — |

---

## Memoria Persistente (Engram)

El power integra **Engram** como memoria persistente entre sesiones. Se instala automáticamente con el script `install.sh`.

### Qué guarda

- Diagnósticos de incidentes resueltos (causa raíz + solución)
- Patrones Oracle descubiertos
- Queries útiles reutilizables
- Decisiones técnicas del equipo

### Sincronización con Confluence

- **Engram** = caché local rápida (consulta instantánea)
- **Confluence** = fuente canónica del equipo (permanente)
- Al resolver un incidente → se guarda en Engram + se propone subir a Confluence

### Steering global

El archivo `steering-global/engram-knowledge-sync.md` se instala en `~/.kiro/steering/` y aplica la política de memoria en cualquier workspace.


### Oracle Tronador

**Esquema principal: `OPS$PUMA`** — Todas las tablas de negocio están aquí. Los usuarios de conexión (DEV_XXXXXXXXXX) son cuentas individuales con grants. SIEMPRE usar `schema="OPS$PUMA"` en `describe_table` y `list_tables`, y filtrar por `owner = 'OPS$PUMA'` en queries de metadatos.

| Ambiente | Host | Disponibilidad |
| --- | --- | --- |
| Dev | 10.1.2.76:1521/tron | ✅ Siempre |
| Stage | 10.7.2.14:1521/tron | ⚠️ Puede fallar (thin mode) |
| Prod | Configurar por usuario | 🔒 Deshabilitado por defecto |

**Tools disponibles (MCP oracle-readonly):**

| Tool | Descripción |
|---|---|
| `query` | Ejecuta SELECT de solo lectura (máx 500 filas) |
| `list_tables` | Lista tablas de un esquema |
| `describe_table` | Describe columnas de una tabla |
| `list_schemas` | Lista esquemas disponibles |
| `get_source` | Lee código fuente PL/SQL (packages, procedures, functions, triggers) |
| `search_objects` | Busca objetos por nombre parcial en ALL_OBJECTS |
| `get_dependencies` | Obtiene dependencias de un objeto (quién lo usa / a quién usa) |

**Tablas principales:**

| Tabla | Descripción |
| --- | --- |
| `A2000030` | Pólizas (cabecera, 18 triggers) |
| `A2000020` | Riesgos |
| `A2000040` | Coberturas |
| `A2000160` | Primas |
| `A2000163` | Facturas |
| `A2990700` | Facturación/cuotas |
| `SB_RECAUDO` | Recaudos VPA |
| `SB_CONVENIO` | Débito automático |

---

## Workflows principales

### 1. Atención de incidente (ciclo completo)

> 🚀 **Modo autónomo:** Decir "atiende el caso MDSB-XXXXX" ejecuta las fases 0-9 automáticamente.
> Ver steering `atencion-incidente-autonomo.md` para el detalle de cada fase.

```
 CONTEXTO (Fase 0 — autónomo)
 ────────
 0. Consultar Base de Conocimiento (confluence_get_page, page_id: 1677787138)
    → Revisar patrones conocidos, tablas relevantes, lecciones aprendidas

 DIAGNÓSTICO (Fase 1 — autónomo)
 ────────
 1. Recibir caso MDSB-XXXXX
 2. Consultar Jira (descripción, comentarios, vínculos)
 3. Buscar Confluence (runbooks, documentación relacionada)
 4. Consultar Oracle (datos póliza, facturas, recaudos)
 5. Validar DeudaService (si el caso lo menciona)
 6. Buscar casos Jira relacionados
 7. Comparar con patrones conocidos de la KB
 8. Identificar causa raíz

 DOCUMENTACIÓN (Fase 2-3 — autónomo)
 ─────────────
 9.  Documentar hallazgos en Confluence (template estándar)
 10. Crear Historia en GD986 + vincular MDSB + vincular Confluence
 11. Crear Sub-tarea "Análisis" + registrar tiempo

 REQUERIMIENTOS (bajo demanda)
 ──────────────
 12. Generar documento de requerimientos (spec) con:
     - Comportamiento actual (defecto)
     - Comportamiento esperado (correcto)
     - Comportamiento sin cambios (regresión)
     - Guía de pruebas unitarias

 IMPLEMENTACIÓN (bajo demanda)
 ──────────────
 13. Crear rama en Git desde master (nombre = Jira principal, ej: GD986-1254)
 14. Realizar cambios PUNTUALES en los archivos afectados
     ⚠️ NUNCA reemplazar el archivo completo — solo las líneas que cambian
     📦 Si el fix requiere exponer un SP como servicio REST, usar #new-feature-guide o #scaffolding-microservicio
 15. Commit con mensaje: "GD986-XXXX: [descripción corta del cambio]"
 16. Crear Sub-tarea "Desarrollo" + registrar tiempo

 PRUEBAS (bajo demanda)
 ───────
 17. Ejecutar pruebas unitarias según la guía generada en paso 12
 18. Documentar evidencia de pruebas
 19. Crear Sub-tarea "Pruebas" + registrar tiempo

 ENTREGA (bajo demanda)
 ───────
 20. Push de la rama al repositorio
 21. Crear Pull Request hacia dev (desde GitHub web o gh CLI)
     - Título: "GD986-XXXX: [descripción]"
     - Descripción: link a Confluence + criterios de aceptación
 22. Solicitar revisión de pares
```

### 2. Convenciones de Git

| Regla | Detalle |
| --- | --- |
| Rama base | Siempre desde `master` |
| Nombre de rama | Jira principal (ej: `GD986-1254`) |
| Commits | `GD986-XXXX: descripción corta` |
| Cambios | Solo líneas afectadas, NUNCA archivo completo |
| PR destino | `dev` |
| PR título | `GD986-XXXX: descripción` |
| PR descripción | Link Confluence + criterios aceptación |

⚠️ **IMPORTANTE:** Nunca reemplazar un archivo `.pkb` o `.prc` completo. Siempre hacer cambios puntuales (las líneas específicas que se modifican). Reemplazar archivos completos genera conflictos con otros desarrolladores que trabajan en el mismo paquete.

### 3. Registro de tiempos

```
- Tiempo SIEMPRE en Sub-tareas (nunca en Historia)
- Sub-tarea con estimación (originalEstimate)
- Worklog con descripción de lo realizado
- Al final de cada sesión: recordar registrar
```

### 4. Gestión de backlog

```
1. Traer casos con JQL (lotes de 45)
2. Categorizar y encontrar duplicados
3. Generar CSV de seguimiento
4. Cerrar duplicados con comentario + vínculo al padre
```

---

## Microservicios con Adaptador V3

### Qué es el Adaptador V3

El Adaptador V3 es un API Gateway que permite a microservicios Java/Spring Boot 3 ejecutar procedimientos almacenados Oracle vía HTTP/JSON con autenticación OAuth2. El microservicio NO se conecta directamente a Oracle.

```
Controller → Service → CoreService → Repository (Adapter) → DatabaseAdapterV3Client → API Gateway → Oracle SP
```

### Capacidades

| Capacidad | Steering file | Invocación |
|---|---|---|
| Crear microservicio desde cero | `scaffolding-microservicio.md` | `#scaffolding-microservicio` |
| Agregar nueva operación/endpoint | `new-feature-guide.md` | `#new-feature-guide` |
| Consultar estándares de implementación | `estandares-adapter-v3.md` | `#estandares-adapter-v3` |

### Regla Fundamental: Jakarta EE

⚠️ Las librerías internas de Bolívar (`bolivar-core-error-handling-starter`, `bolivar-centralizador-logs`) fueron compiladas contra Spring Boot 2.x (javax.*). Spring Boot 3 usa jakarta.*. Las siguientes reglas son OBLIGATORIAS:

1. **Exclusiones en build.gradle**: Siempre excluir `javax.servlet`, `javax.validation`, `javax.annotation` y `org.springdoc` de las librerías internas.
2. **@AccessBolivarLogger**: NO usar. Registrar `BolivarLogger` manualmente en `BolivarLoggerConfig`.
3. **ComponentScan**: Excluir `com.bolivar.centralizador.logs.config.*` con `FilterType.REGEX`.
4. **management.health.db.enabled=false**: Obligatorio (sin conexión JDBC directa).
5. **SP públicos**: Verificar que el procedimiento Oracle esté en la especificación del paquete (no solo en el body).

### Stack Tecnológico

| Tecnología | Versión |
|---|---|
| Java | 17 |
| Spring Boot | 3.2.12 |
| Gradle | 8.12 (via Wrapper) |
| JUnit | 5 |
| springdoc-openapi | 2.3.0 |
| JaCoCo | 0.8.11 |
| Lombok | (BOM Spring Boot) |
| MapStruct | 1.5.5 |

### Flujo: Nuevo servicio que expone un SP

1. Identificar el procedimiento Oracle (package, procedure, parámetros IN/OUT) — usar `get_source` del MCP oracle-readonly
2. Verificar que el SP esté en la ESPECIFICACIÓN del paquete (no solo en el body)
3. Invocar `#scaffolding-microservicio` si es un microservicio nuevo, o `#new-feature-guide` si se agrega a uno existente
4. Seguir el checklist de `#estandares-adapter-v3` para la implementación
5. Documentar en Confluence y crear Historia en Jira (workflow estándar del equipo)

---

## Troubleshooting

### Regla Crítica: Análisis de Impacto

⚠️ **OBLIGATORIO:** Antes de sugerir CUALQUIER cambio en código PL/SQL (paquetes, procedimientos, funciones, triggers), se DEBE:

1. Consultar dependencias en Oracle (`all_dependencies`)
2. Buscar referencias en el repositorio local
3. Verificar triggers en tablas afectadas
4. Presentar resumen de impacto al usuario ANTES de proceder
5. Consultar la Base de Conocimiento (Confluence ID: 1677787138) para patrones conocidos

Ver steering `analisis-impacto.md` para el procedimiento completo.

### Regla: Consultar Base de Conocimiento

Antes de consultar tablas desconocidas o trabajar con procesos nuevos, SIEMPRE:
1. Consultar la Base de Conocimiento en Confluence (ID: 1677787138)
2. Si la tabla no está documentada, buscar en `OPS$PUMA.A1000000`
3. Actualizar la Base de Conocimiento con hallazgos nuevos

### "invalid peer certificate: UnknownIssuer"
El Power ya usa `UV_NATIVE_TLS=true` que debería resolver esto automáticamente. Si persiste:
- **macOS:** Verificar que Netskope esté activo y el certificado `ca.segurosbolivar-co.goskope.com` esté en Keychain
- **Windows:** Verificar que el certificado corporativo esté en "Trusted Root Certification Authorities"
- **Linux:** Agregar el certificado a `/etc/ssl/certs/` o configurar `SSL_CERT_FILE`

### "El valor de la operación debe ser un documento de Atlassian"
Campo `customfield_10332` necesita formato ADF, no texto plano.

### "DPY-3015: password verifier type not supported in thin mode"
BD stage no soporta thin mode. Usar BD dev (oracle-readonly).

### "No se encontró un tipo de enlace con el nombre 'Relates to'"
Jira está en español. Usar `"Relacionado"` (no "Relates to").

### "Criterios de aceptación es obligatorio" / "Aplicación Impactada - CMDB es obligatorio"
Ver sección "Campos obligatorios" arriba. Ambos campos deben ir en `additional_fields`.

### El server de Oracle no conecta
- Verificar que estés en la VPN corporativa
- Verificar usuario/contraseña Oracle
- Dev (10.1.2.76) es el más estable; stage (10.7.2.14) puede fallar
