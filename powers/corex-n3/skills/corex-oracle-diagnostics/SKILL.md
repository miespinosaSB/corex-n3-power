---
name: corex-oracle-diagnostics
description: Diagnóstico de incidentes en Oracle Tronador (esquema OPS$PUMA). Usar cuando el usuario menciona casos MDSB, errores en pólizas, facturas, recaudos, emisión, siniestros, o necesita consultar tablas/packages de Tronador.
---

# Oracle Diagnostics — Tribu Corex

## Flujo de diagnóstico

1. **Buscar en Engram** diagnósticos previos similares (`mem_search`)
2. **Cargar KB** de Confluence (page_id: 1677787138)
3. **Obtener caso Jira** completo con comentarios
4. **Consultar Oracle** — datos en tablas principales
5. **Leer código fuente** PL/SQL con `get_source`
6. **Verificar dependencias** con `get_dependencies`
7. **Buscar casos relacionados** en Jira
8. **Persistir diagnóstico** en Engram

## Tablas principales (OPS$PUMA)

| Tabla | Descripción |
|---|---|
| A2000030 | Pólizas (cabecera) |
| A2000020 | Riesgos |
| A2000040 | Coberturas |
| A2000160 | Primas |
| A2000163 | Facturas |
| A2990700 | Facturación/cuotas |
| SB_RECAUDO | Recaudos VPA |
| SB_CONVENIO | Débito automático |
| A1000000 | Terceros |
| A4000010 | Siniestros (cabecera) |

## Reglas

- **Solo lectura**: NUNCA INSERT, UPDATE, DELETE, DDL
- **Esquema**: Siempre `OPS$PUMA`
- **Límite**: `ROWNUM <= 50` en todas las queries
- **Leer antes de afirmar**: Si dices "el SP hace X", debes haber leído el código
- **Resiliencia**: Si oracle-readonly falla, intentar oracle-stage

## Packages frecuentes

| Package | Módulo |
|---|---|
| SIM_PCK_DEUDA | Facturación/deuda |
| SIM_PCK_RECAUDO | Recaudo |
| SIM_PCK_EMISION | Emisión |
| SIM_PCK_POLIZA | Pólizas |
| COR_PCK_FACTURACION | Facturación Corex |
| SIM_PCK_SINIESTRO | Siniestros |

## Formato del reporte

```markdown
# 🔍 Diagnóstico: MDSB-XXXXX

## Resumen
- **Problema:** <1-2 líneas>
- **Causa raíz:** <identificada / probable / requiere investigación>
- **Confianza:** Alta / Media / Baja

## Hallazgos en Oracle
<Resumen por tabla consultada>

## Análisis de código fuente
<Si se leyó PL/SQL>

## Flujo del problema
[Entrada] → [Paso 1] → ... → [Donde falla]

## Pasos sugeridos
1. <Acción concreta>
```
