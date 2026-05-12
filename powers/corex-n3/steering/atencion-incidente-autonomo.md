---
inclusion: auto
---

# Atención Autónoma de Incidentes — Ciclo Completo

## Trigger

Cuando el usuario diga **"atiende el caso MDSB-XXXXX"**, **"atiende MDSB-XXXXX"**, **"caso MDSB-XXXXX"**, o cualquier variante que incluya una clave MDSB seguida de la intención de atenderlo, ejecutar el ciclo completo descrito abajo **de forma autónoma**, sin pedir confirmación en cada paso.

## Principio de Autonomía

- Ejecutar todas las fases en secuencia sin pausas ni preguntas intermedias.
- Solo detenerse para la **pregunta obligatoria de Fase 0** (email + proyecto/epic).
- Después de Fase 0, ejecutar Fases 1-5 sin interrupciones.
- Al finalizar, presentar el reporte consolidado con todos los artefactos creados.

---

## FASE 0 — PREPARACIÓN (requiere input del usuario)

### 0.1 Engram-First: Buscar diagnósticos previos (NUEVO — Bloque D)

**ANTES de cargar la KB de Confluence**, buscar en Engram si ya existe un diagnóstico previo del mismo patrón:

```
mem_search(query="<síntomas o palabras clave del caso MDSB>", project="tronador-oracle-db", type="bugfix")
mem_search(query="<tabla o package mencionado en el caso>", project="tronador-oracle-db", type="pattern")
```

**Si Engram devuelve un resultado relevante:**
- Usar ese conocimiento como punto de partida
- Reducir las consultas Oracle a solo verificar datos específicos del caso actual
- Omitir la carga completa de KB si el patrón ya está en Engram con suficiente detalle

**Si Engram no tiene resultados relevantes:** continuar con 0.2.

### 0.2 Cargar Base de Conocimiento (con cache inteligente)

**Regla de frescura:** Si la sesión anterior fue hace < 24h y ya cargó la KB (verificar en `mem_context`), omitir la recarga completa. Solo cargar la página del módulo específico que el caso requiera.

Si se necesita cargar, consultar la KB principal y los patrones de problemas:

```
confluence_get_page(page_id="1677787138", convert_to_markdown=true)
confluence_get_page(page_id="1688371201", convert_to_markdown=true)
```

Almacenar internamente: diccionario de datos, patrones conocidos, paquetes documentados, lecciones aprendidas.

**La KB es la fuente de verdad del sistema.** Contiene el conocimiento acumulado de todos los incidentes anteriores. Cuanto más rica sea, menos consultas Oracle se necesitan y más rápido es el diagnóstico. Este es el mecanismo de aprendizaje continuo del equipo.

### 0.3 Preguntar datos de sesión (OBLIGATORIO)

Antes de continuar, preguntar al usuario **en un solo mensaje**:

> Para atender este caso necesito:
> 1. **Tu email** (para asignar los issues) — si ya lo conozco de una sesión anterior, confirmar.
> 2. **¿En qué proyecto y epic creo la Historia?** Ejemplos:
>    - GD986 epic GD986-824 (Emisión - Disponibilidad)
>    - GD980 epic GD980-XXX (Modificación)
>    - GD987 epic GD987-XXX (Siniestros)
>    - Otro proyecto/epic de la tribu

**NUNCA asumir el proyecto ni el epic.** Cada miembro del equipo trabaja en tableros distintos (emisión, modificación, cotización, liquidación, comisiones, siniestros, indemnizaciones, reaseguros, coaseguros, etc.). El power sirve a toda la tribu.

Una vez recibida la respuesta:

```
jira_get_user_profile(user_identifier="<email>")
```

Guardar para la sesión:
- `accountId` del usuario
- `project_key` (ej: GD986, GD980, GD987...)
- `epic_key` (ej: GD986-824, GD980-XXX...)

---

## FASE 1 — DIAGNÓSTICO (autónomo, guiado por código fuente)

