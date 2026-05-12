---
inclusion: auto
---

# Diagnóstico Eficiente — Menos Créditos, Mejor Efectividad

## ⚠️ REGLA FUNDAMENTAL: Leer Código, NO Simular

**NUNCA simular un proceso. SIEMPRE leer el código PL/SQL que lo ejecuta.**

La verdad del proceso está en los packages Oracle, no en suposiciones del agente. El diagnóstico correcto sigue este flujo:

```
1. IDENTIFICAR → ¿Qué SP/package ejecuta el proceso del caso?
2. LEER        → get_source(object_name, "PACKAGE BODY") — leer el código completo
3. SEGUIR      → Trazar el flujo del SP línea por línea (ENTRADA → TRANSFORMACIÓN → SALIDA)
4. REPLICAR    → Ejecutar las MISMAS queries que hace el SP, con los datos del caso
5. DIVERGENCIA → Encontrar el punto exacto donde resultado esperado ≠ resultado real
```

### Lo que NUNCA debes hacer:
- ❌ Calcular manualmente lo que un SP ya calcula
- ❌ Suponer cómo funciona un proceso sin leer el código
- ❌ Hacer queries exploratorias a tablas random esperando encontrar algo
- ❌ Inventar lógica de negocio que no está en el código

### Lo que SIEMPRE debes hacer:
- ✅ Leer el package body COMPLETO antes de hacer queries de datos
- ✅ Identificar las tablas que el SP consulta/modifica (están en el código)
- ✅ Ejecutar las mismas condiciones WHERE que usa el SP
- ✅ Si el SP llama a otro SP → leer ese también (get_dependencies + get_source)
- ✅ Reportar la línea exacta del código donde ocurre el problema

### Ejemplo correcto:
```
Caso: "La deuda no se calcula correctamente para la póliza 123456"

1. IDENTIFICAR: El cálculo de deuda lo hace SIM_PCK_DEUDA.CALCULA_DEUDA
2. LEER: get_source("SIM_PCK_DEUDA", "PACKAGE BODY")
3. SEGUIR: El SP hace:
   - Busca facturas en A2000163 WHERE num_secu_pol = X AND tipo_reg = 'T'
   - Busca cuotas en A2990700 WHERE num_factura = Y AND mca_cobrada = 'N'
   - Suma imp_prima + imp_imptos de cuotas no cobradas
4. REPLICAR: Ejecuto las MISMAS queries con num_pol1 = '123456'
5. DIVERGENCIA: El SP filtra por mca_cobrada = 'N' pero la cuota 3 tiene
   mca_cobrada = 'S' con fecha posterior al vencimiento → el pago se aplicó
   tarde y el servicio no lo detecta porque cachea el resultado
```

---

## Principio

Cada llamada MCP consume créditos. El diagnóstico más eficiente es el que resuelve con la menor cantidad de llamadas posibles, sin sacrificar precisión. Este steering define las estrategias para lograrlo.

---

## Estrategia 1: Engram-First

**Antes de cualquier llamada a Oracle o Confluence**, buscar en Engram si ya existe un diagnóstico previo del mismo patrón.

```
mem_search(query="<síntomas del caso>", project="tronador-oracle-db", type="bugfix")
mem_search(query="<tabla o package mencionado>", project="tronador-oracle-db", type="pattern")
```

**Regla:** Si Engram devuelve un resultado con confianza alta (match directo en título o contenido), usar ese conocimiento como punto de partida. Solo ir a Oracle para verificar datos específicos del caso actual.

**Ahorro estimado:** 2-5 llamadas MCP por caso cuando el patrón ya fue diagnosticado antes.

---

## Estrategia 2: Cache de KB en Engram

La KB de Confluence no cambia cada hora. No recargarla en cada sesión si ya se leyó recientemente.

**Regla de frescura:**
- Si la sesión anterior fue hace < 24h y leyó la KB → usar el contexto de Engram
- Si la sesión anterior fue hace > 24h → recargar KB desde Confluence
- Si el caso menciona un módulo que NO se consultó recientemente → cargar solo esa página hija

