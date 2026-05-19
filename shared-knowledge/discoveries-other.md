# Descubrimientos y Otros — Engram Export

> Exportado: 2026-05-15 | Proyectos: corex-n3-power (9), simon-cotizadores-core-wl (10), tronador-oracle-db (128)

---

## #146 — Publicación exitosa bff-common 1.1.0 — referencia de librería real en JFrog

**Tipo:** discovery | **Fecha:** 2026-05-15 | **Proyecto:** corex-n3-power

**What**: Se publicó exitosamente `com.segurosbolivar.simon.ventas:bff-common:1.1.0` en JFrog desde el pipeline de GitHub Actions. Es la primera librería Gradle del equipo publicada con éxito.
**Why**: Validación end-to-end del flujo documentado en steering publicacion-librerias-jfrog.md.
**Where**: Repo `segurosbolivar/simon-ventas-lib`, branch `v1.1.0-release`, repo JFrog `commons-gradle-simon-ventas-dev-local`
**Learned**: El flujo completo funciona: push a v*-release → pipeline validación (automático) → workflow_dispatch → artifactoryPublish → artefacto en JFrog. El step "Get Library Info" usa `mvn help:evaluate` para leer versión del pom.xml dummy. El composite action `gradle-publish@master` ejecuta `./gradlew artifactoryPublish` (NO `publish`).

---

## #142 — WorkflowFile.json para librerías: key es repository_url_upload

**Tipo:** discovery | **Fecha:** 2026-05-15 | **Proyecto:** corex-n3-power

**What**: En WorkflowFile.json para librerías, la key correcta es repository_url_upload (no repositoryUrl ni repository_url).
**Why**: El template de librerías busca esa key específica para saber dónde publicar el artefacto.
**Where**: WorkflowFile.json en raíz del repo de librería
**Learned**: El release_path debe apuntar a build/libs/{artifactId}-{version}.jar. Verificar siempre las keys exactas que espera el template — son diferentes entre template de librerías y template de microservicios.

---

## #141 — Plugin com.jfrog.artifactory 5.2.5 obligatorio para publicar librerías

**Tipo:** discovery | **Fecha:** 2026-05-15 | **Proyecto:** corex-n3-power

**What**: El plugin com.jfrog.artifactory version 5.2.5 es obligatorio en build.gradle.kts para librerías que se publican en JFrog.
**Why**: Sin él, la task artifactoryPublish no existe y el pipeline de publicación falla.
**Where**: build.gradle.kts de la librería, bloque plugins
**Learned**: Debe estar junto con maven-publish y java-library. El bloque artifactory{} configura contextUrl, repoKey, username/password desde properties de Gradle.

---

## #139 — Template librerías Gradle requiere pom.xml y package.json dummy

**Tipo:** discovery | **Fecha:** 2026-05-15 | **Proyecto:** corex-n3-power

**What**: El template de DevOps para librerías Gradle (devops-actions-library-templates@v2.0.0-branch) requiere archivos pom.xml y package.json dummy en la raíz del repo.
**Why**: El template lee versión y nombre de esos archivos aunque el build real sea Gradle. Sin ellos el pipeline falla con LIBRARY_NAME vacío.
**Where**: Raíz del repo de la librería
**Learned**: Son archivos obligatorios con contenido mínimo (solo version y artifactId/name). También requiere src/main/resources/.gitkeep porque el template intenta copiar .env ahí.

---

## #85 — Equipo, gestión y entorno de desarrollo

**Tipo:** config | **Fecha:** 2026-05-14 | **Proyecto:** simon-cotizadores-core-wl | **Topic:** config/team-and-environment

**What**: Equipo, gestión y convenciones del proyecto GD903

**Why**: Contexto organizacional para continuidad

**Where**: Jira GD903, GitHub segurosbolivar/

**Equipo**:
- Michael Espinosa (michael.espinosa@segurosbolivar.com) — Tech Lead
- Dev B — Gaps emisión/búsqueda (branch: feature/emision-gaps-dev-b)

**Jira**:
- Proyecto: GD903
- Epic: Migración Cotizador Autos
- Campos obligatorios: Tipo trabajo (Funcional), Criterios aceptación (ADF), CMDB (Tronador 419497)
- Tiempos: SIEMPRE en sub-tareas, nunca en la Historia

**Git**:
- Branch principal desarrollo: `migrate/autos-production`
- Branch Dev B: `feature/emision-gaps-dev-b`
- Commits: `feat(scope): descripción` o `fix(scope): descripción`
- Deploy frontend: copiar dist/ a simon-ventas-autos-frontend
- Deploy BFF: copiar jar a simon-ventas-autos-ms

**Entorno local**:
- Java 21 (SDKMAN zulu-21.0.5)
- Gradle 8.10.2 (SDKMAN)
- Node 18+ (para Angular)
- Certificado Netskope importado en JDK cacerts (obligatorio para HTTPS corporativo)
- Proxy Netskope intercepta services.gradle.org pero NO jfrog.io

**Learned**: El certificado SSL corporativo (Netskope/Grupo Bolívar) debe importarse manualmente al truststore de Java con keytool. Sin esto, Gradle no puede descargar dependencias.

---

## #136 — Publicación exitosa bff-common en JFrog — pipeline completo

**Tipo:** discovery | **Fecha:** 2026-05-15 | **Proyecto:** simon-cotizadores-core-wl