### 1.1 Obtener caso Jira completo

```
jira_get_issue(issue_key="MDSB-XXXXX", fields="*all", comment_limit=20)
```

Extraer: summary, descripción, comentarios cronológicos, issues vinculados, estado, prioridad, labels, componentes, reporter.

### 1.2 Extraer datos clave

Analizar descripción + comentarios para identificar **todo dato que pueda servir para el diagnóstico**:
- Números de póliza, certificados, endosos
- Identificación (CC, NIT, cédula)
- Números de recibo, factura, cuota
- Códigos de ramo, sección, producto
- Mensajes de error específicos
- Nombres de tablas, packages, procedimientos, funciones, triggers
- Nombres de programas batch (CB/CR) o pantallas (AP/CP/CC/AC)
- Cualquier referencia a procesos de negocio (emisión, recaudo, siniestro, reaseguro, etc.)

### 1.3 Buscar documentación relacionada en Confluence y Jira

```
confluence_search(query="<términos clave del error o proceso>", limit=5, spaces_filter="BDCT")
jira_search(jql='project = MDSB AND text ~ "<término clave>" ORDER BY created DESC', limit=10)
```

Anotar claves de casos duplicados o relacionados para vincularlos después.

### 1.4 Leer código fuente — OBLIGATORIO ANTES de consultar datos en Oracle

⚠️ **REGLA CRÍTICA: No hacer queries de datos sin antes leer el código que los procesa.**

El diagnóstico correcto requiere entender QUÉ HACE el código antes de verificar datos. Sin leer el código, cualquier query es exploratoria y puede llevar a conclusiones incorrectas.

**Orden obligatorio de búsqueda en repositorios:**

#### Paso A: Repositorio Oracle DB (tronador-oracle-db) — FUENTE DE VERDAD PL/SQL

Buscar el package/procedure/function/trigger mencionado en el caso:

```
Ruta: tronador-oracle-db/Base Datos/Packages/<NOMBRE>.pkb  (body)
Ruta: tronador-oracle-db/Base Datos/Packages/<NOMBRE>.pks  (spec)
Ruta: tronador-oracle-db/Base Datos/Procedimientos/<NOMBRE>.prc
Ruta: tronador-oracle-db/Base Datos/Funciones/<NOMBRE>.fnc
Ruta: tronador-oracle-db/Base Datos/Triggers/<NOMBRE>.trg
```

**Técnicas de lectura eficiente para packages grandes:**
- `grep_search` para localizar una función/procedure específica dentro del package
- `read_file` con `start_line`/`end_line` para leer solo la sección relevante
- `readCode` con selector `PackageName.procedureName` para ir directo

**Si el archivo NO existe en el repo** → fallback a `get_source` del MCP oracle-readonly.

#### Paso B: Repositorio COBOL (tronador-core-cobol) — Procesos batch

Si el caso menciona un proceso batch, nocturno, o programado, o si el SP Oracle es invocado por un programa batch:

```
Ruta: tronador-core-cobol/<NOMBRE>.pco
```

Buscar por convención de nombres:
- `CB` = Batch (proceso nocturno/programado)
- `CR` = Batch Report (generación de reportes)
- Números: `226` = emisión colectivas, `270` = salud, `299` = cartera, `502` = recaudo, `902` = siniestros

**Qué buscar en el COBOL:**
- Parámetros que envía al SP Oracle (`CALL`, `EXECUTE`)
- Condiciones previas que filtran datos antes de llamar al SP
- Manejo de errores y reintentos
- SQL embebido que complementa la lógica del SP

#### Paso C: Repositorio Forms (tronador-forms) — Pantallas y validaciones UI

Si el caso menciona una pantalla, formulario, o error de interfaz:

```
Ruta: tronador-forms/FMT/<NOMBRE>.fmt
```

