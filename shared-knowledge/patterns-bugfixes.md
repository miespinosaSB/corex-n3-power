# Patrones y Bugfixes — Engram Export

> Exportado: 2026-05-15 | Proyectos: corex-n3-power (9), simon-cotizadores-core-wl (10), tronador-oracle-db (128)

---

## #145 — framework_version obligatorio en pipeline de librerías para Java 21

**Tipo:** bugfix | **Fecha:** 2026-05-15 | **Proyecto:** corex-n3-power

**What**: Sin `framework_version` en el pipeline.yml, el template provisiona Gradle 6.9 por defecto, que es incompatible con Java 21 toolchain.
**Why**: `language_version` es para Java, NO para Gradle. El parámetro correcto para la versión de Gradle es `framework_version`.
**Where**: .github/workflows/pipeline.yml → jobs.main.with
**Learned**: Siempre agregar `framework_version: "8.10"` (o la versión del wrapper) junto con `language_version: "21"`. Sin esto el build falla con errores de compatibilidad de toolchain.

---

## #144 — Bearer token en pipeline JFrog — composite action usa JFROG_TOKEN no user/password

**Tipo:** bugfix | **Fecha:** 2026-05-15 | **Proyecto:** corex-n3-power

**What**: El composite action `devops-actions-library-templates@v2.0.0-branch` inyecta `JFROG_TOKEN` (access token Bearer), NO user/password separados. Si el build.gradle.kts usa `credentials { username; password }` con JFROG_USER/JFROG_PASSWORD → 401.
**Why**: Error 401 al ejecutar `artifactoryPublish` en el pipeline. Las variables JFROG_USER y JFROG_PASSWORD no existen en el composite action.
**Where**: build.gradle.kts del repo de librería, bloque artifactory → publish → repository
**Learned**: El pipeline pasa credenciales como Gradle properties: `-Partifactory_user`, `-Partifactory_password`, `-Partifactory_url`, `-Prepository_url`. El build.gradle.kts debe leer con `findProperty()`. Para desarrollo local, usar gradle.properties (en .gitignore) con user/password reales.

---

## #143 — Referencia cruzada entre steerings con #[[file:...]]

**Tipo:** pattern | **Fecha:** 2026-05-15 | **Proyecto:** corex-n3-power

