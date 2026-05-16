#!/usr/bin/env node
/**
 * build-emision-json.js
 * 
 * Genera el JSON de emisión para el API Liviano a partir de una estructura
 * simplificada de datos. El agente genera solo los datos; este script
 * ensambla el JSON con consecutivos, grupos y estructura correcta.
 *
 * Uso:
 *   node build-emision-json.js <input.json> [output.json]
 *
 * Si no se especifica output, imprime a stdout.
 *
 * Estructura del input.json:
 * {
 *   "typProceso": { ... },
 *   "datosFijos": { "nmcmp": "valor", ... },
 *   "datosVariablesPoliza": { "COD_CAMPO": "valor", ... },
 *   "datosVariablesRiesgo": { "COD_CAMPO": "valor", ... },
 *   "datosVariablesAlternativa": { "COD_CAMPO": "valor", ... },
 *   "agentes": [ { "codigo": "38335", "participacion": "100", "lider": "S", "comision": null } ],
 *   "coberturas": [ { "codigo": "901", "sumaAseg": "100000000", "tasa": "0,22", "prima": "220000", "gratuita": null } ],
 *   "nominaVnue": [ { "cobertura": "901", "nombre": "PEDRO", "apellido": "PEREZ", ... } ],
 *   "nominaTuto": [ { ... } ],
 *   "coaseguradoras": [ { ... } ],
 *   "debitoAutomatico": { ... },
 *   "textos": [ { ... } ],
 *   "vigenciaCoberturas": false,
 *   "fechaInicio": "15052026",
 *   "fechaFin": "15052027"
 * }
 */

const fs = require('fs');
const path = require('path');