Buscar por convención de nombres:
- `AP` = Alta de Póliza, `CP` = Consulta de Póliza, `CC` = Consulta/Cambio
- `AC` = Alta/Cambio, `AS` = Alta Siniestro, `AR` = Alta Reaseguro
- Números: `200` = emisión, `270` = salud, `502` = recaudo, `850` = reaseguros

**Qué buscar en Forms:**
- Triggers de validación (WHEN-VALIDATE-ITEM, PRE-INSERT, POST-QUERY)
- Llamadas a SPs Oracle desde la pantalla
- Validaciones de UI que no están en la BD
- Mensajes de error personalizados

#### Paso D: Dependencias y objetos relacionados

Una vez leído el código principal, identificar dependencias:
- Si el SP llama a otros SPs → leer esos también (repetir Paso A)
- Usar `get_dependencies` del MCP Oracle para mapear quién usa/es usado por el objeto
- Buscar triggers en tablas afectadas: `tronador-oracle-db/Base Datos/Triggers/`

### 1.5 Consultar Oracle — Solo para DATOS, guiado por lo que dice el código

**AHORA SÍ** consultar Oracle, pero SOLO para verificar datos específicos que el código fuente indica que son relevantes.

Usar `oracle-readonly` (dev). Si falla, intentar `oracle-stage`.

**Reglas:** esquema `OPS$PUMA`, siempre `ROWNUM <= 50`, solo SELECT.

**Estrategia de eficiencia (steering `diagnostico-eficiente.md`):**

1. **Clasificar el caso en un módulo** usando los árboles de decisión:
   - Emisión/Pólizas → si menciona póliza, vigencia, estado, endoso
   - Facturación/Deuda → si menciona deuda, factura, cuota, prima
   - Recaudo/VPA → si menciona recaudo, débito automático, convenio
   - Siniestros → si menciona siniestro, reclamo, indemnización

2. **Usar templates SQL pre-armados** (ver `diagnostico-eficiente.md` Estrategia 6):
   - Template póliza completa: 1 query con JOIN que trae póliza + facturas + cuotas
   - Template deuda: facturas pendientes vs movimientos de caja
   - Template recaudo VPA: SB_RECAUDO + SB_CONVENIO en un solo query
   - Template búsqueda por documento: A2001300 + A2000030

3. **Consolidar queries con JOINs** — NUNCA hacer 4 queries simples cuando 1 JOIN resuelve todo.

4. **Meta: ≤ 4 llamadas Oracle por caso.** Si se necesitan más, evaluar si se pueden consolidar.

5. **Las queries deben replicar lo que hace el código.** Ejecutar las MISMAS condiciones WHERE que usa el SP/programa. No inventar queries exploratorias.

### 1.6 Diagnóstico profundo — Seguir el flujo COMPLETO (OBLIGATORIO)

⚠️ **REGLA CRÍTICA:** No detenerse en los filtros de entrada. Un dato que pasa todos los filtros de selección puede ser transformado, descartado o anulado en pasos posteriores.

Para CUALQUIER proceso Oracle que se esté diagnosticando, trazar el flujo completo:

**1. Entrada** — ¿El dato entra al proceso?
- Verificar que los datos existen en las tablas fuente
- Verificar que pasan los filtros/condiciones del SQL

**2. Transformación** — ¿Qué le pasa al dato DENTRO del proceso?
- Identificar TODAS las funciones/procedimientos internos que modifican el dato
- Leer el código de CADA función intermedia — no asumir que "funcionan bien"
- Verificar las tablas auxiliares que participan en cálculos (descuentos, ajustes, validaciones)
- Buscar `WHEN OTHERS THEN` que puedan tragar errores silenciosamente

**3. Salida** — ¿El dato llega al resultado final?
- Verificar la tabla intermedia o variable de salida
- Verificar los filtros de lectura final (ej: `valor_deuda <> 0`)
- Confirmar que el resultado coincide con lo que el servicio/consumidor espera

