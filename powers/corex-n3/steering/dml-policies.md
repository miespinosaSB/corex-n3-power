# Políticas de Cambios de Datos (DML)

## Reglas Fundamentales

1. **Solo DML permitido**: INSERT, UPDATE, DELETE, MERGE, SELECT INTO
2. **DDL prohibido**: CREATE, ALTER, DROP, TRUNCATE, RENAME, GRANT, REVOKE
3. **Rollback obligatorio**: Todo script debe tener su archivo _ROLLBACK.sql
4. **No usar procedimientos almacenados** para cambios de datos — DML directo

## Nomenclatura de Archivos

| Script principal | Rollback |
| --- | --- |
| `INSERT_[Tabla].sql` | `INSERT_[Tabla]_ROLLBACK.sql` |
| `UPDATE_[Tabla].sql` | `UPDATE_[Tabla]_ROLLBACK.sql` |
| `DELETE_[Tabla].sql` | `DELETE_[Tabla]_ROLLBACK.sql` |

Múltiples: `UPDATE_A2000030_01.sql` / `UPDATE_A2000030_01_ROLLBACK.sql`

## Encabezado Obligatorio

```sql
-- Jira: MDSB-XXXXXX
-- Objetivo: [Descripción del cambio]
-- Solicitante: [Nombre]
-- Fecha: DD/MM/YYYY
```

## Estructura Estándar

```sql
SET SERVEROUTPUT ON;
BEGIN
  UPDATE tabla
  SET columna = valor
  WHERE filtro = condicion;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('OK. Filas: ' || SQL%ROWCOUNT);
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/
```

## Checklist

- [ ] Encabezado con Jira, Objetivo, Solicitante, Fecha
- [ ] Solo DML (no DDL)
- [ ] BEGIN/COMMIT/ROLLBACK con EXCEPTION
- [ ] DBMS_OUTPUT para trazabilidad
- [ ] WHERE (no masivos sin filtro)
- [ ] SQL%ROWCOUNT
- [ ] Archivo rollback
- [ ] Nomenclatura correcta
- [ ] Encoding ISO-8859-1