**Implementación:** Al inicio de sesión, verificar en `mem_context` si hay un session_summary reciente que incluya "KB cargada". Si existe y es < 24h, omitir la carga de Confluence.

---

## Estrategia 3: Queries Precisas con JOINs

**Nunca hacer múltiples queries simples cuando un JOIN resuelve todo en una sola llamada.**

### Anti-patrón (4 llamadas):
```sql
-- Llamada 1
SELECT num_secu_pol FROM A2000030 WHERE num_pol1 = '123456'
-- Llamada 2
SELECT * FROM A2000163 WHERE num_secu_pol = 99999
-- Llamada 3
SELECT * FROM A2990700 WHERE num_secu_pol = 99999
-- Llamada 4
SELECT * FROM A5021600 WHERE num_pol1 = '123456'
```

### Patrón correcto (1-2 llamadas):
```sql
-- Llamada 1: Póliza + Facturas + Cuotas en un solo query
SELECT p.num_secu_pol, p.num_pol1, p.fecha_vig_pol, p.fecha_venc_pol,
       p.periodo_fact, p.for_cobro, p.mca_vigente,
       f.num_factura, f.fecha_vig_fact, f.fecha_vto_fact, f.num_end_ref,
       c.num_cuota, c.imp_prima, c.imp_imptos, c.fec_vto_cuota
FROM A2000030 p
LEFT JOIN A2000163 f ON f.num_secu_pol = p.num_secu_pol 
  AND f.tipo_reg = 'T' AND f.cod_agrup_cont = 'GENERICOS' AND f.num_end_rev IS NULL
LEFT JOIN A2990700 c ON c.num_secu_pol = p.num_secu_pol AND c.num_factura = f.num_factura
WHERE p.num_pol1 = :poliza
AND p.num_end = (SELECT MAX(num_end) FROM A2000030 b WHERE b.num_secu_pol = p.num_secu_pol)
ORDER BY f.fecha_vto_fact, c.num_cuota
```

```sql
-- Llamada 2: Movimientos de caja (si el caso lo requiere)
SELECT tipo_actu, imp_prima, imp_mon_pais, imp_imptos_mon_local, num_factura, cod_benef
FROM A5021600
WHERE num_pol1 = :poliza AND cod_secc = :seccion
```

---

## Estrategia 4: Árboles de Decisión por Módulo

Antes de consultar Oracle, clasificar el caso en un módulo y seguir el árbol de decisión correspondiente. Esto evita consultas exploratorias.

### Árbol: Emisión / Pólizas

```
¿El caso menciona póliza?
├── SÍ → ¿Tiene número de póliza?
│   ├── SÍ → Query consolidado póliza+facturas+cuotas (1 llamada)
│   │   └── ¿El problema es de vigencia/estado?
│   │       ├── SÍ → Verificar mca_vigente, fecha_venc_pol, num_end
│   │       └── NO → ¿Es de facturación?
│   │           ├── SÍ → Ir a Árbol Facturación
│   │           └── NO → ¿Es de coberturas?
│   │               └── SÍ → Query A2000040 filtrado
│   └── NO → Buscar por documento del tomador
│       └── Query A2001300 + A2000030 con JOIN
└── NO → Clasificar en otro módulo
```

### Árbol: Facturación / Deuda

```
¿El caso menciona deuda, factura, o cuota?
├── SÍ → ¿Tiene número de póliza?
│   ├── SÍ → Query consolidado (Estrategia 3)
│   │   └── ¿Hay facturas sin pago?
│   │       ├── SÍ → Verificar A5021600 (movimientos caja)
│   │       │   └── ¿Hay movimientos que anulan la deuda?
│   │       │       ├── SÍ → Causa: pago aplicado pero no reflejado en servicio
│   │       │       └── NO → Verificar SIM_PCK_DEUDA (get_source)
│   │       └── NO → ¿El servicio reporta deuda pero no hay facturas pendientes?
│   │           └── SÍ → Verificar SIM_DEUDA_POLIZA + lógica del SP
│   └── NO → Buscar por documento
└── NO → Clasificar en otro módulo
```

### Árbol: Recaudo / VPA