**What**: Se publicó exitosamente `com.segurosbolivar.simon.ventas:bff-common:1.1.0` en JFrog desde el pipeline de GitHub Actions.

**Why**: La librería transversal necesita estar en JFrog para que los BFFs la consuman como dependencia.

**Where**: Repo `segurosbolivar/simon-ventas-lib`, branch `v1.1.0-release`

**Learned**:
- El template `devops-actions-library-templates@v2.0.0-branch` tiene soporte incompleto para Gradle
- El composite action `gradle-publish@master` ejecuta `./gradlew artifactoryPublish` (NO `publish`)
- Requiere el plugin `com.jfrog.artifactory` (v5.2.5) en el build.gradle.kts
- Las credenciales se pasan como Gradle properties: `-Partifactory_user`, `-Partifactory_password`, `-Partifactory_url`, `-Prepository_url`
- El `WorkflowFile.json` usa `repository_url_upload` (no `repositoryUrl.dev.repository_url`) para el publish
- El step "Get Library Info" usa `mvn help:evaluate` para leer la versión (bug: no lee NAME para Gradle)
- Se necesita un `pom.xml` dummy para que lea la versión correctamente
- Se necesita `src/main/resources/` para que el template copie `.env`
- El proyecto debe ser single-module (no multi-módulo) para compatibilidad con el template
- Flujo: push a `v*-release` → pipeline validación (automático) → pipeline publicación (manual)
- Repo JFrog: `commons-gradle-simon-ventas-dev-local`

---

## #81 — Estado actual del desarrollo — mayo 2026

**Tipo:** discovery | **Fecha:** 2026-05-14 | **Proyecto:** simon-cotizadores-core-wl | **Topic:** progress/current-state

**What**: Estado actual del desarrollo del cotizador de autos (mayo 2026)

**Why**: Registro del progreso para continuidad entre sesiones

**Where**: Branch `migrate/autos-production` en simon-cotizadores-core-wl

**Completado**:
- ✅ Búsqueda por placa (SOAP InspeccionAutos + fallback SISA REST)
- ✅ Búsqueda por Fasecolda (marca/modelo)
- ✅ Formulario multi-step con stepper
- ✅ Step Tomador (búsqueda tercero, crear tercero)
- ✅ Step Vehículo (datos Fasecolda, accesorios, 0km)
- ✅ Step Coberturas (tabla alternativas de cotización)
- ✅ Step Deducibles (tabla comparativa, recalcular)
- ✅ Cotización SOAP (liquidar + cotizar)
- ✅ PDF descargable
- ✅ SMS con cotización
- ✅ Auth LDAP + JWT cookie + external-redirect
- ✅ SARLAFT (obtenerMarcas + generarUrl)
- ✅ Gestión documental (FileNet: crear caso, subir docs, notificar SQS)
- ✅ Librería transversal extraída a repo independiente (simon-ventas-lib)
- ✅ Sonar quality gate pasado (92% coverage)

**En progreso**:
- 🟡 Descuento técnico (WIP — último commit del equipo)
- 🟡 Pipeline de simon-ventas-lib (pendiente config DevOps: language_package_manager=gradle, secrets AWS)
- 🟡 Emisión completa (conductor habitual, beneficiarios, firma)

**Pendiente**:
- 🔲 Solicitud de código Fasecolda
- 🔲 Modificación de póliza
- 🔲 Consulta de pólizas existentes
- 🔲 Deploy a producción

**Learned**: El equipo tiene 2 devs activos. Dev B trabaja en gaps de emisión (branch feature/emision-gaps-dev-b). Los cambios recientes no tocan la lib transversal.

---

## #135 — FAU04 DIAN — baseImponible inconsistente en facturas con línea asistencia Bolívar

**Tipo:** discovery | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

**What**: Diagnóstico completo de rechazo DIAN regla FAU04 en facturación electrónica para pólizas ramo 250 (Nuevo Producto Automóviles) que tienen línea de Asistencia Bolívar. La causa raíz es un error en la división de bases imponibles: al calcular baseImponible de la línea principal (vehículo), el sistema le RESTA el valor de la asistencia ($332,653), cuando debería usar importePrima directamente como baseImponible (dado que tributo ZY tiene tasa 0).

Aritmética del error (póliza 1003612214101):
- valorSubTotalConversion = $2,103,257 (prima total)
- Línea 1: importePrima=$1,770,604, baseImponible=$1,437,951 (ERROR: $1,770,604 - $332,653 = $1,437,951)
- Línea 2: importePrima=$332,653, baseImponible=$332,653 (OK)
- SUM(baseImponible) = $1,770,604 ≠ $2,103,257 → DIAN rechaza con FAU04

El error está en SIM_PCK_FACTURA_ELECTRONICA al armar los items de factura: calcula baseImponible de línea 1 como (importePrima - prima_asistencia) en lugar de usar importePrima directamente.

