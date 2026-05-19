# Arquitectura y Diseño — Engram Export

> Exportado: 2026-05-15 | Proyectos: corex-n3-power (9), simon-cotizadores-core-wl (10), tronador-oracle-db (128)

---

## #138 — Librerías JFrog vs Microservicios: dominios distintos, steerings separados

**Tipo:** architecture | **Fecha:** 2026-05-15 | **Proyecto:** corex-n3-power

**What**: Librerías (JFrog) y Microservicios (ECS) son dominios completamente distintos que requieren steerings separados.
**Why**: Usan templates de pipeline diferentes, estructuras de proyecto diferentes, y flujos de versionamiento diferentes.
**Where**: steering/publicacion-librerias-jfrog.md (nuevo) vs steering/scaffolding-microservicio.md (existente)
**Learned**: Templates: Librerías → devops-actions-library-templates | MS → devops-actions-microservices-monorepo-templates. Estructura: Librerías → single-module obligatorio | MS → multi-módulo monorepo (apis/{nombre-ms}/). Artefacto: Librerías → JAR en JFrog Artifactory | MS → Docker image en ECR → ECS Fargate. Criterio separación: si usan templates, estructuras y flujos de versionamiento diferentes → steerings separados aunque compartan tecnología base (Gradle, Java).

---

## #84 — Librería transversal bff-common — simon-ventas-lib

**Tipo:** architecture | **Fecha:** 2026-05-14 | **Proyecto:** simon-cotizadores-core-wl | **Topic:** architecture/shared-library

**What**: Librería transversal bff-common extraída a repo independiente simon-ventas-lib

**Why**: Para que múltiples BFFs de Simon Ventas (autos, vida, hogar) consuman la misma librería como dependencia Gradle desde JFrog

**Where**: Repo `segurosbolivar/simon-ventas-lib`, branch `v1.0.0-release`

**Contenido de bff-common**:
- Auth: LdapAuthAdapter, SimulationAuthAdapter, SeguridadSoapAdapter, JwtUtil, JwtAuthFilter, SecurityConfig, AuthController
- Config: CorsConfig, GlobalExceptionHandler, RestClientConfig
- SOAP: SoapHelperBase (parseo XML genérico + DataHeader builder)
- Ports: CatalogBackendPort, DocManagementPort, SarlaftBackendPort, LdapAuthPort, SeguridadBackendPort
- Adapters REST: DocManagementRestAdapter, SarlaftRestAdapter
- Adapters SOAP: CatalogSoapAdapter
- Strategy: ProductCaseStrategy + BaseProductCaseStrategy (patrón para gestión documental por producto)
- DTOs: SarlaftRequest/Response, CrearCaseRequest/Response, GenerarUrlRequest/Response, etc.

**Publicación**:
- Group: `com.segurosbolivar.simon.ventas`
- Artifact: `bff-common`
- Version: `1.0.0-SNAPSHOT`
- Repo JFrog: `commons-gradle-simon-ventas-{dev|stage|prod}-local`
- Pipeline: `devops-actions-library-templates@v2.0.0` (pendiente config DevOps: cambiar npm→gradle, secrets AWS)

**Cómo consumir desde un BFF**:
```kotlin
implementation("com.segurosbolivar.simon.ventas:bff-common:1.0.0-SNAPSHOT")
```
Mientras tanto usar `publishToMavenLocal` + `mavenLocal()` para desarrollo local.

**Learned**: El pipeline del repo nuevo tenía language_package_manager=npm (incorrecto). DevOps debe cambiarlo a gradle y configurar secrets AWS. Sonar quality gate: 92% coverage, 0 vulnerabilidades.

---

## #83 — Flujo legacy SimonQuotation — referencia para paridad

**Tipo:** architecture | **Fecha:** 2026-05-14 | **Proyecto:** simon-cotizadores-core-wl | **Topic:** architecture/legacy-flow

**What**: Flujo del legacy SimonQuotation para cotización de autos

**Why**: Referencia para mantener paridad funcional en la migración

**Where**: src/main/webapp/ y src/main/java/ en simon-cotizadores-core-wl