```
¿El caso menciona recaudo, débito automático, o VPA?
├── SÍ → ¿Tiene número de póliza?
│   ├── SÍ → Query SB_RECAUDO + SB_CONVENIO (1 llamada con JOIN)
│   │   └── ¿Estado del recaudo?
│   │       ├── OFD (ofertado) → Verificar si hay convenio activo
│   │       ├── REC (recaudado) → Verificar A5020301 (aplicación)
│   │       └── ANU (anulado) → Verificar motivo en SB_RECAUDO.OBSERVACION
│   └── NO → Buscar por documento en SB_CLIENTE_POLIZA
└── NO → Clasificar en otro módulo
```

### Árbol: Siniestros / Indemnizaciones

```
¿El caso menciona siniestro, reclamo, o indemnización?
├── SÍ → ¿Tiene número de siniestro?
│   ├── SÍ → Query A4000030 (cabecera siniestro)
│   │   └── ¿Estado del siniestro?
│   │       ├── Abierto → Verificar reservas (A4000040)
│   │       ├── Cerrado → Verificar pagos (A4000050)
│   │       └── Reabierto → Verificar historial de estados
│   └── NO → Buscar por póliza en A4000030
└── NO → Clasificar en otro módulo
```

---

## Estrategia 5: Scoring de Confianza

Al finalizar el diagnóstico, asignar un nivel de confianza:

| Nivel | Criterio | Acción |
|---|---|---|
| **Alta** | Causa raíz identificada con evidencia en datos + código fuente | Reportar directamente |
| **Media** | Causa probable basada en patrón conocido, sin verificación completa | Reportar con nota "requiere verificación en prod" |
| **Baja** | Hipótesis sin evidencia suficiente | Profundizar automáticamente (ver abajo) |

### Profundización automática (confianza Baja)

Si el scoring es Bajo, ejecutar automáticamente:

1. **Leer código fuente** del package/procedure involucrado (`get_source`)
2. **Verificar dependencias** (`get_dependencies`) para encontrar otros objetos que participan
3. **Buscar en el repositorio local** archivos `.pkb`, `.prc`, `.fnc` relacionados
4. **Consultar Engram** por casos similares anteriores
5. **Re-evaluar** con la nueva información

Si después de profundizar sigue en Baja → reportar como "requiere investigación adicional" con las hipótesis ordenadas por probabilidad.

---

## Estrategia 6: Templates SQL por Patrón

Queries pre-armadas listas para usar. Solo reemplazar los parámetros.

### Template: Diagnóstico completo de póliza
```sql
-- INPUT: :poliza (num_pol1)
-- OUTPUT: Estado completo de la póliza con facturas y cuotas
SELECT p.num_secu_pol, p.num_pol1, p.cod_cia, p.cod_secc, p.cod_ramo,
       p.num_end, p.fecha_vig_pol, p.fecha_venc_pol, p.mca_vigente,
       p.periodo_fact, p.for_cobro, p.nro_documto,
       f.num_factura, f.fecha_vig_fact, f.fecha_vto_fact,
       c.num_cuota, c.imp_prima, c.imp_imptos, c.fec_vto_cuota, c.mca_cobrada
FROM A2000030 p
LEFT JOIN A2000163 f ON f.num_secu_pol = p.num_secu_pol 
  AND f.tipo_reg = 'T' AND f.cod_agrup_cont = 'GENERICOS' AND f.num_end_rev IS NULL
LEFT JOIN A2990700 c ON c.num_secu_pol = p.num_secu_pol AND c.num_factura = f.num_factura
WHERE p.num_pol1 = :poliza
AND p.num_end = (SELECT MAX(num_end) FROM A2000030 b WHERE b.num_secu_pol = p.num_secu_pol)
AND ROWNUM <= 50
ORDER BY f.fecha_vto_fact DESC, c.num_cuota
```