function buildRegistros(input) {
  const registros = [];

  // Campos a excluir de DATOS FIJOS (no deben ir en el JSON)
  const CAMPOS_EXCLUIR_DATOS_FIJOS = ['MrcCtzcn'];

  // --- DATOS FIJOS ---
  if (input.datosFijos) {
    let cnsctv = 1;
    for (const [nmcmp, vlrcmp] of Object.entries(input.datosFijos)) {
      if (vlrcmp === undefined || vlrcmp === null) continue;
      if (CAMPOS_EXCLUIR_DATOS_FIJOS.includes(nmcmp)) continue;
      registros.push({
        cnsctv: cnsctv++,
        estrctr: "DATOS FIJOS",
        rsg: null,
        tpmvmnt: "EO",
        nmcmp,
        vlrcmp: String(vlrcmp),
        dscrpcn: null,
        grp: null,
        infrmcn01: null
      });
    }
  }

  // --- DATOS VARIABLES nivel póliza (rsg=null) ---
  if (input.datosVariablesPoliza) {
    let cnsctv = 1;
    for (const [nmcmp, vlrcmp] of Object.entries(input.datosVariablesPoliza)) {
      if (vlrcmp === undefined) continue;
      registros.push({
        cnsctv: cnsctv++,
        estrctr: "DATOS VARIABLES",
        rsg: null,
        tpmvmnt: "EO",
        nmcmp,
        vlrcmp: vlrcmp === null ? null : String(vlrcmp),
        dscrpcn: null,
        grp: null,
        infrmcn01: null
      });
    }
  }

  // --- DATOS VARIABLES nivel riesgo (rsg="1") ---
  if (input.datosVariablesRiesgo) {
    let cnsctv = 1;
    const rsg = input.riesgoId || "1";
    for (const [nmcmp, vlrcmp] of Object.entries(input.datosVariablesRiesgo)) {
      if (vlrcmp === undefined) continue;
      registros.push({
        cnsctv: cnsctv++,
        estrctr: "DATOS VARIABLES",
        rsg,
        tpmvmnt: "EO",
        nmcmp,
        vlrcmp: vlrcmp === null ? null : String(vlrcmp),
        dscrpcn: null,
        grp: null,
        infrmcn01: null
      });
    }
  }

  // --- DATOS VARIABLES nivel alternativa (rsg="1", nivel 5) ---
  if (input.datosVariablesAlternativa) {
    let cnsctv = 1;
    const rsg = input.riesgoId || "1";
    for (const [nmcmp, vlrcmp] of Object.entries(input.datosVariablesAlternativa)) {
      if (vlrcmp === undefined) continue;
      registros.push({
        cnsctv: cnsctv++,
        estrctr: "DATOS VARIABLES",
        rsg,
        tpmvmnt: "EO",
        nmcmp,
        vlrcmp: vlrcmp === null ? null : String(vlrcmp),
        dscrpcn: null,
        grp: null,
        infrmcn01: null
      });
    }
  }

  // --- AGENTES ---
  if (input.agentes && input.agentes.length > 0) {
    input.agentes.forEach((agente, idx) => {
      const grp = String(idx + 1);
      let cnsctv = 1;
      registros.push({ cnsctv: cnsctv++, estrctr: "AGENTES", rsg: null, tpmvmnt: "EO", nmcmp: "Intrmdr", vlrcmp: String(agente.codigo), dscrpcn: null, grp, infrmcn01: null });
      registros.push({ cnsctv: cnsctv++, estrctr: "AGENTES", rsg: null, tpmvmnt: "EO", nmcmp: "PrctjPrtcpcn", vlrcmp: String(agente.participacion), dscrpcn: null, grp, infrmcn01: null });
      registros.push({ cnsctv: cnsctv++, estrctr: "AGENTES", rsg: null, tpmvmnt: "EO", nmcmp: "McLdr", vlrcmp: agente.lider || "N", dscrpcn: null, grp, infrmcn01: null });
      if (agente.comision) {
        registros.push({ cnsctv: cnsctv++, estrctr: "AGENTES", rsg: null, tpmvmnt: "EO", nmcmp: "PrctjCmsn", vlrcmp: String(agente.comision), dscrpcn: null, grp, infrmcn01: null });
      }
    });
  }

  // --- COBERTURAS ---
  if (input.coberturas && input.coberturas.length > 0) {
    const rsg = input.riesgoId || "1";
    input.coberturas.forEach((cob, idx) => {
      const grp = String(idx + 1);
      let cnsctv = 1;
      registros.push({ cnsctv: cnsctv++, estrctr: "COBERTURAS", rsg, tpmvmnt: "EO", nmcmp: "CdgCbrtr", vlrcmp: String(cob.codigo), dscrpcn: null, grp, infrmcn01: null });
      registros.push({ cnsctv: cnsctv++, estrctr: "COBERTURAS", rsg, tpmvmnt: "EO", nmcmp: "VlrAsgrd", vlrcmp: String(cob.sumaAseg), dscrpcn: null, grp, infrmcn01: null });
      if (cob.tasa) {
        registros.push({ cnsctv: cnsctv++, estrctr: "COBERTURAS", rsg, tpmvmnt: "EO", nmcmp: "TsdlCbrtr", vlrcmp: String(cob.tasa), dscrpcn: null, grp, infrmcn01: null });
      }
      if (cob.prima) {
        registros.push({ cnsctv: cnsctv++, estrctr: "COBERTURAS", rsg, tpmvmnt: "EO", nmcmp: "VlrPrma", vlrcmp: String(cob.prima), dscrpcn: null, grp, infrmcn01: null });
      }
      if (input.vigenciaCoberturas) {
        registros.push({ cnsctv: cnsctv++, estrctr: "COBERTURAS", rsg, tpmvmnt: "EO", nmcmp: "FchIncVgncCbrtr", vlrcmp: cob.fechaInicio || formatDateCob(input.fechaInicio), dscrpcn: null, grp, infrmcn01: null });
        registros.push({ cnsctv: cnsctv++, estrctr: "COBERTURAS", rsg, tpmvmnt: "EO", nmcmp: "FchFnlVgncCbrtr", vlrcmp: cob.fechaFin || formatDateCob(input.fechaFin), dscrpcn: null, grp, infrmcn01: null });
      }
      if (cob.gratuita === "S") {
        registros.push({ cnsctv: cnsctv++, estrctr: "COBERTURAS", rsg, tpmvmnt: "EO", nmcmp: "MrcGrttCbrtr", vlrcmp: "S", dscrpcn: null, grp, infrmcn01: null });
      }
    });
  }

  // --- COASEGURADORAS ---
  if (input.coaseguradoras && input.coaseguradoras.length > 0) {
    input.coaseguradoras.forEach((coa, idx) => {
      const grp = String(idx + 1);
      let cnsctv = 1;
      registros.push({ cnsctv: cnsctv++, estrctr: "COASEGURADORAS", rsg: null, tpmvmnt: "EO", nmcmp: "Csgrdr", vlrcmp: String(coa.codigoCompania), dscrpcn: null, grp, infrmcn01: null });
      registros.push({ cnsctv: cnsctv++, estrctr: "COASEGURADORAS", rsg: null, tpmvmnt: "EO", nmcmp: "PrcntjPrtcpcnCsgrdr", vlrcmp: String(coa.porcentaje), dscrpcn: null, grp, infrmcn01: null });
      if (coa.numPoliza) {
        registros.push({ cnsctv: cnsctv++, estrctr: "COASEGURADORAS", rsg: null, tpmvmnt: "EO", nmcmp: "NmrdplzdCmpnCsgrdr", vlrcmp: String(coa.numPoliza), dscrpcn: null, grp, infrmcn01: null });
      }
      if (coa.numEndoso) {
        registros.push({ cnsctv: cnsctv++, estrctr: "COASEGURADORAS", rsg: null, tpmvmnt: "EO", nmcmp: "NmrdEndsdlCsgrdr", vlrcmp: String(coa.numEndoso), dscrpcn: null, grp, infrmcn01: null });
      }
    });
  }

  // --- NOMINA_VNUE ---
  if (input.nominaVnue && input.nominaVnue.length > 0) {
    const rsg = input.riesgoId || "1";
    input.nominaVnue.forEach((nom, idx) => {
      const grp = String(idx + 1);
      let cnsctv = 1;
      registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_VNUE", rsg, tpmvmnt: "EO", nmcmp: "CdgCbrtr", vlrcmp: String(nom.cobertura), dscrpcn: null, grp, infrmcn01: null });
      if (nom.nombre) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_VNUE", rsg, tpmvmnt: "EO", nmcmp: "Nmbr", vlrcmp: nom.nombre, dscrpcn: null, grp, infrmcn01: null });
      if (nom.apellido) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_VNUE", rsg, tpmvmnt: "EO", nmcmp: "Aplld", vlrcmp: nom.apellido, dscrpcn: null, grp, infrmcn01: null });
      if (nom.tipoDoc) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_VNUE", rsg, tpmvmnt: "EO", nmcmp: "TpDcmnt", vlrcmp: nom.tipoDoc, dscrpcn: null, grp, infrmcn01: null });
      if (nom.numDoc) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_VNUE", rsg, tpmvmnt: "EO", nmcmp: "NmrDcmnt", vlrcmp: String(nom.numDoc), dscrpcn: null, grp, infrmcn01: null });
      if (nom.porcentaje) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_VNUE", rsg, tpmvmnt: "EO", nmcmp: "Prcntj", vlrcmp: String(nom.porcentaje), dscrpcn: null, grp, infrmcn01: null });
      if (nom.tipoBeneficiario) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_VNUE", rsg, tpmvmnt: "EO", nmcmp: "TpBnfcr", vlrcmp: String(nom.tipoBeneficiario), dscrpcn: null, grp, infrmcn01: null });
      if (nom.parentesco) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_VNUE", rsg, tpmvmnt: "EO", nmcmp: "Prntsc", vlrcmp: String(nom.parentesco), dscrpcn: null, grp, infrmcn01: null });
      if (nom.fechaNacimiento) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_VNUE", rsg, tpmvmnt: "EO", nmcmp: "FchEqp", vlrcmp: nom.fechaNacimiento, dscrpcn: null, grp, infrmcn01: null });
    });
  }

  // --- NOMINA_TUTO ---
  if (input.nominaTuto && input.nominaTuto.length > 0) {
    const rsg = input.riesgoId || "1";
    input.nominaTuto.forEach((nom, idx) => {
      const grp = String(idx + 1);
      let cnsctv = 1;
      registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_TUTO", rsg, tpmvmnt: "EO", nmcmp: "CdgCbrtr", vlrcmp: String(nom.cobertura), dscrpcn: null, grp, infrmcn01: null });
      if (nom.nombre) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_TUTO", rsg, tpmvmnt: "EO", nmcmp: "Nmbr", vlrcmp: nom.nombre, dscrpcn: null, grp, infrmcn01: null });
      if (nom.apellido) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_TUTO", rsg, tpmvmnt: "EO", nmcmp: "Aplld", vlrcmp: nom.apellido, dscrpcn: null, grp, infrmcn01: null });
      if (nom.fechaNacimiento) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_TUTO", rsg, tpmvmnt: "EO", nmcmp: "FchNcmnt", vlrcmp: nom.fechaNacimiento, dscrpcn: null, grp, infrmcn01: null });
      if (nom.valorAsegurado) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_TUTO", rsg, tpmvmnt: "EO", nmcmp: "VlrAsgrd", vlrcmp: String(nom.valorAsegurado), dscrpcn: null, grp, infrmcn01: null });
      if (nom.extension) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_TUTO", rsg, tpmvmnt: "EO", nmcmp: "Extnsn", vlrcmp: String(nom.extension), dscrpcn: null, grp, infrmcn01: null });
      if (nom.gradoEscolar) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_TUTO", rsg, tpmvmnt: "EO", nmcmp: "GrdEsclr", vlrcmp: String(nom.gradoEscolar), dscrpcn: null, grp, infrmcn01: null });
      if (nom.rangoEscolar) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_TUTO", rsg, tpmvmnt: "EO", nmcmp: "RngEsclr", vlrcmp: String(nom.rangoEscolar), dscrpcn: null, grp, infrmcn01: null });
      if (nom.incremento) registros.push({ cnsctv: cnsctv++, estrctr: "NOMINA_TUTO", rsg, tpmvmnt: "EO", nmcmp: "Incrmnt", vlrcmp: String(nom.incremento), dscrpcn: null, grp, infrmcn01: null });
    });
  }

  // --- DEBITO AUTOMATICO ---
  if (input.debitoAutomatico) {
    const db = input.debitoAutomatico;
    let cnsctv = 1;
    const campos = [
      ["Bnc", db.banco],
      ["CnldDscnt", db.canalDescuento],
      ["BnkAccnt", db.numeroCuenta],
      ["FchdVncmntdTrjtdCrdt", db.fechaVencimiento],
      ["DcmntdlTtlrdlcnt", db.documentoTitular],
      ["TpdDcmntdlTtlrdlcnt", db.tipoDocTitular],
      ["Ttlrdlcnt", db.nombreTitular],
      ["DrccndlTtlrdlcnt", db.direccionTitular],
      ["CdddlTtlrdlcnt", db.ciudadTitular],
      ["TlfndlTtlrdlcnt", db.telefonoTitular],
      ["EmldlTtlrdlcnt", db.emailTitular]
    ];
    for (const [nmcmp, vlrcmp] of campos) {
      if (vlrcmp === undefined || vlrcmp === null) continue;
      registros.push({ cnsctv: cnsctv++, estrctr: "DEBITO AUTOMATICO", rsg: null, tpmvmnt: "EO", nmcmp, vlrcmp: String(vlrcmp), dscrpcn: null, grp: null, infrmcn01: null });
    }
  }

  // --- TEXTOS ---
  if (input.textos && input.textos.length > 0) {
    input.textos.forEach((txt, idx) => {
      const grp = String(idx + 1);
      let cnsctv = 1;
      registros.push({ cnsctv: cnsctv++, estrctr: "TEXTOS", rsg: null, tpmvmnt: "EO", nmcmp: "CdgTxt", vlrcmp: String(txt.codigo), dscrpcn: null, grp, infrmcn01: null });
      registros.push({ cnsctv: cnsctv++, estrctr: "TEXTOS", rsg: null, tpmvmnt: "EO", nmcmp: "SbrCdgTxt", vlrcmp: String(txt.subcodigo), dscrpcn: null, grp, infrmcn01: null });
      registros.push({ cnsctv: cnsctv++, estrctr: "TEXTOS", rsg: null, tpmvmnt: "EO", nmcmp: "NmrdOrdn", vlrcmp: String(txt.orden), dscrpcn: null, grp, infrmcn01: null });
      registros.push({ cnsctv: cnsctv++, estrctr: "TEXTOS", rsg: null, tpmvmnt: "EO", nmcmp: "Txt", vlrcmp: null, dscrpcn: null, grp, infrmcn01: txt.texto });
    });
  }

  return registros;
}