**Flujo Legacy (Struts)**:
1. `autosHome.jsp` + `autosinicioNew.js` — Búsqueda por placa o marca. Llama DWR (Direct Web Remoting) a Java
2. `autosQuote.jsp` + `autosquoteNew.js` — Formulario de cotización (un solo JSP con tabs/secciones)
3. `autosQuoteViewNew.jsp` — Vista de cotización generada
4. `autosFormalizationCreateNew.jsp` + `autosFormalizationCreateNew.js` — Emisión/formalización

**Capas Java Legacy**:
- `com.segurosbolivar.dwr/` — Servicios DWR (Ajax desde JSP)
- `com.segurosbolivar.facadeImpl/` — Facades que llaman servicios SOAP
- `com.segurosbolivar.action/` — Struts Actions
- `com.segurosbolivar.form/` — Struts ActionForms

**Servicios SOAP del legacy (mismos que usa el BFF nuevo)**:
- InspeccionAutosService — obtenerInspeccionVig, obtenerInspeccionVigPlaca
- ListasService — obtenerCatalogoDatos, obtenerMarcasVehiculo, obtenerSubproductos
- AutosService — liquidarCotizacion, cotizarPoliza, obtenerPDF, enviarSMS
- FasecoldaService — obtenerCodigoFasecolda
- TercerosService — obtenerTercero, crearTercero
- SeguridadService — validarTipoUsuario

**Learned**: El legacy usa DWR (Direct Web Remoting) para Ajax — es como un RPC desde JavaScript a Java. El BFF nuevo reemplaza esa capa con REST endpoints que llaman los mismos servicios SOAP.

---

## #80 — Estructura de repositorios y despliegue

**Tipo:** architecture | **Fecha:** 2026-05-14 | **Proyecto:** simon-cotizadores-core-wl | **Topic:** architecture/repo-structure

**What**: Estructura de repositorios y despliegue del cotizador de autos

**Why**: Necesario para entender dónde vive cada pieza y cómo se despliega

**Where**: Múltiples repos en GitHub `segurosbolivar/`

**Repositorios**:
- `simon-cotizadores-core-wl` — Monorepo de DESARROLLO (legacy + Angular + BFF + libs). Branch principal: `migrate/autos-production`
- `simon-ventas-autos-frontend` — Repo de DEPLOY del frontend Angular. Pipeline: S3 + CloudFront
- `simon-ventas-autos-ms` — Repo de DEPLOY del BFF Spring Boot. Pipeline: ECS Fargate
- `simon-ventas-lib` (nuevo) — Librería transversal `bff-common` extraída. Pipeline: JFrog Artifactory (pendiente config DevOps)

**Estructura del monorepo**:
```
simon-cotizadores-core-wl/
├── src/main/webapp/          ← Legacy Struts (JSPs, JS, tags)
├── src/main/java/            ← Legacy Java (Actions, Facades, DWR)
├── autos-quotation/          ← Angular 17 SPA
├── autos-quotation-bff/      ← BFF Spring Boot
├── libs/cotizador-core/      ← Lib Angular compartida
└── libs/bff-common/          ← Lib Java compartida (extraída a simon-ventas-lib)
```

**Learned**: El monorepo es solo para desarrollo. Para deploy se copian los artefactos a repos separados. La lib transversal se publicó como paquete Gradle en JFrog para que otros BFFs la consuman como dependencia.

---

## #79 — Proyecto GD903 — Migración Cotizador Autos

**Tipo:** architecture | **Fecha:** 2026-05-14 | **Proyecto:** simon-cotizadores-core-wl | **Topic:** architecture/project-overview

**What**: Migración del cotizador de seguros de autos desde Java/Struts (SimonQuotation legacy) a una SPA Angular 17 + BFF Spring Boot 3.3.5 (Java 21, Gradle 8.10).

**Why**: El legacy es un monolito Struts con JSPs que no escala, es difícil de mantener y no permite UX moderna. El proyecto GD903 busca reemplazarlo con una arquitectura moderna manteniendo paridad funcional.

**Where**: Monorepo `segurosbolivar/simon-cotizadores-core-wl` (branch: `migrate/autos-production`)