**Regla de evidencia:** Si el usuario proporciona evidencia (screenshots, respuestas de servicio) que contradice el análisis, **la evidencia tiene prioridad**. Buscar qué se está omitiendo.

**Regla de consultas:** SIEMPRE probar las consultas SQL en Dev antes de enviarlas al usuario para producción. No enviar consultas con columnas o tablas que no se han verificado.

> **Origen:** Lección aprendida MDSB-1031049 — se analizaron 12 filtros de `fnc_sqlprimer` (todos pasaban) pero se omitió `prc_verifica_pagos_factura` que consulta A5021600 y descuenta cobros. El diagnóstico inicial fue incorrecto.

### 1.7 Comparar con patrones conocidos y asignar scoring de confianza

Cruzar hallazgos con los patrones cargados en Fase 0. Si hay coincidencia:
- Indicar qué patrón aplica
- Incluir la solución documentada
- Evaluar si aplica directamente o necesita adaptación

**🚨 REGLA DE PRECISIÓN ABSOLUTA:**

Toda conclusión del diagnóstico DEBE cumplir:
- Estar respaldada por código fuente leído (citar archivo y línea/sección)
- Estar verificada con datos reales (citar query ejecutada y resultado)
- Si algo no se pudo verificar → declararlo explícitamente como "NO VERIFICADO"

**NUNCA presentar una suposición como conclusión.** Un diagnóstico incorrecto tiene consecuencias graves en producción.

**Scoring de confianza:**

| Nivel | Criterio | Acción |
|---|---|---|
| **Alta** | Causa raíz identificada con evidencia en código fuente (archivo + línea) + datos verificados (query + resultado) | Reportar con evidencia citada |
| **Media** | Causa probable con código fuente leído pero sin datos de producción para confirmar | Reportar con nota "requiere verificación en prod" + citar qué falta verificar |
| **Baja** | Hipótesis sin evidencia suficiente en código ni datos | Profundizar automáticamente (ver abajo) |

**⚠️ NUNCA reportar confianza Alta sin haber leído el código fuente relevante.** Si no se leyó el código, la confianza máxima es Media.

**Si confianza es Baja → profundización automática:**
1. Leer más código fuente (funciones internas, dependencias) de los 3 repos
2. Verificar dependencias (`get_dependencies`)
3. Buscar en los 3 repositorios archivos relacionados
4. Consultar Engram por casos similares anteriores
5. Re-evaluar con la nueva información

Si después de profundizar sigue en Baja → reportar como "requiere investigación adicional" con:
- Hipótesis ordenadas por probabilidad
- Qué evidencia falta para confirmar cada una
- Qué archivos/queries se necesitan revisar en producción

---

## FASE 2 — DOCUMENTACIÓN EN CONFLUENCE

Usar el template del steering `template-confluence.md`. Crear como hija de la página padre de HUs (ID: 1441136649).

```
confluence_create_page(
  space_key="BDCT",
  title="[<PROJECT_KEY>-XXXX] <Título descriptivo del problema>",
  parent_id="1441136649",
  content=<contenido según template-confluence.md>,
  content_format="markdown"
)
```

**Contenido mínimo obligatorio** (según template):
- Identificación (código HU, título, área, fecha, autor)
- Descripción general y problema detectado
- Solución propuesta (basada en el diagnóstico)
- Consultas SQL usadas durante el diagnóstico
- Casos Jira relacionados (MDSB-XXXXX + relacionados encontrados)
- Última modificación

Guardar el `page_id` de la página creada.

**Nota:** El título usa `[<PROJECT_KEY>-XXXX]` como placeholder. Se actualizará en Fase 3 cuando se conozca la clave real de la HU.

---

## FASE 3 — CREAR HISTORIA EN JIRA

Seguir las reglas del steering `workflow-jira-tiempos.md` y la estructura BDD del steering `escritura-hu.md`. Usar el **proyecto y epic indicados por el usuario en Fase 0**.

