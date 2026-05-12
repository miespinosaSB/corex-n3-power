# Convenciones Oracle - Equipo Tronador

## Encoding
- Archivos SQL/PL-SQL (`.sql`, `.pks`, `.pkb`, `.fnc`): **ISO-8859-1 (Latin1)** — la BD usa WE8ISO8859P1
- Archivos de documentación (`.md`, `.txt`, `.json`, `.yml`): **UTF-8**
- Si ves caracteres corruptos (Ã¡ en vez de á) en la BD, el archivo SQL se guardó en UTF-8 por error
- Si ves caracteres corruptos en documentación, se guardó en ISO-8859-1 por error

## Naming
- Tablas/Columnas: UPPER_SNAKE_CASE (`SIM_POLIZA`, `ARL_TRABAJADOR`)
- Packages: prefijo módulo + `PCK_` (`SIM_PCK_FACTURA_ELECTRONICA`)
- Funciones: UPPER_CASE descriptivo (`BUSCA_PROGRAMA`, `DIAS_RECLAMO`)
- Índices: `{TABLA}_PK`, `{TABLA}_{COL}_FK_I`
- Variables PL/SQL: `v_` locales, `p_` parámetros, `c_` constantes

## Formato
- Keywords SQL en UPPERCASE
- Identación 2 espacios (NO tabs)
- Cada columna en línea propia si >3 columnas
- Alias significativos (no `a`, `b` — usar `pol`, `trab`)
- Terminar PL/SQL con `/` en línea separada
- Máximo 120 caracteres por línea

## Buenas Prácticas SQL
- Bind variables (`:param`) siempre — nunca concatenar valores
- `WHERE ROWNUM <= N` o `FETCH FIRST N ROWS ONLY` para limitar
- `NVL()` o `COALESCE()` para NULLs
- `EXISTS` sobre `IN` para subqueries
- No `SELECT *` en producción
- Evitar funciones PL/SQL en SELECT (context switch)
- `ORDER BY` con nombres de columna, no posiciones

## Buenas Prácticas PL/SQL
- Bloque `EXCEPTION` con `WHEN OTHERS THEN ROLLBACK` obligatorio
- `DBMS_OUTPUT.PUT_LINE` para trazabilidad
- `SQL%ROWCOUNT` después de DML
- Control de transacciones: `BEGIN` / `COMMIT` / `ROLLBACK`

## Prohibiciones
- ❌ DDL en scripts de datos
- ❌ Procedimientos almacenados para cambios de datos
- ❌ Scripts sin rollback
- ❌ SELECT * en producción
- ❌ Concatenar valores en queries
- ❌ Encoding diferente a ISO-8859-1 en archivos SQL