**Arquitectura**:
- Frontend: Angular 17 standalone components + NgRx store + Design System sb-ui
- BFF: Spring Boot 3.3.5 con arquitectura hexagonal (Ports & Adapters)
- Integración: SOAP via WebServiceTemplate (InspeccionAutos, Listas, Autos, Fasecolda, Terceros)
- Auth: LDAP corporativo + JWT cookie (sb_session) + external-redirect desde portal intranet
- Librería transversal: `libs/bff-common/` (ahora extraída a repo independiente `simon-ventas-lib`)

**Flujos principales**:
1. Búsqueda vehículo (placa o Fasecolda)
2. Multi-step: Tomador → Vehículo → Coberturas → Deducibles → Conductor → Beneficiarios → Documentación → Resumen
3. Cotización con PDF
4. Emisión de póliza (SARLAFT + documentación FileNet)

**Learned**: El BFF NUNCA llama Oracle directamente — todo pasa por servicios SOAP legacy. Angular nunca llama SOAP — todo pasa por el BFF REST.

---

## #125 — CRX_PROCESO_REPORTE_FACTURACION — paquete optimizado alternativo con switch

**Tipo:** architecture | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/crx-proceso-reporte-facturacion

**What**: CRX_PROCESO_REPORTE_FACTURACION es una versión optimizada del paquete original creada por Brayan Gamez (GD1129-113, GD1129-117). Se activa con switch C9999909 COD_TAB='PRCS_RPT_FCTRCN' DAT_CAR='CONSULTA_DEUDA' DAT_CAR2='F'. Actualmente el switch está en 'O' (usa el original).

**Why**: Necesario saber que cualquier fix en proceso_reporte_facturacion debe replicarse en CRX para cuando se active el switch.

**Where**: Package CRX_PROCESO_REPORTE_FACTURACION (OPS$PUMA), última modificación 13-may-2026.

**Learned**:
- Elimina del flujo principal: SOAT boletas (tipo_op 5), provisorias, multi-compañía, agrupadas
- Optimiza con BULK COLLECT más agresivo y elimina SQL dinámico redundante en préstamo digital
- Mantiene misma interfaz (types compatibles) — switch puede alternar sin romper contrato
- GD986-1278 y GD986-1306 NO están replicados en CRX — riesgo si se activa switch
- Autor: Brayan Gamez (brayan.gamez@samtel.eu) — DigitalProf-IT
- Tiene función TRAEVERSION_FUN para control de versión

---

## #124 — Mapa completo flujos consulta deuda Pago en Línea — 8 escenarios identificados

**Tipo:** architecture | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/proceso-reporte-facturacion-deuda-flujos

**What**: Análisis exhaustivo del paquete PROCESO_REPORTE_FACTURACION identificó 8 flujos de consulta de deuda para canal 1 (Pago en Línea) y 8 escenarios de falla potencial.

**Why**: 30+ casos en backlog de "Servicio de Deuda" — QA reporta que GD986-1278 no cubre todos los escenarios.

**Where**: Package PROCESO_REPORTE_FACTURACION (body), funciones fnc_sqlprimer*, fnc_tomar_FormaCobro, fnc_tomar_poliza, fnc_estadofactura. Switch en C9999909 COD_TAB='PRCS_RPT_FCTRCN'.

**Learned**:
- 8 flujos: facturas A2990700, VPA RPR, ahorro extra REX, débito SB_CONVENIO, multi-CIA, agrupadas, cotizaciones, provisorias
- GD986-1278 solo cubre flujos 2/3/4 (VPA) — condición OR VALOR_FPU!=0 AND VALOR_RIESGO=0
- GD986-1306 filtro exclusión solo en fnc_sqlprimer, falta en fnc_sqlprimer_poliza y fnc_sqlpoliza_polflot
- Switch PRCS_RPT_FCTRCN puede redirigir a crx_proceso_reporte_facturacion (modo 'F') — si activo, fixes en paquete original no aplican
- fnc_tomar_FormaCobro retorna 'N' si canal_descto es NULL en A2000060 (excluye pólizas DB silenciosamente)
- C1991801 con mca_re=1 y cod_estado=1 es prerequisito para que un producto aparezca
- Ventana 720 días configurable en C9999909 'DIAS_POLIZAS_PE'
- fnc_estadofactura excluye facturas con mca_estado='P' en A2000163