**Why**: Pólizas 1003612215701 y 1003612214101 del tomador NIT 900232067 rechazadas repetidamente por DIAN desde 27-28/04/2026. Es un caso especial que solo afecta pólizas con línea de Asistencia Bolívar (recaudo a nombre de tercero).
**Where**: OPS$PUMA.SIM_PCK_FACTURA_ELECTRONICA (procedimiento PRC_WEBSERV_POST_FACTE — armado de itemsFactura), tabla SIM_FACTURA_ELECTRONICA, tabla SIM_LOG_FACTURA_E
**Learned**: 1) FAU04 = "Base Imponible distinto a suma de bases imponibles de líneas de detalle". 2) Solo afecta pólizas con 2 líneas (prima + asistencia Bolívar como recaudo a nombre de tercero). 3) El error es en la DIVISIÓN de bases, no en los datos del adquirente. 4) La diferencia siempre es exactamente el valor de la asistencia ($332,653). 5) El sistema reintenta diariamente sin éxito porque el cálculo siempre produce el mismo error.

---

## #132 — Factura electrónica estado EE - Regla FAU04 DIAN - error datos adquirente

**Tipo:** discovery | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

**What**: Pólizas 1003612215701 y 1003612214101 (ramo 250, producto 54292 - Nuevo Producto Automóviles) del tomador NIT 900232067 (Fundación Servicio de los Jesuitas para los Refugiados) tienen factura electrónica en estado EE (Error Operador) con mensaje "Regla: FAU04" de la DIAN. No se generó CUFE. Ambas facturas fueron rechazadas por la DIAN.
**Why**: Consulta de usuario para verificar estado de facturación electrónica en producción.
**Where**: OPS$PUMA.SIM_FACTURA_ELECTRONICA (IDs 57624883, 57683519), OPS$PUMA.A2000030, OPS$PUMA.A2990700
**Learned**: Regla FAU04 de DIAN = error en validación del adquirente (datos del tomador). Cuando múltiples pólizas del mismo tomador fallan con FAU04, el problema está en los datos del tercero (dirección, email, régimen tributario). Estado EE = requiere reproceso manual después de corregir datos.

---

## #129 — oracle-readonly NO es producción — requiere Jira para prod

**Tipo:** discovery | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

**What**: Se clarificó que el MCP server `oracle-readonly` apunta a un ambiente de desarrollo/QA, NO a producción. Para consultas en producción se debe crear un Jira con las queries.
**Why**: Se asumió incorrectamente que oracle-readonly era producción al buscar pólizas de facturación electrónica.
**Where**: Configuración MCP oracle-readonly y oracle-stage
**Learned**: Nunca asumir que oracle-readonly es producción. El flujo correcto para consultar producción es: 1) Preparar las queries, 2) Crear un Jira de solicitud, 3) Esperar ejecución. oracle-stage también es pre-producción.

---

## #127 — Escenario 1 Deuda — 3 causas raíz póliza no visible: C1991801 + fnc_tomar_FormaCobro + rehabilitadas

**Tipo:** discovery | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db | **Topic:** discovery/escenario1-deuda-poliza-no-visible-causas

**What**: Diagnóstico sistémico del Escenario 1 "Póliza no visible en Pago en Línea" — identificadas 3 causas raíz con datos cuantificados de producción.

**Why**: Plan de choque servicio de deuda — 30+ casos en backlog. Necesitamos resolver todos los escenarios, no solo VPA.

**Where**: Tabla C1991801 (parametrización productos habilitados), función fnc_tomar_FormaCobro en PROCESO_REPORTE_FACTURACION, tabla C9999909 (PARAM_PAGO_CC_PL, PROD_DB_LIBRANZAS), tabla A2000060 (canal_descto).

**Learned**:
- Causa A: 8 combinaciones sección/ramo con 668 facturas EP NO están en C1991801 — productos: Swiss Life (371), ARL (178), Tranquilidad Rural (36), Hogar Protección Total (339/23, 34 facturas), Desempleo, Vida Protección, Clase U, Protección Pagos
- Causa B: fnc_tomar_FormaCobro excluye forma cobro GP completamente (1,632 facturas prod 948 + 1,333 prod 727). DB solo pasa si canal_descto existe en A2000060 y cumple condiciones
- Causa C: Pólizas rehabilitadas cambian forma cobro a CC pero si ramo no está en C9999909.PARAM_PAGO_CC_PL → invisible
- Query diagnóstica clave: SELECT cod_cia, cod_secc, cod_ramo, COUNT(*) FROM a2990700 WHERE cod_situacion='EP' AND NOT EXISTS (SELECT 1 FROM c1991801...) GROUP BY... 
- Solución: Parametrización (INSERTs en C1991801 y C9999909) + posible ajuste código fnc_tomar_FormaCobro para GP
- IMPORTANTE: Validar con negocio cuáles productos SÍ deben aparecer — algunos (ARL, Colectivas) probablemente son intencionales

---

## #126 — 5 patrones de falla Servicio Deuda — clasificación casos Jira por escenario técnico

**Tipo:** discovery | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db | **Topic:** discovery/patrones-falla-servicio-deuda-clasificacion

**What**: Clasificación de 30+ casos de Servicio de Deuda en 5 patrones de síntoma distintos, mapeados a causas técnicas en PROCESO_REPORTE_FACTURACION.

**Why**: QA reporta que GD986-1278 no cubre todos los escenarios. Se necesita plan de choque integral.

**Where**: Casos GD986 en Jira (backlog), paquete PROCESO_REPORTE_FACTURACION, tablas C1991801, A2990700, A2000060, SIM_DEUDA_POLIZA.

