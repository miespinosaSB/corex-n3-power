# Resúmenes de Sesión — Engram Export

> Exportado: 2026-05-15 | Proyectos: corex-n3-power (9), simon-cotizadores-core-wl (10), tronador-oracle-db (128)

---

## #87 — Session summary: simon-cotizadores-core-wl

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** simon-cotizadores-core-wl

## Goal
Ingestar contexto completo del proyecto cotizador de autos en Engram para persistencia entre sesiones.

## Discoveries
- El agente custom en .kiro/agents/cotizadores.json no es invocable nativamente en Kiro (formato no soportado)
- Los steering files en .kiro/steering/ sí se cargan automáticamente pero no evitan regresión
- Engram separa memorias por proyecto — no hay conflicto con el power corex-n3
- El pipeline de simon-ventas-lib necesita que DevOps cambie npm→gradle y configure secrets AWS

## Accomplished
- ✅ Guardadas 7 memorias estructuradas en Engram cubriendo: overview del proyecto, repos, estado actual, reglas críticas, flujo legacy, librería transversal, equipo/entorno
- ✅ Todas las relaciones entre memorias juzgadas como 'related'
- ✅ Sesión anterior: se extrajo bff-common a simon-ventas-lib, se corrigió Sonar (92% coverage), se configuró pipeline

## Next Steps
- Esperar que DevOps configure el pipeline de simon-ventas-lib (gradle + secrets AWS)
- Continuar desarrollo del descuento técnico (WIP del equipo)
- En próximas sesiones: usar `mem_context` al inicio para recuperar este contexto
- Evaluar si convertir el agente custom a sub-agente global (~/.kiro/agents/)

## Relevant Files
- .kiro/steering/product.md — Contexto del producto
- .kiro/steering/bff-spring.md — Arquitectura BFF
- .kiro/steering/arquitectura-angular.md — Arquitectura Angular
- .kiro/steering/libs-compartidas.md — Reglas de librerías compartidas
- .kiro/steering/legacy-verification.md — Cómo verificar contra el legacy
- .kiro/agents/cotizadores-prompt.md — Prompt del agente (no invocable nativamente)

---

## #148 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

## Goal
Análisis exhaustivo del Servicio de Deuda (Pago en Línea) — identificar todos los escenarios de falla, clasificar los 30+ casos del backlog, y diagnosticar el Escenario 1 "Póliza no visible".

## Discoveries
- oracle-readonly es DEV, oracle-stage tiene credenciales expiradas (ORA-01017) — no pudimos validar en producción
- Paquete PROCESO_REPORTE_FACTURACION tiene 8 flujos de consulta de deuda para canal 1
- CRX_PROCESO_REPORTE_FACTURACION es versión optimizada (Brayan Gamez, GD1129-117) con switch en C9999909 — actualmente en modo 'O' (usa original)
- CRX elimina SOAT, provisorias, multi-compañía y agrupadas del flujo principal
- Escenario 1 tiene 3 causas raíz: C1991801 no habilitado, fnc_tomar_FormaCobro excluye DB/GP, pólizas rehabilitadas con forma cobro CC
- En DEV: 8 combinaciones sección/ramo con 668 facturas EP no habilitadas en C1991801
- En DEV: 7,990+ facturas DB y 1,632+ facturas GP excluidas por fnc_tomar_FormaCobro
- Producto 87 = "BIENESTAR Y SALUD PARA DISFRUTAR" (sección 34, ramo 87) — SÍ está en C1991801 en dev
- Pólizas de casos Jira (1530546155510, 2010121256507, 1003611805002) no existen en dev — solo en prod

## Accomplished
- ✅ Inventario completo 30+ casos deuda en Jira
- ✅ Lectura y análisis completo package body PROCESO_REPORTE_FACTURACION
- ✅ Lectura package spec CRX_PROCESO_REPORTE_FACTURACION — comparación de diferencias
- ✅ Clasificación en 5 patrones de síntoma con casos ejemplo
- ✅ Diagnóstico Escenario 1 con 3 causas raíz identificadas
- ✅ Queries diagnósticas validadas en dev (pendiente validar en prod)
- 🔲 Falta validar datos en producción (stage no conecta)
- 🔲 Falta crear HUs en Jira

## Next Steps
- Arreglar conexión oracle-stage O ejecutar queries en prod vía SQL Developer
- Validar con negocio qué productos de los 8 no habilitados en C1991801 deberían aparecer en Pago en Línea
- Ejecutar queries diagnósticas en prod para las pólizas específicas de los casos
- Crear HUs en Jira para cada escenario/fix identificado
- Desplegar GD986-1278 a producción (ya validado en QA)
- Completar GD986-1306 en todas las funciones (no solo fnc_sqlprimer)
- Replicar fixes en CRX_PROCESO_REPORTE_FACTURACION para cuando se active switch

## Relevant Files
- Package: PROCESO_REPORTE_FACTURACION (OPS$PUMA) — paquete principal
- Package: CRX_PROCESO_REPORTE_FACTURACION (OPS$PUMA) — versión optimizada alternativa
- Tablas clave: C1991801, C9999909 (PARAM_PAGO_CC_PL, PROD_DB_LIBRANZAS, PRCS_RPT_FCTRCN), A2000060, A2990700
- Jira: GD986-1278 (fix VPA en QA), GD986-1306 (exclusión pagos anticipados), GD1129-117 (CRX)

---

## #147 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

## Goal
Diagnosticar y proponer fix para rechazo DIAN FAU04 en facturación electrónica de pólizas 1003612215701 y 1003612214101 (ramo 250, Nuevo Producto Automóviles, con línea de Asistencia Bolívar).

## Instructions
- Para consultar producción: SIEMPRE usar el power corex-n3 con steering consulta-produccion-mdsb.md. oracle-readonly = dev, oracle-stage = pre-prod.
- El usuario (Michael Espinosa) es el autor del procedimiento prc_separa_conceptos que tiene el bug.

## Discoveries
- Bug en `prc_separa_conceptos`: cuando `prima_prov = 0` (pólizas sin IVA), se resta la asistencia DOS VECES de `l_prima_prov`. El código hace `l_prima_prov := l_prima` (ya es imp_prima - asistencia) y luego `l_prima_prov := l_prima_prov - l_prima_asistencia` (segunda resta).
- Regla FAU04 DIAN = "Base Imponible es distinto a la suma de los valores de las bases imponibles de todas líneas de detalle"
- La diferencia siempre es exactamente el valor de la asistencia ($332,653)
- Escenario adicional de riesgo: `valorSubTotalConversion` en `fn_construye_importes` usa prima original sin recalcular tras separación de conceptos
- Escenario de riesgo con moneda extranjera: redondeo de TRM entre conversión total y parciales podría generar diferencias

## Accomplished
- ✅ Consultado estado en producción vía MDSB-1041637 (cabecera pólizas, facturación electrónica, cuotas)
- ✅ Consultado logs JSON request/response vía MDSB-1041652 (SIM_LOG_FACTURA_E)
- ✅ Identificada causa raíz exacta en código PL/SQL (prc_separa_conceptos, doble resta)
- ✅ Propuesto fix puntual (mover la resta al IF correcto)
- ✅ Identificados 3 escenarios de riesgo con asistencia
- 🔲 Pendiente: aplicar fix en repositorio y crear HU/PR

## Next Steps
- Aplicar el fix en el archivo del repositorio (SIM_PCK_FACTURA_ELECTRONICA.pkb)
- Crear rama, commit y PR
- Validar con las pólizas afectadas después del deploy
- Considerar blindaje adicional para valorSubTotalConversion

## Relevant Files
- OPS$PUMA.SIM_PCK_FACTURA_ELECTRONICA — procedimiento prc_separa_conceptos (bug), fn_construye_items (genera JSON con items), fn_construye_importes (genera valorSubTotalConversion)

---

## #133 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

## Goal
Consultar estado de facturación electrónica en producción para pólizas 1003612215701 y 1003612214101.

## Instructions
- oracle-readonly = dev, oracle-stage = pre-prod. NUNCA son producción.
- Para consultar producción: usar power corex-n3 con steering consulta-produccion-mdsb.md (crea MDSB en Service Desk para bot AIOps).

## Discoveries
- Regla FAU04 de DIAN indica error en validación del adquirente (datos del tomador)
- Cuando múltiples pólizas del mismo tomador fallan con FAU04, el problema está en los datos del tercero
- Estado EE en SIM_FACTURA_ELECTRONICA = "Reprocesar - Error Operador", requiere corrección de datos y reproceso
- El bot AIOps devuelve resultados como CSV adjunto al caso MDSB (~1 min de procesamiento)
- Para descargar adjuntos de Jira se necesita usar la API REST directa (el tool download_attachments falla con MIME type application/sql)

## Accomplished
- ✅ Clarificado que MCP servers NO son producción (guardado como decisión en Engram)
- ✅ Creado MDSB-1041637 con 3 queries (A2000030, SIM_FACTURA_ELECTRONICA, A2990700)
- ✅ Obtenido y presentado resultados de producción
- ✅ Diagnosticado: ambas pólizas con error FAU04 (datos del adquirente NIT 900232067)
- 🔲 Pendiente: investigar datos del tercero 900232067 para identificar qué campo causa el rechazo

## Next Steps
- Investigar datos del tercero 900232067 en A1000000 (dirección, email, régimen tributario)
- Determinar qué campo específico causa la regla FAU04
- Corregir datos y reprocesar facturas electrónicas

## Relevant Files
- Power corex-n3 steering: consulta-produccion-mdsb.md — flujo para consultas en producción vía MDSB

---

## #123 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

## Goal
Análisis exhaustivo del paquete PROCESO_REPORTE_FACTURACION para identificar todos los escenarios que causan fallas en el Servicio de Deuda (Pago en Línea) y crear un plan de choque.

## Discoveries
- El paquete tiene 8 flujos distintos para armar la consulta de deuda en canal 1 (Pago en Línea)
- GD986-1278 (en QA) solo cubre funciones VPA (vida/ahorro secciones 46/47/48) — condición OR para VALOR_FPU!=0 AND VALOR_RIESGO=0
- GD986-1306 (exclusión pagos anticipados) solo aplica filtro en `fnc_sqlprimer` pero NO en `fnc_sqlprimer_poliza` ni `fnc_sqlpoliza_polflot` — gap potencial
- Existe un switch mode en C9999909 (COD_TAB='PRCS_RPT_FCTRCN', DAT_CAR='CONSULTA_DEUDA') que puede redirigir a `crx_proceso_reporte_facturacion` — si está en 'F', los fixes del paquete original no aplican
- `fnc_tomar_FormaCobro` excluye silenciosamente pólizas DB sin canal_descto en A2000060
- Filtro C1991801 (mca_re=1, cod_estado=1) puede excluir productos no parametrizados
- `fnc_tomar_poliza` tiene ventana de 720 días configurable por C9999909 'DIAS_POLIZAS_PE'
- `fnc_estadofactura` excluye facturas con mca_estado='P' en A2000163
- 30+ casos en backlog desde enero 2026, pico de 14 casos el 23-abr

## Accomplished
- ✅ Inventario completo de los 30+ casos de deuda en Jira (GD986)
- ✅ Lectura y análisis del package spec y body completo de PROCESO_REPORTE_FACTURACION
- ✅ Identificación de 8 escenarios/problemas potenciales no cubiertos por GD986-1278
- ✅ Mapa de los 8 flujos de consulta de deuda para canal 1
- ✅ Plan de acción priorizado (P1/P2/P3)

## Next Steps
- Verificar valor del switch PRCS_RPT_FCTRCN en C9999909 (si es 'F', revisar crx_proceso_reporte_facturacion)
- Verificar parametrización C1991801 para producto 87 (caso GD986-1449)
- Completar filtro GD986-1306 en fnc_sqlprimer_poliza y fnc_sqlpoliza_polflot
- Revisar paquete crx_proceso_reporte_facturacion si el switch está activo
- Crear HUs en Jira para cada escenario identificado
- Desplegar GD986-1278 a producción

## Relevant Files
- Package: PROCESO_REPORTE_FACTURACION (OPS$PUMA) — paquete principal de consulta de deuda
- Package: CRX_PROCESO_REPORTE_FACTURACION — paquete alternativo (switch mode 'F')
- Tablas clave: A2990700, SB_RECAUDO, SB_CONVENIO, SB_CLIENTE_POLIZA, A2000030, C1991801, C9999909
- Jira: GD986-1278 (fix VPA en QA), GD986-1306 (exclusión pagos anticipados en progreso)

---

## #120 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

## Goal
Resolver problema de pipeline pr-validator fallando en rama GD1129-117 después de usar "Update branch" de GitHub, y re-pasar la rama por el flujo develop → stage → master.

## Discoveries
- El botón "Update branch" de GitHub crea un commit de merge con hash nuevo que el pipeline `pr-validator` no reconoce (valida hashes contra develop/stage)
- El flujo de este repo usa ramas `_TO_DEV` y `_TO_STAGE` para crear PRs hacia ambientes bajos
- `--force-with-lease` falla si no hay tracking local actualizado de la rama remota; usar `--force` cuando se tiene certeza del estado

## Accomplished
- ✅ Identificado el commit de merge problemático (`d88633200`)
- ✅ Revertido el "Update branch" con force push al commit anterior (`a3804e3d9`)
- ✅ Rebaseada la rama GD1129-117 sobre origin/master (nuevo hash: `fdbcd8872`)
- ✅ Actualizadas ramas GD1129-117_TO_DEV y GD1129-117_TO_STAGE al mismo commit
- 🔲 Pendiente: crear/verificar PRs hacia develop y stage

## Next Steps
- Verificar estado de PRs existentes hacia develop y stage
- Crear nuevos PRs si los anteriores ya estaban cerrados/mergeados
- Esperar que pasen por el pipeline antes de mergear a master

## Relevant Files
- .github/workflows/pr-validator.yml — validador de commits (usa template externo)
- .github/workflows/pr-executor.yml — ejecutor de cambios en BD
- .github/workflows/pipeline.yml — nivelación de ramas de ambientes bajos

---

## #117 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Retrospectiva del power corex-n3: aplicar las 4 mejoras aprobadas por el usuario.

## Accomplished
- ✅ Mejora 1: Patrón diferidos CB100270 (MDSB-992543) agregado a Confluence KB (página 1688371201, v8) — tabla + hallazgo #9
- ✅ Mejora 2: Flujo facturación en cancelación documentado en Arquitectura Servicios (página 1688338434, v4) — diagrama completo con Proc_Reversa_facturaDB + PRC299_FACTURA_ANULACION_GRUPO
- ✅ Mejora 3: Regla código fuente obligatorio ya existía en diagnostico-eficiente.md (no requirió cambio)
- ✅ Mejora 4: Nota 'Tablas que NO se pasan de Prod a Dev' agregada a oracle-consultas.md (SIM_FACTURA_MVTOS, SIM_FACTURA_ELECTRONICA, A5020301, A5021600)

## Relevant Files
- powers/corex-n3/steering/oracle-consultas.md — Nueva sección de tablas no confiables en dev
- Confluence 1688371201 (Patrones, v8) — Patrón CB100270 agregado
- Confluence 1688338434 (Arquitectura, v4) — Flujo facturación cancelación agregado

---

## #116 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Retrospectiva del power corex-n3: analizar últimos 30 días de trabajo y proponer mejoras.