### Template: Deuda y movimientos de caja
```sql
-- INPUT: :poliza, :seccion
-- OUTPUT: Facturas pendientes vs movimientos de caja aplicados
SELECT f.num_factura, f.fecha_vto_fact,
       NVL(mc.total_pagado, 0) AS total_pagado,
       (SELECT SUM(imp_prima) FROM A2990700 q 
        WHERE q.num_secu_pol = f.num_secu_pol AND q.num_factura = f.num_factura) AS total_factura
FROM A2000163 f
LEFT JOIN (
  SELECT num_factura, SUM(imp_prima) AS total_pagado
  FROM A5021600
  WHERE num_pol1 = :poliza AND cod_secc = :seccion
  GROUP BY num_factura
) mc ON mc.num_factura = f.num_factura
WHERE f.num_secu_pol = (SELECT num_secu_pol FROM A2000030 WHERE num_pol1 = :poliza AND ROWNUM = 1)
AND f.tipo_reg = 'T' AND f.cod_agrup_cont = 'GENERICOS' AND f.num_end_rev IS NULL
AND ROWNUM <= 30
ORDER BY f.fecha_vto_fact DESC
```

### Template: Recaudo VPA completo
```sql
-- INPUT: :poliza
-- OUTPUT: Estado de recaudo VPA con convenio
SELECT r.NUMERO_POLIZA, r.SECCION, r.PRODUCTO, r.VALOR_FPU,
       r.VALOR_RIESGO, r.VALOR_A_RECAUDAR, r.ESTADO_REGISTRO, r.TIPO_RECAUDO,
       r.FECHA_CREACION, r.FECHA_MODIFICACION,
       c.TIPO_CONVENIO, c.ESTADO AS ESTADO_CONVENIO, c.ENTIDAD_FINANCIERA
FROM SB_RECAUDO r
LEFT JOIN SB_CONVENIO c ON c.NUMERO_POLIZA = r.NUMERO_POLIZA AND c.SECCION = r.SECCION
WHERE r.NUMERO_POLIZA = :poliza
AND ROWNUM <= 50
ORDER BY r.FECHA_CREACION DESC
```

### Template: Búsqueda por documento del tomador
```sql
-- INPUT: :documento (nro_documto del tercero)
-- OUTPUT: Pólizas asociadas al documento
SELECT p.num_pol1, p.cod_secc, p.cod_ramo, p.fecha_vig_pol, p.fecha_venc_pol,
       p.mca_vigente, p.for_cobro, t.num_poliza_grupo
FROM A2000030 p
JOIN A2001300 t ON t.num_secu_pol = p.num_secu_pol AND t.cod_campo3 = 1
WHERE t.nro_documto = :documento
AND p.num_end = (SELECT MAX(num_end) FROM A2000030 b WHERE b.num_secu_pol = p.num_secu_pol)
AND ROWNUM <= 20
ORDER BY p.fecha_venc_pol DESC
```

---

## Estrategia 7: Feedback Loop Post-Diagnóstico

Al finalizar cada diagnóstico, evaluar la eficiencia:

| Métrica | Cómo medir | Meta |
|---|---|---|
| Llamadas Oracle | Contar queries ejecutados | ≤ 4 por caso |
| Llamadas Confluence | Contar lecturas de página | ≤ 2 por caso |
| Confianza final | Scoring del diagnóstico | ≥ Media |
| Patrón reutilizado | ¿Se usó un patrón de la KB? | SÍ en >60% de casos |
| Tiempo total | Desde inicio hasta reporte | ≤ 5 min de ejecución |

Si un diagnóstico excede 6 llamadas Oracle → evaluar qué queries podrían consolidarse y proponer un nuevo template.

Si un diagnóstico termina en confianza Baja → evaluar qué información faltaba y proponer agregarla a la KB.

---

## Resumen de Reglas

1. **Engram primero, Oracle después.** Siempre buscar diagnósticos previos antes de consultar la BD.
2. **Un JOIN vale más que tres queries.** Consolidar consultas siempre que sea posible.
3. **Seguir el árbol, no explorar.** Clasificar el caso y seguir el flujo del módulo correspondiente.
4. **Templates sobre queries ad-hoc.** Usar los templates pre-armados, solo ajustar parámetros.
5. **Profundizar solo si es necesario.** Si la confianza es Alta o Media, no hacer queries adicionales.
6. **Cada caso mejora el sistema.** Si un diagnóstico requirió exploración, documentar para que el siguiente no la necesite.