**What**: Cuando hay steerings de dominios relacionados pero distintos, agregar una línea de referencia cruzada (#[[file:...]]) en la cabecera del steering más general.
**Why**: Para que el agente descubra el steering especializado cuando sea relevante sin tener que cargar todos en contexto.
**Where**: steering/scaffolding-microservicio.md → referencia a steering/publicacion-librerias-jfrog.md
**Learned**: Esto evita que el agente aplique reglas de microservicios a librerías o viceversa. El criterio para separar steerings es: ¿comparten el mismo flujo de trabajo end-to-end? Si no, separar y referenciar.

---

## #140 — Versionamiento librerías JFrog: rama nueva por versión, sin SNAPSHOT

**Tipo:** pattern | **Fecha:** 2026-05-15 | **Proyecto:** corex-n3-power

**What**: Cada versión nueva de una librería requiere una rama nueva (ej: v1.0.0-release, v1.1.0-release). NO usar -SNAPSHOT para releases publicados.
**Why**: El template valida que la versión sea mayor que el último tag existente. El flujo es: crear rama vX.Y.Z-release → push → pipeline valida → workflow_dispatch para publicar.
**Where**: Pipeline devops-actions-library-templates
**Learned**: La versión debe actualizarse en 3 archivos simultáneamente: build.gradle.kts, pom.xml (dummy), package.json (dummy).

---

## #88 — Fix publicación JFrog — Bearer token + framework_version

**Tipo:** bugfix | **Fecha:** 2026-05-14 | **Proyecto:** simon-cotizadores-core-wl

**What**: Se corrigió la autenticación del pipeline CI/CD para publicar en JFrog. El composite action `devops-actions-library-templates@v2.0.0-branch` pasa un `jfrog_token` como variable de entorno `JFROG_TOKEN`, pero el build.gradle.kts usaba username/password (JFROG_USER/JFROG_PASSWORD) que no existían → 401.

**Why**: Error 401 al ejecutar `publishLibraryPublicationToJfrogRepository` en el pipeline.

**Where**: `simon-ventas-lib/build.gradle.kts`, `simon-ventas-lib/WorkflowFile.json`, `simon-ventas-lib/gradle.properties`

**Learned**:
- El composite action de DevOps inyecta `JFROG_TOKEN` (access token), NO user/password separados
- Se debe usar `HttpHeaderCredentials` con `Bearer $token` en vez de `credentials { username; password }`
- `language_version` en el pipeline es para Java, no Gradle. Para Gradle se usa `framework_version`
- Sin `framework_version`, el action provisiona Gradle 6.9 por defecto (incompatible con Java 21 toolchain)
- `gradle.properties` está en .gitignore — seguro para credenciales locales

---

## #82 — Reglas críticas — NO violar al hacer cambios

**Tipo:** pattern | **Fecha:** 2026-05-14 | **Proyecto:** simon-cotizadores-core-wl | **Topic:** patterns/critical-rules

**What**: Reglas críticas que NO se deben violar al hacer cambios en el cotizador

**Why**: Prevenir regresión y daños al código existente

**Where**: Todo el monorepo simon-cotizadores-core-wl

**Reglas**:
1. **NUNCA duplicar código** que ya existe en libs/ — si algo está en bff-common o cotizador-core, usarlo
2. **Angular: standalone components SIEMPRE** — no NgModules, no *ngIf/*ngFor (usar @if/@for)
3. **BFF: Ports & Adapters** — nunca llamar WebServiceTemplate directamente desde un controller o service. Siempre via Port interface + Adapter @Profile("soap")
4. **Perfiles Spring: SIEMPRE incluir 'soap'** — sin él la app no arranca (SPRING_PROFILES_ACTIVE=dev,soap)
5. **Auth Angular NO va en cotizador-core** — AuthService, AuthGuard, authInterceptor viven en core/auth/ del producto
6. **Auth backend SÍ va en bff-common** — LDAP, JWT, SecurityConfig, JwtAuthFilter son transversales
7. **Verificar contra el legacy ANTES de afirmar** — leer JSPs/JS en src/main/webapp/ antes de decir cómo funciona algo
8. **No tocar libs/ sin verificar que todos los productos compilan** — la lib es compartida
9. **Design System sb-ui obligatorio** — clases sb-ui-*, data-brand="seguros-bolivar"
10. **DataHeader estándar en TODA llamada SOAP** — modulo, proceso, subProceso, codCia, codSecc, codProducto, subProducto, codUrs, canal

**Learned**: La mayoría de bugs han sido por violar regla 1 (duplicar código), regla 3 (llamar SOAP sin adapter) y regla 7 (asumir comportamiento del legacy sin leer el código).

---

## #137 — BUG prc_separa_conceptos — doble resta asistencia cuando prima_prov=0 causa FAU04

**Tipo:** bugfix | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db | **Topic:** bugfix/fau04-doble-resta-asistencia-prima-prov-cero

**What**: Bug en `prc_separa_conceptos` de `SIM_PCK_FACTURA_ELECTRONICA`: cuando `prima_prov = 0` (pólizas sin IVA con asistencia), se resta la asistencia DOS VECES de `l_prima_prov`. El código hace: `l_prima_prov := l_prima` (que ya es `imp_prima - asistencia`) y luego `l_prima_prov := l_prima_prov - l_prima_asistencia` (segunda resta). Esto causa que `baseImponible` de línea 1 sea incorrecta, y la DIAN rechaza con FAU04 porque `valorSubTotalConversion != SUM(baseImponible)`.
**Why**: Pólizas ramo 250 (Nuevo Producto Automóviles) con línea de Asistencia Bolívar y sin IVA (prima_prov=0) son rechazadas por DIAN con regla FAU04.
**Where**: OPS$PUMA.SIM_PCK_FACTURA_ELECTRONICA, procedimiento `prc_separa_conceptos`, líneas del bloque `IF l_prima_asistencia != 0`
**Learned**: El fix debe evitar la doble resta: cuando `prima_prov = 0`, `l_prima` ya tiene `imp_prima - asistencia`, así que NO se debe restar asistencia de nuevo. La condición `IF (ip_factura.prima_prov IS NOT NULL AND ip_factura.prima_prov != 0)` no contempló el caso de pólizas sin IVA donde prima_prov=0 pero sí hay asistencia.

---

## #118 — RESUELTO: MDSB-1034420 correctivo aplicado en prod - suma primas = 0

**Tipo:** bugfix | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

**What**: Correctivo MDSB-1034420 ejecutado exitosamente en producción. Factura negativa generada para póliza 2592000257502 (sección 923, CIA 3). Suma total de primas = 0 (cuadra perfectamente).

**Why**: PRC299_FACTURA_ANULACION_GRUPO con PFECHAVIGEND=NULL generó factura 2 con IMP_PRIMA=-60712, COD_SITUACION='EP'. La factura positiva (CT) se cruza con la negativa (EP) dejando la póliza sin deuda.

**Where**: Producción (TRON). Validación: MDSB-1041145 (Consulta con éxito).

**Learned**: El ciclo completo del caso MDSB-1034420 fue: diagnóstico con código fuente → confirmación en prod → correctivo validado en dev → scripts + rollback → ejecución en prod → validación post-correctivo. Total: ~4 horas de trabajo efectivo.

---

## #106 — VALIDADO en dev: correctivo MDSB-1034420 genera factura negativa OK

**Tipo:** bugfix | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: Correctivo PRC299_FACTURA_ANULACION_GRUPO validado exitosamente en dev para póliza 2592000257502 (sección 923). Genera factura 2 con prima negativa -60712 en A2000163 y cuota EP en A2990700.

**Why**: La póliza fue cancelada pero el cursor de Proc_Reversa_facturaDB no encontró la factura por discrepancia de fechas. Llamar PRC299_FACTURA_ANULACION_GRUPO directamente con PFECHAVIGEND=NULL salta el cursor problemático.

**Where**: Dev (10.1.2.76), NUM_SECU_POL=29829343733, PNUMFACTURABASE=1, PFECHAVIGEND=NULL, PNUMEND=1.

**Learned**: 1) El correctivo genera exactamente los registros esperados: 3 filas en A2000163 (GENERICOS, 923023923, 923888923) con prima*-1, y 1 fila en A2990700 con COD_SITUACION='EP'. 2) También genera registros en A2990701 (comisiones), A2000252 (comisiones agente), A2000191 (impuestos). 3) El script es seguro para producción — mismo NUM_SECU_POL confirmado en prod via MDSB-1040981.

---

## #93 — MDSB-1034420: Nota crédito no generada en cancelación póliza 923 por discrepancia fechas vigencia vs factura

**Tipo:** bugfix | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: Póliza 2592000257502 (sección 923, TuSeguro, CIA 3) cancelada con endoso 1 (COD_END=922, SUB_COD_END=3, TIPO_END='AT') pero no se generó la factura negativa (nota crédito) en A2990700 ni en A2000163.

**Why**: Discrepancia de fechas: FECHA_VIG_POL=01/09/2025 pero la factura original tiene FEC_EFECTO=21/07/2025. El endoso de cancelación tiene FECHA_VIG_END=01/09/2025. La prima negativa SÍ se calculó en A2000160 (IMP_PRIMA_END=-60712) pero NO se distribuyó en A2000163 ni se generó cuota en A2990700. Adicionalmente, SIM_FACTURA_MVTOS tiene un registro NE con error 'NO EXISTE FACTURA ELECTRONICA' porque la sección 923 está excluida de facturación electrónica DIAN (C9999909).

**Where**: Tablas A2000030, A2000160, A2000163, A2990700, SIM_FACTURA_MVTOS, SIM_FACTURA_ELECTRONICA, C9999909. Paquetes candidatos: SIM_PCK_FACTURACION, PCK_FACTURA_ELECTRONICA.

**Learned**: 1) Sección 923 está configurada como 'Productos que no se van a enviar a la DIAN' en C9999909. 2) El proceso de cancelación calcula prima negativa en A2000160 pero falla al generar la factura en A2000163/A2990700. 3) Caso similar MDSB-832098 del mismo producto 923 con error 'Fecha de vigencia del endoso no está comprendida en la vigencia póliza'. 4) Segundo caso afectado: 3551000195310-923.

---

## #69 — MDSB-992543: Dos causas raíz en facturación exclusión — CEIL + diferidos

**Tipo:** bugfix | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

**What**: El caso MDSB-992543 (póliza 1000486837825, riesgo 662) tiene DOS causas raíz independientes que explican la diferencia de $15,332 entre cobro y devolución.

**Why**: La factura 13 (devolución por exclusión) devolvía más de lo cobrado en factura 12. Se identificaron dos componentes separados.

**Where**: 
- SIM_PCK299_AB100273.pkb → prc_CalcCoeficiente (bug CEIL, ~$2,849, CORREGIDO)
- SIM_PCK299_CB100270.pkb → V_factor línea 72 (diferidos × 13 meses, ~$12,483, PENDIENTE validación funcional)

**Learned**:
- CEIL(MONTHS_BETWEEN * 30) infla v_DiasCotiz en +1 cuando fecha vigencia no es fin de mes y vencimiento sí lo es. Fix: usar TRUNC.
- CB100270 multiplica diferido mensual por meses RESTANTES hasta vencimiento póliza. En exclusiones inmediatas (inclusión y exclusión mismo día), esto devuelve diferidos que nunca se cobraron.
- El fix CEIL→TRUNC solo resuelve $2,849. Los ~$12,483 restantes requieren validación funcional sobre si V_factor debe considerar meses efectivamente cobrados vs meses restantes.
- Patrón: cuando MONTHS_BETWEEN involucra fin-de-mes, Oracle usa divisor 31 para la fracción, lo que genera decimales que CEIL redondea hacia arriba incorrectamente.

---

## #63 — MDSB-992543 RESUELTO: Fórmula facturación = IMP_PRIMA_END*CoefFact + diferidos(CB100270)

**Tipo:** bugfix | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

**What**: Reproducido exactamente el monto de -162,693 de la factura 13 del caso MDSB-992543. La fórmula incluye un ajuste de diferidos (C1000270) que se aplica DESPUÉS del INSERT por Sim_Pck299_Cb100270.Prc_Proceso.
**Why**: Para determinar si la diferencia de $15,332 entre factura 12 y 13 es bug o comportamiento esperado.
**Where**: SIM_PCK299_CB100270.pkb (Prc_upd163 línea 303, Prc_lee270 línea 230), SIM_PCK299_AB100273.pkb (llamada en línea 820)
**Learned**:
1. FÓRMULA COMPLETA: IMP_PRIMA = ROUND(IMP_PRIMA_END * v_CoefFact, 0) + (IMP_PRIMA_163_C1000270 * V_factor)
2. Para MDSB-992543: -197,949 + (2,712 * 13) = -197,949 + 35,256 = -162,693 ✓
3. V_factor = CEIL(MONTHS_BETWEEN(FechaVencPol, FechaVtoFact)) = CEIL(MB('30-APR-2027','31-MAR-2026')) = 13
4. Sim_Pck299_Cb100270 se llama DESPUÉS del INSERT cuando: PeriodoFact=1 AND CodSecc=1 AND NumEnd>0 AND TipoEnd NOT IN ('AT','RE')
5. El paquete CB100270 hace UPDATE A2000163 SET imp_prima = imp_prima + (V_impprima163 * V_coefpol) donde V_impprima163 = SUM(imp_prima_163) * V_factor de C1000270
6. La diferencia de $15,332 entre factura 12 ($149,809) y factura 13 ($162,693) se explica por: la devolución incluye diferidos por 13 meses restantes (35,256 * CoefFact = 3,328) + la proporción de 39 días vs 31 días
7. CONCLUSIÓN: Es COMPORTAMIENTO ESPERADO del sistema — al excluir un riesgo se devuelve prima proporcional + diferidos pendientes

---

## #56 — Fix: credenciales .env no disponibles en shell del agente

**Tipo:** bugfix | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

**What**: El steering consulta-produccion-mdsb.md usaba `os.environ["JIRA_USERNAME"]` y `$JIRA_USERNAME` en curl, pero esas variables no existen en el shell del agente. Solo están disponibles dentro del proceso de los MCP servers (se cargan desde ~/.kiro/settings/.env al iniciar cada server).
**Why**: El agente fallaba con "Las credenciales no están disponibles como variables de entorno en el shell" al intentar crear requests MDSB.
**Where**: powers/corex-n3/steering/consulta-produccion-mdsb.md
**Learned**: Las credenciales en Kiro powers viven en ~/.kiro/settings/.env y se inyectan SOLO en los procesos MCP (via `set -a; . .env; set +a; exec ...`). Para scripts que el agente ejecuta en terminal, hay que leer el .env manualmente con open(). Nunca asumir que están en os.environ.

---

## #37 — Diagnóstico MDSB-992543: Diferencia primas factura 12 vs 13 por desalineación de fechas de efecto

**Tipo:** bugfix | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

**What**: Diagnóstico de diferencia de $15,332 entre prima cobrada en factura 12 y devuelta en factura 13 para póliza 1000486837825, riesgo 662 (placa LRO484)
**Why**: La factura 13 (devolución por exclusión endoso 16) devuelve más de lo cobrado en factura 12 porque los períodos de cálculo son diferentes: factura 12 efecto 28/02 (31 días), factura 13 efecto 20/02 (39 días)
**Where**: Tablas A2000030 (endosos 13 y 16), A2000040 (coberturas riesgo 662), A2990700 (facturas), A2000163 (detalle facturas), C1000270 (diferidos)
**Learned**: Cuando un riesgo se incluye a mitad de período y se excluye desde la misma fecha de inclusión, la devolución se calcula desde la fecha de vigencia del endoso (no desde la fecha de efecto de la factura anterior). Esto genera una diferencia aparente que NO es un bug — es comportamiento esperado del sistema de facturación. La diferencia corresponde a los días entre la fecha de vigencia del endoso y la fecha de efecto de la factura mensual. Clave: verificar siempre FEC_EFECTO en A2990700 vs FECHA_VIG_END en A2000030 para entender diferencias de primas en exclusiones.

---

## #5 — Reinstalar power pierde server.py y deja mcp.json con placeholders

**Tipo:** bugfix | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** bugfix/power-reinstall-breaks-oracle

**What**: Al reinstalar el power corex-n3 desde Kiro, se pierden server.py y el mcp.json queda con variables placeholder ($COREX_SERVER_PATH, $ORACLE_USER) sin resolver. Kiro copia el mcp.json del source literal, no ejecuta el install.sh.

**Why**: El usuario reinstalé el power y las conexiones Oracle dejaron de funcionar. El mcp.json del source usa variables genéricas para portabilidad entre compañeros, pero Kiro no las resuelve al instalar.

**Where**: ~/.kiro/powers/installed/corex-n3/mcp.json — requiere valores reales (paths absolutos, credenciales). ~/.kiro/powers/installed/corex-n3/server.py — debe copiarse manualmente si se pierde.

**Learned**: "Install Power from local directory" en Kiro NO ejecuta install.sh — solo copia POWER.md, mcp.json y steering/. El server.py y los valores reales del mcp.json deben restaurarse manualmente después de reinstalar, o ejecutar install.sh por separado. Para el futuro: el install.sh debería también escribir el mcp.json en ~/.kiro/powers/installed/corex-n3/ con valores resueltos, no solo en ~/.kiro/settings/mcp.json.

---

## #134 — Query log facturación electrónica — SIM_LOG_FACTURA_E con CLOBs

**Tipo:** pattern | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

**What**: Query para consultar logs de facturación electrónica (request/response JSON) en SIM_LOG_FACTURA_E usando DBMS_LOB.SUBSTR para extraer CLOBs.
**Why**: Los campos API_REQ_JSON y API_RESP_JSON son CLOB y SQL*Plus no los muestra sin configuración especial.
**Where**: OPS$PUMA.SIM_LOG_FACTURA_E (se busca por NUM_SECU_POL, obtenido de SIM_FACTURA_ELECTRONICA)
**Learned**: Para ver CLOBs en SQL*Plus: SET LONG 32000, SET LONGCHUNKSIZE 32000, SET LINESIZE 32000, y usar DBMS_LOB.SUBSTR(campo, 4000, 1). La tabla SIM_LOG_FACTURA_E tiene: CODIGO, DESCRIPCION, PROGRAMA, FECHA, USUARIO, NUM_SECU_POL, DATOS_ADICIONALES, API_REQ_JSON (CLOB), API_RESP_JSON (CLOB). Se relaciona con SIM_FACTURA_ELECTRONICA por NUM_SECU_POL.

---

## #130 — Flujo consulta producción vía MDSB — primera ejecución exitosa

**Tipo:** pattern | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

**What**: Se ejecutó el flujo completo de consulta a producción vía MDSB usando el steering `consulta-produccion-mdsb.md` del power corex-n3. Se creó MDSB-1041637 para consultar facturación electrónica de pólizas 1003612215701 y 1003612214101.
**Why**: El usuario necesitaba datos de producción y oracle-readonly apunta a dev (no a prod). El proceso correcto es crear un MDSB en Service Desk para que el bot AIOps ejecute la consulta.
**Where**: Power corex-n3, steering consulta-produccion-mdsb.md
**Learned**: 1) oracle-readonly = dev, oracle-stage = pre-prod, producción = solo vía MDSB. 2) El script Python lee credenciales de ~/.kiro/settings/.env (no de env vars del shell). 3) El archivo SQL DEBE adjuntarse AL MOMENTO de crear el request (no después). 4) Las tablas clave para facturación electrónica son: SIM_FACTURA_ELECTRONICA (DIAN), A2990700 (cuotas), A2000030 (cabecera pólizas).

---

## #119 — Pipeline pr-validator falla tras Update Branch en GitHub

**Tipo:** pattern | **Fecha:** 2026-05-15 | **Proyecto:** tronador-oracle-db

**What**: El pipeline `pr-validator` de tronador-oracle-db valida que los hashes de commits estén integrados en ramas previas (develop → stage → master). Cuando se usa el botón "Update branch" de GitHub, se crea un commit de merge con un hash nuevo que nunca existió en develop/stage, causando que el pipeline falle.

**Why**: GitHub hace merge de master INTO la rama feature, generando un commit de merge con hash nuevo que el validador externo (`devops-actions-oracle-db-pr-validator-templates`) no reconoce.

**Where**: .github/workflows/pr-validator.yml → usa template externo segurosbolivar/devops-actions-oracle-db-pr-validator-templates

**Learned**: 
- NUNCA usar "Update branch" de GitHub en este repo si la rama ya pasó por develop/stage
- Solución 1: `git reset --hard <hash_antes_del_merge>` + force push para volver al estado previo
- Solución 2: Rebase sobre master para eliminar el commit de merge
- La opción más segura es resetear al estado anterior si la rama ya estaba validada en develop/stage

---

## #103 — Checklist seguridad PRC299_FACTURA_ANULACION_GRUPO: verificaciones previas obligatorias

**Tipo:** pattern | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: Validación exhaustiva de seguridad del script correctivo para MDSB-1034420 antes de ejecutar en dev. Se recorrió el código de PRC299_FACTURA_ANULACION_GRUPO paso a paso con los datos reales de la póliza.

**Why**: Confirmar que no hay condiciones de salida prematura ni efectos secundarios inesperados antes de ejecutar.

**Where**: PRC299_FACTURA_ANULACION_GRUPO con datos: PNUMSECUPOL=29829343733, PNUMFACTURABASE=1, PFECHAVIGEND=NULL, PNUMEND=1.

**Learned**: 1) Con PFECHAVIGEND=NULL y factura CT, el procedimiento NO prorratea (usa fechas originales). 2) Verificaciones previas obligatorias: A5020301 recibo≠9999955 (no cruce), canal_descto≠10, periodo_fact≠12, FECHA_VIG_FACT≠FECHA_VTO_FACT. 3) El coeficiente resulta exactamente -1 cuando MONTHS_BETWEEN(VTO,VIG)/MONTHS_BETWEEN(VTO,VIG)=1. 4) El procedimiento solo hace INSERTs (no modifica ni borra registros existentes). 5) Tablas afectadas: A2000163, A2990700, A2990701, A2000252, A2000191 (todas con nueva factura 2).

---

## #101 — Correctivo: Generar factura negativa en 923 via PRC299_FACTURA_ANULACION_GRUPO o Generación Interactiva

**Tipo:** pattern | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: Para corregir pólizas 923 canceladas sin nota crédito, hay dos opciones: 1) Generación Interactiva de Factura desde Tronador (/Facturacion/Generacion Interactiva con CIA, Sección, Póliza, Endoso), 2) Llamar directamente PRC299_FACTURA_ANULACION_GRUPO con PFECHAVIGEND=NULL para devolver 100% sin prorrateo.

**Why**: El cursor de Proc_Reversa_facturaDB no encuentra la factura, pero PRC299_FACTURA_ANULACION_GRUPO puede llamarse directamente saltando el cursor. Con PFECHAVIGEND=NULL el procedimiento no prorratea y usa las fechas originales de la factura (coeficiente=-1, devolución total).

**Where**: PRC299_FACTURA_ANULACION_GRUPO (procedure standalone), SIM_PCK_FACTURACION.Proc_Factura_Interactiva → sim_pck_proceso_dml_emision.proc_genera_factura. Caso referencia: MDSB-951481 (mismo producto 923, resuelto con Generación Interactiva).

**Learned**: 1) MDSB-951481 es precedente exacto: póliza 923 anulada sin factura negativa, resuelta con Generación Interactiva. 2) El usuario puede no tener acceso al módulo 923 en Generación Interactiva — necesita alguien de Operaciones. 3) PRC299_FACTURA_ANULACION_GRUPO con PFECHAVIGEND=NULL no prorratea (devuelve todo). 4) MDSB-783872/MDSB-647142 muestran el patrón de reversar+regenerar factura como workaround estándar. 5) MDSB-961532 fue el cambio de enero 2026 a PRC299_FACTURA_ANULACION_GRUPO (v1.2 por Rosario Puertas) que agregó condición para anulaciones automáticas vs en línea.

---

## #95 — Patrón: Nota crédito no generada en cancelación sección 923 por fecha factura < fecha vigencia

**Tipo:** pattern | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: En pólizas de sección 923 (TuSeguro/Ofertas Protección General), cuando la fecha de emisión/factura es anterior a la fecha de vigencia real de la póliza, el proceso de cancelación calcula la prima negativa en A2000160 pero NO genera la factura negativa en A2000163 ni la cuota en A2990700.

**Why**: El proceso de facturación del endoso de cancelación busca la factura vigente en el rango de fechas del endoso (FECHA_VIG_END). Si la factura original tiene FEC_EFECTO anterior a FECHA_VIG_POL, no la encuentra y no genera el negativo. Adicionalmente, la sección 923 está excluida de facturación electrónica DIAN (C9999909), lo que causa error secundario 'NO EXISTE FACTURA ELECTRONICA' en SIM_FACTURA_MVTOS.

**Where**: Proceso de facturación de endosos en SIM_PCK_FACTURACION. Tablas: A2000160 (prima OK), A2000163 (sin registro), A2990700 (sin cuota negativa). Configuración: C9999909 COD_TAB='FACTURACION_ELEC' COD_SECC=923.

**Learned**: 1) Producto 923 permite emitir con fecha de factura anterior a vigencia. 2) El proceso de cancelación no contempla este escenario. 3) Patrón recurrente: MDSB-832098 (jun 2025) y MDSB-1034420 (may 2026). 4) Diagnóstico rápido: verificar A2000160.IMP_PRIMA_END < 0 AND no existe registro en A2000163 para el mismo endoso.

---

## #91 — Patrón: Asimetría cobro periódico vs devolución por endoso en Autos

**Tipo:** pattern | **Fecha:** 2026-05-14 | **Proyecto:** tronador-oracle-db

**What**: La diferencia entre factura periódica (cobro) y factura de endoso (devolución) se debe a que usan fuentes de datos y flujos distintos dentro del mismo orquestador AB100277.

**Why**: Patrón recurrente en exclusiones de riesgos en Autos (sección 1) con período mensual y COD_DURACION=2.

**Where**: SIM_PCK299_AB100277.PRC_PROCESO → SIM_PCK299_AB100273.PRC_INICIO

**Learned**:
- Factura periódica (proceso 'RE'): usa `prima_anu` de A2000040, coeficiente 1/12, NO pasa por CB100270
- Factura de endoso (proceso 'EM'): usa `imp_prima_end` de A2000160, coeficiente proporcional (días/total), SÍ pasa por CB100270
- `imp_prima_end` incluye prima + gastos expedición (es mayor que prima_anu)
- CB100270 solo se ejecuta cuando: V_procesoFact != 'RE' AND V_Tipoend != 'AT' AND V_Tipoend != 'RE'
- La condición está en AB100273 línea 811, NO en AB100277
- Esto genera asimetría inherente: cobro mensual ≠ devolución proporcional, incluso sin bugs
- Para comparar correctamente: prima_anu/12 vs imp_prima_end*CoefFact son fórmulas distintas por diseño

---

## #66 — Sync Engram → shared-knowledge/ en corex-n3-power

**Tipo:** pattern | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db

**What**: Se exportaron las memorias Engram más relevantes al directorio shared-knowledge/ del repo corex-n3-power, organizadas en 4 archivos: decisions.md (4 decisiones técnicas), architecture-facturacion.md (3 flujos de facturación con diagrama consolidado), patterns-bugfixes.md (4 patrones/bugfixes incluyendo MDSB-992543), sessions-summary.md (2 sesiones clave).
**Why**: Para que el conocimiento persista en Git y sea accesible a todo el equipo sin depender de la BD local de Engram.
**Where**: corex-n3-power/shared-knowledge/ (decisions.md, architecture-facturacion.md, patterns-bugfixes.md, sessions-summary.md, README.md)
**Learned**: El comando 'actualiza conocimiento' exporta las memorias más valiosas (decisions, architecture, patterns, bugfixes, session_summaries) agrupadas por categoría. Las session_summaries solo se exportan si son significativas (diagnósticos completos, optimizaciones mayores).

---

## #65 — Patrón: Diferidos CB100270 generan devolución mayor al cobro en exclusiones autos

**Tipo:** pattern | **Fecha:** 2026-05-13 | **Proyecto:** tronador-oracle-db | **Topic:** pattern/diferidos-cb100270-exclusion-autos

**What**: Diagnóstico completo MDSB-992543 — diferencia $15,332 entre factura cobro y devolución por exclusión de riesgo en autos colectivos
**Why**: Riesgo 662 (placa LRO484) incluido y excluido el mismo día (20-FEB-2026), la devolución es mayor al cobro
**Where**: Sim_Pck299_Cb100270.pkb (Prc_upd163 línea 303, V_factor línea 72), SIM_PCK299_AB100273.pkb (llamada línea 811-831)
**Learned**:
1. FÓRMULA COMPLETA FACTURACIÓN EXCLUSIÓN: IMP_PRIMA_FINAL = ROUND(IMP_PRIMA_END × CoefFact, 0) + (IMP_PRIMA_163_C1000270 × V_factor × V_coefpol)
2. V_factor = CEIL(MONTHS_BETWEEN(FechaVencPol, FechaVtoFact)) — meses RESTANTES hasta vencimiento, NO meses cobrados
3. Para MDSB-992543: -197,949 + (2,712 × 13 × 1) = -162,693
4. ASIMETRÍA: Cobro usa prima_anu/12 + 1_diferido = $149,809. Devolución usa fórmula proporcional + 13_diferidos = $162,693
5. Sim_Pck299_Cb100270 se ejecuta DESPUÉS del INSERT cuando: PeriodoFact=1 AND CodSecc=1 AND NumEnd>0 AND TipoEnd NOT IN ('AT','RE')
6. El paquete CB100270 NO valida cuántos diferidos se cobraron realmente — devuelve por meses futuros
7. Requiere validación funcional: ¿el diferido es obligación futura cancelable o cobro mensual devolvible solo si se cobró?
8. Flujo completo: Form AC100731 → SIM_PCK_ANULACIONENDOSO → PROC_GENERA_FACTURA → AB100277 → AB100273 (INSERT) → CB100270 (UPDATE +diferidos)

---

## #46 — Patrón: Diferencia primas factura cobro vs devolución por desalineación FECHA_VIG_END vs FEC_EFECTO

**Tipo:** pattern | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

**What**: Cuando un riesgo se incluye a mitad de período (FECHA_VIG_END != fecha inicio factura mensual) y luego se excluye desde la misma fecha, la devolución puede ser mayor que la cuota mensual cobrada.
**Why**: La factura de cobro mensual usa FEC_EFECTO (inicio del mes) como base del período. La factura de devolución por exclusión usa FECHA_VIG_END del endoso de inclusión como inicio del período. Si FECHA_VIG_END < FEC_EFECTO de la factura mensual, la devolución cubre más días.
**Where**: PRC299_FACTURA_ANULACION_GRUPO (COEFFACT), SIM_PCK_PROCESO_DML_EMISION.proc_genera_factura → Sim_Pck299_Ab100277.prc_Inicio, tablas A2000163, A2990700, C1000270
**Learned**: NO es un bug. Los días 'extra' devueltos ya fueron cobrados en la factura anterior. Para verificar: comparar FEC_EFECTO en A2990700 de la factura de cobro vs FECHA_VIG_FACT en A2000163 de la factura de devolución. Si FECHA_VIG_FACT < FEC_EFECTO → la diferencia corresponde a días cobrados en factura previa. Clave: C1000270.MESES indica los meses de diferido para el cálculo de cuota.

---

## #41 — Patrón: Exclusión devuelve más que inclusión cuando MESES_excl < MESES_incl en C1000270

**Tipo:** pattern | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db

**What**: En facturación de exclusiones, si C1000270 tiene MESES menor para la exclusión que para la inclusión, la cuota de devolución (PRIMA_COB/MESES_excl) es mayor que la cuota cobrada (PRIMA_COB/MESES_incl). Esto genera diferencias en facturas.
**Why**: El sistema resta 1 al campo MESES cuando calcula la exclusión (asume que ya se cobró 1 cuota). Pero la cuota cobrada se calculó con el MESES original (mayor). Al dividir la misma PRIMA_COB por un número menor, cada cuota de devolución es mayor.
**Where**: C1000270 (campo MESES y EXCLUSION), proceso de facturación en SIM_PCK299_AB100274 y SIM_PCK_PROCESO_DML_EMISION.proc_genera_factura
**Learned**: Para diagnosticar diferencias de primas entre facturas de cobro y devolución: 1) Consultar C1000270 en PRODUCCIÓN (Dev puede no tener registro de exclusión). 2) Comparar MESES de inclusión vs exclusión. 3) Si MESES_excl = MESES_incl - 1, la diferencia es PRIMA_COB*(1/MESES_excl - 1/MESES_incl). 4) Este patrón aplica a cualquier póliza con pago fraccionado donde se excluye un riesgo después de 1 factura.

---

## #39 — Regla de diagnóstico: leer código PL/SQL, no simular procesos

**Tipo:** pattern | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** pattern/diagnostico-leer-codigo-no-simular

**What**: Se identificó que el agente de diagnóstico divaga haciendo queries exploratorias y cálculos manuales en vez de leer el código PL/SQL que ejecuta el proceso real.

**Why**: La verdad del proceso está en los packages Oracle, no en suposiciones del agente. El diagnóstico correcto es: leer el SP → seguir su flujo → replicar con datos del caso → encontrar dónde diverge.

**Where**: Steering diagnostico-eficiente.md y atencion-incidente-autonomo.md necesitan actualización.

**Learned**: Regla crítica para diagnóstico: NUNCA simular un proceso. SIEMPRE leer el código que lo ejecuta (get_source) y replicar su lógica con los datos del caso. El flujo correcto es: (1) identificar qué SP/package ejecuta el proceso, (2) leer su código completo, (3) ejecutar las mismas queries que hace el SP con los datos reales, (4) encontrar el punto exacto donde resultado esperado ≠ resultado real.

---

## #36 — Lección: siempre verificar paths internos al migrar estructura de repo

**Tipo:** pattern | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** pattern/repo-migration-paths

**What**: Se corrigieron TODOS los paths .kiro/ en el repo corex-n3-power. Los scripts, steering, README y GUIA-USO ahora apuntan correctamente a powers/corex-n3/scripts/ y shared-knowledge/ (raíz).

**Why**: El repo no tiene .kiro/ a nivel de proyecto. Todas las referencias eran incorrectas y habrían fallado para los compañeros.

**Where**: 8 archivos corregidos en el repo corex-n3-power.

**Learned**: Al migrar archivos de un repo con .kiro/ a uno sin .kiro/, hay que buscar y reemplazar TODAS las referencias internas. Usar grep -rn '\.kiro/' para encontrarlas. Las únicas referencias válidas son ~/.kiro/ y $HOME/.kiro/ (destino de install.sh).

---

## #15 — Patrones de problemas frecuentes en Tronador y diagnóstico

**Tipo:** pattern | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** reference/tronador-patterns

**What**: Patrones de problemas frecuentes en Tronador y cómo diagnosticarlos.

**Patrón 1: Factura no generada**
- Síntoma: Póliza activa pero sin factura
- Tablas: A2000030 (mca_vigente), A2000163 (buscar por num_poliza), A2990700 (cuotas)
- Causa común: Trigger de facturación falló silenciosamente, o póliza en estado intermedio
- Diagnóstico: Verificar mca_facturada en A2000163, buscar errores en SIM_PCK_FACTURA

**Patrón 2: Recaudo no aplicado**
- Síntoma: Pago recibido pero deuda no disminuye
- Tablas: SB_RECAUDO (val_recaudo, estado), A2990700 (saldo_cuota)
- Causa común: Recaudo en estado pendiente, o mismatch entre num_poliza del recaudo y la cuota
- Diagnóstico: Cruzar SB_RECAUDO.num_poliza con A2990700.num_poliza, verificar SIM_PCK_RECAUDO

**Patrón 3: Error en emisión/renovación**
- Síntoma: Póliza no se puede emitir o renovar
- Tablas: A2000030 (tip_spto, mca_vigente), A2000020 (riesgos activos)
- Causa común: Suplemento anterior no cerrado, o validación de negocio en SIM_PCK_EMISION
- Diagnóstico: Verificar último suplemento (MAX num_spto), leer SIM_PCK_EMISION o SIM_PCK_RENOVACION

**Patrón 4: Siniestro sin pago**
- Síntoma: Siniestro aprobado pero sin indemnización
- Tablas: A4000010 (estado_siniestro), A4000020 (reserva), A4000030 (pagos)
- Causa común: Reserva insuficiente, o proceso de aprobación incompleto
- Diagnóstico: Verificar estado en A4000010, comparar reserva vs pago solicitado

**Patrón 5: Débito automático rechazado**
- Síntoma: Cobro no se realizó
- Tablas: SB_CONVENIO (estado_convenio, num_cuenta), SB_RECAUDO
- Causa común: Cuenta inactiva, fondos insuficientes (código rechazo banco)
- Diagnóstico: Verificar estado del convenio, buscar código de rechazo en respuesta del banco

---

## #14 — Packages PL/SQL principales de Tronador y convenciones de nombres

**Tipo:** pattern | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** reference/tronador-packages

**What**: Packages PL/SQL principales de Tronador y su propósito.

**Facturación/Deuda:**
- SIM_PCK_DEUDA: Cálculo y gestión de deuda de pólizas
- COR_PCK_FACTURACION: Facturación Corex (nuevo)
- SIM_PCK_FACTURA: Generación de facturas
- SIM_PCK_CUOTA: Gestión de cuotas

**Recaudo:**
- SIM_PCK_RECAUDO: Proceso de recaudo general
- SIM_PCK_RECAUDO_VPA: Recaudo VPA específico
- SIM_PCK_DEBITO_AUTO: Débito automático

**Emisión:**
- SIM_PCK_EMISION: Emisión de pólizas
- SIM_PCK_POLIZA: Operaciones sobre pólizas
- SIM_PCK_RENOVACION: Renovación de pólizas
- SIM_PCK_SUPLEMENTO: Suplementos/modificaciones

**Siniestros:**
- SIM_PCK_SINIESTRO: Gestión de siniestros
- SIM_PCK_RESERVA: Reservas de siniestros
- SIM_PCK_INDEMNIZACION: Pagos de indemnización

**Comisiones:**
- SIM_PCK_COMISION: Cálculo de comisiones
- SIM_PCK_LIQUIDACION: Liquidación de comisiones

**Utilidades:**
- SIM_PCK_UTIL: Funciones utilitarias generales
- SIM_PCK_FECHA: Operaciones con fechas
- SIM_PCK_PARAMETRO: Lectura de parámetros del sistema

**Patrón de nombres:**
- SIM_PCK_*: Packages del sistema SIM (core)
- COR_PCK_*: Packages de Corex (nuevos/migrados)
- SIM_FNC_*: Funciones standalone
- SIM_PRC_*: Procedures standalone

---

## #13 — Diccionario de tablas principales Tronador (OPS$PUMA)

**Tipo:** pattern | **Fecha:** 2026-05-12 | **Proyecto:** tronador-oracle-db | **Topic:** reference/tronador-tables

**What**: Diccionario de tablas principales de Tronador (OPS$PUMA) para diagnóstico de incidentes.

**Tablas de Pólizas/Emisión:**
- A2000030: Pólizas (cabecera, 18 triggers). PK: cod_cia + num_poliza + num_spto + num_apli + num_spto_apli
- A2000020: Riesgos. FK a A2000030
- A2000040: Coberturas. FK a A2000020
- A2000160: Primas. Detalle de prima por cobertura
- A2000060: Cláusulas
- A2000050: Roles (tomador, asegurado, beneficiario)

**Tablas de Facturación/Recaudo:**
- A2000163: Facturas. Estado factura (mca_facturada, mca_anulada)
- A2990700: Cuotas de facturación. num_cuota, fec_vencimiento, imp_cuota
- SB_RECAUDO: Recaudos VPA. num_recaudo, fec_recaudo, val_recaudo
- SB_CONVENIO: Débito automático. Convenio + cuenta bancaria
- A5000030: Recibos de caja

**Tablas de Siniestros:**
- A4000010: Siniestros (cabecera). num_siniestro, fec_ocurrencia
- A4000020: Reservas
- A4000030: Pagos de siniestro

**Tablas de Terceros:**
- A1000000: Terceros. cod_docum + tip_docum = PK
- A1000002: Direcciones
- A1000004: Teléfonos

**Tablas de Reaseguros:**
- A8000010: Contratos de reaseguro
- A8000020: Cesiones

---