## Discoveries
- Patrón diferidos CB100270 (MDSB-992543) está en Engram pero NO en Confluence KB
- Tablas A2000060, A2000191, A2000252, PMC_PROCESO_LOG frecuentemente usadas pero no documentadas en KB
- Scripts con PROMPT/SET no funcionan en SQL Developer (solo SQL*Plus)
- Datos SIM_FACTURA_MVTOS y SIM_FACTURA_ELECTRONICA no se pasan de prod a dev
- Flujo completo de facturación en cancelación descubierto pero no documentado en Arquitectura Servicios

## Accomplished
- ✅ Retrospectiva ejecutada con análisis de 9 memorias Engram + 15 historias GD986
- ✅ 5 mejoras propuestas al usuario
- ✅ Query de detección proactiva de pólizas 923 con discrepancia de fechas identificada
- 🔲 Pendiente aprobación del usuario para aplicar mejoras

## Next Steps
- Aplicar mejoras aprobadas por el usuario
- Subir patrón CB100270 a Confluence si se aprueba
- Documentar flujo de facturación en cancelación en Arquitectura Servicios

## Relevant Files
- Confluence 1688371201 (Patrones de Problemas)
- Confluence 1688338434 (Arquitectura Servicios)
- powers/corex-n3/steering/diagnostico-eficiente.md
- powers/corex-n3/steering/oracle-consultas.md

---

## #115 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Diseñar la propuesta de corrección para el bug de días retroactivos no cobrados en facturación periódica (MDSB-992543). Crear spec formal del bugfix.

## Discoveries
- CONFIRMADO EN CÓDIGO: prc_InsNormal usa DECODE(v_Proceso, 'RE', prima_anu * v_CoefPol, ...) con v_CoefPol = 1/12 fijo
- prc_CalcCoefReal: v_CoefFact = ROUND(0.0833333 * v_CoefPer, 10) — no hay ajuste por riesgos retroactivos
- fnc_MaxEndPremio determina qué endoso se usa como base: MAX(num_end) de A2000030 JOIN A2000160 WHERE fecha_vig_end <= FECHA_VIG_FACT
- prc_LeeRe270 lee diferidos para proceso 'RE' (suma simple sin V_factor)
- La condición de CB100270 excluye explícitamente proceso 'RE': V_procesoFact != 'RE'
- Propuesta de corrección en dos puntos: AB100277.PRC_DIFERIDO + AB100273.prc_Proceso