---

## #89 — Flujo completo facturación: AB100277 (COBOL + PL/SQL) como orquestador

**Tipo:** architecture | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: Confirmado que AB100277 existe en dos versiones coexistentes: el COBOL legacy (AB100277.pco) y el PL/SQL moderno (SIM_PCK299_AB100277). Ambos son el orquestador principal de generación de facturas para endosos.

**Why**: Para el caso MDSB-992543, necesitábamos confirmar qué programa genera la factura 12 (periódica) y la factura 13 (exclusión). Ambas pasan por AB100277.

**Where**: 
- tronador-core-cobol/AB100277.pco (COBOL batch)
- Base Datos/Packages/SIM_PCK299_AB100277.pkb (PL/SQL)

**Learned**:
- El PL/SQL dice en su header "Reemplaza al AB100277.pco" pero el COBOL sigue existiendo
- Flujo PL/SQL: PRC_INICIO → PRC_LECTUNICA → PRC_PROCESO → PRC_LEE160 → decide subproducto (367→AB100273, 368/370→AB100273_RC) → PRC_PREMIO → PRC_CUOTAS → PRC_DIFERIDO
- PRC_DIFERIDO se ejecuta cuando: PERIODOFACT=1 AND CODSECC=1(Autos) AND NUMEND>0 AND TIPOEND!='MV'
- PRC_INS270 crea el registro de exclusión en C1000270 (valores negativos, EXCLUSION='S') para riesgos con MCA_BAJA_RIES='S'
- El COBOL tiene la misma lógica en párrafo 6000-BUSCA-DIFERIDO (línea 1985)
- Para Autos ramo 250: si subproducto IN (368,370) → usa AB100273_RC, sino → usa AB100273 estándar
- La condición de diferidos en el COBOL (línea 690): IF PERIODOFACT=1 AND CODSECC=1 AND NUMEND>0 AND TIPOEND!='MV'

---

## #61 — Flujo exclusión autos: Form AC100731 → SIM_PCK_ANULACIONENDOSO → PROC_GENERA_FACTURA

**Tipo:** architecture | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

**What**: Descubierto que la exclusión del riesgo 662 (endoso 16) se ejecuta via SIM_PCK_ANULACIONENDOSO.PROC_PASO_REALES_ANULAENDOSO, NO directamente desde el form AC100731
**Why**: Para trazar el flujo completo de facturación del caso MDSB-992543 y entender por qué la fórmula no reproduce el monto
**Where**: Base Datos/Packages/SIM_PCK_ANULACIONENDOSO.pkb (línea 491), Form AC100731.fmt
**Learned**:
1. Form AC100731 (cod_end 731) NO contiene lógica de facturación — solo graba datos del endoso
2. El flujo real es: Form → SIM_PCK_ANULACIONENDOSO.PROC_PASO_REALES_ANULAENDOSO → UPDATE MCA_TERM_OK='S' → PROC_GENERA_FACTURA → AB100277 → AB100273
3. ANTES de facturar, el paquete hace: UPDATE A2000030 SET MCA_END_ANU='S', CANT_CUOTAS=1 en el endoso que se anula (13)
4. También llama a PROC_RIESGOS_REVERSADOS y PROC_COPIADATOSFIJOS_SIM_A_A que pueden modificar datos en A2000160
5. El endoso 16 es una ANULACIÓN del endoso 13 (no una exclusión independiente) — IP_NUMENDANULA=13, IP_NUMEND=16
6. SIM_SUBPRODUCTO = 367 (no 368/370) → confirma que va por AB100273 (no AB100273_RC)
7. El trigger SIM_TRG_AU_A2000030 NO genera factura — solo sincroniza datos

---

## #55 — Flujo completo facturación endosos: fórmula v_CoefFact y prc299_obtengo_vto_fact

**Tipo:** architecture | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

