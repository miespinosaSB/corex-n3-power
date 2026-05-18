# corex-emission-builder

Agente especializado en generar el JSON de entrada para el API Liviano de Emisión (`POST /api/v1/expgenerica/procesar`).

## Qué hace

1. Identifica el producto a emitir (conversacional o por códigos)
2. Recopila datos del negocio guiando al usuario con preguntas en lenguaje natural
3. Consulta Oracle para obtener la parametrización correcta (campos obligatorios, coberturas, intermediarios)
4. Ensambla el JSON con la estructura y lenguaje canónico correcto
5. Valida las reglas de negocio antes de entregar
6. Entrega el JSON al usuario (opcionalmente lo guarda como archivo)

## Cómo usarlo

```
Necesito emitir una póliza de cumplimiento para un contrato de obra
Genera una emisión de vehículos para un Honda Pilot
Quiero emitir un seguro de vida deudores
Emisión para cia 3, secc 4, prod 450
```

No necesitas conocer los códigos internos — el agente te guía.

## Prerequisitos

Este agente requiere:
- **MCP Oracle Readonly** — Conexión al ambiente de desarrollo de Tronador (configurado en el power `corex-n3`)
- **Power corex-n3 instalado** — El agente hereda la configuración MCP del power

## Herramientas que usa

- **Oracle Readonly** — Consulta `SIM_PRODUCTOS`, `G2000020`, `SIM_G2000020`, `G2000010`, `A1002100`, `INTERMEDIARIOS`, `A2990500`, `CONVENIOS_CLAVE`, `A1001700`, `CRX_EXP_GENERICA`, `A2000030`, `A2000020`, `A2000040`
- **Confluence (mcp-atlassian)** — Busca/crea memoria del producto en espacio BDCT
- **Shell** — Ejecuta `node scripts/build-emision-json.js` para generar el JSON final
- **File System** — Guarda el JSON generado y archivos de datos

## Referencia técnica

El steering file `powers/corex-n3/steering/api-liviano-emision.md` contiene:
- Endpoints y ambientes
- Estructura completa del JSON
- Campos canónicos por segmento
- Fuentes de datos Oracle
- Validaciones aplicadas
- Formatos de fecha