**Learned**:
- Escenario 1 "Póliza no visible" (~10 casos): C1991801 no habilitado o fnc_tomar_FormaCobro excluye. Ej: GD986-1449 (prod 87), GD986-972 (prod 952), GD986-838 (vida rehabilitada forma cobro caja)
- Escenario 2 "Valor incorrecto" (~8 casos): Falta exclusión pagos anticipados o pol_finan no marcada. Ej: GD986-1422 (prod 956 suscripción), GD986-1405 (prod 948 doble valor), GD986-1387 (financiación muestra total)
- Escenario 3 "Deuda fantasma anulada" (~5 casos): Factura EP sin nota crédito post-anulación. Ej: GD986-1291 (autos anulada). Patrón MDSB-1034420
- Escenario 4 "Duplicado cambio tomador" (~2 casos): sec_tercero duplicado en A2001300. Ej: GD986-999 (cambio razón social)
- Escenario 5 "Factura indebida" (~5 casos): Timing pagos vs caja cerrada o factura estado intermedio. Ej: GD986-1440 (salud conjunta), GD986-1298 (pagos no reflejados)

---

## #122 — Plan de choque Servicio de Deuda — 30+ casos backlog, fix en QA

**Tipo:** discovery | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

**What**: Análisis del tablero GD986 revela ~30 casos activos en backlog de "Servicio de Deuda" (Pago en Línea no muestra deuda de pólizas activas). Pico de 14 casos el 23-abr y 9 casos en mayo 5-14. Todos son Error Productivo sin asignar.

**Why**: El fix principal (GD986-1278) que corrige 5 funciones de consulta dinámica en proceso_reporte_facturacion.prc_consulta_deuda_pagolinea ya está validado en QA por Rocio Castro (15-may-2026). Falta paso a producción.

**Where**: Paquete proceso_reporte_facturacion — funciones fnc_sqlprimer_vidaahr_poliza, fnc_sqlprimer_ahr_extra, fnc_sqlprimer_ahr_extra_poliza, fnc_sqlprimer_vidaahrdb, fnc_sqlprimer_vidaahrdb_poliza. Productos vida/ahorro secciones 46, 47, 48.

**Learned**: 
- GD986-1278 (fix 5 funciones) está en QA validado — necesita paso a prod urgente
- GD986-1306 (exclusión pagos anticipados/suscripción) está en progreso con Mildred Benitez
- Los 30 casos son esencialmente duplicados del mismo síntoma
- Patrón: endosos tipo 47/12 (AUMENTO CUOTA AHORRO) con VALOR_RIESGO=0 y VALOR_FPU>0 no se detectaban
- Plan: acelerar deploy, cerrar masivo, completar exclusión suscripción, filtro en mesa

---

## #121 — Rebase incompatible con pipeline de validación de hashes multi-rama

**Tipo:** discovery | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

**What**: Después de hacer rebase en una rama que ya pasó por develop/stage, GitHub no muestra diff en el PR hacia develop porque el contenido ya existe (solo cambiaron los hashes). Un commit vacío (`--allow-empty`) tampoco genera diff de archivos.

**Why**: GitHub compara contenido de archivos (tree), no hashes de commits. Si el código ya está en develop, no hay diff que mostrar aunque los hashes sean diferentes.

**Where**: tronador-oracle-db, flujo GD1129-117_TO_DEV → develop

**Learned**: 
- NO hacer rebase si la rama ya pasó por develop/stage — los hashes originales son los que el pipeline reconoce
- Si ya se hizo rebase, la única salida limpia es: (a) volver a los hashes originales sin rebase, o (b) forzar un merge directo a develop/stage
- El rebase es incompatible con pipelines que validan hashes a través de múltiples ramas

---

## #112 — MDSB-992543: Código confirmado — prc_InsNormal usa coeficiente fijo 1/12 sin ajuste retroactivo

**Tipo:** discovery | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: Confirmado en código fuente que prc_InsNormal de AB100273 usa coeficiente fijo 1/12 (prc_CalcCoefReal) para proceso 'RE' sin distinguir riesgos con vigencia retroactiva. La fórmula es: IMP_PRIMA = prima_anu * v_CoefPol donde v_CoefPol = 0.0833333 (1/12) para todos los riesgos por igual.

**Why**: Esto explica por qué la factura 12 no cobró los 8 días retroactivos (20-FEB → 28-FEB) del riesgo 662. El sistema aplica el mismo coeficiente mensual a todos los riesgos sin verificar si alguno tiene FECHA_VIG_END anterior al FECHA_VIG_FACT de la periódica.

**Where**: SIM_PCK299_AB100273.pkb — prc_InsNormal (línea del INSERT), prc_CalcCoefReal (cálculo v_CoefFact = 0.0833333 * v_CoefPer)

**Learned**:
- prc_InsNormal DECODE: proceso 'RE' → prima_anu * v_CoefPol; proceso 'EM' → imp_prima_end * v_CoefFact
- prc_CalcCoefReal para mensual: v_CoefFact = ROUND(0.0833333 * v_CoefPer, 10); v_CoefPol = v_CoefFact
- v_CoefPer = ROUND(v_PeriodoFactRe / v_PeriodoFact, 2) — para 30 días / 1 mes = 1.0
- NO existe lógica que ajuste por riesgos con FECHA_VIG_END < FECHA_VIG_FACT
- La corrección podría ir en PRC_DIFERIDO de AB100277 (ya maneja ajustes post-factura) o como paso adicional en prc_Proceso de AB100273
- fnc_MaxEndPremio busca MAX(num_end) de A2000030 JOIN A2000160 WHERE fecha_vig_end <= FECHA_VIG_FACT — esto determina qué endoso se usa como base para la periódica
- prc_LeeRe270 lee diferidos de C1000270 para proceso 'RE' (suma simple sin V_factor, a diferencia de prc_Lee270 que multiplica por CEIL(MONTHS_BETWEEN))