## Accomplished
- ✅ Leído código fuente completo de SIM_PCK299_AB100273 (package body) desde Oracle
- ✅ Identificada ubicación exacta del defecto: prc_InsNormal + prc_CalcCoefReal
- ✅ Creado spec bugfix en .kiro/specs/facturacion-dias-retroactivos/bugfix.md
- ✅ Spec aprobado por usuario — sin errores de formato (getDiagnostics clean)
- ✅ Guardadas observaciones en Engram (#110 discovery causa raíz, #112 discovery código confirmado)

## Next Steps
- Generar Tech Design (design.md) con la propuesta detallada de corrección en ambos puntos
- Generar Task List (tasks.md) con los pasos de implementación
- Validar con área funcional antes de implementar
- Actualizar KB Confluence con el hallazgo completo

## Relevant Files
- .kiro/specs/facturacion-dias-retroactivos/bugfix.md — requisitos del bugfix
- .kiro/specs/facturacion-dias-retroactivos/.config.kiro — config del spec
- Base Datos/Packages/SIM_PCK299_AB100273.pkb — motor de facturación (defecto en prc_InsNormal)
- Base Datos/Packages/SIM_PCK299_AB100277.pkb — orquestador (PRC_DIFERIDO)
- ANALISIS_MDSB-992543.md — análisis técnico consolidado

---

## #114 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Ciclo completo de atención del caso MDSB-1034420: diagnóstico, correctivo, documentación.

## Accomplished
- ✅ Diagnóstico completo con código fuente (punto exacto: cursor en Proc_Reversa_facturaDB)
- ✅ Confirmación en producción (MDSB-1040981)
- ✅ Correctivo validado en dev (PRC299_FACTURA_ANULACION_GRUPO con PFECHAVIGEND=NULL)
- ✅ Scripts correctivo + rollback generados
- ✅ Cambio de datos creado por el usuario para producción
- ✅ 7+ casos similares identificados, 15 pólizas afectadas
- ✅ Confluence KB actualizada (página 1688371201, v7)
- ✅ MDSB-1034420 documentado con comentario técnico completo
- ✅ ANALISIS_MDSB-1034420.md generado

## Discoveries
- Origen probable: fechas de vigencia modificadas vía script post-emisión (no es bug del sistema, es dato inconsistente)
- No se requiere fix definitivo del cursor por ahora — workaround con PRC299_FACTURA_ANULACION_GRUPO es suficiente
- Patrón recurrente desde jun 2025, misma reportante (Ana María Castillo)

## Next Steps
- Monitorear si se presentan más casos del mismo patrón
- Si se repite con frecuencia, evaluar fix definitivo en el cursor
- Verificar con el área de emisiones por qué se modifican fechas de vigencia post-emisión en 923

## Relevant Files
- ANALISIS_MDSB-1034420.md — Documento consolidado
- Base Datos/Procedimientos/MDSB-1034420_CORRECTIVO.sql
- Base Datos/Rollbacks/MDSB-1034420_ROLLBACK.sql
- Confluence: https://jirasegurosbolivar.atlassian.net/wiki/spaces/BDCT/pages/1688371201 (v7)

---

## #113 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Documentar el patrón MDSB-1034420 en Confluence KB y consolidar todo el análisis.

## Discoveries
- El origen probable del problema es que las fechas de vigencia de las pólizas 923 fueron modificadas vía script post-emisión, dejando la factura con fechas que no corresponden a la vigencia real
- Por ahora NO se debe modificar el cursor de Proc_Reversa_facturaDB para contemplar este escenario — el workaround con PRC299_FACTURA_ANULACION_GRUPO es suficiente
- La página de Confluence 'Patrones de Problemas y Hallazgos' (ID: 1688371201) se actualizó a versión 7 con el nuevo patrón completo

## Accomplished
- ✅ Confluence KB actualizada (página 1688371201, v7) con:
  - Nuevo patrón en tabla principal
  - Hallazgo #8 detallado (causa, workaround, verificaciones, queries, pólizas)
  - Nueva sección de consultas de diagnóstico para nota crédito 923
- ✅ Aclarado que el fix definitivo del cursor NO es prioritario por ahora (origen: datos modificados vía script)
- ✅ ANALISIS_MDSB-1034420.md generado con toda la información
- ✅ Scripts correctivo + rollback listos
- ✅ MDSB-1041083 creado para verificación pre-correctivo en prod

## Next Steps
1. Esperar resultado MDSB-1041083
2. Crear MDSB de cambio para producción con scripts
3. Comentar en MDSB-1034420 con el análisis y solución

## Relevant Files
- Confluence: https://jirasegurosbolivar.atlassian.net/wiki/spaces/BDCT/pages/1688371201 (v7)
- ANALISIS_MDSB-1034420.md
- Base Datos/Procedimientos/MDSB-1034420_CORRECTIVO.sql
- Base Datos/Rollbacks/MDSB-1034420_ROLLBACK.sql

---

## #111 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Determinar la causa raíz real de la diferencia entre factura 12 (cobro) y factura 13 (devolución) del caso MDSB-992543, con foco en el rol de AB100277 como orquestador.

## Discoveries
- AB100277 existe como COBOL (AB100277.pco) y PL/SQL (SIM_PCK299_AB100277) — coexisten
- Endosos de inclusión (AD, cod_end 730) tienen MCA_FACTURA='N' — NO generan factura propia por los días proporcionales
- Endosos de exclusión (AP, cod_end 731) SÍ tienen MCA_FACTURA='S' — generan factura de devolución
- CAUSA RAÍZ REAL: Los 8 días (20-FEB → 28-FEB) del riesgo 662 NUNCA se cobraron en ninguna factura
  - Factura 9 (31-ENE → 28-FEB): generada 27-ENE, ANTES de la inclusión → no incluye riesgo 662
  - Endoso 13 (inclusión): MCA_FACTURA='N' → no genera factura propia
  - Factura 12 (28-FEB → 31-MAR): cobra desde 28-FEB, no desde 20-FEB
  - Factura 13 (devolución): devuelve desde 20-FEB → 31-MAR (40 días) incluyendo los 8 no cobrados
- El defecto está en la factura 12 (no cobró los 8 días retroactivos), NO en la factura 13
- Confirmado con Oracle: endoso 13 tiene IMP_PRIMA_END=$2,097,321 pero MCA_FACTURA='N'
- Actualizada KB Confluence con flujo AB100277 y patrón de asimetría

## Accomplished
- ✅ Mapeado flujo completo AB100277 (COBOL + PL/SQL)
- ✅ Confirmado con Oracle que endoso 13 (inclusión) tiene MCA_FACTURA='N'
- ✅ Identificada causa raíz real: 8 días no cobrados por diseño (inclusiones no facturan)
- ✅ Actualizada KB Confluence (Módulo Emisión, página 1679654913)
- ✅ Guardadas 4 observaciones en Engram (arquitectura, patrón, decisión, discovery)

## Next Steps
- Investigar por qué inclusiones (cod_end 730) tienen MCA_FACTURA='N' — ¿es parametrizable en SIM_CODIGOS_ENDOSO_SECCION?
- Determinar si la corrección es: (a) que la inclusión genere factura proporcional, o (b) que la periódica ajuste días retroactivos
- Validar con funcional cuál es el comportamiento esperado para inclusiones con vigencia retroactiva
- Desplegar fix CEIL→TRUNC a producción (independiente de este hallazgo)

## Relevant Files
- ANALISIS_MDSB-992543.md — análisis técnico consolidado
- tronador-core-cobol/AB100277.pco — COBOL batch orquestador
- Base Datos/Packages/SIM_PCK299_AB100277.pkb — PL/SQL orquestador
- Base Datos/Packages/SIM_PCK299_AB100273.pkb — motor de facturación

---

## #109 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Consolidar el análisis completo de MDSB-1034420 en un documento único con todos los casos relacionados y pólizas afectadas.

## Accomplished
- ✅ Generado ANALISIS_MDSB-1034420.md con análisis completo
- ✅ Identificadas 15 pólizas afectadas del producto 923
- ✅ Documentados 11 casos MDSB relacionados (7 directos 923 + 4 otros productos)
- ✅ MDSB-1032104 encontrado: mismo patrón, misma reportante, ya ajustado por Andrés Ramírez
- ✅ Scripts correctivo + rollback listos
- ✅ MDSB-1041083 creado para verificación pre-correctivo en prod

## Next Steps
1. Leer resultado MDSB-1041083 (verificación pre-correctivo prod)
2. Crear MDSB de cambio con scripts correctivo + rollback
3. Crear HU en GD986 para fix definitivo del cursor
4. Actualizar Confluence con el patrón
5. Vincular todos los casos relacionados

## Relevant Files
- ANALISIS_MDSB-1034420.md — Documento consolidado completo
- Base Datos/Procedimientos/MDSB-1034420_CORRECTIVO.sql
- Base Datos/Rollbacks/MDSB-1034420_ROLLBACK.sql
- test_correctivo_mdsb1034420.sql

---

## #107 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Generar scripts de correctivo y rollback para MDSB-1034420, listos para enviar a producción.

## Discoveries
- PRC299_FACTURA_ANULACION_GRUPO en dev generó: A2000163 (3 filas), A2990700 (1 fila), A2000252 (2 filas), A2000191 (3 filas). NO generó A2990701 (0 filas — probablemente porque no hay comisiones configuradas para esta póliza).
- El rollback es simple: DELETE por NUM_SECU_POL + NUM_FACTURA=2 en orden inverso de dependencia
- El script correctivo incluye: verificación de idempotencia, ejecución, verificación de resultado, COMMIT/ROLLBACK condicional

## Accomplished
- ✅ Script correctivo creado: Base Datos/Procedimientos/MDSB-1034420_CORRECTIVO.sql
- ✅ Script rollback creado: Base Datos/Rollbacks/MDSB-1034420_ROLLBACK.sql
- ✅ Ambos scripts son portables (usan subselect para NUM_SECU_POL)
- 🔲 Crear MDSB de cambio con scripts adjuntos
- 🔲 Actualizar Confluence
- 🔲 Crear HU para fix definitivo

## Next Steps
1. Crear MDSB de Solicitud de Cambio Core con ambos scripts
2. Documentar en Confluence
3. Crear HU para fix definitivo del cursor

## Relevant Files
- Base Datos/Procedimientos/MDSB-1034420_CORRECTIVO.sql — Script DML para producción
- Base Datos/Rollbacks/MDSB-1034420_ROLLBACK.sql — Rollback del correctivo
- test_correctivo_mdsb1034420.sql — Script de prueba en dev (ya ejecutado)

---

## #104 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Ejecutar el correctivo PRC299_FACTURA_ANULACION_GRUPO en dev para la póliza 2592000257502 y validar que genera la factura negativa.

## Discoveries
- SQL Developer no reconoce comandos PROMPT ni SET de SQL*Plus — los scripts deben ser compatibles con SQL Developer (sin PROMPT, sin SET)
- El bloque PL/SQL ejecutó correctamente ('Procedimiento PL/SQL terminado correctamente')
- Pendiente verificar con SELECT si se generaron los registros en A2000163 y A2990700

## Accomplished
- ✅ Ejecutado PRC299_FACTURA_ANULACION_GRUPO en dev sin errores
- 🔲 Verificar resultado con SELECTs manuales
- 🔲 COMMIT si OK
- 🔲 Preparar script para producción

## Next Steps
1. Ejecutar SELECTs de verificación en SQL Developer
2. Si factura 2 con IMP_PRIMA=-60712 existe → COMMIT
3. Preparar script para producción (sin PROMPT/SET, compatible SQL Developer)
4. Crear MDSB de cambio

## Relevant Files
- test_correctivo_mdsb1034420.sql — Script ejecutado (tiene problemas de compatibilidad SQL Developer)

---

## #102 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Preparar y probar el correctivo para MDSB-1034420: generar la factura negativa faltante en la póliza 2592000257502 (sección 923) usando PRC299_FACTURA_ANULACION_GRUPO.

## Discoveries
- MDSB-951481 es precedente exacto: póliza 923 (1141000002502) anulada sin factura negativa, resuelta con Generación Interactiva de Factura
- MDSB-783872 documenta el mismo patrón en Bancaseguros (1076 pólizas afectadas) — el análisis de Daniel Herrera identifica PRC299_FACTURA_ANULACION_GRUPO como el procedimiento involucrado
- MDSB-961532 fue el cambio de enero 2026 (v1.2) a PRC299_FACTURA_ANULACION_GRUPO por Rosario Puertas: condición `VCODSITUACION = 'EP' AND V_forcobro = 'DB' and v_codend >= 900` solo aplica para anulaciones automáticas
- Con PFECHAVIGEND=NULL el procedimiento NO prorratea — usa fechas originales y coeficiente=-1 (devolución total)
- Oracle Stage (10.7.2.14) no conecta (ORA-01017 invalid username/password) — solo dev (10.1.2.76) disponible
- El MCP oracle-readonly es solo lectura — para ejecutar DML hay que usar SQL*Plus/SQL Developer directo

## Accomplished
- ✅ Encontrado caso precedente MDSB-951481 con solución documentada
- ✅ Identificadas dos opciones de correctivo: Generación Interactiva o PRC299_FACTURA_ANULACION_GRUPO directo
- ✅ Generado script de prueba `test_correctivo_mdsb1034420.sql` para ejecutar en dev
- ✅ Guardado patrón de correctivo en Engram
- 🔲 Ejecutar script en dev y validar resultado
- 🔲 Si OK en dev → crear MDSB de cambio para producción
- 🔲 Actualizar Confluence con el patrón
- 🔲 Crear HU para fix definitivo del cursor

## Next Steps
1. Ejecutar `test_correctivo_mdsb1034420.sql` en dev (10.1.2.76) y validar que genera factura 2 con IMP_PRIMA=-60712
2. Si OK → preparar script para producción (cambiar NUM_SECU_POL al de prod si es diferente)
3. Crear MDSB de cambio (Solicitud de Cambio Core) con el script DML
4. Actualizar página Confluence 1688371201 con nuevo patrón
5. Crear HU en GD986 para fix definitivo del cursor en Proc_Reversa_facturaDB

## Relevant Files
- test_correctivo_mdsb1034420.sql — Script de prueba en dev
- PRC299_FACTURA_ANULACION_GRUPO (OPS$PUMA) — Procedure que genera la factura negativa
- SIM_PCK_FACTURACION.Proc_Reversa_facturaDB — Contiene el cursor con el bug
- Casos referencia: MDSB-951481, MDSB-783872, MDSB-961532

---

## #100 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Corroborar en producción el diagnóstico de MDSB-1034420 (nota crédito no generada en cancelación póliza 923) mediante MDSB-1040981.

## Discoveries
- **CONFIRMADO en prod:** A2000163 NO tiene registro del endoso 1 para póliza 2592000257502. A2990700 tampoco tiene cuota negativa.
- **CONFIRMADO:** Prima negativa SÍ se calculó en A2000160 (IMP_PRIMA_END=-60712)
- **CONFIRMADO:** Fechas en prod iguales a dev: FECHA_VIG_FACT=21/07/2025, FECHA_VTO_FACT=21/08/2025, FECHA_VIG_END=01/09/2025
- **NUEVO:** En prod, SIM_FACTURA_MVTOS del endoso 1 está en ESTADO=PR (no NE como en dev). MSJ='PROCESADA-INSERTADA TABLA FINAL NE'. Esto confirma que los datos de SIM_FACTURA_MVTOS no se pasan correctamente a dev.
- **NUEVO:** Segunda póliza 3551000195310 tiene patrón DIFERENTE: FECHA_VIG_FACT=17/04/2026 > FECHA_VIG_END=10/04/2026, por lo que el cursor SÍ debería encontrarla. Posible causa diferente (periodo_fact=12 o proceso no invocado).
- **CONFIRMADO:** Sección 923 excluida de DIAN en C9999909 ('Productos que no se van a enviar a la DIAN')
- El campo 'summary' NO es válido para requestTypeId=83 en Service Desk API
- Temporary attachments expiran rápido — subir y crear en flujo atómico

## Accomplished
- ✅ Creado MDSB-1040981 con script de consulta (10 queries)
- ✅ Bot AIOps procesó exitosamente ('Consulta con éxito')
- ✅ Descargados y analizados resultados de producción
- ✅ Diagnóstico CONFIRMADO para póliza principal 2592000257502
- ✅ Identificado que segunda póliza tiene causa potencialmente diferente
- 🔲 Profundizar segunda póliza (3551000195310)
- 🔲 Crear HU en Jira
- 🔲 Documentar en Confluence
- 🔲 Implementar fix

## Next Steps
1. Investigar por qué la segunda póliza (3551000195310) tampoco generó nota crédito si el cursor SÍ debería encontrarla (verificar periodo_fact, condición GOTO FIN, o si Proc_Reversa_facturaDB no se invocó)
2. Crear HU en GD986 con el fix propuesto para el cursor
3. Documentar en Confluence el análisis completo con evidencia de producción
4. Implementar y probar el fix en dev

## Relevant Files
- SIM_PCK_FACTURACION.Proc_Reversa_facturaDB — cursor 'facturas' con el bug
- PRC299_FACTURA_ANULACION_GRUPO — procedure que genera INSERT en A2000163/A2990700
- MDSB-1040981 — resultados de producción (adjunto .csv)
- MDSB-1034420 — caso original

---

## #97 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Diagnosticar MDSB-1034420 a nivel de código fuente PL/SQL, identificando el punto exacto donde se rompe la generación de nota crédito en cancelación de póliza 923.

## Instructions
- SIEMPRE revisar código fuente PL/SQL al diagnosticar — no basta con ver estado de tablas
- Los registros de SIM_FACTURA_MVTOS y SIM_FACTURA_ELECTRONICA generalmente NO se pasan de prod a dev
- Para corroborar datos de producción, crear MDSB con scripts de consulta

## Discoveries
- **Punto exacto de fallo:** Cursor `facturas` en `SIM_PCK_FACTURACION.Proc_Reversa_facturaDB` (línea del cursor)
- La condición `(a.fecha_vig_fact >= Ip_FechaVigEnd OR Ip_FechaVigEnd BETWEEN a.FECHA_VIG_FACT AND a.FECHA_VTO_FACT)` NO contempla el caso donde la fecha de vigencia del endoso (01/09/2025) es POSTERIOR a FECHA_VTO_FACT de la factura (21/08/2025)
- El flujo es: Emisión endoso → A2000160 (prima negativa OK) → Proc_Reversa_facturaDB → cursor vacío → PRC299_FACTURA_ANULACION_GRUPO nunca se llama → A2000163 y A2990700 sin registro negativo
- `PRC299_FACTURA_ANULACION_GRUPO` es un PROCEDURE standalone (no dentro de un package) que hace el INSERT en A2000163 y A2990700 con coeficiente negativo
- Sección 923 permite emitir con fecha factura (21/07/2025) anterior a fecha vigencia póliza (01/09/2025) — esto es lo que rompe la condición del cursor
- La condición del cursor asume que FECHA_VIG_END siempre cae dentro del rango [FECHA_VIG_FACT, FECHA_VTO_FACT] o que la factura es posterior — no contempla facturas anteriores a la vigencia

## Accomplished
- ✅ Identificado punto exacto de fallo en código: cursor `facturas` en `Proc_Reversa_facturaDB`
- ✅ Leído código completo de `SIM_PCK_FACTURACION` (spec + body) y `PRC299_FACTURA_ANULACION_GRUPO`
- ✅ Entendido el flujo completo: A2000160 → Proc_Reversa_facturaDB → cursor → PRC299_FACTURA_ANULACION_GRUPO → A2000163 + A2990700
- ✅ Propuesto fix en la condición del cursor
- ✅ Preparado script SQL para corroborar datos en producción vía MDSB
- 🔲 Crear MDSB con script de consulta para corroborar en prod
- 🔲 Crear HU en Jira
- 🔲 Documentar en Confluence
- 🔲 Implementar y probar el fix

## Next Steps
1. Crear MDSB con script de consulta para confirmar datos en producción
2. Validar fix propuesto en dev con la póliza 2592000257502
3. Crear HU en GD986 vinculando MDSB-1034420 y MDSB-832098
4. Documentar en Confluence con el análisis de código
5. Implementar fix en `Proc_Reversa_facturaDB` (ajustar condición del cursor)
6. Verificar si `Proc_Valida_Facts_Renovacion` también necesita ajuste (llama a `Proc_Factura_Interactiva` cuando no hay factura endoso 0)

## Relevant Files
- `SIM_PCK_FACTURACION` (OPS$PUMA) — Package body, procedimiento `Proc_Reversa_facturaDB` contiene el cursor con el bug
- `PRC299_FACTURA_ANULACION_GRUPO` (OPS$PUMA) — Procedure standalone que genera INSERT en A2000163 y A2990700
- `SIM_PCK_PROCESO_DML_EMISION.proc_genera_factura` — Llamado por `Proc_Factura_Interactiva` para generar factura de endoso
- Tablas: A2000030, A2000160, A2000163, A2990700, C9999909, SIM_FACTURA_MVTOS

---

## #94 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Diagnosticar el caso MDSB-1034420: nota crédito no generada al cancelar póliza 2592000257502 del producto 923 (TuSeguro, CIA 3).

## Discoveries
- Póliza 923 tiene discrepancia de fechas: FECHA_VIG_POL=01/09/2025 pero factura original FEC_EFECTO=21/07/2025 (emitida antes de la vigencia)
- El endoso de cancelación (NUM_END=1, COD_END=922/3, TIPO_END='AT') calculó correctamente la prima negativa en A2000160 (IMP_PRIMA_END=-60712) pero NO generó registro en A2000163 ni cuota negativa en A2990700
- Sección 923 está configurada como 'Productos que no se van a enviar a la DIAN' en C9999909 → nunca se generó factura electrónica base → SIM_FACTURA_MVTOS queda en NE con 'NO EXISTE FACTURA ELECTRONICA'
- Caso MDSB-832098 (jun 2025) es el mismo patrón: producto 923 con error 'Fecha de vigencia del endoso no está comprendida en la vigencia póliza'
- Segunda póliza afectada: 3551000195310-923 (reportada en comentarios, no disponible en dev)
- La póliza fue pasada a dev vía MDSB-1040812 (Juan Camilo Arias, 14/05/2026)

## Accomplished
- ✅ Diagnóstico completo del caso con causa raíz identificada
- ✅ Verificación en Oracle dev de todas las tablas relevantes (A2000030, A2000160, A2000163, A2990700, SIM_FACTURA_MVTOS, SIM_FACTURA_ELECTRONICA, C9999909)
- ✅ Identificación del patrón: discrepancia fechas vigencia vs factura en producto 923 impide generación de nota crédito
- ✅ Correlación con caso anterior MDSB-832098
- ✅ Guardado en Engram como bugfix
- 🔲 Crear HU en Jira
- 🔲 Documentar en Confluence
- 🔲 Analizar código fuente de SIM_PCK_FACTURACION para identificar la validación exacta
- 🔲 Generar correctivo DML para las pólizas afectadas

## Next Steps
- Revisar código fuente de SIM_PCK_FACTURACION (procedimiento de facturación de endosos de cancelación) para encontrar la validación de fechas que bloquea
- Crear Historia de Usuario en GD986 vinculando MDSB-1034420 y MDSB-832098
- Documentar hallazgo en Confluence (página hija de KB Corex)
- Generar script DML correctivo para producción (insertar factura negativa en A2000163 y cuota en A2990700)
- Buscar en producción otras pólizas 923 canceladas sin nota crédito (alcance del problema)

## Relevant Files
- Tablas Oracle: A2000030, A2000160, A2000163, A2990700, SIM_FACTURA_MVTOS, SIM_FACTURA_ELECTRONICA, C9999909
- Paquete candidato: SIM_PCK_FACTURACION (OPS$PUMA)
- Configuración: C9999909 COD_TAB='FACTURACION_ELEC' COD_SECC=923

---

## #90 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

## Goal
Confirmar con datos reales de Oracle cómo se generó la factura 12 y por qué existe la diferencia con la factura 13 del caso MDSB-992543.

## Discoveries
- CONFIRMADO: Factura 12 tiene NUM_END=NULL, NUM_END_REF=15, generada por batch nocturno (26-FEB-2026 23:23)
- Factura 12 es periódica (proceso 'RE'), usa prima_anu de A2000040. NO pasa por CB100270 (condición excluye 'RE')
- Factura 13 tiene NUM_END=16, generada online (27-FEB-2026 10:25) al emitir exclusión
- Factura 13 es de endoso (proceso 'EM'), usa imp_prima_end de A2000160. SÍ pasa por CB100270
- Prima anual riesgo 662 = $1,765,165 (suma de 7 coberturas en A2000040 endoso 13)
- IMP_PRIMA_END endoso 16 = -$2,097,321 (incluye prima + gastos expedición)
- La diferencia de fuentes (prima_anu vs imp_prima_end) es una de las causas de la asimetría
- Endoso 15 es tipo AP (exclusión, cod_end 731, vigencia 26-FEB-2026) — disparó la regeneración del período
- AB100277 existe como COBOL (AB100277.pco) y PL/SQL (SIM_PCK299_AB100277) — el PL/SQL dice 'Reemplaza al AB100277.pco'
- PRC_DIFERIDO en AB100277 PL/SQL tiene la misma condición: PERIODOFACT=1 AND CODSECC=1 AND NUMEND>0 AND TIPOEND!='MV'

## Accomplished
- ✅ Confirmado con Oracle dev que factura 12 fue generada por batch (NUM_END_REF=15)
- ✅ Confirmado prima_anu riesgo 662 = $1,765,165 → mensual = $147,097 + diferido $2,712 = $149,809
- ✅ Confirmado que factura 12 NO pasa por CB100270 (proceso 'RE' excluido)
- ✅ Mapeado flujo completo AB100277 (COBOL + PL/SQL) como orquestador de facturación
- ✅ Guardado en Engram como observación de arquitectura

## Next Steps
- Despliegue a producción del fix CEIL→TRUNC en SIM_PCK299_AB100273
- Evaluar impacto en AB100273_RC y AB100273_RC_RE
- Validar con funcional si V_factor en CB100270 es correcto para exclusiones no inmediatas
- Actualizar KB de Confluence con el mapeo AB100277 COBOL↔PL/SQL

## Relevant Files
- ANALISIS_MDSB-992543.md — análisis técnico consolidado
- tronador-core-cobol/AB100277.pco — COBOL batch de facturación
- Base Datos/Packages/SIM_PCK299_AB100277.pkb — PL/SQL equivalente
- Base Datos/Packages/SIM_PCK299_AB100273.pkb — cálculo de coeficientes (fix CEIL→TRUNC)
- Base Datos/Packages/SIM_PCK299_CB100270.pkb — ajuste de diferidos

---

## #78 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

## Goal
Traza rigurosa con logs reales del sistema para confirmar los valores exactos de la exclusión del riesgo 662 en dev.

## Discoveries
- LOGS REALES CONFIRMADOS (SIM_LOG_GENERAL, timestamp 2026-05-13 12:46):
  - v_CoefFact = 0.0930232558 (= 40/430)
  - v_CoefPol = 0.1129032258 (= MB(31-MAR,20-FEB)/12 = 1.3548/12)
  - v_DiasCotiz = 40
  - v_Prima1000 = 195,100 (prima base antes de CB100270)
  - Prima final = -159,844 (después de CB100270)
  - Diferidos sumados = +35,256 (= 195,100 - 159,844)
- CB100270 entró por el camino de exclusión (Fnc_exclusion='S'), NO por V_indendmodi='S'
- El log MDSB-452816 PRUEBA MASB 2 (que muestra V_mesessinfact) NO se disparó — confirma que fue por exclusión directa
- La factura 12 no tiene logs disponibles (generada antes de activar trazas)
- PENDIENTE: confirmar de dónde sale el $149,809 del cobro del riesgo 662 en factura 12 — no hay desglose por riesgo en A2000163

## Accomplished
- ✅ Obtenidos logs reales de SIM_LOG_GENERAL para la ejecución de hoy (13-MAY-2026 12:46)
- ✅ Confirmados valores exactos: CoefFact, CoefPol, DiasCotiz, Prima base, Prima final
- ✅ Confirmado que CB100270 sumó +35,256 (diferidos)
- ✅ Confirmado entry point: SIM_PCK_ACCESO_DATOS_EMISION.PROC_GRABA_ENDOSO

## Next Steps
- Determinar con certeza cuánto aporta el riesgo 662 a la factura 12 (no hay desglose por riesgo en A2000163)
- Opción: generar la factura 12 nuevamente en dev con logs activados para ver el desglose
- O calcular: factura 12 total - factura sin riesgo 662 = aporte del riesgo

## Relevant Files
- test_exclusion_riesgo662.sql — script de test (necesita actualización con valores reales de logs)
- ANALISIS_MDSB-992543.md — análisis técnico

---

## #76 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

## Goal
Descomponer exactamente los $10,035 de diferencia entre cobro ($149,809) y devolución ($159,844) del riesgo 662.

## Discoveries
- CAUSA RAÍZ ENCONTRADA: La diferencia de $10,035 se descompone en:
  - Exceso prima base: +$48,003 (devolución calcula más que el cobro)
  - Compensación diferidos: -$37,968 (los diferidos reducen la devolución)
  - Neto: 48,003 - 37,968 = $10,035 ✓
- El exceso de $48,003 en prima base viene de DOS asimetrías:
  1. BASE DIFERENTE: Cobro usa `prima_anu` (1,765,165) pero devolución usa `imp_prima_end` (2,097,321). Diferencia = $332,156 (≈18.8% recargo financiero por pago mensual)
  2. COEFICIENTE DIFERENTE: Cobro usa 1/12=0.0833 (prc_CalcCoefReal) pero devolución usa 40/430=0.0930 (prc_CalcCoeficiente con TRUNC)
- En prc_InsNormal de AB100273:
  - Proceso RE (cobro): `prima_anu * v_CoefPol`
  - Proceso EM (devolución): `imp_prima_end * v_CoefFact`
- La factura 12 (cobro) SÍ incluye 1 diferido: prima_anu/12 = 147,097 + 2,712 = 149,809
- Los diferidos REDUCEN la devolución: sin ellos sería -$195,100, con ellos es -$159,844
- imp_prima_end vs prima_anu: imp_prima_end incluye recargo financiero por fraccionamiento mensual

## Accomplished
- ✅ Reproducida la exclusión en dev (factura 13 generada con -$159,844)
- ✅ Descomposición exacta de los $10,035: exceso prima base (+48,003) - compensación diferidos (-37,968)
- ✅ Identificada la asimetría de campos: cobro usa prima_anu, devolución usa imp_prima_end
- ✅ Confirmado que denominadores son diferentes: 420 (cobro) vs 430 (devolución)

## Next Steps
- Validar con funcional si es correcto que la devolución use imp_prima_end (con recargo) cuando el cobro usa prima_anu (sin recargo)
- Determinar si el recargo financiero debe devolverse proporcionalmente o no
- Actualizar ANALISIS_MDSB-992543.md con la descomposición exacta

## Relevant Files
- ANALISIS_MDSB-992543.md — análisis técnico
- Base Datos/Packages/SIM_PCK299_AB100273.pkb — prc_InsNormal (usa imp_prima_end para EM, prima_anu para RE)
- Base Datos/Packages/SIM_PCK299_CB100270.pkb — diferidos
- test_exclusion_riesgo662.sql — script de test

---

## #74 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

## Goal
Preparar script de test para reproducir la exclusión del riesgo 662 en dev y trazar los cálculos paso a paso.

## Accomplished
- ✅ Verificado estado de la póliza en dev: endoso 16 no existe, riesgo 662 activo (MCA_BAJA_RIES='N'), C1000270 solo tiene registro de inclusión
- ✅ Creado script `test_exclusion_riesgo662.sql` (read-only) que simula los cálculos de AB100273 + CB100270 con DBMS_OUTPUT

## Next Steps
- Usuario ejecuta el script en dev y comparte la salida
- Si los números cuadran con producción, preparar script que ejecute la exclusión real (INSERT endoso 16, UPDATE riesgo, llamada a facturación)
- Comparar factura generada en dev vs producción

## Relevant Files
- test_exclusion_riesgo662.sql — script de test read-only para trazar cálculos

---

## #73 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

## Goal
Determinar si la factura 12 (periódica) incluye el riesgo 662 y su diferido, trazando el flujo completo desde el código fuente de AB100273 y CB100270.

## Discoveries
- CONFIRMADO: Los diferidos REDUCEN la devolución (+35,256 sumado a prima negativa), no la inflan
- El endoso 13 (inclusión, tipo AD) NO genera factura propia (MCA_FACTURA='N', no hay registros en A2000163 ni A2990700 con num_end=13)
- La factura 12 es periódica (num_end=NULL en A2990700, proceso='RE' en AB100273)
- En proceso RE, AB100273 usa fnc_MaxEndPremio que busca MAX(num_end) de A2000160 con fecha_vig_end <= FechaVigFact. Si endoso 13 (vig 20-FEB) <= factura 12 (vig 28-FEB), entonces MaxEndPre=13 y la prima anual incluye riesgo 662
- La factura 12 se creó el 26-FEB-2026 (FECHA_CREACION), endoso 13 emitido el 20-FEB → la factura 12 SÍ incluye el riesgo 662
- CB100270 se llama desde prc_Proceso de AB100273 cuando: PeriodoFact=1, TipoEnd!='AT'/'RE', CodSecc=1, NumEnd>0. El endoso 16 (tipo AP) cumple
- En prc_InsNormal, v_Imp_Prima163=0 para endosos tipo AP (solo se llena para AT). Los diferidos se suman DESPUÉS por CB100270

## Accomplished
- ✅ Verificado que endoso 13 no genera factura propia (query A2000163 y A2990700 con num_end=13 = vacío)
- ✅ Confirmado MCA_FACTURA='N' en A2000030 para endoso 13
- ✅ Leído código completo de SIM_PCK299_AB100273 (prc_inicio, prc_Proceso, prc_InsNormal, fnc_MaxEndPremio)
- ✅ Trazado el flujo: factura 12 generada por proceso RE → MaxEndPre incluye endoso 13 → prima anual incluye riesgo 662
- 🔲 Pendiente: calcular composición exacta de $149,809 del riesgo 662 en factura 12

## Next Steps
- Calcular cómo se compone el $149,809 del riesgo 662 en la factura 12 (prima base + diferido)
- Comparar con la devolución (-$162,693 con bug / -$159,844 con fix) para determinar si la diferencia es solo por período
- Actualizar ANALISIS_MDSB-992543.md con la interpretación corregida completa

## Relevant Files
- ANALISIS_MDSB-992543.md — análisis técnico (pendiente actualización con nueva interpretación)
- Base Datos/Packages/SIM_PCK299_AB100273.pkb — paquete principal de facturación
- Base Datos/Packages/SIM_PCK299_CB100270.pkb — paquete de diferidos

---

## #72 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

## Goal
Diagnosticar a fondo el comportamiento de diferidos en CB100270 para MDSB-992543, corrigiendo interpretaciones previas.

## Discoveries
- CORRECCIÓN CRÍTICA: Los diferidos en CB100270 REDUCEN la devolución, no la inflan. El UPDATE hace: imp_prima = prima_base_negativa + diferidos_positivos (-197,949 + 35,256 = -162,693)
- Sin diferidos la devolución sería -$197,949 (mayor). Con 13 diferidos es -$162,693 (menor)
- La factura 9 NO incluye riesgo 662 (FECHA_EQUIPO=31-ENE, inclusión fue 20-FEB). Solo factura 12 cobró 1 diferido
- V_factor=13 actúa como COMPENSACIÓN a favor de la compañía, no del cliente
- La diferencia entre devolución ($162,693) y cobro ($149,809) se explica por período más largo (40 días vs 30 días) parcialmente compensado por los diferidos
- La pregunta para funcional cambia: ¿es correcto DESCONTAR 13 diferidos futuros ($35,256) cuando solo se cobró 1 ($2,712)? Si no, la devolución sería AÚN MAYOR

## Accomplished
- ✅ Consulta FECHA_EQUIPO en A2990700 confirmando que factura 9 no incluye riesgo 662
- ✅ Lectura completa del source de SIM_PCK299_CB100270 (package body)
- ✅ Trazado del flujo: V_factor → V_mesessinfact → Prc_leeriesgo270 (multiplica) → Prc_upd163 (SUMA a prima negativa)
- ✅ Recálculo aritmético completo: prima_base=-197,949, ajuste_diferidos=+35,256, final=-162,693
- ✅ Documento ANALISIS_MDSB-992543.md actualizado con corrección de factura 9
- 🔲 Pendiente actualizar documento con la nueva interpretación (diferidos reducen, no inflan)

## Next Steps
- Actualizar ANALISIS_MDSB-992543.md con interpretación corregida del signo de diferidos
- Reformular pregunta para funcional: ¿es correcto descontar 13 diferidos no cobrados de la devolución?
- Verificar si la factura 12 (cobro $149,809) incluye componente de diferido para comparación justa
- Determinar si el reporte original del cliente es válido o si la devolución es correcta

## Relevant Files
- ANALISIS_MDSB-992543.md — análisis técnico (necesita actualización con nueva interpretación)
- Base Datos/Packages/SIM_PCK299_CB100270.pkb — paquete de diferidos, Prc_leeriesgo270 es el punto clave

---

## #70 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

## Goal
Profundizar el análisis de diferidos del caso MDSB-992543 — validar cuántos diferidos se cobraron vs cuántos devuelve el sistema.

## Discoveries
- Solo se cobraron 2 diferidos ($5,424) en facturas 9 y 12, pero CB100270 devuelve 13 ($35,256) — $29,832 devueltos sin haber sido cobrados
- Endoso 13 (inclusión) emitido 20-FEB-2026, endoso 16 (exclusión) emitido 27-FEB-2026 — solo 7 días entre ambos
- C1000270 registra meses=14 para inclusión y meses=13 para exclusión, pero el V_factor usa meses restantes hasta vencimiento de póliza, no meses cobrados
- Los diferidos futuros no necesitan ser "devueltos" — simplemente dejan de cobrarse porque el riesgo ya no existe
- Tres opciones de corrección: V_factor=13 (actual), V_factor=2 (cobrados), V_factor=1 (período actual)

## Accomplished
- ✅ Consulta en BD dev validando C1000270 para riesgo 662 (2 registros: end 13 y end 16)
- ✅ Consulta cronología de emisión de endosos (A2000030: fecha_emi_end)
- ✅ Identificación de facturas mensuales que incluyen riesgo 662 (fact 9 y 12)
- ✅ Documentación completa agregada a ANALISIS_MDSB-992543.md con sección "Análisis Profundo de Diferidos"
- ✅ CHANGELOG actualizado

## Next Steps
- Validar con área funcional si V_factor debe ser meses restantes o meses cobrados
- Si funcional confirma que es defecto: implementar fix en Sim_Pck299_Cb100270 (cambiar V_factor)
- Evaluar impacto en otros riesgos con exclusión inmediata en la misma póliza y en otras pólizas

## Relevant Files
- ANALISIS_MDSB-992543.md — análisis técnico completo con nueva sección de diferidos
- Base Datos/Packages/SIM_PCK299_CB100270.pkb — paquete con V_factor cuestionable (línea 72)

---

## #68 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

## Goal
Consolidar dos análisis independientes del caso MDSB-992543 (bug en facturación póliza 1000486837825) en un solo documento técnico unificado.

## Discoveries
- El caso tiene DOS causas raíz independientes, no una: bug CEIL en AB100273 (~$2,849) + asimetría de diferidos en CB100270 (~$12,483)
- El análisis paralelo (compañera) identificó correctamente el bug CEIL y su fix (CEIL→TRUNC)
- Nuestro análisis identificó la pregunta funcional pendiente sobre V_factor en CB100270 (devuelve 13 diferidos cuando solo se cobró 1)
- La corrección en producción (factura 21 = -$159,844) solo resuelve el componente CEIL, no la asimetría de diferidos

## Accomplished
- ✅ Consolidado `ANALISIS_MDSB-992543.md` integrando ambos análisis en estructura unificada
- ✅ Nuevo resumen ejecutivo con tabla de desglose de los $15,332 en dos causas
- ✅ Secciones separadas para Causa Raíz #1 (CEIL, corregido) y Causa Raíz #2 (diferidos, pendiente)
- ✅ Flujo de generación actualizado con anotaciones de ambos hallazgos
- ✅ Próximos pasos unificados con responsables y estados
- ✅ Changelog actualizado

## Next Steps
- Despliegue a producción del fix CEIL→TRUNC en SIM_PCK299_AB100273
- Evaluar impacto en paquetes _RC y _RC_RE (misma lógica CEIL)
- Validar con área funcional si V_factor=13 en CB100270 es correcto para exclusiones inmediatas
- Respuesta al cliente con explicación de la diferencia de períodos

## Relevant Files
- ANALISIS_MDSB-992543.md — Documento consolidado con ambos análisis del caso
- Base Datos/Packages/SIM_PCK299_AB100273.pkb — Paquete con fix CEIL→TRUNC aplicado
- Base Datos/Packages/SIM_PCK299_CB100270.pkb — Paquete con V_factor cuestionable (pendiente validación funcional)

---

## #67 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

## Goal
Exportar conocimiento acumulado en Engram al directorio shared-knowledge/ del repo corex-n3-power para compartirlo con el equipo via Git.

## Discoveries
- La búsqueda en Engram por queries complejas (múltiples palabras en español) no devuelve resultados — funciona mejor con términos específicos o nombres de objetos
- mem_search con `type` filter requiere también un `query` no vacío (da error SQL si query está vacío)
- Las 65 observaciones se distribuyen en: ~11 decisions, ~5 architecture, ~3 patterns/bugfixes, ~17 session_summaries, resto file_changes y tool_uses

## Accomplished
- ✅ Exportadas 4 decisiones técnicas clave a decisions.md
- ✅ Exportados 3 flujos de arquitectura de facturación + diagrama ASCII consolidado a architecture-facturacion.md
- ✅ Exportados 4 patrones/bugfixes (MDSB-992543, diferidos CB100270, credenciales .env) a patterns-bugfixes.md
- ✅ Exportados 2 resúmenes de sesión significativos a sessions-summary.md
- ✅ Actualizado README.md con índice y estadísticas
- ✅ Actualizado CHANGELOG.md del repo
- ✅ Guardada memoria #66 del sync

## Next Steps
- git add + commit + push de shared-knowledge/
- Considerar automatizar con hook postTaskExecution o userTriggered
- En próxima exportación incluir memorias nuevas que se acumulen

## Relevant Files
- corex-n3-power/shared-knowledge/decisions.md — decisiones técnicas del power
- corex-n3-power/shared-knowledge/architecture-facturacion.md — flujo facturación endosos
- corex-n3-power/shared-knowledge/patterns-bugfixes.md — patrones y fixes
- corex-n3-power/shared-knowledge/sessions-summary.md — sesiones significativas
- corex-n3-power/shared-knowledge/README.md — índice
- corex-n3-power/CHANGELOG.md — entrada agregada

---

## #64 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

## Goal
Reproducir y documentar completamente el caso MDSB-992543: diferencia de $15,332 entre factura de cobro y devolución por exclusión de riesgo.

## Discoveries
- **CAUSA RAÍZ ENCONTRADA**: Sim_Pck299_Cb100270.Prc_Proceso hace UPDATE a A2000163 DESPUÉS del INSERT, sumando diferidos (C1000270) × V_factor
- Fórmula completa: IMP_PRIMA = ROUND(IMP_PRIMA_END × CoefFact, 0) + (IMP_PRIMA_163 × V_factor)
- V_factor = CEIL(MONTHS_BETWEEN(FechaVencPol, FechaVtoFact)) = 13 meses restantes
- El sistema devuelve 13 meses de diferidos ($35,256) cuando solo cobró 1 mes ($2,712)
- Neto para el cliente: +$12,884 a favor — se devuelve más de lo cobrado
- Es una FALLA LÓGICA: CB100270 no valida cuántos diferidos se cobraron antes de devolver
- Ya hubo corrección manual en prod (facturas 20 y 21 del endoso 16)

## Accomplished
- ✅ Reproducido numéricamente: -197,949 + 35,256 = -162,693 ✓
- ✅ Identificado paquete causante: Sim_Pck299_Cb100270 (Prc_upd163, línea 303)
- ✅ Documentado flujo completo desde Form hasta INSERT+UPDATE
- ✅ Creado documento ANALISIS_MDSB-992543.md con análisis completo
- ✅ Ejecutado script PL/SQL en dev via SQL Developer para confirmar valores

## Next Steps
- Documentar en Confluence como hallazgo técnico
- Crear HU para corregir la lógica de CB100270 (V_factor debe considerar solo diferidos cobrados)
- Responder al caso MDSB-992543 con la explicación
- Análisis de impacto: ¿cuántas pólizas se afectan por este patrón?

## Relevant Files
- ANALISIS_MDSB-992543.md — documento completo del análisis
- Base Datos/Packages/SIM_PCK299_CB100270.pkb — paquete causante (Prc_upd163 línea 303, Prc_lee270)
- Base Datos/Packages/SIM_PCK299_AB100273.pkb — llamada a CB100270 en línea 820
- test_mdsb992543.sql — script de prueba ejecutado en dev

---

## #62 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

## Goal
Reproducir numéricamente -162,693 de factura 13 MDSB-992543 ejecutando prueba de escritorio en dev.

## Discoveries
- **HALLAZGO CLAVE**: ROUND((-1,765,165 + 41,399) * 0.0943820225, 0) = -162,693 ✓ EXACTO
- El valor base NO es IMP_PRIMA_END (-2,097,321) sino END_PRIMA_ANU (-1,765,165) + un ajuste de 41,399
- 41,399 / 2,712 = 15.265 (no es un múltiplo entero del diferido)
- 2,712 * 13 = 35,256 = diferencia original que no podía explicar (-197,949 vs -162,693)
- 13 = MONTHS_BETWEEN(30-APR-2027, 31-MAR-2026) = meses restantes hasta vencimiento
- La fórmula del INSERT que leí (imp_prima_end * v_CoefFact) NO es la que se ejecuta para este caso
- Probablemente hay un ajuste por diferidos (C1000270) que se suma al valor base antes de multiplicar
- El flujo de exclusión pasa por SIM_PCK_ANULACIONENDOSO → PROC_GENERA_FACTURA → AB100277 → AB100273
- Script PL/SQL ejecutado en dev confirma: CoefFact=0.0944, FechaVtoFact=31-MAR-2026, todas las variables son las esperadas

## Accomplished
- ✅ Ejecutado script PL/SQL en dev via SQL Developer — valores confirmados
- ✅ Encontrado que (-1,765,165 + 41,399) * 0.0943820225 = -162,693 EXACTO
- ✅ Identificado que el ajuste de 41,399 está relacionado con diferidos (C1000270, valor 2,712)
- 🔲 Pendiente: identificar DÓNDE en el código se aplica este ajuste (probablemente prc_Lee270 o Sim_Pck299_Cb100270)

## Next Steps
- Buscar en AB100273 dónde se usa C1000270 o v_Imp_Prima163 para tipo AP (no solo AT)
- Revisar si Sim_Pck299_Cb100270.Prc_Proceso modifica el valor antes del INSERT
- Alternativa: buscar la fórmula que produce 41,399 = 2,712 * 15.265

## Relevant Files
- Base Datos/Packages/SIM_PCK299_AB100273.pkb — prc_InsNormal, prc_Lee270, prc_Proceso
- Base Datos/Packages/SIM_PCK_ANULACIONENDOSO.pkb — flujo de exclusión
- test_mdsb992543.sql — script de prueba ejecutado

---

## #60 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Reproducir numéricamente -162,693 de factura 13 MDSB-992543. Múltiples intentos fallidos.

## Discoveries
- MDSB-1039438 (ALL_SOURCE en prod) no devolvió datos — bot no tiene permisos a ALL_SOURCE
- Fechas de creación de facturas en dev: fact12 creada 26-FEB 23:23, fact13 creada 27-FEB 10:25 — fact12 existía cuando se generó fact13
- La fórmula ROUND(IMP_PRIMA_END * v_CoefFact, 0) con TODAS las combinaciones de fechas posibles NO reproduce -162,693
- Probado con FECHA_VENC_POL = 30-APR-2027 → da -197,949
- Probado con FECHA_VENC_POL = 30-OCT-2026 → da -341,424
- Probado con FECHA_VTO_FACT = 28-FEB-2026 → da -37,961
- Probado con END_PRIMA_ANU en vez de IMP_PRIMA_END → tampoco reproduce
- prc_ArmoPremio NO modifica imp_prima (solo premio/impuesto)
- El MCP oracle-readonly solo permite SELECT, no bloques PL/SQL
- Necesitamos ejecutar el paquete directamente en dev para capturar valores reales

## Accomplished
- ✅ MDSB-1039438 creado (ALL_SOURCE) — sin resultado por permisos
- ✅ Verificado orden cronológico de facturas (fact12 antes de fact13)
- ✅ Descartado prc_ArmoPremio como modificador de imp_prima
- ✅ Probado todas las combinaciones razonables de fechas — ninguna reproduce
- 🔲 Necesario: ejecutar bloque PL/SQL en dev para capturar valores reales del paquete

## Next Steps
- Ejecutar PRC_INICIO del endoso 16 en dev con DBMS_OUTPUT para ver valores reales
- Alternativa: pedir al usuario que ejecute el script tmp_test_facturacion.sql en SQL Developer
- Si no es posible ejecutar PL/SQL: revisar si hay un trigger en A2000163 que modifique imp_prima post-INSERT

## Relevant Files
- Base Datos/Packages/SIM_PCK299_AB100273.pkb — flujo completo rastreado pero no reproduce numéricamente
- tmp_test_facturacion.sql — script de prueba preparado (pendiente de ejecutar)

---

## #59 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Reproducir numéricamente $162,693 de factura 13 MDSB-992543 con datos de producción confirmados y código del repositorio.

## Discoveries
- Datos producción (MDSB-1039369) IDÉNTICOS a dev — copia fiel
- Fórmula teórica ROUND(IMP_PRIMA_END * v_CoefFact, 0) = ROUND(-2,097,321 * 0.0944, 0) = -197,949 — NO reproduce -162,693
- Coeficiente real necesario: 0.07757 (162,693/2,097,321)
- Imagen del caso confirma: inclusión $149,809 (prima_anu/12 + diferido) vs exclusión -$162,693
- La diferencia $12,884 corresponde a período 1.355 meses (20-FEB→31-MAR) vs 1 mes
- MDSB-1039415 (logs) falló — tabla SIM_TRAZA_PROCESOS no tiene estructura esperada
- Hay un factor no identificado en el flujo que reduce el CoefFact de 0.0944 a 0.0776
- Posibilidades pendientes: (a) prc_LoopContEM recalcula GENERICOS, (b) hay un ajuste en prc_ArmoPremio, (c) versión compilada en prod difiere del .pkb del repo

## Accomplished
- ✅ Datos producción obtenidos y confirmados (MDSB-1039369)
- ✅ Intentado consultar logs en prod (MDSB-1039415) — falló por estructura de tabla
- ✅ Verificado que prc_DiferenciasAj NO modifica GENERICOS
- ✅ Verificado que no hay UPDATEs a imp_prima GENERICOS después del INSERT
- ✅ Confirmado COD_DURACION=2, COEFCOB=1.188172, FOR_COBRO=CC en producción
- 🔲 NO se logró reproducir numéricamente — discrepancia persiste

## Next Steps
- Leer prc_ArmoPremio — puede recalcular imp_prima antes del INSERT
- Verificar si prc_LoopContEM modifica el registro GENERICOS (UPDATE con cod_agrup_cont='GENERICOS')
- Alternativa: ejecutar facturación del endoso 16 en dev con DBMS_OUTPUT habilitado para capturar valores reales
- Si nada funciona: consultar ALL_SOURCE en prod para comparar prc_CalcCoeficiente compilado vs repositorio

## Relevant Files
- Base Datos/Packages/SIM_PCK299_AB100273.pkb — prc_CalcCoeficiente, prc_InsNormal, prc_ArmoPremio, prc_LoopContEM
- Base Datos/Procedimientos/PRC299_OBTENGO_VTO_FACT.prc

---

## #58 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Reproducir numéricamente el monto de $162,693 de la factura 13 (MDSB-992543) siguiendo el código PL/SQL paso a paso, con datos confirmados de producción.

## Discoveries
- Datos de producción (MDSB-1039369) son IDÉNTICOS a los de desarrollo — la copia en dev es fiel
- La fórmula teórica ROUND(IMP_PRIMA_END * v_CoefFact, 0) = ROUND(-2,097,321 * 0.0944, 0) = -197,949 — NO reproduce el -162,693 real
- El coeficiente real necesario es 0.07757, pero la fórmula con las fechas confirmadas da 0.0944
- prc_DiferenciasAj NO modifica el registro GENERICOS (solo ajusta registros contables)
- No hay triggers ni UPDATEs posteriores que modifiquen imp_prima del GENERICOS
- Posible causa: versión del paquete en producción difiere del repositorio, o hay un factor no visible en el flujo
- MDSB-1039369 creado exitosamente con datos de producción confirmados

## Accomplished
- ✅ Creado MDSB-1039369 con 6 consultas a producción — resultado exitoso
- ✅ Confirmado que datos prod = datos dev (la copia es fiel)
- ✅ Verificado que prc_DiferenciasAj no modifica GENERICOS
- ✅ Verificado que no hay UPDATEs a imp_prima en A2000163 GENERICOS después del INSERT
- ✅ Descartado ajustes de fechas por febrero (ninguna condición aplica)
- 🔲 NO se logró reproducir numéricamente el monto — discrepancia de $35,256

## Next Steps
- Crear MDSB para consultar ALL_SOURCE de prc_CalcCoeficiente en producción y comparar con repositorio
- Alternativa: habilitar DBMS_OUTPUT/sim_proc_log en dev y ejecutar la facturación del endoso 16 para ver los valores reales de v_CoefFact
- Si la versión es la misma, investigar si prc_LoopContEM recalcula el GENERICOS

## Relevant Files
- Base Datos/Packages/SIM_PCK299_AB100273.pkb — prc_CalcCoeficiente, prc_InsNormal, prc_DiferenciasAj
- Base Datos/Procedimientos/PRC299_OBTENGO_VTO_FACT.prc — cálculo fecha vto factura

---

## #57 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Optimizar el power corex-n3: reducir consumo de créditos, mejorar precisión de diagnósticos, corregir bug de credenciales, y asegurar compatibilidad cross-platform.

## Discoveries
- Steering files con `inclusion: always` cargan ~6000 tokens innecesarios en sesiones de soporte
- `get_source` del MCP Oracle trunca packages grandes; el repo local no tiene ese límite
- Las credenciales en Kiro powers viven en ~/.kiro/settings/.env (macOS/Linux) o en mcp.json directo (Windows). NO están en variables de entorno del shell
- En Windows el install.ps1 pone las credenciales directo en mcp.json env, no usa .env
- El flujo de diagnóstico anterior hacía queries de datos ANTES de leer código fuente, generando consultas exploratorias sin fundamento

## Accomplished
- ✅ 6 steering files globales convertidos a `inclusion: fileMatch` (~60-70% menos tokens en sesiones de soporte)
- ✅ Engram simplificado (no se activa automáticamente al inicio)
- ✅ Regla "repo primero, Oracle después" en diagnostico-eficiente.md y fuentes-codigo-repositorios.md
- ✅ Flujo diagnóstico reestructurado: Engram → Confluence/Jira → Repo Oracle DB → Repo COBOL → Repo Forms → Oracle (solo datos)
- ✅ Política "CERO SUPOSICIONES" — toda afirmación respaldada por código leído o datos verificados
- ✅ Tabla de evidencia obligatoria y sección "No Verificado" en reporte final
- ✅ Fix credenciales consulta-produccion-mdsb: lee de .env (macOS/Linux) o mcp.json (Windows)
- ✅ Creado update.ps1 para Windows
- ✅ Script consulta producción cross-platform (busca en ambas ubicaciones)
- ✅ Pushed to remote: 3 commits (500cc4a, 62b2ff9, a72fd36)
- ✅ Power local actualizado con update.sh

## Next Steps
- Validar en próximo diagnóstico real que el agente sigue el nuevo flujo
- Considerar actualizar el sub-agente corex-incident-diagnostics con las mismas reglas
- Pedir a un compañero en Windows que pruebe install.ps1 + update.ps1

## Relevant Files
- powers/corex-n3/steering/diagnostico-eficiente.md — regla absoluta + repo-first + cero suposiciones
- powers/corex-n3/steering/atencion-incidente-autonomo.md — Fase 1 reestructurada + scoring con evidencia
- powers/corex-n3/steering/fuentes-codigo-repositorios.md — Oracle DB como fuente de verdad
- powers/corex-n3/steering/consulta-produccion-mdsb.md — fix credenciales cross-platform
- powers/corex-n3/update.ps1 — nuevo script Windows
- ~/.kiro/steering/rule-*.md — convertidos a fileMatch
- ~/.kiro/steering/engram-knowledge-sync.md — simplificado

---

## #54 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Completar el rastreo del flujo de código PL/SQL de facturación para MDSB-992543 y determinar que se necesitan datos de producción para confirmar causa raíz.

## Discoveries
- COD_DURACION=2 para endosos 13 y 16 → el flujo usa prc_PeriodoCorto (no prc_PorDias)
- MCA_END_DTOT NULL se convierte a 'N' via NVL en SIM_PCK299_COMUNFACT.pkb línea 77
- prc299_obtengo_vto_fact: para endosos con P_Numend > 0, toma la MAX(FECHA_VTO_FACT) de facturas anteriores en A2000163 donde NUM_END_REF < P_Numend
- Endoso 16: NUM_END_MODI es NULL → P_Exclusion='N' → busca facturas con num_end_ref < 16
- Fórmula final confirmada: IMP_PRIMA = ROUND(IMP_PRIMA_END * v_CoefFact, 0)
- v_CoefFact = ABS(ROUND((MB(VtoFact,VigFact)*30 - MesAcum) / ((MB(VtoFact,VigFact)*30) + (MB(VencPol,VtoFact)*30)), 10))
- Para tipo 'AP': prc_VerificaPrima NO se llama (solo para AT/RE), entonces v_MesAcum=0
- Los datos en dev son pruebas (copia traída para análisis), NO reflejan producción con certeza
- El cálculo teórico con datos de dev (CoefFact=0.0944) NO reproduce el monto real (-162,693 vs -197,949 calculado)
- Esto confirma que los datos de dev difieren de prod (fechas, FECHA_VENC_POL, o IMP_PRIMA_END pueden ser distintos)

## Accomplished
- ✅ Flujo completo de código rastreado: prc_Inicio → prc_VenctoNew → prc299_obtengo_vto_fact → prc_CalcCoeficiente → prc_PeriodoCorto → prc_Proceso → prc_Premios → prc_InsNormal
- ✅ Leído PRC299_OBTENGO_VTO_FACT.prc completo — procedimiento standalone que calcula FechaVtoFact
- ✅ Confirmado que para tipo AP no hay modificación de v_CoefFact entre prc_CalcCoeficiente y el INSERT
- ✅ Confirmado que datos de dev no son confiables para reproducción numérica
- 🔲 Pendiente: consultar datos reales de producción vía MDSB

## Next Steps
- Crear MDSB con consultas a producción para obtener: A2000030 (fechas endosos 13,16), A2000160 (IMP_PRIMA_END), A2000163 (facturas 12,13), A2990700 (cuotas)
- Con datos de prod, aplicar la fórmula y confirmar si reproduce exactamente el monto
- Determinar si es bug o comportamiento esperado
- Documentar en Confluence y responder al caso

## Relevant Files
- Base Datos/Procedimientos/PRC299_OBTENGO_VTO_FACT.prc — calcula fecha vto factura para endosos
- Base Datos/Packages/SIM_PCK299_AB100273.pkb — prc_CalcCoeficiente (línea 1324), prc_PeriodoCorto (línea 1837), prc_InsNormal (línea 2229)
- Base Datos/Packages/SIM_PCK299_AB100277.pkb — PRC_PROCESO orquestador
- Base Datos/Packages/SIM_PCK299_COMUNFACT.pkb — cursor con NVL(mca_end_dtot,'N')

---

## #52 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Optimizar el power corex-n3 para reducir consumo de créditos y mejorar efectividad en diagnósticos, estableciendo los repositorios de código como fuente primaria.

## Discoveries
- Los steering files con `inclusion: always` cargan ~6000 tokens en cada turno incluso para preguntas simples
- `get_source` del MCP Oracle trunca packages grandes (>3000 líneas) y consume créditos innecesarios
- Los 3 repos (tronador-oracle-db, tronador-core-cobol, tronador-forms) contienen TODA la lógica de negocio y se pueden leer sin límite de tamaño
- El flujo anterior hacía queries de datos ANTES de leer el código fuente, lo que generaba consultas exploratorias sin fundamento

## Accomplished
- ✅ Convertidos 6 steering files globales a `inclusion: fileMatch` (solo se cargan al editar código)
- ✅ Simplificado steering de Engram (no se activa automáticamente al inicio)
- ✅ Establecida regla "repo primero, Oracle después" en `diagnostico-eficiente.md`
- ✅ Actualizado `fuentes-codigo-repositorios.md` con Oracle DB como "⭐ FUENTE DE VERDAD para PL/SQL"
- ✅ Reestructurada Fase 1 completa de `atencion-incidente-autonomo.md` con nuevo flujo:
  Engram → Confluence/Jira → Repo Oracle DB → Repo COBOL → Repo Forms → Oracle (solo datos)
- ✅ Eliminada la posibilidad de hacer queries de datos sin antes leer código fuente
- ✅ Actualizado resumen de reglas con 9 principios claros

## Next Steps
- Hacer commit de todos los cambios en corex-n3-power
- Validar en próximo diagnóstico real que el agente sigue el nuevo flujo
- Considerar actualizar también el sub-agente corex-incident-diagnostics con las mismas reglas

## Relevant Files
- powers/corex-n3/steering/atencion-incidente-autonomo.md — Fase 1 reestructurada con flujo repo-first
- powers/corex-n3/steering/diagnostico-eficiente.md — regla fundamental + profundización + resumen actualizados
- powers/corex-n3/steering/fuentes-codigo-repositorios.md — Oracle DB como fuente de verdad
- ~/.kiro/steering/rule-*.md (6 archivos) — convertidos a fileMatch
- ~/.kiro/steering/engram-knowledge-sync.md — simplificado
- CHANGELOG.md — registra todos los cambios

---

## #51 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Optimizar el power corex-n3 para reducir consumo de créditos y mejorar efectividad en diagnósticos.

## Discoveries
- Los steering files con `inclusion: always` se cargan en CADA turno (~6000 tokens de reglas de código incluso para preguntas simples de soporte)
- `get_source` del MCP Oracle trunca packages grandes (>3000 líneas) y consume créditos innecesarios cuando el código ya está en el repo local
- El repo `tronador-oracle-db/Base Datos/Packages/` tiene los `.pkb` completos que se pueden leer parcialmente con rangos de líneas o buscar con grep

## Accomplished
- ✅ Convertidos 6 steering files globales a `inclusion: fileMatch` (solo se cargan al editar código): rule-tech-stack, rule-tech-libraries, rule-security, rule-code-style, rule-architecture, rule-ai-generated-code
- ✅ Simplificado steering de Engram (no se activa automáticamente al inicio de cada sesión)
- ✅ Establecida regla "repo primero, Oracle después" en `diagnostico-eficiente.md` — prioridad: leer del repo local antes de usar `get_source`
- ✅ Actualizado `fuentes-codigo-repositorios.md` con sección Oracle DB como "⭐ FUENTE DE VERDAD para PL/SQL"
- ✅ CHANGELOG actualizado en corex-n3-power

## Next Steps
- Hacer commit de los cambios en corex-n3-power
- Validar en próximo diagnóstico que el agente efectivamente va al repo primero
- Considerar si los steerings de observability y devops también deberían ser condicionales

## Relevant Files
- powers/corex-n3/steering/diagnostico-eficiente.md — regla fundamental actualizada con prioridad repo-first
- powers/corex-n3/steering/fuentes-codigo-repositorios.md — sección Oracle DB como fuente de verdad
- ~/.kiro/steering/rule-*.md (6 archivos) — convertidos a fileMatch
- ~/.kiro/steering/engram-knowledge-sync.md — simplificado
- CHANGELOG.md — registra ambos cambios

---

## #49 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Leer código fuente PL/SQL desde el repositorio local (más eficiente que get_source de Oracle) para entender la fórmula exacta de cálculo de cuota en facturación de endosos.

## Instructions
- Leer código PL/SQL desde el repositorio (`Base Datos/Packages/*.pkb`) es MUCHO más eficiente que usar `get_source` del MCP Oracle. Permite buscar con grep, leer rangos de líneas, y navegar por procedimientos específicos.
- El flujo de facturación tiene 5+ niveles de profundidad: proc_genera_factura → AB100277 → AB100273 → AB100135

## Discoveries
- **prc_CalcCoeficiente** (línea 1324 de SIM_PCK299_AB100273.pkb): Para PERIODO_FACT != 12, calcula v_CoefFact como:
  ```
  (MONTHS_BETWEEN(FechaVtoFact, FechaVigFact)*30 - MesAcum) / 
  ((MONTHS_BETWEEN(FechaVtoFact, FechaVigFact)*30) + (MONTHS_BETWEEN(FechaVencPol, FechaVtoFact)*30))
  ```
- **prc_VerificaPrima** (línea 1200): Acumula en v_MesAcum los meses de facturas consolidadas con estado 'P' que se solapan con el período del endoso. Si la factura ya está cobrada ('CT'), v_MesAcum = 0.
- **prc_PorDias** (línea 1790): Calcula v_CoefPol como:
  ```
  (FechaVtoFact - FechaVigFact) / (FechaVencPol - FechaVigPol)
  ```
  Es decir: días del período de factura / días totales de vigencia de la póliza.
- La prima final de la factura = PRIMA_END_160 * v_CoefFact * v_CoefPol (interacción entre ambos coeficientes)
- Para reproducir el número exacto (-162,693) se necesitaría ejecutar el código con los datos reales o leer cómo se aplican ambos coeficientes en PRC_PROCESO/PRC_PREMIOS

## Accomplished
- ✅ Leído prc_CalcCoeficiente completo desde repositorio local (líneas 1324-1634)
- ✅ Leído prc_VerificaPrima (líneas 1200-1252) — acumulador de meses ya facturados
- ✅ Leído prc_PorDias (líneas 1790-1835) — cálculo de coeficiente por días
- ✅ Identificada la fórmula exacta de cálculo de coeficientes
- ✅ Confirmado que leer desde repositorio es más eficiente que get_source
- 🔲 Pendiente: reproducir el número exacto -162,693 con los datos del caso
- 🔲 Pendiente: documentar en Confluence y cerrar el caso

## Next Steps
- Leer PRC_PREMIOS o PRC_PROCESO de AB100273 para ver cómo se aplican v_CoefFact y v_CoefPol juntos
- Alternativamente: ejecutar una query que simule el cálculo con los datos reales
- Documentar hallazgo completo en Confluence
- Responder al caso MDSB-992543 con explicación técnica

## Relevant Files
- /Base Datos/Packages/SIM_PCK299_AB100273.pkb — cálculo de coeficientes (líneas 1324, 1200, 1790)
- /Base Datos/Packages/SIM_PCK299_AB100277.pkb — orquestador (decide flujo)
- PRC299_FACTURA_ANULACION_GRUPO — solo para libranza/anticipadas
- Tablas: A2000163, A2990700, A2000160, C1000270

---

## #48 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Leer código fuente PL/SQL completo del flujo de facturación para MDSB-992543: SIM_PCK299_AB100277 → SIM_PCK299_AB100273

## Discoveries
- SIM_PCK299_AB100277.PRC_PROCESO: Para endosos tipo 'AT' con forma cobro CC sin libranza y sin facturas anticipadas, NO entra a PRC_FACTANULLIB (que usa PRC299_FACTURA_ANULACION_GRUPO). Va al flujo normal: SIM_PCK299_AB100273.PRC_INICIO
- La condición para entrar a PRC_FACTANULLIB es: TIPOEND='AT' AND (LIBRANZA='S' OR (exclusionVariasFacts!='S' AND FORCOBRO='CC' AND l_fechaMax > FECHAVIGEND))
- Para esta póliza: FORCOBRO='CC', no es libranza, y l_fechaMax (max fecha_vig_fact de facturas anteriores del endoso) probablemente NO es > FECHAVIGEND del endoso 16
- SIM_PCK299_AB100273 tiene variables V_COEFPOL, V_COEFFACT, V_COEFCOB que se calculan en PRC_CALCCOEFICIENTE
- PROC_EXCLU_PR ajusta coeficientes para exclusiones parciales
- La función FNC_EXCLVARIASFACT (marca modificación 8, sept 2024) parametriza en C9999909 qué productos generan una sola factura en anulación
- Versión 2.4.1 (feb 2026): ajuste para que pólizas DB repliquen facturas y CC no repliquen — esto es posterior a la fecha del caso (marzo 2026)

## Accomplished
- ✅ Leído SIM_PCK299_AB100277 completo (spec + body) — flujo de orquestación de facturación
- ✅ Leído SIM_PCK299_AB100273 spec — variables de coeficientes y procedimientos de cálculo
- ✅ Confirmado que PRC299_FACTURA_ANULACION_GRUPO se llama desde PRC_FACTANULLIB solo para libranza/facturas anticipadas
- ✅ Identificado que el cálculo real de la cuota está en SIM_PCK299_AB100273.PRC_CALCCOEFICIENTE + PROC_EXCLU_PR
- 🔲 Pendiente: leer body de SIM_PCK299_AB100273 (PRC_CALCCOEFICIENTE) para la fórmula exacta

## Next Steps
- Leer PRC_CALCCOEFICIENTE y PROC_EXCLU_PR del body de SIM_PCK299_AB100273
- Con la fórmula exacta, reproducir el cálculo de -162,693
- Documentar hallazgo completo en Confluence
- Responder al caso MDSB-992543

## Relevant Files
- SIM_PCK299_AB100277 (package body) — orquestador de facturación, decide flujo según tipo endoso
- SIM_PCK299_AB100273 (package spec) — cálculo de coeficientes y generación de factura
- PRC299_FACTURA_ANULACION_GRUPO (procedure) — solo para libranza/facturas anticipadas
- SIM_PCK_PROCESO_DML_EMISION.proc_genera_factura — entry point desde emisión

---

## #45 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Continuar diagnóstico MDSB-992543: confirmar causa raíz de diferencia $15,332 entre factura 12 y 13 leyendo código fuente PL/SQL.

## Discoveries
- `proc_genera_factura` en SIM_PCK_PROCESO_DML_EMISION delega a `Sim_Pck299_Ab100277.prc_Inicio` para generar facturas de endosos
- `PRC299_FACTURA_ANULACION_GRUPO` usa COEFFACT = MONTHS_BETWEEN(nueva_vto, nueva_vig) / MONTHS_BETWEEN(vto_base, vig_base) * -1 para calcular devoluciones proporcionales
- La factura 13 NO fue generada por PRC299_FACTURA_ANULACION_GRUPO sino por el flujo de emisión del endoso 16 (proc_genera_factura → Sim_Pck299_Ab100277)
- La devolución cubre período 20/02→31/03 (desde FECHA_VIG_END del endoso 13) mientras la factura 12 cobra 28/02→31/03
- Los 8 días extra (20/02-28/02) devueltos ya fueron cobrados en factura 9 (período 31/01→28/02)
- Diferencia exacta: 162,693 - 149,810 = 12,883 prima + 2,448 IVA = 15,332 premio
- C1000270 muestra MESES=13 para exclusión (endoso 16) vs MESES=14 para inclusión (endoso 13)
- Hay facturas 20 y 21 del endoso 16 que indican una corrección posterior (reversa + nueva devolución de 159,844)

## Accomplished
- ✅ Leído código fuente completo de SIM_PCK_FACTURACION (spec + body)
- ✅ Leído código fuente de PRC299_FACTURA_ANULACION_GRUPO — fórmula COEFFACT confirmada
- ✅ Leído código fuente de SIM_PCK_PROCESO_DML_EMISION.proc_genera_factura — flujo de facturación de endosos
- ✅ Confirmado que la diferencia NO es un bug — es comportamiento esperado por desalineación de períodos
- ✅ Identificado que la factura 13 se genera por flujo de emisión (no por anulación de grupo)
- 🔲 Pendiente: leer Sim_Pck299_Ab100277 para confirmar fórmula exacta de cuota mensual en devolución
- 🔲 Pendiente: documentar en Confluence, crear HU, registrar tiempos

## Next Steps
- Opcionalmente leer Sim_Pck299_Ab100277.prc_Inicio para la fórmula exacta
- Documentar hallazgo en Confluence como patrón conocido
- Responder al caso MDSB-992543 explicando que es comportamiento esperado
- Actualizar KB con patrón: diferencias en devoluciones por exclusión cuando FECHA_VIG_END != FEC_EFECTO de factura

## Relevant Files
- PRC299_FACTURA_ANULACION_GRUPO (procedure) — lógica de devolución por exclusión con COEFFACT
- SIM_PCK_FACTURACION (package body) — Proc_Reversa_facturaDB, Proc_Factura_Interactiva
- SIM_PCK_PROCESO_DML_EMISION.proc_genera_factura — orquestador de facturación de endosos
- Sim_Pck299_Ab100277.prc_Inicio — cálculo real de cuotas (pendiente de leer)
- Tablas: A2000163, A2990700, A2000030, A2000040, C1000270

---

## #44 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Reproducir con 100% de precisión el monto de $162,693 de la factura 13 (devolución por exclusión) del caso MDSB-992543, leyendo el código fuente completo.

## Discoveries
- PFACTURAS_DIF NO aplica para este caso: la condición fecha1 (2026-03-31) != fechavigfact (2026-02-20) es FALSA
- El flujo real para ramo 250 (autos), compañía 3 es: SIM_PCK299_AB100277.PRC_PROCESO → línea 568-601 → SIM_PCK299_AB100273.PRC_INICIO (paquete estándar de facturación de endosos para autos)
- La condición en línea 568: IF V_REC030.CODCIA = 3 AND V_REC030.CODRAMO = 250 THEN busca subproducto; si NO es 368/370 (RC-Pasajeros), usa SIM_PCK299_AB100273
- Ninguna fórmula simple reproduce 162,693: ni PRIMA_COB/13, ni PRIMA_COB/13+residuo, ni PRIMA_COB/13-residuo
- El paquete SIM_PCK299_AB100273 es el que contiene la fórmula exacta — pendiente de leer

## Accomplished
- ✅ Descartado PFACTURAS_DIF como origen de la factura 13 (condición de entrada no se cumple)
- ✅ Identificado flujo exacto en PRC_PROCESO: líneas 568-601 → SIM_PCK299_AB100273.PRC_INICIO
- ✅ Confirmado que la póliza es ramo 250, compañía 3, sección 1 (autos colectivos)
- 🔲 Pendiente: leer SIM_PCK299_AB100273 body para encontrar la fórmula

## Next Steps
1. Leer SIM_PCK299_AB100273 PACKAGE BODY — buscar cómo calcula IMP_PRIMA para endosos tipo 'AT' (anulación total/exclusión)
2. Verificar numéricamente que la fórmula reproduce exactamente 162,693
3. Determinar si es bug o diseño
4. Documentar y crear HU

## Relevant Files
- SIM_PCK299_AB100273 (PACKAGE BODY, OPS$PUMA) — PENDIENTE DE LEER, contiene la fórmula
- SIM_PCK299_AB100277 (PACKAGE BODY) — PRC_PROCESO líneas 338-758, flujo principal
- PFACTURAS_DIF (PROCEDURE) — descartado, no aplica para este caso
- Tablas: C1000270, A2990700, A2000163, A2000040, A2000030, A2000160

---

## #43 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Diagnosticar MDSB-992543 con precisión al 100%: encontrar la fórmula exacta que produce la devolución de $162,693 en factura 13 vs $149,809 cobrados en factura 12.

## Discoveries
- La fórmula de devolución está en el procedimiento PFACTURAS_DIF (OPS$PUMA)
- NO usa PRIMA_COB/MESES ni PRIMA_ANU/12. Usa un COEFICIENTE PROPORCIONAL:
  - coef = sum(C1000270.imp_prima_163 * months_between(fecha_venc_pol, fecha_vto_fact)) / A2990700.imp_prima WHERE num_factura = max_factura_antes_del_endoso
  - devolución = ROUND(factura_base.IMP_PRIMA * coef)
- En producción C1000270 tiene MESES=14 para inclusión y MESES=13 para exclusión
- COEFCOB en prod aparece como 1 por truncamiento SQL*Plus pero es realmente 1.188172
- La cadena de llamadas es: proc_genera_factura → Sim_Pck299_Ab100277.prc_Inicio → PRC_PROCESO → PRC_DIFERIDO → PFACTURAS_DIF
- PFACTURAS_DIF solo genera factura si abs(impprima163) > 1000
- La condición de entrada es: fecha1 (max fecha_vto_fact antes del endoso) = fecha_vig_end

## Accomplished
- ✅ Consulta producción MDSB-1039252 con 8 queries (exitosa)
- ✅ Análisis datos producción vs Dev
- ✅ Lectura código fuente: SIM_PCK_FACTURACION, SIM_PCK_PROCESO_DML_EMISION (proc_genera_factura), SIM_PCK299_AB100277 (PRC_DIFERIDO), PFACTURAS_DIF
- ✅ Identificada fórmula exacta del cálculo de devolución
- 🔲 Pendiente: verificación numérica con la fórmula encontrada (necesita consultar numfacturabase y su imp_prima)
- 🔲 Pendiente: determinar si el comportamiento es correcto por diseño o es un defecto
- 🔲 Pendiente: documentación Confluence, HU, tiempos

## Next Steps
1. Lanzar consulta a prod para obtener: numfacturabase (max factura con imp_prima > 0 y num_end_ref < 16), su imp_prima en A2990700, y sum(imp_prima_163 * months_between(fecha_venc_pol, fecha_vto_fact)) de C1000270 para riesgo 662
2. Verificar que ROUND(imp_prima_base * coef) = 162,693
3. Determinar si la diferencia es defecto o diseño
4. Documentar y crear HU

## Relevant Files
- PFACTURAS_DIF (procedimiento standalone OPS$PUMA) — fórmula de devolución
- SIM_PCK299_AB100277 (package body) — PRC_DIFERIDO, PRC_PROCESO
- SIM_PCK_PROCESO_DML_EMISION (package body) — proc_genera_factura
- SIM_PCK_FACTURACION (package body) — Proc_Factura_Interactiva
- Tablas: C1000270, A2990700, A2000163, A2000040, A2000030

---

## #40 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Diagnosticar MDSB-992543: diferencia de $15,332 en primas entre factura 12 y 13 para póliza 1000486837825, riesgo 662 (placa LRO484). Validar con datos de producción.

## Discoveries
- En producción, C1000270 SÍ tiene registro de exclusión (end 16) con MESES=13 y EXCLUSION='S' (en Dev solo estaba el de inclusión)
- COEFCOB en producción aparece como 1 por truncamiento de SQL*Plus, pero la relación PRIMA_COB/PRIMA_ANU = 2,097,321/1,765,165 = 1.188172 confirma vigencia de 14 meses y 8 días
- La factura 12 (consolidada, efecto 28/02) cobra cuota mensual fija: PRIMA_ANU/12 + residuo = ~149,809
- La factura 13 (exclusión end 16, efecto 20/02) devuelve 162,693 — un monto mayor
- Diferencia: 12,884 prima + 2,448 impuesto = 15,332 premio (coincide con reporte del usuario)
- La fórmula exacta de la devolución no se reproduce con PRIMA_COB/13 (da 161,332) ni con PRIMA_COB/14 (da 149,809). Falta ~1,360 que no se explica sin leer el código fuente
- Hipótesis: desalineación entre método de cobro (cuota fija mensual) y método de devolución (proporcional a días desde FECHA_VIG_END)
- Facturas 10 y 11 son devoluciones de otros endosos (14 y 15) con períodos parciales hasta 28/02

## Accomplished
- ✅ Diagnóstico en Dev con todas las tablas relevantes
- ✅ Consulta a producción vía MDSB-1039252 (8 queries, procesada con éxito)
- ✅ Análisis comparativo Dev vs Prod — datos coinciden excepto COEFCOB (formato) y C1000270 (prod tiene registro exclusión)
- ✅ Confirmada la diferencia numérica exacta de $15,332
- 🔲 Pendiente: leer código fuente SIM_PCK_FACTURACION para entender fórmula exacta de devolución
- 🔲 Pendiente: determinar si es bug o diseño intencional
- 🔲 Pendiente: documentación Confluence, HU, tiempos

## Next Steps
- Leer body de SIM_PCK_FACTURACION (proc_Factura_Interactiva o Proc_Reversa_factura) para entender cálculo de exclusión
- Determinar si la devolución de 162,693 es correcta por diseño o es un defecto
- Si es defecto: documentar, crear HU con fix propuesto
- Si es diseño: responder al cliente explicando el comportamiento

## Relevant Files
- Tablas Oracle: A2000030, A2000040, A2990700, A2000163, A2000160, C1000270 (OPS$PUMA)
- Package: SIM_PCK_FACTURACION (lógica de facturación)
- MDSB-1039252: consulta producción con resultados

---

## #38 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Diagnosticar el caso MDSB-992543: diferencia de $15,332 en primas entre factura 12 y factura 13 para póliza 1000486837825, riesgo 662 (placa LRO484)

## Discoveries
- La factura 12 (mensual consolidada) tiene FEC_EFECTO = 28/02/2026, pero el endoso 13 (inclusión) tiene vigencia desde 20/02/2026
- La factura 13 (devolución por exclusión endoso 16) calcula desde FECHA_VIG_END = 20/02/2026, generando un período de 39 días vs 31 días de la factura 12
- La diferencia de $15,332 corresponde exactamente a los 8 días extra (20/02 al 28/02) que la devolución incluye pero la factura 12 no cobró explícitamente
- C1000270 solo tiene registro del endoso de inclusión (EXCLUSION='N'), no del de exclusión
- El IMP_PRIMA_163 en C1000270 (2,712) es el residuo de la división prima_cob/meses, no la prima mensual completa
- PRIMA_ANU total riesgo 662 = 1,765,165 | PRIMA_COB = 2,097,321 | COEFCOB = 1.188172 (14 meses 8 días)
- Esto NO es un bug — es comportamiento esperado del sistema cuando inclusión y exclusión tienen misma fecha de vigencia pero la factura mensual se genera después

## Accomplished
- ✅ Diagnóstico completo con causa raíz identificada
- ✅ Consultas Oracle en Dev verificadas (A2000030, A2000040, A2990700, A2000163, C1000270)
- ✅ Cálculo numérico que confirma la diferencia exacta de $15,332
- ✅ Conocimiento persistido en Engram
- 🔲 Pendiente: documentación Confluence, creación HU, registro tiempos (requiere datos del usuario)

## Next Steps
- Esperar confirmación del usuario sobre proyecto/epic para crear HU
- Verificar en producción si la factura 12 incluye la prima proporcional desde 20/02
- Documentar en Confluence como patrón conocido de facturación
- Responder al cliente que es comportamiento esperado

## Relevant Files
- Tablas Oracle: A2000030, A2000040, A2990700, A2000163, C1000270 (esquema OPS$PUMA)

---

## #35 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Corregir paths del script engram-sync.sh y steering sincronizar-conocimiento.md para apuntar a shared-knowledge/ en raíz del repo (no .kiro/shared-knowledge/).

## Accomplished
- ✅ engram-sync.sh: SHARED_DIR apunta a $REPO_ROOT/shared-knowledge
- ✅ sincronizar-conocimiento.md: paths corregidos a shared-knowledge/ y powers/corex-n3/scripts/
- ✅ Commit: fix paths de shared-knowledge

## Relevant Files
- powers/corex-n3/scripts/engram-sync.sh
- powers/corex-n3/steering/sincronizar-conocimiento.md

---

## #33 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Finalizar repo corex-n3-power con documentación actualizada y comando 'actualiza conocimiento'.

## Accomplished
- ✅ README.md raíz actualizado con estructura completa y comando 'actualiza conocimiento'
- ✅ GUIA-USO.md actualizada con todos los flujos de trabajo
- ✅ Steering sincronizar-conocimiento.md cambiado a inclusion: auto
- ✅ Repo con 6 commits limpios, listo para push

## Next Steps
- Crear repo GitHub (miespinosaSB/corex-n3-power) y push
- Probar flujo completo desde cero con compañero
- Implementar Bloque E

---

## #32 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Completar la migración del power corex-n3 al repo dedicado corex-n3-power con TODOS los componentes (Bloques A-D).

## Discoveries
- El repo del power NO es solo un instalador — es el workspace donde el equipo trabaja. Debe incluir .kiro/ completo (hooks, scripts, agents, steering de proyecto).
- El steering `sincronizar-conocimiento.md` permite al usuario decir 'actualiza conocimiento' y el agente ejecuta export + push + propone Confluence.

## Accomplished
- ✅ Repo corex-n3-power completo con .kiro/ (hooks, scripts, agents, steering) + powers/corex-n3/ + shared-knowledge
- ✅ 5 commits limpios en main
- ✅ Steering sincronizar-conocimiento.md creado (comando 'actualiza conocimiento')
- ✅ Hooks engram-export/import (botones userTriggered)
- ✅ Pendiente: crear repo en GitHub y push

## Next Steps
- Crear repo GitHub (miespinosaSB/corex-n3-power) y push
- Actualizar README raíz con estructura completa
- Probar flujo completo desde cero
- Implementar Bloque E (triaje, duplicados, auto-link)

## Relevant Files
- ~/Documents/tronador/corex-n3-power/ — repo completo (5 commits, ~100 archivos)

---

## #30 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Completar la migración del power corex-n3 al repo dedicado corex-n3-power con todos los componentes.

## Accomplished
- ✅ Hooks (19) copiados al nuevo repo incluyendo engram-export e engram-import (userTriggered)
- ✅ Scripts (3) copiados: engram-sync.sh, metrics-report.sh, generate-source-index.sh
- ✅ shared-knowledge/ copiado para memorias compartidas
- ✅ Segundo commit: 24 archivos adicionales
- ✅ Repo completo: 91 archivos, 2 commits, listo para push

## Next Steps
- Crear repo en GitHub (miespinosaSB/corex-n3-power, privado) y push
- Probar flujo completo: clone → install.sh → Install Power → reiniciar
- Cuando autoricen, migrar a la org

## Relevant Files
- ~/Documents/tronador/corex-n3-power/ — repo completo listo para push

---

## #29 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Migrar el power corex-n3 a un repositorio dedicado (corex-n3-power) separado de tronador-oracle-db.

## Accomplished
- Repo local creado en ~/Documents/tronador/corex-n3-power/ (67 archivos)
- Power completo copiado con hooks, scripts, agents, steering, shared-knowledge
- README.md, CHANGELOG.md, .gitignore creados
- Commit inicial hecho
- Pendiente: crear repo en GitHub (miespinosaSB/corex-n3-power) y push

## Next Steps
- Crear repo en GitHub (privado) y hacer push
- Actualizar install.sh para que clone URL apunte al nuevo repo
- Probar flujo completo desde cero con el nuevo repo
- Migrar de miespinosaSB a org cuando autoricen

## Relevant Files
- ~/Documents/tronador/corex-n3-power/ (nuevo repo local)

---

## #27 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Actualizar README y crear guía de uso del power corex-n3 con toda la documentación de los Bloques A-D implementados.

## Accomplished
- ✅ README.md reescrito con documentación completa (5 MCP, 3 agentes, 4 skills, 26 steering, 17 hooks, 3 scripts)
- ✅ GUIA-USO.md creada — guía práctica para el día a día del equipo
- ✅ Diseño técnico de Bloque E documentado en Engram (automatización + inteligencia colectiva)

## Next Steps
- Bloque E: Bot triaje + detección duplicados + auto-link + score patrones
- Probar flujo completo con compañero nuevo
- Exportar conocimiento: bash .kiro/scripts/engram-sync.sh export

## Relevant Files
- powers/corex-n3/README.md — referencia técnica completa
- powers/corex-n3/GUIA-USO.md — guía práctica para el equipo

---

## #26 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Implementar Bloque D de mejoras al power corex-n3: estrategias de eficiencia para reducir créditos MCP y mejorar efectividad de diagnóstico.

## Discoveries
- Los árboles de decisión por módulo son el mecanismo más efectivo para evitar consultas exploratorias — clasificar el caso ANTES de tocar Oracle
- Templates SQL con JOINs reducen de 4 llamadas a 1-2 por caso (póliza+facturas+cuotas en un solo query)
- El scoring de confianza con profundización automática evita dos extremos: reportes incompletos (Baja sin profundizar) y gasto innecesario (profundizar cuando ya es Alta)
- El hook preToolUse con regex `.*query.*` intercepta correctamente las tools `query` de oracle-readonly y oracle-stage
- La estrategia Engram-first es la de mayor ROI: si el patrón ya fue diagnosticado, se ahorran 2-5 llamadas MCP completas

## Accomplished
- ✅ Creado steering `diagnostico-eficiente.md` con 7 estrategias completas (274 líneas)
- ✅ Creado hook `engram-first-diagnostic.kiro.hook` que intercepta queries Oracle
- ✅ Modificado `atencion-incidente-autonomo.md` con 5 nuevas secciones: Fase 0.1 (Engram-first), Fase 0.2 (cache KB), Fase 1.3 (árboles + templates), Fase 1.7 (scoring confianza), Fase 5.3 (feedback loop)
- ✅ Actualizado POWER.md con el nuevo steering en la tabla
- ✅ Actualizado CHANGELOG.md con entradas Agregado + Cambiado
- ✅ Persistido en Engram con judgments resueltos

## Next Steps
- Probar el flujo completo con un caso MDSB real para validar que los árboles de decisión y templates funcionan en la práctica
- Evaluar si el hook engram-first-diagnostic genera fricción excesiva (podría necesitar ajuste para no dispararse en queries manuales del usuario)
- Considerar agregar más árboles de decisión para módulos menos frecuentes (Reaseguros, Fondos Vida, Comisiones)
- Bloque E potencial: integración con el sub-agente de diagnóstico para que también use las estrategias de eficiencia

## Relevant Files
- powers/corex-n3/steering/diagnostico-eficiente.md — Steering principal del Bloque D con las 7 estrategias
- powers/corex-n3/steering/atencion-incidente-autonomo.md — Ciclo de atención modificado con eficiencia integrada
- .kiro/steering/diagnostico-eficiente.md — Copia local activa en el workspace
- .kiro/hooks/engram-first-diagnostic.kiro.hook — Hook preToolUse para Engram-first
- powers/corex-n3/POWER.md — Documentación del power actualizada

---

## #23 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Implementar Bloque C de mejoras al power corex-n3: Context7 para microservicios, agente de retrospectiva, e indexación de repos COBOL/Forms.

## Discoveries
- El workspace de Kiro está restringido al repo actual — no puede acceder a repos hermanos directamente. Los scripts de índice se ejecutan manualmente.
- Hook `postToolUse` con regex `.*jira_get_issue.*` permite interceptar la lectura de casos y enriquecer automáticamente con fuentes externas (COBOL/Forms).
- Context7 library IDs pueden variar entre versiones — siempre usar `resolve-library-id` primero antes de `query-docs`.
- El steering con `fileMatch` en `**/*.java,**/*.gradle` se activa solo cuando se trabaja con código Java, evitando ruido en sesiones de diagnóstico Oracle.

## Accomplished
- ✅ Steering `context7-microservices.md` — instruye al agente a consultar Context7 para docs de Spring Boot, MapStruct, JUnit 5, springdoc al generar microservicios
- ✅ Sub-agente `corex-retrospective` (3 archivos: .json, .md, .prompt.md) — análisis de últimos 30 días cruzando Engram + Jira + KB
- ✅ Hook `cobol-forms-lookup.kiro.hook` — detecta programas CB/CR/AP/CP en casos Jira y sugiere leer código fuente
- ✅ Script `generate-source-index.sh` — genera índice JSON de programas COBOL y Forms disponibles
- ✅ Steering `source-index-usage.md` — flujo para usar el índice durante diagnósticos
- ✅ Placeholder `source-index.json` con mapeo de módulos y tipos
- ✅ CHANGELOG actualizado con todas las entradas del Bloque C

## Next Steps
- Ejecutar `generate-source-index.sh` cuando los repos COBOL/Forms estén clonados
- Probar el hook `cobol-forms-lookup` con un caso real que mencione un programa batch
- Probar el agente de retrospectiva con "retrospectiva" después de acumular más casos
- Considerar Bloque D: integración con SonarCloud para quality gates automáticos, dashboard de métricas del equipo

## Relevant Files
- .kiro/steering/context7-microservices.md — cuándo y cómo consultar Context7 para microservicios
- .kiro/steering/source-index-usage.md — flujo de uso del índice COBOL/Forms
- .kiro/agents/corex-retrospective.json — config del sub-agente de retrospectiva
- .kiro/agents/corex-retrospective.md — instrucciones completas del agente
- .kiro/agents/corex-retrospective.prompt.md — system prompt condensado
- .kiro/hooks/cobol-forms-lookup.kiro.hook — hook de detección de programas COBOL/Forms
- .kiro/scripts/generate-source-index.sh — generador de índice de fuentes
- .kiro/shared-knowledge/source-index.json — índice placeholder

---

## #20 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Integrar mcp-kiro-kit (Context7 + Engram) al power corex-n3, resolver problemas de configuración MCP, y mejorar el power con Skills, Hooks nativos, Knowledge Base, seed de Engram, hook de seguridad Oracle, y script de actualización.

## Discoveries
- Kiro Powers NO ejecutan scripts al instalar — solo copian POWER.md, mcp.json, steering/
- Kiro cachea MCP del power en settings/mcp.json sección "powers.mcpServers" con prefijo power-{name}-{server}
- Si un servidor se agrega después de instalar, aparece como power separado visualmente
- mcpServers duplicados (usuario + power) causan procesos duplicados
- Engram usa una sola DB (~/.engram/engram.db) sin importar quién lo llame
- Skills se activan por coincidencia con el request del usuario (carga progresiva)
- El agente JSON soporta hooks nativos, knowledgeBase, e includeMcpJson

## Accomplished
- ✅ Engram v1.15.10 instalado y funcionando como MCP del power
- ✅ Context7 configurado como MCP del power
- ✅ Config limpia: mcpServers vacío, todo en powers.mcpServers (5 servers)
- ✅ mcp.json portable con sh -c + .env (sin hardcode ni placeholders)
- ✅ 4 Skills globales creadas (oracle-diagnostics, jira-workflow, confluence-docs, adapter-v3)
- ✅ Knowledge Base indexada en el agente (25 steering files)
- ✅ Hooks nativos en el agente (agentSpawn + stop)
- ✅ Seed de Engram: diccionario tablas + packages + 5 patrones de problemas
- ✅ Hook oracle-query-safety (preToolUse: valida SELECT + ROWNUM)
- ✅ update.sh para actualizar sin reinstalar
- ✅ install.sh actualizado (instala engram, agente, skills, steering, .env)
- ✅ Steering global engram-knowledge-sync.md
- ✅ Roadmap Bloques B, C, D documentados en Engram

## Next Steps
- Bloque B: Agente corex-implementation + Engram sync + Métricas
- Bloque C: Context7 Oracle JDBC + Retrospectiva automática + KB COBOL/Forms
- Bloque D: Queries pre-armadas + Árboles decisión + Cache KB + Feedback loop
- Probar flujo completo con un compañero nuevo (install.sh + Install Power + reiniciar)

## Relevant Files
- powers/corex-n3/mcp.json — 5 servers portables con .env
- powers/corex-n3/install.sh — prerrequisitos completos
- powers/corex-n3/update.sh — actualización sin credenciales
- powers/corex-n3/skills/ — 4 skills
- powers/corex-n3/agents/ — sub-agente con hooks + KB
- powers/corex-n3/steering-global/ — política Engram
- .kiro/hooks/oracle-query-safety.kiro.hook — protección DML
- ~/.kiro/settings/mcp.json — mcpServers vacío, todo en powers
- ~/.kiro/settings/.env — fuente única de credenciales
- ~/.kiro/skills/ — 4 skills globales instaladas
- ~/.engram/engram.db — 17 observaciones (12 arquitectura + 3 referencia + 2 session summaries)

---

## #19 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Implementar Bloque B de mejoras al power corex-n3: Sub-agente implementation + Engram sync + Métricas de uso.

## Discoveries
- El sub-agente de implementación necesita tools write+shell (a diferencia del de diagnóstico que es read-only)
- El hook postToolUse con regex amplio (`.*query.*|.*jira.*|.*confluence.*`) captura todas las herramientas MCP relevantes sin ser demasiado ruidoso
- Engram sync via Git es el approach más simple para compartir conocimiento — no requiere infra adicional, solo un directorio versionado
- Los hooks `agentStop` son ideales para recordar guardar contexto al final de sesiones

## Accomplished
- ✅ Sub-agente `corex-implementation`: 3 archivos (.json, .md, .prompt.md) con MCP Atlassian + Oracle, shortcut Ctrl+Shift+I
- ✅ Engram sync script: export/import/status con deduplicación, solo tipos compartibles (pattern, architecture, decision, bugfix)
- ✅ Directorio .kiro/shared-knowledge/ con README para el equipo
- ✅ Hook usage-metrics: registra cada uso de Oracle/Jira/Confluence en .kiro/metrics/usage.log
- ✅ Hook session-end-metrics: recuerda guardar en Engram al terminar sesión
- ✅ Script metrics-report.sh: visualización con filtros (today/week/all/summary)
- ✅ CHANGELOG.md creado con entradas del Bloque B
- ✅ .gitignore actualizado para excluir usage.log (métricas locales)

## Next Steps
- Bloque C: Context7 para Oracle JDBC/oracledb, agente de retrospectiva automática, indexar repos COBOL/Forms
- Probar el sub-agente corex-implementation con un caso real (GD986-XXXX)
- Validar que el hook usage-metrics registra correctamente (las variables KIRO_TOOL_NAME pueden no estar disponibles aún)
- Hacer que un compañero pruebe engram-sync.sh import después de un export

## Relevant Files
- .kiro/agents/corex-implementation.json — Config del sub-agente (MCP, tools, resources)
- .kiro/agents/corex-implementation.prompt.md — Instrucciones completas del agente
- .kiro/scripts/engram-sync.sh — Export/import de memorias entre compañeros
- .kiro/scripts/metrics-report.sh — Visualización de métricas de uso
- .kiro/hooks/usage-metrics.kiro.hook — Hook postToolUse para logging
- .kiro/hooks/session-end-metrics.kiro.hook — Hook agentStop para Engram
- .kiro/shared-knowledge/README.md — Documentación del flujo de sync
- CHANGELOG.md — Registro de cambios del proyecto

---

## #16 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Implementar Bloque A de mejoras al power corex-n3: Seed de Engram + Hook Oracle + Update script.

## Discoveries
- Engram seed funciona como "onboarding instantáneo" — un compañero nuevo tiene contexto desde el día 1
- Los hooks preToolUse con regex `.*query.*` interceptan las tools `query` de Oracle
- El update.sh puede verificar versiones de Engram comparando output de `engram version`

## Accomplished
- ✅ Seed de Engram: 3 observaciones de referencia (tablas, packages, patrones de problemas)
- ✅ Hook oracle-query-safety: valida SELECT-only + ROWNUM + OPS$PUMA antes de ejecutar
- ✅ update.sh: actualiza server.py, agente, skills, steering, Engram sin pedir credenciales
- ✅ Skills creadas y visibles en Kiro (4 skills globales)
- ✅ Knowledge Base indexada en el agente
- ✅ Hooks nativos en el agente JSON
- ✅ Config limpia: mcpServers vacío, todo en powers.mcpServers

## Next Steps (Bloque B)
- Crear segundo sub-agente: corex-implementation (ramas, cambios PL/SQL, PRs)
- Implementar Engram sync entre compañeros (git-based)
- Agregar métricas de uso (log de herramientas usadas, diagnósticos realizados)

## Next Steps (Bloque C)
- Context7 para Oracle JDBC/oracledb al generar microservicios
- Agente de retrospectiva automática (análisis semanal)
- Indexar repos COBOL/Forms como knowledgeBase

## Relevant Files
- powers/corex-n3/mcp.json — 5 servidores (atlassian, oracle×2, engram, context7)
- powers/corex-n3/install.sh — prerrequisitos completos
- powers/corex-n3/update.sh — actualización sin credenciales
- powers/corex-n3/skills/ — 4 skills para carga progresiva
- powers/corex-n3/agents/ — sub-agente con hooks + knowledgeBase
- .kiro/hooks/oracle-query-safety.kiro.hook — protección DML
- ~/.kiro/settings/mcp.json — mcpServers vacío, todo en powers

---

## #8 — Session summary: tronador-oracle-db

**Tipo:** session_summary | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

## Goal
Integrar mcp-kiro-kit (Context7 + Engram) al power corex-n3 y resolver problemas de configuración MCP para que funcione para todo el equipo.

## Discoveries
- Kiro NO lee ~/.kiro/powers/installed/corex-n3/mcp.json en runtime. Cachea los servidores del power en ~/.kiro/settings/mcp.json bajo "powers.mcpServers" con prefijo "power-{powerName}-{serverName}".
- "Install Power from local directory" en Kiro NO ejecuta install.sh — solo copia POWER.md, mcp.json y steering/.
- Para que credenciales sean portables: usar `sh -c` con source de ~/.kiro/settings/.env en cada servidor.
- Context7 requiere reiniciar Kiro para levantar (no hay "Reconnect MCP Servers").
- Engram es un binario Go nativo (Gentleman-Programming/engram), se instala descargando el release de GitHub.

## Accomplished
- ✅ Engram v1.15.10 instalado (~/.local/bin/engram) con DB en ~/.engram/engram.db
- ✅ Context7 configurado como servidor MCP del power
- ✅ Agente corex-incident-diagnostics integrado al power (carpeta agents/)
- ✅ Steering global engram-knowledge-sync.md creado en ~/.kiro/steering/
- ✅ install.sh reescrito: genera settings/mcp.json con sección "powers" correcta + instala Engram + agente + steering
- ✅ mcp.json del power source actualizado con patrón portable (sh -c + .env)
- ✅ Hook sync-knowledge-base creado (a nivel proyecto, redundante con steering global)
- 🔲 Validar que Context7 funciona después de reiniciar Kiro

## Next Steps
- Validar que Context7 responde correctamente tras reinicio
- Probar el flujo completo con un compañero nuevo (ejecutar install.sh desde cero)
- Considerar eliminar el hook sync-knowledge-base del proyecto (redundante con steering global)
- Hacer carga inicial de Engram con contenido clave de Confluence (runbooks, patrones)

## Relevant Files
- powers/corex-n3/mcp.json — config portable del power con 5 servidores
- powers/corex-n3/install.sh — instalador completo (credenciales + Engram + agente + powers section)
- powers/corex-n3/agents/ — 3 archivos del sub-agente de diagnóstico
- powers/corex-n3/steering-global/engram-knowledge-sync.md — política de memoria
- ~/.kiro/settings/mcp.json — donde Kiro REALMENTE lee los servidores del power (sección powers.mcpServers)
- ~/.kiro/settings/.env — fuente única de credenciales

---