/**
 * Convierte fecha de DATOS FIJOS (ddMMyyyy) a formato COBERTURAS (dd/MM/yyyy)
 */
function formatDateCob(ddMMyyyy) {
  if (!ddMMyyyy || ddMMyyyy.includes('/')) return ddMMyyyy;
  return `${ddMMyyyy.substring(0, 2)}/${ddMMyyyy.substring(2, 4)}/${ddMMyyyy.substring(4)}`;
}

/**
 * Validaciones básicas antes de generar
 */
function validate(input) {
  const errors = [];

  if (!input.typProceso) errors.push("Falta typProceso");
  if (!input.datosFijos) errors.push("Falta datosFijos");
  if (!input.agentes || input.agentes.length === 0) errors.push("Falta al menos un agente");
  if (!input.coberturas || input.coberturas.length === 0) errors.push("Falta al menos una cobertura");

  // Validar suma participación agentes = 100
  if (input.agentes) {
    const suma = input.agentes.reduce((acc, a) => acc + Number(a.participacion || 0), 0);
    if (suma !== 100) errors.push(`Suma participación agentes = ${suma}, debe ser 100`);
  }

  // Validar un solo líder
  if (input.agentes) {
    const lideres = input.agentes.filter(a => a.lider === "S");
    if (lideres.length !== 1) errors.push(`Debe haber exactamente 1 agente líder, hay ${lideres.length}`);
  }

  // Validar agente líder = productor en datos fijos
  if (input.agentes && input.datosFijos) {
    const lider = input.agentes.find(a => a.lider === "S");
    const productor = input.datosFijos.Intrmdr;
    if (lider && productor && String(lider.codigo) !== String(productor)) {
      errors.push(`Agente líder (${lider.codigo}) ≠ productor en DATOS FIJOS (${productor})`);
    }
  }

  // Validar coberturas no gratuitas tienen prima > 0
  if (input.coberturas) {
    input.coberturas.forEach((cob, idx) => {
      if (cob.gratuita !== "S" && (!cob.prima || Number(cob.prima) <= 0)) {
        errors.push(`Cobertura ${cob.codigo} (índice ${idx}): prima debe ser > 0 (no es gratuita)`);
      }
    });
  }

  // Validar fechas de vigencia
  if (input.fechaInicio && input.fechaFin) {
    if (input.fechaInicio >= input.fechaFin) {
      errors.push(`Fecha inicio (${input.fechaInicio}) debe ser anterior a fecha fin (${input.fechaFin})`);
    }
  }

  return errors;
}

