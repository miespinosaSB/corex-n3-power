# Patrones y Bugfixes — Engram Export

> Exportado: 2026-05-12 | Proyecto: tronador-oracle-db

---

## #65 — Patrón: Diferidos CB100270 generan devolución mayor al cobro en exclusiones autos

**Tipo:** pattern | **Fecha:** 2026-05-13 | **Topic:** pattern/diferidos-cb100270-exclusion-autos

**What**: Diagnóstico completo MDSB-992543 — diferencia $15,332 entre factura cobro y devolución por exclusión de riesgo en autos colectivos.

**Why**: Riesgo 662 (placa LRO484) incluido y excluido el mismo día (20-FEB-2026), la devolución es mayor al cobro.

**Where**: Sim_Pck299_Cb100270.pkb (Prc_upd163 línea 303, V_factor línea 72), SIM_PCK299_AB100273.pkb (llamada línea 811-831)

**Learned**:
1. **FÓRMULA COMPLETA FACTURACIÓN EXCLUSIÓN**: `IMP_PRIMA_FINAL = ROUND(IMP_PRIMA_END × CoefFact, 0) + (IMP_PRIMA_163_C1000270 × V_factor × V_coefpol)`
2. V_factor = CEIL(MONTHS_BETWEEN(FechaVencPol, FechaVtoFact)) — meses RESTANTES hasta vencimiento, NO meses cobrados
3. Para MDSB-992543: -197,949 + (2,712 × 13 × 1) = -162,693
4. **ASIMETRÍA**: Cobro usa prima_anu/12 + 1_diferido = $149,809. Devolución usa fórmula proporcional + 13_diferidos = $162,693
5. Sim_Pck299_Cb100270 se ejecuta DESPUÉS del INSERT cuando: PeriodoFact=1 AND CodSecc=1 AND NumEnd>0 AND TipoEnd NOT IN ('AT','RE')
6. El paquete CB100270 NO valida cuántos diferidos se cobraron realmente — devuelve por meses futuros
7. Requiere validación funcional: ¿el diferido es obligación futura cancelable o cobro mensual devolvible solo si se cobró?
8. Flujo completo: `Form AC100731 → SIM_PCK_ANULACIONENDOSO → PROC_GENERA_FACTURA → AB100277 → AB100273 (INSERT) → CB100270 (UPDATE +diferidos)`

### Señales para detectar este patrón
- Factura de devolución > factura de cobro en exclusiones
- Riesgo incluido y excluido en el mismo período
- Tabla C1000270 con registros para el endoso
- TipoEnd diferente de 'AT' y 'RE'

---

## #63 — MDSB-992543 RESUELTO: Fórmula facturación = IMP_PRIMA_END*CoefFact + diferidos(CB100270)

**Tipo:** bugfix | **Fecha:** 2026-05-13

**What**: Reproducido exactamente el monto de -162,693 de la factura 13 del caso MDSB-992543. La fórmula incluye un ajuste de diferidos (C1000270) que se aplica DESPUÉS del INSERT por Sim_Pck299_Cb100270.Prc_Proceso.

**Why**: Para determinar si la diferencia de $15,332 entre factura 12 y 13 es bug o comportamiento esperado.

**Where**: SIM_PCK299_CB100270.pkb (Prc_upd163 línea 303, Prc_lee270 línea 230), SIM_PCK299_AB100273.pkb (llamada en línea 820)

**Learned**:
1. FÓRMULA COMPLETA: `IMP_PRIMA = ROUND(IMP_PRIMA_END * v_CoefFact, 0) + (IMP_PRIMA_163_C1000270 * V_factor)`
2. Para MDSB-992543: -197,949 + (2,712 * 13) = -197,949 + 35,256 = -162,693 ✓
3. V_factor = CEIL(MONTHS_BETWEEN(FechaVencPol, FechaVtoFact)) = CEIL(MB('30-APR-2027','31-MAR-2026')) = 13
4. Sim_Pck299_Cb100270 se llama DESPUÉS del INSERT cuando: PeriodoFact=1 AND CodSecc=1 AND NumEnd>0 AND TipoEnd NOT IN ('AT','RE')
5. El paquete CB100270 hace `UPDATE A2000163 SET imp_prima = imp_prima + (V_impprima163 * V_coefpol)` donde V_impprima163 = SUM(imp_prima_163) * V_factor de C1000270
6. La diferencia de $15,332 entre factura 12 ($149,809) y factura 13 ($162,693) se explica por: la devolución incluye diferidos por 13 meses restantes (35,256 * CoefFact = 3,328) + la proporción de 39 días vs 31 días
7. **CONCLUSIÓN**: Es COMPORTAMIENTO ESPERADO del sistema — al excluir un riesgo se devuelve prima proporcional + diferidos pendientes

---

## #37 — Diagnóstico MDSB-992543: Diferencia primas factura 12 vs 13 por desalineación de fechas

**Tipo:** bugfix | **Fecha:** 2026-05-12

**What**: Diagnóstico de diferencia de $15,332 entre prima cobrada en factura 12 y devuelta en factura 13 para póliza 1000486837825, riesgo 662 (placa LRO484).

**Why**: La factura 13 (devolución por exclusión endoso 16) devuelve más de lo cobrado en factura 12 porque los períodos de cálculo son diferentes: factura 12 efecto 28/02 (31 días), factura 13 efecto 20/02 (39 días).

**Where**: Tablas A2000030 (endosos 13 y 16), A2000040 (coberturas riesgo 662), A2990700 (facturas), A2000163 (detalle facturas), C1000270 (diferidos)

**Learned**: Cuando un riesgo se incluye a mitad de período y se excluye desde la misma fecha de inclusión, la devolución se calcula desde la fecha de vigencia del endoso (no desde la fecha de efecto de la factura anterior). Esto genera una diferencia aparente que NO es un bug — es comportamiento esperado del sistema de facturación. La diferencia corresponde a los días entre la fecha de vigencia del endoso y la fecha de efecto de la factura mensual. **Clave: verificar siempre FEC_EFECTO en A2990700 vs FECHA_VIG_END en A2000030 para entender diferencias de primas en exclusiones.**

---

## #56 — Fix: credenciales .env no disponibles en shell del agente

**Tipo:** bugfix | **Fecha:** 2026-05-12

**What**: El steering consulta-produccion-mdsb.md usaba `os.environ["JIRA_USERNAME"]` y `$JIRA_USERNAME` en curl, pero esas variables no existen en el shell del agente. Solo están disponibles dentro del proceso de los MCP servers (se cargan desde ~/.kiro/settings/.env al iniciar cada server).

**Why**: El agente fallaba con "Las credenciales no están disponibles como variables de entorno en el shell" al intentar crear requests MDSB.

**Where**: powers/corex-n3/steering/consulta-produccion-mdsb.md

**Learned**: Las credenciales en Kiro powers viven en `~/.kiro/settings/.env` y se inyectan SOLO en los procesos MCP (via `set -a; . .env; set +a; exec ...`). Para scripts que el agente ejecuta en terminal, hay que leer el .env manualmente con `open()`. Nunca asumir que están en `os.environ`.
