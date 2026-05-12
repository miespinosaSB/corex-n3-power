---
inclusion: manual
---

# Guía de uso del MCP Oracle

## Ambientes disponibles

| MCP Server | Ambiente | Host | Uso |
|---|---|---|---|
| oracle-readonly | Dev | 10.1.2.76 | Desarrollo y pruebas |
| oracle-stage | Stage | 10.7.2.14 | Validación pre-producción |
| oracle-prod | Prod | Configurar | Solo consulta con autorización |

## Cómo consultar la BD desde Kiro

Puedes pedirle a Kiro que consulte la base de datos directamente. Ejemplos:

- "Muéstrame la estructura de la tabla SIM_POLIZA"
- "¿Cuántos registros tiene la tabla ARL_TRABAJADOR en stage?"
- "Lista las tablas del esquema SIMAPI"
- "Busca las columnas que tengan 'FECHA' en la tabla X"

## Cuándo usar cada ambiente

- **Dev**: Para explorar datos de prueba, validar queries, entender estructura
- **Stage**: Para validar datos más cercanos a producción, comparar con dev
- **Prod**: Solo cuando necesites datos reales y tengas autorización. Viene deshabilitado por defecto.

## Tips

- Usa `list_tables` antes de hacer queries para conocer las tablas disponibles
- Usa `describe_table` para ver columnas y tipos antes de escribir un SELECT
- Los queries están limitados a 500 filas. Usa WHERE para filtrar
- Todo es read-only: no puedes modificar datos desde el MCP