---

## #110 — MDSB-992543: Causa raíz real — 8 días no cobrados por MCA_FACTURA=N en inclusiones

**Tipo:** discovery | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: Descubierto que la causa raíz real de la diferencia $10,035 entre factura 12 y 13 es que los 8 días retroactivos (20-FEB → 28-FEB) del riesgo 662 NUNCA se cobraron. El endoso 13 (inclusión, cod_end 730) tiene MCA_FACTURA='N' — no genera factura propia. Y la factura 12 (periódica, 28-FEB → 31-MAR) solo cobra desde el 28-FEB, ignorando que el riesgo tiene vigencia desde el 20-FEB.

**Why**: La factura 13 (devolución) usa FECHA_VIG_FACT=20-FEB (fecha vigencia del endoso) y devuelve 40 días. Pero la factura 12 solo cobró 30 días (28-FEB → 31-MAR). Los 8 días del 20-FEB al 28-FEB nunca se cobraron en ninguna factura.

**Where**: SIM_PCK299_AB100277.PRC_PROCESO (genera factura periódica sin ajustar días retroactivos), A2000030.MCA_FACTURA='N' para endosos de inclusión (cod_end 730)

**Learned**:
- Endosos de inclusión (AD, cod_end 730) en Autos colectivos tienen MCA_FACTURA='N' por diseño — no generan factura propia
- Endosos de exclusión (AP, cod_end 731) SÍ tienen MCA_FACTURA='S' — generan factura de devolución
- La factura periódica (proceso 'RE') no verifica si hay riesgos nuevos con vigencia anterior al inicio del período
- Esto genera asimetría: la devolución cubre desde FECHA_VIG_END (20-FEB) pero el cobro solo desde FECHA_VIG_FACT de la periódica (28-FEB)
- El defecto NO está en la factura 13 (devolución correcta desde vigencia del endoso) sino en que los 8 días nunca se cobraron
- Dos posibles correcciones: (a) que la inclusión genere factura proporcional por los días retroactivos, o (b) que la factura periódica detecte riesgos nuevos con vigencia anterior y ajuste

---

## #108 — Alcance: 7+ casos producto 923 + 3 otros productos con mismo bug en PRC299_FACTURA_ANULACION_GRUPO

**Tipo:** discovery | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: Se identificaron al menos 7 casos directos del producto 923 con el mismo patrón (cancelación sin nota crédito por discrepancia fechas vigencia vs factura) desde junio 2025, más 3 casos de otros productos con el mismo procedimiento PRC299_FACTURA_ANULACION_GRUPO.

**Why**: Confirma que es un problema sistémico y recurrente que justifica un fix definitivo en el cursor de Proc_Reversa_facturaDB.

**Where**: Jira MDSB. Casos directos 923: MDSB-1034420, MDSB-1032104, MDSB-951481, MDSB-832098, MDSB-870430, MDSB-852411, MDSB-871726. Otros productos mismo procedimiento: MDSB-783872 (Bancaseguros, 1076 pólizas), MDSB-757766 (Salud colectiva), MDSB-974511 (Resp. Civil).

**Learned**: 1) MDSB-1032104 es la misma póliza 1141000016902 de MDSB-832098, ya ajustada por Andrés Ramírez el 14/05/2026. 2) Ana María Castillo es la reportante recurrente de estos casos. 3) El patrón existe desde al menos oct 2023 (MDSB-464724). 4) MDSB-783872 reportó 1076 pólizas afectadas en Bancaseguros con el mismo procedimiento.

---

## #99 — MDSB-1040981 creado para corroborar datos prod de MDSB-1034420

**Tipo:** discovery | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: Se creó MDSB-1040981 con script de consulta para corroborar en producción los datos del diagnóstico de MDSB-1034420.

**Why**: Los datos de SIM_FACTURA_MVTOS y SIM_FACTURA_ELECTRONICA no se pasan de prod a dev. Necesitamos confirmar que en producción: 1) A2000163 no tiene registro del endoso 1, 2) A2990700 no tiene cuota negativa, 3) Las fechas de factura vs vigencia son las mismas que en dev.

**Where**: MDSB-1040981 (consulta prod), referencia MDSB-1034420.

**Learned**: 1) El campo 'summary' NO es válido para requestTypeId=83 (Requerimientos DBA) — solo usar form.answers. 2) Los temporary attachments expiran rápido — subir y crear request en un solo flujo atómico. 3) El script debe incluir ALTER SESSION + SET commands obligatorios.

---

## #98 — Prod confirmado: cursor Proc_Reversa_facturaDB + posible segunda causa en póliza 3551000195310

**Tipo:** discovery | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db | **Topic:** bug/proc-reversa-facturadb-cursor-fecha-vig-end