**What**: Rastreo completo del flujo de facturación de endosos en Tronador — desde la entrada hasta el INSERT en A2000163
**Why**: Diagnosticar MDSB-992543 (diferencia primas factura 12 vs 13)
**Where**: PRC299_OBTENGO_VTO_FACT.prc, SIM_PCK299_AB100273.pkb (prc_CalcCoeficiente, prc_PeriodoCorto, prc_InsNormal), SIM_PCK299_COMUNFACT.pkb
**Learned**:
1. Flujo: prc_Inicio → prc_VenctoNew → prc299_obtengo_vto_fact → prc_CalcCoeficiente → prc_Proceso → prc_Premios → prc_InsNormal
2. prc299_obtengo_vto_fact toma MAX(FECHA_VTO_FACT) de facturas anteriores con NUM_END_REF < numend actual
3. Fórmula: IMP_PRIMA = ROUND(IMP_PRIMA_END * v_CoefFact, 0)
4. v_CoefFact para periodo!=12: (MB(Vto,Vig)*30 - MesAcum) / ((MB(Vto,Vig)*30) + (MB(VencPol,Vto)*30))
5. COD_DURACION=2 → prc_PeriodoCorto (v_CoefPol = MB(Vto,Vig)/12)
6. COD_DURACION=1 → prc_PorDias (v_CoefPol = (Vto-Vig)/(VencPol-VigPol))
7. Para tipo AP: prc_VerificaPrima NO se llama, v_MesAcum queda en 0
8. NVL(mca_end_dtot,'N') en COMUNFACT — NULL se trata como 'N'

---

## #50 — Flujo facturación endosos Tronador: AB100277 → AB100273 (coeficientes)

**Tipo:** architecture | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

**What**: Documentado el flujo completo de facturación de endosos en Tronador y las fórmulas de cálculo de coeficientes
**Why**: Para diagnosticar diferencias de primas entre facturas de cobro y devolución (caso MDSB-992543)
**Where**: Base Datos/Packages/SIM_PCK299_AB100273.pkb (prc_CalcCoeficiente línea 1324, prc_PorDias línea 1790, prc_VerificaPrima línea 1200)
**Learned**: 
1. Leer código desde el repositorio local es MUCHO más eficiente que get_source del MCP Oracle
2. El flujo de facturación: proc_genera_factura → SIM_PCK299_AB100277.PRC_INICIO → PRC_PROCESO → SIM_PCK299_AB100273.PRC_INICIO → prc_CalcCoeficiente + prc_PorDias
3. v_CoefFact = proporción del período de factura respecto a vigencia restante
4. v_CoefPol = (días factura) / (días vigencia póliza) — calculado en prc_PorDias
5. prc_VerificaPrima acumula meses de facturas con estado 'P' que se solapan — si ya están cobradas ('CT') no se descuentan
6. PRC_FACTANULLIB (que usa PRC299_FACTURA_ANULACION_GRUPO) solo se invoca para libranza o facturas anticipadas CC

---

## #25 — Bloque D implementado: diagnóstico eficiente — árboles de decisión, templates SQL, scoring, Engram-first

**Tipo:** architecture | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/efficiency-bloque-d

**What**: Se implementó el Bloque D de mejoras al power corex-n3 con 3 entregables:
1. Steering `diagnostico-eficiente.md` — 7 estrategias: Engram-first, cache KB, queries con JOINs, árboles de decisión por módulo (Emisión, Facturación, Recaudo, Siniestros), scoring de confianza (Alta/Media/Baja con profundización automática), templates SQL pre-armados, feedback loop post-diagnóstico
2. Hook `engram-first-diagnostic` — preToolUse que intercepta queries Oracle y recuerda buscar en Engram primero
3. Modificación a `atencion-incidente-autonomo.md` — integra Fase 0.1 (Engram-first), Fase 0.2 (cache KB), Fase 1.3 (árboles + templates), Fase 1.7 (scoring), Fase 5.3 (feedback loop)

**Why**: Reducir consumo de créditos MCP y mejorar efectividad de diagnóstico. El mayor ahorro viene de NO repetir trabajo (Engram-first) y de ir directo al punto (queries pre-armadas + árboles de decisión).