/**
 * Validaciones avanzadas con metadata del producto (dry-run)
 * Metadata contiene: camposObligatorios, longitudes, tipos, coberturasNoGratuitas
 */
function validateWithMetadata(input, metadata) {
  const warnings = [];

  // Validar campos obligatorios presentes
  if (metadata.camposObligatorios) {
    const nivelMap = {
      "1": input.datosVariablesPoliza || {},
      "2": input.datosVariablesRiesgo || {},
      "3": input.datosVariablesRiesgo || {},  // nivel 3 va en riesgo también
      "5": input.datosVariablesAlternativa || {}
    };

    for (const [nivel, campos] of Object.entries(metadata.camposObligatorios)) {
      const datos = nivelMap[nivel];
      for (const campo of campos) {
        if (!(campo in datos)) {
          warnings.push(`[OBLIGATORIO] Campo '${campo}' (nivel ${nivel}) falta en datos variables`);
        }
      }
    }
  }

  // Validar longitudes
  if (metadata.longitudes) {
    const allDatos = {
      ...(input.datosVariablesPoliza || {}),
      ...(input.datosVariablesRiesgo || {}),
      ...(input.datosVariablesAlternativa || {})
    };

    for (const [campo, maxLen] of Object.entries(metadata.longitudes)) {
      if (campo in allDatos && allDatos[campo] !== null) {
        const valor = String(allDatos[campo]);
        if (valor.length > maxLen) {
          warnings.push(`[LONGITUD] Campo '${campo}': valor "${valor}" (${valor.length} chars) excede máximo ${maxLen}`);
        }
      }
    }
  }

  // Validar formato de fechas
  if (metadata.tipos) {
    const allDatos = {
      ...(input.datosVariablesPoliza || {}),
      ...(input.datosVariablesRiesgo || {}),
      ...(input.datosVariablesAlternativa || {})
    };

    const dateRegex8 = /^\d{8}$/;           // ddMMyyyy
    const dateRegex10 = /^\d{2}\/\d{2}\/\d{4}$/;  // dd/MM/yyyy
    const oracleFormat = /^\d{2}-[A-Z]{3}-\d{4}$/; // DD-MON-YYYY (INVÁLIDO)

    for (const [campo, tipo] of Object.entries(metadata.tipos)) {
      if (tipo === 'D' && campo in allDatos && allDatos[campo]) {
        const valor = String(allDatos[campo]);
        if (oracleFormat.test(valor)) {
          warnings.push(`[FORMATO] Campo '${campo}': valor "${valor}" usa formato Oracle DD-MON-YYYY (inválido). Usar dd/MM/yyyy o ddMMyyyy`);
        } else if (valor.length > 10 && !valor.includes(':')) {
          warnings.push(`[FORMATO] Campo '${campo}': valor "${valor}" (${valor.length} chars) posible error de formato fecha`);
        }
      }
    }
  }

  // Validar coberturas no gratuitas
  if (metadata.coberturasNoGratuitas && input.coberturas) {
    const noGratuitas = new Set(metadata.coberturasNoGratuitas.map(String));
    input.coberturas.forEach(cob => {
      if (noGratuitas.has(String(cob.codigo)) && (!cob.prima || Number(cob.prima) <= 0)) {
        warnings.push(`[PRIMA] Cobertura ${cob.codigo}: prima debe ser > 0 (no es gratuita según metadata)`);
      }
    });
  }

  // Validar textos con infrmcn01 para sección 4 (Cumplimiento)
  if (input.typProceso && input.typProceso.cod_secc === 4) {
    if (input.textos && input.textos.length > 0) {
      input.textos.forEach((txt, idx) => {
        if (!txt.texto) {
          warnings.push(`[TEXTO] Texto ${idx + 1}: infrmcn01 vacío. Para Cumplimiento (secc 4) debe tener descripción del contrato.`);
        }
      });
    }
  }

  return warnings;
}

