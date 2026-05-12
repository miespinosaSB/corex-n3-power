---
inclusion: auto
---

# Auto-Mejora Continua del Power

Este steering define los mecanismos por los cuales el power se vuelve más inteligente con cada caso atendido. Hay dos niveles: aprendizaje post-caso (automático) y retrospectiva (bajo demanda).

---

## Nivel 1 — Aprendizaje Post-Caso (automático, cada atención)

Al finalizar cada atención de incidente (Fase 5 del steering `atencion-incidente-autonomo.md`), el agente DEBE ejecutar un **checklist de aprendizaje** antes de presentar el reporte final.

### Checklist de Aprendizaje

Evaluar internamente cada pregunta. Si la respuesta es SÍ, actualizar la página correspondiente de la KB.

| # | Pregunta | Si SÍ → actualizar en... |
|---|---|---|
| 1 | ¿Consulté tablas que NO estaban documentadas en la KB? | Página del módulo correspondiente (A1xxx, A2xxx, etc.) |
| 2 | ¿Descubrí relaciones entre tablas que no estaban documentadas? | Página del módulo + página principal si es cross-módulo |
| 3 | ¿Encontré un patrón de problema que podría repetirse? | **Patrones de Problemas** (1688371201) |
| 4 | ¿Identifiqué un paquete/procedimiento/servicio clave no documentado? | **Arquitectura Servicios** (1688338434) |
| 5 | ¿La consulta SQL que usé para diagnosticar podría servir en casos futuros? | **Patrones de Problemas** (1688371201) — sección "Consultas de Diagnóstico" |
| 6 | ¿El caso reveló un flujo de negocio que no estaba claro? | Página del módulo correspondiente |
| 7 | ¿Hubo un error o traba durante la atención que podría evitarse? | **Patrones de Problemas** (1688371201) — sección "Lecciones Aprendidas" |

### Formato para agregar a Patrones de Problemas

Cuando se identifica un patrón nuevo, agregarlo con esta estructura:

```markdown
### [Nombre descriptivo del patrón]

**Síntomas:** <Cómo se manifiesta el problema — qué dice el caso MDSB>
**Módulo:** <Emisión / Recaudo / Siniestros / etc.>
**Tablas involucradas:** <Lista de tablas>
**Causa raíz:** <Qué lo provoca>
**Consulta de diagnóstico:**
\`\`\`sql
<Query que permite verificar si el problema existe para un caso dado>
\`\`\`
**Solución:** <Qué se hizo o qué se debe hacer>
**Casos de referencia:** <MDSB-XXXXX, GD986-XXXX>
**Fecha:** <DD/MM/YYYY>
```

### Formato para agregar a Arquitectura Servicios

Cuando se identifica un servicio o paquete clave:

```markdown
### [Nombre del paquete/servicio]

**Tipo:** <Package Oracle / Microservicio / Función / Trigger>
**Esquema:** OPS$PUMA
**Propósito:** <Qué hace en una línea>
**Tablas que usa:** <Lista>
**Consumidores:** <Quién lo llama — otros packages, servicios, jobs>
**Parámetros clave:** <IN/OUT principales>
**Notas:** <Gotchas, particularidades, cuidados>
**Documentado desde caso:** <MDSB-XXXXX>
```

---

## Nivel 2 — Retrospectiva (bajo demanda)

### Trigger

Cuando el usuario diga **"retrospectiva"**, **"mejora el power"**, **"auto-mejora"**, **"qué podemos mejorar"**, o variantes similares.

### Proceso

#### Paso 1 — Recopilar casos recientes

Buscar las Historias creadas recientemente en los proyectos de la tribu:

```
jira_search(
  jql='project in (GD980, GD981, GD982, GD983, GD984, GD986, GD987, GD988, GD989) AND issuetype = Historia AND created >= -30d ORDER BY created DESC',
  fields='summary,status,labels,created',
  limit=30
)
```

#### Paso 2 — Leer la KB actual

```
confluence_get_page(page_id="1677787138", convert_to_markdown=true)
confluence_get_page(page_id="1688371201", convert_to_markdown=true)
confluence_get_page(page_id="1688338434", convert_to_markdown=true)
```

#### Paso 3 — Analizar y proponer mejoras

Evaluar:

**A. Patrones repetidos no documentados**
- ¿Hay casos con síntomas similares que no tienen un patrón en la KB?
- → Proponer agregar el patrón

**B. Tablas frecuentes no documentadas**
- ¿Se consultaron tablas que aparecen en múltiples casos pero no están en la KB?
- → Proponer documentar esas tablas con sus columnas clave

**C. Consultas SQL reutilizables**
- ¿Hay queries que se usaron en varios diagnósticos y podrían ser estándar?
- → Proponer agregarlas al steering `oracle-consultas.md` o a Patrones de Problemas

**D. Flujos de negocio descubiertos**
- ¿Se descubrieron flujos (ej: "cuando se anula una póliza, el trigger X actualiza Y") que no están documentados?
- → Proponer documentar en la página del módulo correspondiente

**E. Mejoras al propio power**
- ¿Hubo fricciones recurrentes? (ej: campos que siempre fallan, queries que siempre hay que ajustar)
- → Proponer cambios a los steering files del power

#### Paso 4 — Presentar propuestas

Presentar al usuario un reporte estructurado:

```markdown
# 🔄 Retrospectiva — Auto-Mejora del Power

## Período analizado
<Últimos 30 días — X casos revisados>

## Patrones nuevos detectados
| Patrón | Casos relacionados | ¿Documentado en KB? |
|---|---|---|
| <descripción> | MDSB-XXX, MDSB-YYY | ❌ No |

## Tablas frecuentes no documentadas
| Tabla | Veces referenciada | Módulo |
|---|---|---|
| <tabla> | X | <módulo> |

## Consultas SQL candidatas a estándar
- <descripción de la query y para qué sirve>

## Mejoras propuestas al power
| Mejora | Archivo afectado | Impacto |
|---|---|---|
| <descripción> | <steering file> | Alto/Medio/Bajo |

## ¿Procedo con las actualizaciones?
Indicame cuáles apruebas y las aplico.
```

#### Paso 5 — Aplicar mejoras aprobadas

Con la aprobación del usuario:
- Actualizar las páginas de la KB en Confluence
- Si se aprobaron cambios a steering files → modificar los archivos en `powers/corex-n3/steering/`
- Documentar los cambios realizados

---

## Principios de Auto-Mejora

1. **Solo información verificada.** No agregar suposiciones ni datos de un solo caso sin confirmar.
2. **No datos personales.** Nunca agregar números de póliza, cédulas, NITs, ni datos de clientes a la KB.
3. **Acumular, no reemplazar.** La KB crece, no se reescribe. Solo corregir si algo está mal.
4. **La meta es reducir tokens.** Cada pieza de conocimiento en la KB es una consulta Oracle que no se necesita hacer en el futuro.
5. **El usuario decide.** Las mejoras a steering files siempre se proponen, nunca se aplican sin aprobación.
6. **La KB es del equipo.** Lo que se documenta beneficia a todos los miembros de la tribu, no solo al que atendió el caso.