**Where**: powers/corex-n3/steering/diagnostico-eficiente.md, powers/corex-n3/steering/atencion-incidente-autonomo.md, .kiro/steering/diagnostico-eficiente.md, .kiro/hooks/engram-first-diagnostic.kiro.hook

**Learned**: Los árboles de decisión son el mecanismo más efectivo para evitar consultas exploratorias. Los templates SQL con JOINs reducen de 4 llamadas a 1-2. El scoring de confianza con profundización automática evita reportes incompletos sin gastar créditos innecesarios en casos claros.

---

## #24 — Diseño técnico: Automatización ciclo completo + Inteligencia colectiva

**Tipo:** architecture | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/automation-collective-intelligence

**What**: Se diseñó la implementación técnica de Automatización de Ciclo Completo e Inteligencia Colectiva.

**Automatización:**
- Bot de triaje: JQL para MDSB sin clasificar + Engram pattern match + labels automáticas. Limitación: Kiro no tiene cron, usar botón manual (userTriggered) o GitHub Action.
- Pre-diagnóstico: versión on-demand ("pre-diagnostica los pendientes") que hace diagnóstico ligero (Jira + Engram, sin Oracle profundo).
- Auto-link: al diagnosticar, jira_search agresivo por tabla/package/error + jira_create_issue_link automático si misma causa raíz.

**Inteligencia colectiva:**
- Engram sync: repo privado corex-engram-brain + engram sync --export/--import. Hook agentStop para export, update.sh para import.
- Score de patrones: topic_key consistente + mem_update con used_count. Promoción a Confluence cuando hit > N.
- Detección duplicados: Paso 0.5 en atencion-incidente-autonomo.md — mem_search + jira_search antes de diagnosticar.

**Prioridad de implementación:**
1. Detección duplicados (cambio en steering, sin infra nueva)
2. Auto-link (cambio en steering)
3. Engram sync (repo + scripts)
4. Bot triaje (hook userTriggered)
5. Score patrones (lógica en mem_update)
6. Pre-diagnóstico on-demand (nuevo comando)

**Where**: No implementado. Diseño técnico listo para sesiones paralelas.

**Learned**: Kiro no tiene cron nativo — para automatización periódica hay que usar GitHub Actions, launchd (macOS), o botones manuales (userTriggered hooks). Las mejoras de mayor impacto inmediato son las que solo requieren cambios en steering (duplicados, auto-link) sin infraestructura nueva.

---

## #22 — Bloque C implementado: Context7 + Retrospectiva + Índice COBOL/Forms

**Tipo:** architecture | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

**What**: Se implementó el Bloque C de mejoras al power corex-n3 con 3 componentes:
1. Steering `context7-microservices.md` — instruye al agente a consultar Context7 para docs actualizadas de Spring Boot/MapStruct/JUnit al generar microservicios
2. Sub-agente `corex-retrospective` — analiza últimos 30 días (Engram + Jira), identifica patrones repetidos, propone mejoras a KB y steering
3. Índice COBOL/Forms — hook `cobol-forms-lookup` + script `generate-source-index.sh` + steering `source-index-usage.md` para integrar repos hermanos al diagnóstico

**Why**: Completar la tercera fase de mejoras del power. Context7 reduce hallucinations al generar código Java. La retrospectiva automatiza el ciclo de mejora continua. El índice de fuentes permite diagnósticos más precisos con código COBOL/Forms.

**Where**:
- .kiro/steering/context7-microservices.md
- .kiro/steering/source-index-usage.md
- .kiro/agents/corex-retrospective.json
- .kiro/agents/corex-retrospective.md
- .kiro/agents/corex-retrospective.prompt.md
- .kiro/hooks/cobol-forms-lookup.kiro.hook
- .kiro/scripts/generate-source-index.sh
- .kiro/shared-knowledge/source-index.json

**Learned**:
- El workspace de Kiro está restringido al repo actual, no puede acceder a repos hermanos directamente. El script de índice se ejecuta manualmente.
- El hook postToolUse con regex `.*jira_get_issue.*` permite interceptar la lectura de casos y enriquecer con fuentes externas.
- Context7 IDs pueden variar, siempre usar resolve-library-id primero.

