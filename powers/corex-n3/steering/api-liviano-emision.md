# API Liviano de Emisión — Referencia Técnica

## Endpoint

```
POST /api/v1/expgenerica/procesar
```

Orquesta: crear solicitud → validar → persistir. Una sola llamada.

## Ambientes

| Ambiente | URL Base | x-api-key |
|----------|----------|-----------|
| DEV | `https://e9j5wa8o3i-vpce-0c5bad66a54ad534d.execute-api.us-east-1.amazonaws.com/dev/gestion_polizas` | `mWufkpZJlT3i2g3kwxtNDa3gQSPKpkVmaLFeG11V` |
| STAGE | `https://qkyp0u56dg-vpce-0f8d39dec8a2113ab.execute-api.us-east-1.amazonaws.com/stage/gestion_polizas` | `QCIVccSMoI3MJxcfOU2nK9X2Jk0fZwEn1N1W4913` |

Headers: `Content-Type: application/json` + `x-api-key`

## Estructura del JSON

```json
{
  "typProceso": { ... },
  "registros": [ ... ]
}
```

## typProceso

| Campo | Descripción |
|-------|-------------|
| `modulo` | "2" (pólizas) |
| `proceso` | 261 (emisión estándar) o 265 (emisión completa) |
| `subproceso` | 260 |
| `cod_cia` | Compañía (2=Vida, 3=Generales) |
| `cod_secc` | Sección/ramo |
| `cod_producto` | Producto |
| `subproducto` | Variante (null si no aplica) |
| `cod_usr` | Usuario (null = se asigna por defecto) |
| `canal` | Canal (1=directo, null = se asigna 1) |
| `sistema_origen` | Sistema origen (196=Pago en Línea) |
| `pais` | País (1=Colombia, null = se asigna 1) |

Productos: consultar `OPS$PUMA.SIM_PRODUCTOS WHERE ESTADO = 'A'`

## Registros

Cada registro:

| Campo | Descripción |
|-------|-------------|
| `cnsctv` | Consecutivo ordinal |
| `estrctr` | Segmento (DATOS FIJOS, DATOS VARIABLES, AGENTES, COBERTURAS, etc.) |
| `rsg` | Riesgo (null=póliza, 1+=riesgo) |
| `tpmvmnt` | "EO" (emisión original) |
| `nmcmp` | Nombre canónico del campo |
| `vlrcmp` | Valor (siempre string) |
| `dscrpcn` | Descripción |
| `grp` | Grupo (para múltiples instancias) |
| `infrmcn01` | Texto largo (cláusulas) |

## Fuentes de Datos Oracle

| Tabla | Qué contiene |
|-------|-------------|
| `SIM_PRODUCTOS` | Catálogo de productos (COD_CIA, COD_SECC, COD_PRODUCTO, NOM_PRODUCTO) |
| `CRX_HOMOLOGACION_CAMPOS` | Lenguaje canónico: nmcmp → columna destino por segmento |
| `G2000020` + `SIM_G2000020` | Campos variables por producto (obligatoriedad, tipo, valor defecto) |
| `G2000010` | Tipo y longitud de cada campo variable |
| `A1002100` | Coberturas por producto (COD_COB, TXT_COB, BASICA, NOMINA) |
| `INTERMEDIARIOS` | Existencia/vigencia de intermediarios (CLAVE, FORMA_ACTUACION) |
| `A2990500` | Configuración agencia por cia/sección |
| `CONVENIOS_CLAVE` + `A1001700` | Convenio activo del agente |
| `A1002400` | Formas de cobro válidas |
| `SIM_PROCESOS` | Configuración del proceso (TIPO_NEGOCIO_TRONADOR, APLICA_A_POLIZA_PPAL) |
| `SIM_CONTROL_FECHAS` | Límites de fechas (anticipada, retroactiva, vencimiento) |
| `C1001802` | Máximo comisión pactada por sección/ramo |
| `CRX_EXP_GENERICA` | Solicitudes existentes (ejemplos de referencia) |

## Campos DATOS FIJOS (canónicos)

| nmcmp | Columna | Descripción |
|-------|---------|-------------|
| `Intrmdr` | COD_PROD | Productor (= agente líder) |
| `Tmdr` | NRO_DOCUMTO | Documento tomador |
| `CdgdMnd` | COD_MON | Moneda (1=COP) |
| `PrdcddFrcncdPg` | PERIODO_FACT | Periodicidad (12=anual) |
| `Frmdcbr` | FOR_COBRO | Forma cobro (CC, DB) |
| `Tpddntfccn` | TDOC_TERCERO | Tipo doc tomador |
| `Fchdncdvgnc` | FECHA_VIG_POL | Fecha inicio (ddMMyyyy) |
| `Fchdvncmntdlplz` | FECHA_VENC_POL | Fecha vencimiento (ddMMyyyy) |
| `RldlcmpnCsgrdr` | COD_COA | Coaseguro (0=sin, 1=cedido, 3=recibido) |
| `DsptchTyp` | SIM_TIPO_ENVIO | PE=electrónica, PA=papel |
| `Plzdsgrsprncpl` | NUM_POL_FLOT | Póliza principal |
| `DscrpcnPlz` | DESC_POL | Descripción |
| `NmrMvmntPlzPrncpl` | NUM_END_FLOT | Endoso ppal ("0") |

> `NUM_END` y `MCA_COTIZACION` NO se incluyen. El API los maneja.

## Campos AGENTES