La descripción de la HU debe usar el formato "Como... quiero... para..." con escenarios Dado-Cuando-Entonces derivados del diagnóstico. Ver `escritura-hu.md` para el formato completo.

### 3.1 Crear la Historia

```
jira_create_issue(
  project_key="<PROJECT_KEY>",
  summary="<Título descriptivo basado en el diagnóstico>",
  issue_type="Historia",
  assignee="<email del usuario>",
  description="<Resumen del diagnóstico en markdown>",
  additional_fields='{
    "parent": {"key": "<EPIC_KEY>"},
    "customfield_13801": {"value": "Funcional"},
    "customfield_10332": <ADF con criterios de aceptación derivados del diagnóstico>,
    "customfield_31136": [{"workspaceId": "07e9b295-4dbf-4d90-a54e-3498d6f16eb4", "id": "07e9b295-4dbf-4d90-a54e-3498d6f16eb4:419497", "objectId": "419497"}]
  }'
)
```

Guardar la clave del issue creado (ej: GD986-XXXX, GD980-XXXX, etc.).

### 3.2 Vincular los MDSB relacionados

Para cada caso MDSB (el original + los encontrados como relacionados):

```
jira_create_issue_link(
  link_type="Relacionado",
  inward_issue_key="<HU_KEY>",
  outward_issue_key="MDSB-XXXXX"
)
```

### 3.3 Vincular la página de Confluence

```
jira_create_remote_issue_link(
  issue_key="<HU_KEY>",
  url="https://jirasegurosbolivar.atlassian.net/wiki/spaces/BDCT/pages/<page_id>",
  title="Documentación técnica - <título>",
  relationship="documentation"
)
```

### 3.4 Actualizar título de la página Confluence

Ahora que se conoce la clave real, actualizar el título de la página:

```
confluence_update_page(
  page_id="<page_id>",
  title="[<HU_KEY>] <Título descriptivo>",
  content=<contenido actualizado con código HU real>
)
```

---

## FASE 4 — REGISTRAR TIEMPOS

Seguir las reglas del steering `workflow-jira-tiempos.md`.

### 4.1 Crear Sub-tarea de Análisis

```
jira_create_issue(
  project_key="<PROJECT_KEY>",
  summary="Análisis causa raíz - MDSB-XXXXX",
  issue_type="Sub-tarea",
  assignee="<email del usuario>",
  description="Diagnóstico y análisis de causa raíz del incidente MDSB-XXXXX.\n\nActividades:\n- Consulta KB Confluence\n- Análisis caso Jira (descripción, comentarios, vínculos)\n- Consultas Oracle Tronador\n- Búsqueda de casos relacionados\n- Documentación técnica en Confluence",
  additional_fields='{"parent": {"key": "<HU_KEY>"}, "timetracking": {"originalEstimate": "4h"}}'
)
```

### 4.2 Registrar worklog

```
jira_add_worklog(
  issue_key="<clave sub-tarea>",
  time_spent="<tiempo estimado de la sesión, default 2h>",
  comment="Diagnóstico completo del incidente MDSB-XXXXX:\n- Consulta KB y patrones conocidos\n- Análisis de datos en Oracle (Tronador)\n- Documentación en Confluence\n- Creación de HU y vinculación de casos"
)
```

---

## FASE 5 — REPORTE FINAL Y APRENDIZAJE

### 5.1 Reporte al usuario

Al completar todas las fases, presentar:

```markdown
# ✅ Atención Completa: MDSB-XXXXX

## Diagnóstico
- **Problema:** <resumen en 1-2 líneas>
- **Causa raíz:** <identificada / probable / requiere investigación adicional>
- **Confianza:** <Alta / Media / Baja>
- **Patrón conocido:** <sí/no — cuál>

## Evidencia (OBLIGATORIO)
| Afirmación | Fuente | Referencia |
|---|---|---|
| "<lo que hace el código>" | Código fuente | <archivo>.pkb, línea/sección X |
| "<estado de los datos>" | Query Oracle | SELECT ... WHERE ... → resultado |
| "<comportamiento del proceso>" | COBOL/Forms | <archivo>.pco/.fmt, sección Y |

## ⚠️ No Verificado (si aplica)
- <Qué no se pudo confirmar y por qué>
- <Qué se necesita para verificarlo (query en prod, acceso a logs, etc.)>

## Datos Oracle
- <Resumen de hallazgos relevantes por tabla consultada>

## Artefactos Creados
| Artefacto | Clave/Link |
|---|---|
| Historia | <HU_KEY> |
| Sub-tarea Análisis | <SUB_KEY> |
| Documentación Confluence | <título> (page_id) |
| Tiempo registrado | Xh en <SUB_KEY> |

## MDSB Vinculados
- MDSB-XXXXX (original)
- MDSB-YYYYY (relacionado, si aplica)

## Pasos Siguientes
1. <Acción concreta basada en el diagnóstico>
2. <Siguiente paso>

## ⚠️ Observaciones
- <Hallazgos que requieren atención>
```

### 5.2 Aprendizaje post-caso (OBLIGATORIO)

Ejecutar el **checklist de aprendizaje** definido en el steering `auto-mejora.md` (Nivel 1). Evaluar internamente cada pregunta:

1. ¿Consulté tablas no documentadas en la KB? → Documentar en página del módulo
2. ¿Descubrí relaciones entre tablas no documentadas? → Documentar en página del módulo
3. ¿Encontré un patrón de problema que podría repetirse? → Agregar a Patrones de Problemas (1688371201)
4. ¿Identifiqué un paquete/servicio clave no documentado? → Agregar a Arquitectura Servicios (1688338434)
5. ¿La consulta SQL que usé podría servir en casos futuros? → Agregar a Patrones de Problemas
6. ¿El caso reveló un flujo de negocio que no estaba claro? → Documentar en página del módulo
7. ¿Hubo un error o traba que podría evitarse? → Agregar a Lecciones Aprendidas

Seguir las reglas del steering `base-conocimiento.md` para las actualizaciones. Usar los formatos definidos en `auto-mejora.md`.

**Cada caso atendido enriquece la KB.** La meta es que con el tiempo, la mayoría de los diagnósticos se resuelvan solo con la KB, sin explorar Oracle. Esto reduce tokens y acelera la atención.

### 5.3 Feedback Loop de Eficiencia (Bloque D)

Al finalizar, evaluar internamente la eficiencia del diagnóstico:

| Métrica | Valor en esta sesión | Meta |
|---|---|---|
| Llamadas Oracle | <contar> | ≤ 4 |
| Llamadas Confluence | <contar> | ≤ 2 |
| Confianza final | <Alta/Media/Baja> | ≥ Media |
| Patrón reutilizado de KB/Engram | <Sí/No> | Sí en >60% |

**Si se excedieron 6 llamadas Oracle:**
- Identificar qué queries podrían consolidarse con JOINs
- Proponer un nuevo template SQL para `diagnostico-eficiente.md`

**Si la confianza fue Baja:**
- Identificar qué información faltaba
- Proponer agregarla a la KB para futuros casos

**Persistir en Engram** el diagnóstico completo para que futuros casos similares se resuelvan más rápido:

```
mem_save(
  title="Diagnóstico MDSB-XXXXX: <resumen corto>",
  type="bugfix",
  content="**What**: <causa raíz>\n**Why**: <por qué ocurrió>\n**Where**: <tablas/packages afectados>\n**Learned**: <qué se aprendió para futuros casos>"
)
```

---

## Resiliencia

- Si un paso falla, documentar el error en el reporte final y continuar con los demás pasos.
- Si `oracle-readonly` falla, intentar `oracle-stage`.
- Si la creación de la HU falla por campos obligatorios, revisar el troubleshooting del POWER.md y reintentar.
- Si Confluence falla, documentar los hallazgos en el reporte final y crear la página manualmente después.