---

## #18 — Bloque B implementado: sub-agente implementation + Engram sync + métricas

**Tipo:** architecture | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

**What**: Se implementó el Bloque B de mejoras al power corex-n3 con 3 componentes:
1. Sub-agente `corex-implementation` — ciclo autónomo de implementación (rama, cambios PL/SQL, colisiones, PR)
2. Engram sync git-based — script export/import para compartir memorias entre compañeros
3. Métricas de uso — hook postToolUse + script de reporte con filtros por período

**Why**: Completar el roadmap de mejoras. El sub-agente permite implementar fixes sin salir de Kiro. El sync permite onboarding rápido de nuevos devs. Las métricas dan visibilidad del uso real.

**Where**: .kiro/agents/corex-implementation.* (3 archivos), .kiro/scripts/engram-sync.sh, .kiro/scripts/metrics-report.sh, .kiro/hooks/usage-metrics.kiro.hook, .kiro/hooks/session-end-metrics.kiro.hook, .kiro/shared-knowledge/

**Learned**: El sub-agente necesita acceso a write+shell para crear ramas y hacer commits. El hook postToolUse con regex amplio captura todas las herramientas MCP relevantes. El sync via Git es el approach más simple — no requiere infra adicional.

---

## #12 — Implementadas 3 mejoras: Skills + Hooks nativos + Knowledge Base

**Tipo:** architecture | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/power-improvements-implemented

**What**: Se implementaron 3 mejoras al power corex-n3: (1) Hooks nativos en el agente JSON (agentSpawn + stop), (2) 4 Skills globales con carga progresiva (oracle-diagnostics, jira-workflow, confluence-docs, adapter-v3), (3) Knowledge Base indexada con los 25 steering files del power.

**Why**: El power cargaba todo el contexto siempre. Con skills, solo se carga lo relevante al request. Con knowledgeBase, el agente busca semánticamente en vez de cargar archivos completos. Con hooks, Engram se integra automáticamente al ciclo de vida del agente.

**Where**: ~/.kiro/skills/ (4 carpetas con SKILL.md), ~/.kiro/agents/corex-incident-diagnostics.json (actualizado con hooks + includeMcpJson + knowledgeBase + skills), powers/corex-n3/skills/ (source para distribución), powers/corex-n3/install.sh (actualizado para copiar skills).

**Learned**: Skills usan frontmatter name+description para activación por coincidencia. El agente JSON soporta hooks nativos (agentSpawn, stop, preToolUse, postToolUse, userPromptSubmit). knowledgeBase con indexType 'best' y autoUpdate true re-indexa al spawn del agente. includeMcpJson: true hereda los MCP del settings/mcp.json sin redefinirlos en el agente.

---

## #3 — Agente de diagnóstico integrado al power corex-n3 con instalación automática

**Tipo:** architecture | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/power-agent-distribution

**What**: Se integró el sub-agente de diagnóstico (corex-incident-diagnostics) directamente al power corex-n3, con instalación automática vía install.sh. Se agregaron 3 archivos en `powers/corex-n3/agents/` y se actualizó el instalador para copiarlos a `~/.kiro/agents/` globalmente.

**Why**: Antes el agente vivía solo en ~/.kiro/agents/ del creador. Ahora cualquier compañero que instale el power obtiene automáticamente el agente + Engram + Context7 + steering global.

**Where**: powers/corex-n3/agents/ (3 archivos: .json, .md, .prompt.md), powers/corex-n3/steering-global/engram-knowledge-sync.md, powers/corex-n3/install.sh (actualizado), powers/corex-n3/POWER.md (documentación agregada).

**Learned**: Los Powers de Kiro no tienen un mecanismo nativo para distribuir agentes. La solución es incluir los archivos del agente en el source del power y que el install.sh los copie a ~/.kiro/agents/. El JSON del agente usa $HOME que se expande durante la instalación. También se agregó instalación automática de Engram (descarga binario Go desde GitHub releases según arch del sistema).

---