**What**: Confirmado en producción (MDSB-1040981) que el cursor `facturas` en `Proc_Reversa_facturaDB` no encuentra la factura de la póliza 2592000257502 porque FECHA_VIG_END (01/09/2025) > FECHA_VTO_FACT (21/08/2025). Sin embargo, la segunda póliza 3551000195310 tiene FECHA_VIG_FACT (17/04/2026) > FECHA_VIG_END (10/04/2026), lo que significa que el cursor SÍ debería encontrarla — sugiere una segunda causa de fallo.

**Why**: La póliza principal confirma el bug del cursor. La segunda póliza podría tener otra causa: 1) periodo_fact=12 que activa GOTO FIN en PRC299_FACTURA_ANULACION_GRUPO, 2) condición `v_n_canal = 'N' and v_periodoFact = 12`, o 3) Proc_Reversa_facturaDB no se invocó para esa póliza.

**Where**: Producción, MDSB-1040981 (resultado .csv). Pólizas: 2592000257502 (confirmado), 3551000195310 (pendiente investigar).

**Learned**: 1) En prod SIM_FACTURA_MVTOS endoso 1 está en PR (no NE) — dev no es confiable para esta tabla. 2) Pueden existir MÚLTIPLES causas para el mismo síntoma en sección 923. 3) La segunda póliza tiene factura en EP (no pagada) vs la primera en CT (pagada) — esto podría activar una condición diferente en PRC299_FACTURA_ANULACION_GRUPO.

---

## #77 — Asimetría cobro vs devolución: prima_anu vs imp_prima_end en AB100273

**Tipo:** discovery | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

**What**: La diferencia de $10,035 entre cobro y devolución del riesgo 662 se descompone exactamente en: exceso prima base (+$48,003) - compensación diferidos (-$37,968) = $10,035. El exceso viene de que el cobro (RE) usa `prima_anu` (1,765,165) con coef 1/12, pero la devolución (EM) usa `imp_prima_end` (2,097,321) con coef 40/430. Son campos y fórmulas diferentes.
**Why**: MDSB-992543 — cliente reporta que devolución ($159,844) > cobro ($149,809). La diferencia NO es por los 10 días extra como se pensaba inicialmente.
**Where**: SIM_PCK299_AB100273.prc_InsNormal — DECODE(v_Proceso, 'RE', prima_anu * v_CoefPol, imp_prima_end * v_CoefFact). A2000160: imp_prima_end=2,097,321 vs end_prima_anu=1,765,165 (diferencia=$332,156 = recargo financiero).
**Learned**: imp_prima_end incluye recargo financiero por fraccionamiento mensual (~18.8%). El cobro mensual (RE) usa prima_anu (sin recargo) pero la devolución (EM) usa imp_prima_end (con recargo). Esto genera una asimetría inherente: se devuelve más de lo que se cobra por unidad de tiempo. Los diferidos compensan parcialmente (-$37,968) pero no totalmente.

---

## #75 — Entry point exclusión riesgo: PROC_GRABA_ENDOSO

**Tipo:** discovery | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

**What**: El entry point real para ejecutar una exclusión de riesgo en Tronador es SIM_PCK_ACCESO_DATOS_EMISION.PROC_GRABA_ENDOSO. Requiere que previamente se carguen datos transitorios con PROC_TRANSITORIAS_ENDOSO (cod_endoso 731 para exclusión de riesgo).
**Why**: Para reproducir la exclusión del riesgo 662 en dev y trazar los cálculos paso a paso (MDSB-992543).
**Where**: Package SIM_PCK_ACCESO_DATOS_EMISION (OPS$PUMA) — PROC_TRANSITORIAS_ENDOSO + PROC_GRABA_ENDOSO
**Learned**: El flujo completo es: 1) PROC_TRANSITORIAS_ENDOSO (carga endoso provisional, cod_endoso=731 para exclusión), 2) Marcar riesgo para baja, 3) PROC_GRABA_ENDOSO (graba endoso definitivo + genera factura). Los parámetros usan tipos complejos (SIM_TYP_PROCESO, SIM_TYP_ARRAY_VAR_MOTORREGLAS, SIM_TYP_ARRAY_ERROR).

---

## #71 — Diferidos CB100270: V_factor devuelve meses restantes, no cobrados

**Tipo:** discovery | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

**What**: CORRECCIÓN IMPORTANTE — Los diferidos en CB100270 REDUCEN la devolución, no la inflan. El UPDATE en Prc_upd163 hace: imp_prima = prima_base_negativa + diferidos_positivos. Es decir: -195,100 + 35,256 = -159,844. Sin diferidos la devolución sería -$195,100 (mayor). Con diferidos es -$159,844 (menor).
**Why**: El signo de V_impprima163 es POSITIVO porque C1000270 tiene +2,712 para el endoso de inclusión (end 13). Al sumarlo a una prima negativa (devolución), el efecto es REDUCIR la devolución. Los diferidos compensan, no inflan.
**Where**: Base Datos/Packages/SIM_PCK299_CB100270.pkb — Prc_upd163 (UPDATE A2000163 SET imp_prima = A.Imp_prima + V_impprima163 * V_coefpol)
**Learned**: La interpretación anterior era incorrecta. Los diferidos actúan como compensación: 'te devuelvo la prima proporcional pero te descuento los diferidos futuros que ya no pagarás'. Si V_factor fuera 1 en vez de 13, la devolución sería MAYOR (-195,100 + 2,712 = -192,388) en vez de -159,844. La diferencia de $10,035 entre devolución y cobro se explica solo por el período más largo (40 días vs 30 días). PENDIENTE: confirmar con funcional si esta interpretación es correcta.