/**
 * Merge template con datos del usuario (deep merge, usuario sobreescribe template)
 */
function mergeWithTemplate(template, userData) {
  const result = JSON.parse(JSON.stringify(template)); // deep clone

  // Merge typProceso
  if (userData.typProceso) {
    result.typProceso = { ...result.typProceso, ...userData.typProceso };
  }

  // Merge datosFijos
  if (userData.datosFijos) {
    result.datosFijos = { ...result.datosFijos, ...userData.datosFijos };
  }

  // Merge datosVariablesPoliza
  if (userData.datosVariablesPoliza) {
    result.datosVariablesPoliza = { ...(result.datosVariablesPoliza || {}), ...userData.datosVariablesPoliza };
  }

  // Merge datosVariablesRiesgo
  if (userData.datosVariablesRiesgo) {
    result.datosVariablesRiesgo = { ...(result.datosVariablesRiesgo || {}), ...userData.datosVariablesRiesgo };
  }

  // Merge datosVariablesAlternativa
  if (userData.datosVariablesAlternativa) {
    result.datosVariablesAlternativa = { ...(result.datosVariablesAlternativa || {}), ...userData.datosVariablesAlternativa };
  }

  // Override arrays (no merge, reemplazar completo)
  if (userData.agentes) result.agentes = userData.agentes;
  if (userData.coberturas) result.coberturas = userData.coberturas;
  if (userData.nominaVnue) result.nominaVnue = userData.nominaVnue;
  if (userData.nominaTuto) result.nominaTuto = userData.nominaTuto;
  if (userData.coaseguradoras) result.coaseguradoras = userData.coaseguradoras;
  if (userData.debitoAutomatico) result.debitoAutomatico = userData.debitoAutomatico;
  if (userData.textos) result.textos = userData.textos;

  // Override scalars
  if (userData.vigenciaCoberturas !== undefined) result.vigenciaCoberturas = userData.vigenciaCoberturas;
  if (userData.fechaInicio) result.fechaInicio = userData.fechaInicio;
  if (userData.fechaFin) result.fechaFin = userData.fechaFin;
  if (userData.riesgoId) result.riesgoId = userData.riesgoId;

  // Limpiar placeholders __USUARIO__ que no fueron reemplazados
  const cleanPlaceholders = (obj) => {
    for (const key of Object.keys(obj)) {
      if (typeof obj[key] === 'string' && obj[key].startsWith('__USUARIO')) {
        obj[key] = "0"; // valor seguro por defecto
      }
    }
  };

  if (result.datosFijos) cleanPlaceholders(result.datosFijos);
  if (result.datosVariablesPoliza) cleanPlaceholders(result.datosVariablesPoliza);
  if (result.datosVariablesRiesgo) cleanPlaceholders(result.datosVariablesRiesgo);
  if (result.datosVariablesAlternativa) cleanPlaceholders(result.datosVariablesAlternativa);

  // Eliminar _meta del template si existe
  delete result._meta;

  return result;
}