| nmcmp | Columna |
|-------|---------|
| `Intrmdr` | COD_AGENTE |
| `PrctjPrtcpcn` | PORC_PART |
| `McLdr` | LIDER |
| `PrctjCmsn` | PORC_PACTADO (opcional) |

Reglas:
- Suma PORC_PART = 100%
- Solo un líder
- **Agente líder = Intrmdr de DATOS FIJOS**
- PORC_PACTADO es opcional

## Campos COBERTURAS

| nmcmp | Columna |
|-------|---------|
| `CdgCbrtr` | COD_COB |
| `VlrAsgrd` | SUMA_ASEG |
| `TsdlCbrtr` | TASA_COB |
| `VlrPrma` | PRIMA_COB |
| `FchIncVgncCbrtr` | SIM_FECHA_INCLUSION (dd/MM/yyyy) |
| `FchFnlVgncCbrtr` | SIM_FECHA_EXCLUSION (dd/MM/yyyy) |
| `CfcntCbrtr` | SIM_COEFCOB |
| `MrcGrttCbrtr` | MCA_GRATUITA |

Si `A1002100.NOMINA` no es null → incluir segmento `NOMINA_{valor}`.

## Campos COASEGURADORAS

| nmcmp | Columna |
|-------|---------|
| `NmrdplzdCmpnCsgrdr` | NUM_POL_COA |
| `Csgrdr` | COD_CIACOA |
| `PrcntjPrtcpcnCsgrdr` | PORC_PARTCOA |
| `NmrdEndsdlCsgrdr` | NUM_ENDOSO_COA |

## Campos DEBITO AUTOMATICO (si FOR_COBRO = DB)

| nmcmp | Columna |
|-------|---------|
| `Bnc` | COD_ENTIDAD |
| `CnldDscnt` | CANAL_DESCTO |
| `BnkAccnt` | NRO_CUENTA |
| `FchdVncmntdTrjtdCrdt` | FECHA_VTO (yyyyMM) |
| `DcmntdlTtlrdlcnt` | COD_IDENTIF |
| `TpdDcmntdlTtlrdlcnt` | TIPDOC_CTAHABIENTE |
| `Ttlrdlcnt` | NOMBRE_IDEN |
| `DrccndlTtlrdlcnt` | DIRECCION_IDEN |
| `CdddlTtlrdlcnt` | CIUDAD_IDEN |
| `TlfndlTtlrdlcnt` | TELEFONO_IDEN |
| `EmldlTtlrdlcnt` | EMAIL |

## Campos TEXTOS

| nmcmp | Columna |
|-------|---------|
| `CdgTxt` | CODIGO_TEXTO |
| `SbrCdgTxt` | SUBCODIGO_TEXTO |
| `NmrdOrdn` | ORDEN |
| `Txt` | TEXTO (valor largo en infrmcn01) |

## Campos NOMINA_VNUE

| nmcmp | Columna |
|-------|---------|
| `CdgCbrtr` | COD_COB |
| `Nmbr` | NOMBRE |
| `TpDcmnt` | TIPO_DOCUMTO |
| `NmrDcmnt` | NRO_DOCUMTO |
| `Prcntj` | SUMA_ASEG1 |
| `TpBnfcr` | AMBITO_COB |
| `Aplld` | APELLIDO |
| `Prntsc` | COD_CATEG |
| `FchEqp` | FECHA_NAC |
| `PgTtl` | PRIMA_CAT |
| `RntMnsl` | PRIMA_CAT_EN |

## Validaciones (CRX_PCK_VALIDACIONES_GENERICAS)

| Validación | Qué verifica | Tabla clave |
|------------|-------------|-------------|
| Estructura tabla fija | Tipo, longitud, nullable vs columna destino | `CRX_HOMOLOGACION_CAMPOS` + `ALL_TAB_COLUMNS` |
| Datos variables | Obligatoriedad, tipo, longitud | `G2000020` + `G2000010` |
| Fechas vigencia | Anticipada, retroactiva, vencimiento | `SIM_CONTROL_FECHAS` |
| Intermediarios | Existencia, vigencia, agencia, convenio | `INTERMEDIARIOS`, `A2990500`, `A1001700` |
| Comisión pactada | No supera máximo (solo si COD_COA ≠ 3) | `C1001802` |
| Tercero/Tomador | Existencia, listas restrictivas | `SIM_PCK_PROCESO_DATOS_EMISION.VAL_TERCERO` |
| Asegurado | Si ≠ tomador, también se valida | Mismo que tercero |
| Moneda/Facturación | Configuración existe | `A2990100`, `A2990101` |
| Forma cobro | Existe en config; si DB: datos completos | `A1002400` |
| Coberturas | Existen, prima>0 si no gratuita, suma≠0 | `A1002100` |
| Nóminas | Estructura requerida presente | `A1002100.NOMINA` |
| Coaseguro | Coaseguradora existe, porcentajes válidos | `A1000600`, `A1000300` |
| Póliza principal | Existe y vigente (si aplica) | `A2010030` |
| Textos | Código/subcódigo existen | `A1001800` |
| Controles técnicos | COD_ERROR existe | `G2000210` |

## Formatos de Fecha

| Formato | Dónde |
|---------|-------|
| `ddMMyyyy` | DATOS FIJOS (vigencia póliza) |
| `dd/MM/yyyy` | COBERTURAS, algunos DATOS VARIABLES |
| `yyyyMM` | Vencimiento tarjeta crédito |

## Respuesta Exitosa

```json
{
  "exito": true,
  "nrUnc": "301",
  "mensajeCreacion": "122 campo(s) insertado(s)",
  "numSecuPoliza": 39745412910,
  "numPol1": 1500104540201
}
```