---

## #42 — Fórmula exacta devolución exclusión: PFACTURAS_DIF usa coeficiente proporcional sobre factura base

**Tipo:** discovery | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

**What**: La devolución por exclusión en facturación se calcula en PFACTURAS_DIF usando un coeficiente proporcional: coef = sum(C1000270.imp_prima_163 * months_between(fecha_venc_pol, fecha_vto_fact_anterior)) / A2990700.imp_prima de la factura base. Devolución = ROUND(factura_base * coef). NO es PRIMA_COB/MESES ni PRIMA_ANU/12.
**Why**: El cobro mensual usa cuota fija (PRIMA_ANU/12 + residuo). La devolución usa coeficiente proporcional sobre la factura base completa. Como el coeficiente incluye meses_restantes (que para exclusión puede ser diferente al divisor del cobro), el resultado difiere de la cuota cobrada.
**Where**: Procedimiento PFACTURAS_DIF (OPS$PUMA) → SIM_PCK299_AB100277.PRC_DIFERIDO → PRC_PROCESO. Tablas: C1000270, A2990700, A2000163.
**Learned**: 1) Para reproducir el monto exacto de devolución: obtener numfacturabase (max factura con imp_prima > 0 antes del endoso), su imp_prima en A2990700, y sum(imp_prima_163 * meses_restantes) de C1000270 para riesgos excluidos. 2) coef = impprima163 / imp_prima_factura_base. 3) Solo genera factura si abs(impprima163) > 1000. 4) Condición de entrada: fecha1 (max fecha_vto_fact antes del endoso) = fecha_vig_end del endoso.

---

## #11 — Mejoras identificadas: Skills + Hooks nativos + Knowledge Base para power/agente

**Tipo:** discovery | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/power-improvements-roadmap

**What**: Se investigaron las capacidades de Skills, Hooks nativos de agente, y Knowledge Base en Kiro para mejorar el power corex-n3 y el agente de diagnóstico.

**Why**: El power carga mucho contexto siempre (25 steering files). Skills permiten carga progresiva on-demand. Hooks nativos en el agente JSON permiten automatizar Engram sin depender de .kiro/hooks/ del proyecto. Knowledge Base permite indexar steering para búsqueda semántica.

**Where**: Documentación oficial: kiro.dev/docs/skills/, kiro.dev/docs/cli/custom-agents/configuration-reference/

**Learned**:
1. Skills = carpeta con SKILL.md (frontmatter name+description). Se activan por coincidencia con el request del usuario. Viven en ~/.kiro/skills/ (global) o .kiro/skills/ (workspace).
2. Agente JSON soporta hooks nativos: agentSpawn, userPromptSubmit, preToolUse, postToolUse, stop. No necesitan .kiro/hooks/.
3. Agente soporta knowledgeBase resources: indexa carpetas completas para búsqueda semántica con millones de tokens.
4. includeMcpJson: true en el agente hereda los MCP servers del settings/mcp.json sin redefinirlos.
5. Skills siguen el estándar abierto agentskills.io — portables entre herramientas.

---

## #7 — Kiro cachea MCP del power en settings/mcp.json sección powers (no lee installed/)

**Tipo:** discovery | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** discovery/kiro-power-mcp-architecture

**What**: Kiro NO lee ~/.kiro/powers/installed/corex-n3/mcp.json para los servidores del power. Los cachea en ~/.kiro/settings/mcp.json bajo la sección "powers.mcpServers" con prefijo "power-{nombre}-{servidor}" (ej: power-corex-n3-oracle-readonly). Editar el mcp.json del directorio installed/ no tiene efecto.

**Why**: Después de reinstalar el power, los servidores Oracle seguían fallando con "Failed to spawn: $COREX_SERVER_PATH" porque la sección powers del settings/mcp.json tenía la versión vieja cacheada.

**Where**: ~/.kiro/settings/mcp.json → sección "powers.mcpServers" — es donde Kiro realmente lee la config de servidores del power. ~/.kiro/powers/installed/corex-n3/mcp.json — NO es leído por Kiro en runtime, solo es referencia.

**Learned**: 
1. Para corregir servidores de un power hay que editar DIRECTAMENTE settings/mcp.json en la sección powers.
2. Si un servidor MCP se define tanto en "mcpServers" (usuario) como en "powers.mcpServers", Kiro lo muestra como DOS entradas separadas (una global y una del power). Para evitar duplicación, cada servidor debe estar en UN solo lugar.
3. Context7 y Engram van dentro de powers.mcpServers (como parte del power). Solo lo que es independiente del power va en mcpServers global.
4. El settings/mcp.json sí se monitorea en caliente — los cambios se reflejan sin reiniciar.

---

## #4 — Context7 requiere reconnect MCP y no tiene métricas de ahorro

**Tipo:** discovery | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** discovery/context7-usage

**What**: Context7 está configurado en mcp.json pero no funciona aún — requiere reiniciar/reconectar servidores MCP en Kiro. No existe mecanismo nativo para medir ahorro de tokens; el beneficio es indirecto (menos iteraciones, menos hallucinations, docs actualizadas).