// --- MAIN ---
function main() {
  const args = process.argv.slice(2);
  
  // Parse flags
  let inputPath = null;
  let outputPath = null;
  let templatePath = null;
  let metadataPath = null;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--template' && args[i + 1]) {
      templatePath = path.resolve(args[++i]);
    } else if (args[i] === '--metadata' && args[i + 1]) {
      metadataPath = path.resolve(args[++i]);
    } else if (!inputPath) {
      inputPath = path.resolve(args[i]);
    } else if (!outputPath) {
      outputPath = path.resolve(args[i]);
    }
  }

  if (!inputPath) {
    console.error("Uso: node build-emision-json.js <input.json> [output.json] [--template template.json] [--metadata metadata.json]");
    process.exit(1);
  }

  let input = JSON.parse(fs.readFileSync(inputPath, 'utf8'));

  // Si hay template, hacer merge
  if (templatePath) {
    const template = JSON.parse(fs.readFileSync(templatePath, 'utf8'));
    input = mergeWithTemplate(template, input);
    console.error(`📋 Template aplicado: ${path.basename(templatePath)}`);
  }

  // Validaciones básicas
  const errors = validate(input);
  if (errors.length > 0) {
    console.error("❌ Errores de validación:");
    errors.forEach(e => console.error(`   - ${e}`));
    process.exit(1);
  }

  // Validaciones con metadata (dry-run)
  if (metadataPath) {
    const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
    const warnings = validateWithMetadata(input, metadata);
    if (warnings.length > 0) {
      console.error(`⚠️  Validación con metadata (${warnings.length} problemas):`);
      warnings.forEach(w => console.error(`   - ${w}`));
      // Exit code 2 = errores de validación corregibles (no fatales si se usa --force)
      if (!args.includes('--force')) {
        console.error("\n   Usa --force para generar de todas formas, o corrige los problemas.");
        process.exit(2);
      }
      console.error("\n   --force activo: generando JSON a pesar de las advertencias.");
    } else {
      console.error("✅ Validación con metadata: sin problemas detectados");
    }
  }

  // Construir JSON final
  const output = {
    typProceso: input.typProceso,
    registros: buildRegistros(input)
  };

  const jsonStr = JSON.stringify(output, null, 2);

  if (outputPath) {
    fs.writeFileSync(outputPath, jsonStr, 'utf8');
    console.log(`✅ JSON generado: ${outputPath}`);
    console.log(`   Registros: ${output.registros.length}`);
  } else {
    process.stdout.write(jsonStr);
  }
}

main();
