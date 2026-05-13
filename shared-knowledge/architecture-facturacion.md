# Arquitectura: Flujo de Facturación de Endosos — Engram Export

> Exportado: 2026-05-12 | Proyecto: tronador-oracle-db | Caso: MDSB-992543

## #50 — Flujo facturación endosos Tronador: AB100277 → AB100273 (coeficientes)

**Tipo:** architecture | **Fecha:** 2026-05-12

**What**: Documentado el flujo completo de facturación de endosos en Tronador y las fórmulas de cálculo de coeficientes.

**Why**: Para diagnosticar diferencias de primas entre facturas de cobro y devolución (caso MDSB-992543)

**Where**: Base Datos/Packages/SIM_PCK299_AB100273.pkb (prc_CalcCoeficiente línea 1324, prc_PorDias línea 1790, prc_VerificaPrima línea 1200)

**Learned**:
1. Leer código desde el repositorio local es MUCHO más eficiente que get_source del MCP Oracle
2. El flujo de facturación: `proc_genera_factura → SIM_PCK299_AB100277.PRC_INICIO → PRC_PROCESO → SIM_PCK299_AB100273.PRC_INICIO → prc_CalcCoeficiente + prc_PorDias`
3. v_CoefFact = proporción del período de factura respecto a vigencia restante
4. v_CoefPol = (días factura) / (días vigencia póliza) — calculado en prc_PorDias
5. prc_VerificaPrima acumula meses de facturas con estado 'P' que se solapan — si ya están cobradas ('CT') no se descuentan
6. PRC_FACTANULLIB (que usa PRC299_FACTURA_ANULACION_GRUPO) solo se invoca para libranza o facturas anticipadas CC

---

## #55 — Flujo completo facturación endosos: fórmula v_CoefFact y prc299_obtengo_vto_fact

**Tipo:** architecture | **Fecha:** 2026-05-12

**What**: Rastreo completo del flujo de facturación de endosos en Tronador — desde la entrada hasta el INSERT en A2000163.

**Why**: Diagnosticar MDSB-992543 (diferencia primas factura 12 vs 13)

**Where**: PRC299_OBTENGO_VTO_FACT.prc, SIM_PCK299_AB100273.pkb (prc_CalcCoeficiente, prc_PeriodoCorto, prc_InsNormal), SIM_PCK299_COMUNFACT.pkb

**Learned**:
1. Flujo: `prc_Inicio → prc_VenctoNew → prc299_obtengo_vto_fact → prc_CalcCoeficiente → prc_Proceso → prc_Premios → prc_InsNormal`
2. prc299_obtengo_vto_fact toma MAX(FECHA_VTO_FACT) de facturas anteriores con NUM_END_REF < numend actual
3. Fórmula: `IMP_PRIMA = ROUND(IMP_PRIMA_END * v_CoefFact, 0)`
4. v_CoefFact para periodo!=12: `(MB(Vto,Vig)*30 - MesAcum) / ((MB(Vto,Vig)*30) + (MB(VencPol,Vto)*30))`
5. COD_DURACION=2 → prc_PeriodoCorto (v_CoefPol = MB(Vto,Vig)/12)
6. COD_DURACION=1 → prc_PorDias (v_CoefPol = (Vto-Vig)/(VencPol-VigPol))
7. Para tipo AP: prc_VerificaPrima NO se llama, v_MesAcum queda en 0
8. NVL(mca_end_dtot,'N') en COMUNFACT — NULL se trata como 'N'

---

## #61 — Flujo exclusión autos: Form AC100731 → SIM_PCK_ANULACIONENDOSO → PROC_GENERA_FACTURA

**Tipo:** architecture | **Fecha:** 2026-05-13

**What**: Descubierto que la exclusión del riesgo 662 (endoso 16) se ejecuta via SIM_PCK_ANULACIONENDOSO.PROC_PASO_REALES_ANULAENDOSO, NO directamente desde el form AC100731.

**Why**: Para trazar el flujo completo de facturación del caso MDSB-992543 y entender por qué la fórmula no reproduce el monto.

**Where**: Base Datos/Packages/SIM_PCK_ANULACIONENDOSO.pkb (línea 491), Form AC100731.fmt

**Learned**:
1. Form AC100731 (cod_end 731) NO contiene lógica de facturación — solo graba datos del endoso
2. El flujo real es: `Form → SIM_PCK_ANULACIONENDOSO.PROC_PASO_REALES_ANULAENDOSO → UPDATE MCA_TERM_OK='S' → PROC_GENERA_FACTURA → AB100277 → AB100273`
3. ANTES de facturar, el paquete hace: `UPDATE A2000030 SET MCA_END_ANU='S', CANT_CUOTAS=1` en el endoso que se anula (13)
4. También llama a PROC_RIESGOS_REVERSADOS y PROC_COPIADATOSFIJOS_SIM_A_A que pueden modificar datos en A2000160
5. El endoso 16 es una ANULACIÓN del endoso 13 (no una exclusión independiente) — IP_NUMENDANULA=13, IP_NUMEND=16
6. SIM_SUBPRODUCTO = 367 (no 368/370) → confirma que va por AB100273 (no AB100273_RC)
7. El trigger SIM_TRG_AU_A2000030 NO genera factura — solo sincroniza datos

---

## Diagrama de Flujo Consolidado

```
┌─────────────────────────────────────────────────────────────────────┐
│ FLUJO FACTURACIÓN ENDOSOS (EXCLUSIÓN/ANULACIÓN)                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Form AC100731 (graba endoso)                                       │
│       │                                                             │
│       ▼                                                             │
│  SIM_PCK_ANULACIONENDOSO.PROC_PASO_REALES_ANULAENDOSO              │
│       │  UPDATE A2000030 SET MCA_END_ANU='S', CANT_CUOTAS=1        │
│       │  UPDATE MCA_TERM_OK='S'                                     │
│       ▼                                                             │
│  PROC_GENERA_FACTURA                                                │
│       │                                                             │
│       ▼                                                             │
│  SIM_PCK299_AB100277.PRC_INICIO → PRC_PROCESO                      │
│       │  (tipo 'AT' + CC sin libranza → NO va a PRC_FACTANULLIB)   │
│       ▼                                                             │
│  SIM_PCK299_AB100273.PRC_INICIO                                     │
│       │  prc_VenctoNew → prc299_obtengo_vto_fact                   │
│       │  prc_CalcCoeficiente (v_CoefFact)                          │
│       │  prc_PeriodoCorto (COD_DURACION=2) o prc_PorDias (=1)     │
│       │  prc_Proceso → prc_Premios → prc_InsNormal                │
│       │                                                             │
│       │  INSERT A2000163 (IMP_PRIMA = ROUND(END*CoefFact, 0))     │
│       ▼                                                             │
│  SIM_PCK299_CB100270.Prc_Proceso  ← DESPUÉS del INSERT            │
│       │  Condición: PeriodoFact=1 AND CodSecc=1 AND NumEnd>0      │
│       │             AND TipoEnd NOT IN ('AT','RE')                 │
│       │                                                             │
│       │  UPDATE A2000163 SET imp_prima = imp_prima +               │
│       │         (IMP_PRIMA_163_C1000270 × V_factor × V_coefpol)   │
│       │                                                             │
│       │  V_factor = CEIL(MONTHS_BETWEEN(VencPol, VtoFact))         │
│       ▼                                                             │
│  RESULTADO FINAL: IMP_PRIMA incluye diferidos pendientes           │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```