**Why**: El usuario preguntó cómo verificar que Context7 se usa y si hay métricas de ahorro. Se confirmó que el servidor no levantó porque Kiro no recargó los MCP servers tras el cambio de configuración.

**Where**: ~/.kiro/settings/mcp.json — servidor context7 configurado pero requiere reconnect.

**Learned**: Después de agregar un servidor MCP al mcp.json, Kiro NO lo levanta automáticamente — hay que hacer "Reconnect MCP Servers" desde Command Palette o reiniciar Kiro. Context7 no tiene dashboard de uso ni métricas de tokens. Para visibilidad, se puede agregar al steering una regla de "anotar explícitamente cuando se use Context7".

---

## #2 — Hooks vs Steering global en Kiro — alcance cross-project

**Tipo:** discovery | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** architecture/kiro-hooks-vs-steering

**What**: Se estableció que los hooks de Kiro son a nivel de proyecto (.kiro/hooks/), no globales. Para lograr comportamiento global (en cualquier workspace), se usa un steering file en ~/.kiro/steering/ que instruye al agente a seguir la política de Engram automáticamente.

**Why**: El power corex-n3 no soporta hooks nativos (solo mcp.json, POWER.md y steering/). Necesitábamos que la política de memoria persistente aplique en cualquier proyecto sin copiar archivos.

**Where**: ~/.kiro/steering/engram-knowledge-sync.md — steering global que reemplaza la necesidad de hooks por proyecto. tronador-oracle-db/.kiro/hooks/sync-knowledge-base.kiro.hook — hook redundante que puede eliminarse.

**Learned**: Los Powers de Kiro solo soportan: mcp.json (servidores), POWER.md (documentación), y steering/ (guías). No soportan hooks. Para comportamiento cross-project, usar steering global en ~/.kiro/steering/ es la solución correcta. El steering se carga automáticamente en todas las sesiones sin importar el workspace.

---

## #128 — IMPORTANTE: oracle-readonly es DEV — datos cuantitativos no son de producción

**Tipo:** learning | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db | **Topic:** learning/oracle-readonly-es-dev

**What**: MCP oracle-readonly apunta a DEV, no a producción. Los datos cuantitativos de la sesión (668 facturas no habilitadas, 7990 facturas DB) son de dev. Las pólizas de los casos Jira (1530546155510, 2010121256507, 1003611805002) no existen en dev — probablemente solo están en prod.

**Why**: Error de asunción durante diagnóstico. Para validar datos reales de los casos reportados se necesita acceso a producción o usar oracle-stage si tiene réplica de prod.

**Where**: MCP oracle-readonly = DEV, MCP oracle-stage = por confirmar ambiente.

**Learned**: 
- Siempre aclarar al usuario que oracle-readonly es dev
- Los hallazgos de CÓDIGO (lógica fnc_tomar_FormaCobro, filtro C1991801) son válidos porque el paquete es el mismo en todos los ambientes
- Los hallazgos de DATOS (cantidades, existencia de pólizas) deben validarse en producción
- Para diagnóstico de casos específicos con pólizas de prod, necesito oracle-stage o queries para ejecutar en prod vía Jira

---

## #105 — MCP oracle-readonly no ve cambios uncommitted de otra sesión

**Tipo:** learning | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: Al ejecutar PRC299_FACTURA_ANULACION_GRUPO en dev via MCP oracle-readonly, los cambios no son visibles porque: 1) El MCP es read-only (conexión diferente), 2) Los cambios uncommitted solo son visibles en la misma sesión. El usuario debe verificar en su propia sesión de SQL Developer.

**Why**: Oracle usa MVCC — los cambios no commiteados solo son visibles para la sesión que los hizo. El MCP oracle-readonly es otra conexión.

**Where**: Flujo de prueba en dev para MDSB-1034420.

**Learned**: 1) No puedo verificar cambios DML hechos por el usuario desde el MCP (sesión diferente). 2) El usuario debe verificar en su propia sesión antes de COMMIT. 3) Si PRESULTADO=4 el procedimiento falló silenciosamente (EXCEPTION WHEN OTHERS). 4) Si PRESULTADO=0 pero no hay registros, saltó a <<FIN>> por alguna condición. 5) Siempre usar SET SERVEROUTPUT ON para ver DBMS_OUTPUT.

---

## #96 — MUST: Revisar código fuente PL/SQL en diagnóstico + datos SIM_FACTURA no se pasan a dev

**Tipo:** learning | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: Al diagnosticar incidentes de facturación, SIEMPRE revisar el código fuente PL/SQL para identificar el punto exacto de fallo. No basta con ver el estado de las tablas.

**Why**: El análisis de tablas muestra el síntoma pero no la causa raíz exacta. Necesitamos identificar qué procedimiento/función y en qué línea se rompe el flujo. Además, tablas como SIM_FACTURA_MVTOS y SIM_FACTURA_ELECTRONICA generalmente NO se pasan cuando traen una póliza de producción a desarrollo — hay que corroborar datos en producción vía MDSB.

**Where**: Proceso de diagnóstico del agente N3.

**Learned**: 1) MUST: Siempre revisar código fuente del paquete involucrado para encontrar el punto exacto de fallo. 2) Los registros de SIM_FACTURA_MVTOS y SIM_FACTURA_ELECTRONICA en dev pueden no ser confiables (no se pasan de prod). 3) Para corroborar datos de prod, crear MDSB con scripts de consulta.

---
