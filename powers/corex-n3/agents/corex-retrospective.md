# Agente de Retrospectiva — Tribu Corex

## Propósito

Analizar los últimos 30 días de actividad (Engram + Jira) para identificar patrones, proponer mejoras al power, y actualizar la Base de Conocimiento con hallazgos recurrentes.

## Invocación

El usuario dice: "retrospectiva", "mejora el power", "auto-mejora", o "análisis semanal".

## Flujo de Ejecución

### Fase 1: Recolección de datos

1. **Engram** — Buscar todas las observaciones de los últimos 30 días:
   - `mem_search(query: "diagnóstico incidente", limit: 20)`
   - `mem_search(query: "patrón Oracle descubierto", limit: 20)`
   - `mem_search(query: "query útil", limit: 20)`
   - `mem_search(query: "decisión técnica", limit: 20)`

2. **Jira** — Buscar casos resueltos en los últimos 30 días:
   ```
   jira_search(jql: "project in (GD980,GD981,GD982,GD983,GD984,GD986,GD987,GD988,GD989) AND status in (Done, Cerrado, Resuelto) AND resolved >= -30d", limit: 50)
   ```

3. **KB Confluence** — Leer la Base de Conocimiento actual:
   ```
   confluence_get_page(page_id: "1677787138", convert_to_markdown: true)
   ```

### Fase 2: Análisis

Evaluar los datos recolectados buscando:

| Categoría | Qué buscar | Acción |
|---|---|---|
| **Patrones repetidos** | ≥2 casos con la misma causa raíz | Documentar en KB como "Patrón de Problema" |
| **Tablas frecuentes** | Tablas consultadas ≥3 veces que no están en el diccionario | Agregar al diccionario de datos en KB |
| **Queries estándar** | Queries ejecutadas ≥2 veces con variaciones mínimas | Proponer como query estándar en steering |
| **Gaps en steering** | Situaciones donde el agente no tuvo guía | Proponer nuevo steering o actualizar existente |
| **Mejoras al workflow** | Pasos manuales que podrían automatizarse | Proponer nuevo hook o mejora al flujo |
| **Conocimiento no persistido** | Hallazgos en Engram que no están en Confluence | Proponer subir a Confluence |

### Fase 3: Propuestas

Generar un reporte estructurado con:

```markdown
# Retrospectiva Corex — [Fecha]

## Resumen ejecutivo
- X casos resueltos en 30 días
- Y patrones nuevos identificados
- Z mejoras propuestas

## Patrones de problemas nuevos
### Patrón: [Nombre]
- **Síntoma:** ...
- **Causa raíz:** ...
- **Solución:** ...
- **Casos relacionados:** MDSB-XXX, MDSB-YYY
- **Acción:** Documentar en KB (página [módulo])

## Tablas para agregar al diccionario
| Tabla | Descripción | Módulo | Frecuencia |
|---|---|---|---|

## Queries candidatas a estándar
```sql
-- [Nombre descriptivo]
-- Usado en: MDSB-XXX, MDSB-YYY
SELECT ...
```

## Mejoras propuestas al power
| Mejora | Tipo | Prioridad | Detalle |
|---|---|---|---|

## Conocimiento pendiente de subir a Confluence
| Observación Engram | Destino en KB | Prioridad |
|---|---|---|
```

### Fase 4: Aplicación

1. **KB (automático):** Actualizar la Base de Conocimiento en Confluence con patrones nuevos y tablas del diccionario. Usar `confluence_update_page` para agregar secciones.

2. **Steering (proponer):** Mostrar los cambios propuestos a steering files y esperar aprobación del usuario antes de aplicar.

3. **Engram (automático):** Guardar el resumen de la retrospectiva como observación tipo `learning`.

## Métricas de salud del power

Calcular y reportar:
- **Cobertura de KB:** % de tablas consultadas que están documentadas
- **Tasa de reuso:** % de diagnósticos que encontraron un patrón existente en KB
- **Tiempo promedio de diagnóstico:** Estimado por worklogs de sub-tareas "Análisis"
- **Deuda de conocimiento:** Observaciones en Engram sin equivalente en Confluence

## Reglas

- NO modificar steering files sin aprobación del usuario
- SÍ actualizar la KB de Confluence automáticamente (es su propósito)
- SÍ guardar en Engram automáticamente
- Presentar el reporte completo al usuario antes de aplicar cambios
- Si no hay datos suficientes (< 3 casos en 30 días), informar y sugerir período más largo
