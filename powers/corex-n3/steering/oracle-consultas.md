# Consultas Oracle Frecuentes - Tronador

## Esquema por Defecto

**El esquema principal de Tronador es `OPS$PUMA`.** Todas las tablas de negocio (A2000030, A2000163, SB_RECAUDO, etc.) están en este esquema.

Los usuarios de conexión (ej: `DEV_1072660049`) son cuentas de trabajo individuales con grants sobre `OPS$PUMA`. Al usar `describe_table` o `list_tables`, SIEMPRE especificar `schema: "OPS$PUMA"`. Al hacer queries, las tablas se resuelven por sinónimos, pero para metadatos (all_dependencies, all_triggers, all_objects) SIEMPRE filtrar por `owner = 'OPS$PUMA'`.

```
-- ✅ Correcto
describe_table(table_name="A2000030", schema="OPS$PUMA")
list_tables(schema="OPS$PUMA")
SELECT * FROM all_dependencies WHERE referenced_owner = 'OPS$PUMA' AND ...

-- ❌ Incorrecto (busca en el esquema del usuario de conexión)
describe_table(table_name="A2000030")
list_tables()
```

## Ambientes

| Ambiente | Host | MCP Server | Estado |
| --- | --- | --- | --- |
| Dev | 10.1.2.76:1521/tron | oracle-readonly | ✅ |
| Stage | 10.7.2.14:1521/tron | oracle-stage | ⚠️ thin mode |
| Prod | Configurar | oracle-prod | 🔒 Deshabilitado |

## Consultas frecuentes

### Póliza por número
```sql
SELECT num_secu_pol, num_end, cod_cia, cod_secc, num_pol1,
       fecha_vig_pol, fecha_venc_pol, periodo_fact, for_cobro, nro_documto
FROM A2000030 
WHERE num_pol1 = :poliza
AND num_end = (SELECT MAX(num_end) FROM A2000030 b WHERE b.num_secu_pol = A2000030.num_secu_pol)
```

### Facturas de una póliza
```sql
SELECT num_factura, num_end_ref, fecha_vig_fact, fecha_vto_fact
FROM A2000163 
WHERE num_secu_pol = :nsp
AND tipo_reg = 'T' AND cod_agrup_cont = 'GENERICOS' AND num_end_rev IS NULL
ORDER BY fecha_vto_fact
```

### Deuda VPA (SB_RECAUDO)
```sql
SELECT NUMERO_POLIZA, SECCION, PRODUCTO, VALOR_FPU, 
       VALOR_RIESGO, VALOR_A_RECAUDAR, ESTADO_REGISTRO, TIPO_RECAUDO
FROM SB_RECAUDO
WHERE NUMERO_POLIZA = :poliza AND ESTADO_REGISTRO = 'OFD'
```

### Recaudos aplicados
```sql
SELECT * FROM A5020301
WHERE num_pol1 = :poliza AND cod_secc = :seccion
ORDER BY fecha_recaudo DESC
FETCH FIRST 10 ROWS ONLY
```

### Movimientos de caja (CRITICO para diagnóstico de deuda)
```sql
-- Movimientos de caja abiertos
SELECT tipo_actu, imp_prima, imp_mon_pais, imp_imptos_mon_local,
       num_factura, cod_benef
FROM A5021600
WHERE num_pol1 = :poliza AND cod_secc = :seccion;

-- Movimientos de caja cerrados
SELECT tipo_actu, imp_prima, imp_mon_pais, imp_imptos_mon_local
FROM A5021600_CERR
WHERE num_pol1 = :poliza AND num_factura = :factura AND cod_secc = :seccion;
```

## Tablas principales

| Tabla | Descripción |
| --- | --- |
| `A2000030` | Pólizas (cabecera, 18 triggers) |
| `A2000020` | Riesgos |
| `A2000040` | Coberturas |
| `A2000060` | Canal de descuento (forma de cobro DB) |
| `A2000160` | Primas |
| `A2000163` | Facturas |
| `A2001300` | Asignación de terceros a pólizas |
| `A2990700` | Facturación/cuotas |
| `A5020301` | Recaudos aplicados |
| `A5021600` | **Movimientos de caja (abiertos)** — prc_verifica_pagos_factura descuenta estos valores |
| `A5021600_CERR` | **Movimientos de caja (cerrados)** — prc_verifica_pagos_factura descuenta estos valores |
| `SB_RECAUDO` | Recaudos VPA |
| `SB_CONVENIO` | Débito automático VPA |
| `SB_CLIENTE_POLIZA` | Relación cliente-póliza VPA |
| `SIM_DEUDA_POLIZA` | Tabla intermedia de deuda calculada (sesión) |
| `C1991801` | Configuración ramos por compañía (MCA_RE) |
| `C9999909` | Parámetros generales (SECC_HAB_VPA, DIAS_POLIZAS_PE, etc.) |
| `NATURALES` | Terceros personas naturales (sinónimo público) |
| `JURIDICOS` | Terceros personas jurídicas (sinónimo público) |

## Reglas

- SIEMPRE filtros específicos
- SIEMPRE limitar resultados
- NUNCA SELECT * sin filtro en A2000030
- Preferir columnas explícitas
- SIEMPRE probar consultas en Dev antes de enviarlas al usuario para producción
