---
inclusion: fileMatch
fileMatchPattern: "**/*.{sql,pks,pkb,fnc,trg,vw,prc}"
---

# Convenciones Oracle - Equipo Tronador

## Estructura de la Base de Datos

- Motor: Oracle 19c
- Conexión por SID (no service name)
- Esquemas principales disponibles via MCP: dev (10.1.2.76), stage (10.7.2.14), prod (configurar por usuario)

## Encoding

- Archivos SQL/PL-SQL (`.sql`, `.pks`, `.pkb`, `.fnc`): **ISO-8859-1 (Latin1)** — la BD usa WE8ISO8859P1
- Archivos de documentación (`.md`, `.txt`, `.json`, `.yml`): **UTF-8**
- Si ves caracteres corruptos (Ã¡ en vez de á) en la BD, el archivo SQL se guardó en UTF-8 por error
- Si ves caracteres corruptos en documentación, se guardó en ISO-8859-1 por error
- Si ves caracteres corruptos (Ã¡ en vez de á), el archivo probablemente se guardó en UTF-8 por error

## Convenciones de Naming

- Tablas: UPPER_SNAKE_CASE (ej: `SIM_POLIZA`, `ARL_TRABAJADOR`, `A2000030`)
- Columnas: UPPER_SNAKE_CASE
- Packages: prefijo del módulo + `PCK_` (ej: `SIM_PCK_FACTURA_ELECTRONICA`)
- Funciones: nombre descriptivo en UPPER_CASE (ej: `BUSCA_PROGRAMA`, `DIAS_RECLAMO`)
- Índices: `{TABLA}_PK` para primary keys, `{TABLA}_{COLUMNA}_FK_I` para foreign keys
- Variables PL/SQL: prefijo `v_` para variables locales, `p_` para parámetros, `c_` para constantes

## Formato de Código

- Keywords SQL en UPPERCASE: `SELECT`, `FROM`, `WHERE`, `JOIN`, `ORDER BY`, `BEGIN`, `END`, `EXCEPTION`
- Identación de 2 espacios (NO tabs) dentro de bloques PL/SQL
- Cada columna en su propia línea en SELECTs con más de 3 columnas
- Alias de tablas significativos (no `a`, `b`, `c` — usar `pol`, `trab`, `cob`)
- Terminar bloques PL/SQL con `/` en línea separada
- Líneas de máximo 120 caracteres

## Buenas Prácticas SQL

- Siempre usar bind variables (`:param`) en lugar de concatenar valores — evita SQL injection y mejora performance por reutilización de cursores
- Limitar resultados con `WHERE ROWNUM <= N` o `FETCH FIRST N ROWS ONLY`
- Usar `NVL()` o `COALESCE()` para manejar NULLs explícitamente
- Preferir `EXISTS` sobre `IN` para subqueries
- No usar `SELECT *` en código de producción, listar columnas explícitamente
- Evitar funciones PL/SQL en el SELECT (context switch) — preferir JOINs
- No usar `ORDER BY` con números de posición, usar nombres de columna
- Comentar bloques PL/SQL complejos con `--` o `/* */`

## Buenas Prácticas PL/SQL

- Siempre incluir bloque `EXCEPTION` con `WHEN OTHERS THEN ROLLBACK`
- Usar `DBMS_OUTPUT.PUT_LINE` para trazabilidad
- Validar con `SQL%ROWCOUNT` después de DML para controlar registros afectados
- No usar procedimientos almacenados para cambios de datos — usar DML directo (política de la empresa)
- Control de transacciones obligatorio: `BEGIN` / `COMMIT` / `ROLLBACK`

## Encabezado Obligatorio en Scripts DML

Todo script de cambio de datos DEBE incluir:

```sql
-- Jira: MDSB-XXXXXX
-- Objetivo: [Descripción del cambio]
-- Solicitante: [Nombre]
-- Fecha: DD/MM/YYYY
```

## Nomenclatura de Archivos DML

### Scripts principales
- `INSERT_[NombreTabla].sql`
- `UPDATE_[NombreTabla].sql`
- `DELETE_[NombreTabla].sql`

### Scripts de rollback (OBLIGATORIO)
- `INSERT_[NombreTabla]_ROLLBACK.sql`
- `UPDATE_[NombreTabla]_ROLLBACK.sql`
- `DELETE_[NombreTabla]_ROLLBACK.sql`

### Múltiples scripts (orden secuencial)
- `UPDATE_A2000030_01.sql` / `UPDATE_A2000030_01_ROLLBACK.sql`
- `UPDATE_A2000030_02.sql` / `UPDATE_A2000030_02_ROLLBACK.sql`

## Estructura de Archivos del Repositorio

- `Base Datos/Funciones/*.fnc` - Funciones standalone
- `Base Datos/Packages/*.pks` / `*.pkb` - Packages (spec + body)
- `Base Datos/Indices/*.sql` - Definiciones de índices
- `Base Datos/Jobs/*.sql` - Jobs programados
- `Base Datos/Grants/*.sql` - Permisos

## Packages (.pks / .pkb)

- `.pks` = especificación (header), `.pkb` = body (implementación)
- Siempre incluir `CREATE OR REPLACE` al inicio
- Terminar con `/` en línea separada para ejecución en SQL*Plus
- Documentar parámetros de procedimientos y funciones públicas

## Prohibiciones

- ❌ NO usar DDL en scripts de cambio de datos (CREATE, ALTER, DROP, TRUNCATE, RENAME, GRANT, REVOKE)
- ❌ NO usar procedimientos almacenados para cambios de datos
- ❌ NO enviar scripts sin rollback
- ❌ NO usar SELECT * en código de producción
- ❌ NO concatenar valores en queries (usar bind variables)
- ❌ NO guardar archivos en encoding diferente a ISO-8859-1 (Latin1)
