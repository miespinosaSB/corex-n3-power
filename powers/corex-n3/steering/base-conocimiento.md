---
inclusion: auto
---

# Base de Conocimiento - Contexto Persistente

## Fuente de Verdad

La base de conocimiento del equipo se mantiene en Confluence:
- **Página:** "Base de Conocimiento - Agente N3 Corex"
- **ID:** 1677787138
- **Espacio:** BDCT
- **URL:** https://jirasegurosbolivar.atlassian.net/wiki/spaces/BDCT/pages/1677787138

## Cuándo Consultar

SIEMPRE consultar la base de conocimiento (confluence_get_page con page_id 1677787138) cuando:
1. Se va a trabajar con una tabla que no se conoce bien
2. Se necesita entender relaciones entre tablas
3. Se va a modificar un paquete o procedimiento
4. Se encuentra un patrón de problema recurrente
5. Se necesita contexto sobre un proceso de negocio

### Páginas hijas — Conocimiento Operativo

| Página | Page ID | Cuándo consultar |
|---|---|---|
| Arquitectura Servicios y Paquetes | 1688338434 | Flujo de servicios, consumidores de paquetes, análisis de impacto |
| Patrones de Problemas y Hallazgos | 1688371201 | Problemas recurrentes, lecciones aprendidas, consultas de diagnóstico |

**Flujo recomendado al recibir un caso:**
1. Leer página principal (1677787138) → identificar tablas y módulo involucrado
2. Si es un problema recurrente → leer Patrones de Problemas (1688371201)
3. Si se va a modificar código → leer Arquitectura Servicios (1688338434) para análisis de impacto
4. Si se necesita detalle de columnas → leer la página del módulo correspondiente

### Páginas hijas — Diccionario de Datos por Módulo

Cuando se necesite detalle de columnas de un módulo específico, consultar la página hija correspondiente:

| Módulo | Page ID | Cuándo consultar |
|---|---|---|
| Parámetros Generales (A1xxx) | 1677885457 | Terceros, monedas, sucursales, SIPLA/SARLAFT |
| Emisión (A2xxx) | 1679654913 | Pólizas, riesgos, coberturas, facturas, cuotas |
| Siniestros (A4xxx) | 1678475266 | Juicios, siniestros, indemnizaciones |
| Tesorería/Recaudo (A5xxx) | 1678311427 | Recaudos, órdenes de pago, transferencias |
| Reaseguros (A8xxx) | 1679556610 | Cesión, facturación, cuenta corriente reaseguros |
| Fondos Vida (A9xxx) | 1677819908 | Movimientos, saldos, traslados fondo vida |
| VPA Fondos (SB_xxx) | 1678311447 | Recaudos VPA, débito automático, retiros, saldos |

Ejemplo: si el incidente involucra SB_RECAUDO → consultar page_id 1678311447 para ver todas las columnas.

## Cuándo Actualizar

Actualizar la página hija correspondiente cuando:
1. Se descubre un patrón de problema nuevo → actualizar **Patrones de Problemas** (1688371201)
2. Se identifica un paquete/procedimiento o servicio → actualizar **Arquitectura Servicios** (1688338434)
3. Se descubre información de columnas/tablas → actualizar la **página del módulo** correspondiente
4. Se descubre una referencia rápida útil → actualizar la **página principal** (1677787138)

**NO meter todo en la página principal.** Usar las páginas hijas para el detalle.

## Formato de Actualización

Al actualizar cualquier página de la KB, SIEMPRE:
1. Leer el contenido actual primero (confluence_get_page)
2. Agregar la nueva información en la sección correspondiente de la **página hija correcta**
3. Mantener el formato markdown existente
4. Actualizar la fecha de última actualización
5. No eliminar información existente, solo agregar o corregir

## Tableros Jira Disponibles

El power NO está limitado al tablero de emisión (GD986). Los tableros disponibles son:

| Tablero | ID | Proyecto |
|---|---|---|
| TableroGD980 | 4524 | GD980 |
| TableroGD981 | 4525 | GD981 |
| TableroGD982 | 4526 | GD982 |
| TableroGD983 | 4527 | GD983 |
| TableroGD984 | 4626 | GD984 |
| TableroGD986 | 4660 | GD986 (Emisión) |
| TableroGD987 | 4661 | GD987 |
| TableroGD988 | 4793 | GD988 |
| Tablero GD989 | 5293 | GD989 |

Cuando el usuario mencione un proyecto diferente a GD986, usar el tablero correspondiente.

## Diccionario de Datos

La tabla `OPS$PUMA.A1000000` contiene el diccionario maestro de Tronador:
- Columna `TABLA`: nombre de la tabla
- Columna `COLUMNA`: nombre de la columna (si es '1TABLA', el COMENTARIO describe la tabla)
- Columna `COMENTARIO`: descripción
- Columna `MCA_BAJA`: si es NULL, el registro está activo

Para buscar información de una tabla desconocida:
```sql
SELECT COLUMNA, COMENTARIO 
FROM OPS$PUMA.A1000000 
WHERE TABLA = :NOMBRE_TABLA 
AND MCA_BAJA IS NULL 
ORDER BY COLUMNA
```

## Directriz: Actualización Automática al Finalizar Sesión

Al finalizar cada sesión de trabajo donde se haya descubierto información nueva y relevante, el agente DEBE:

1. Identificar qué página hija corresponde (Patrones, Arquitectura, o Módulo de datos)
2. Leer la página hija actual (confluence_get_page con el page_id correspondiente)
3. Agregar la información nueva en la sección correspondiente
4. Actualizar la fecha de última actualización
5. Guardar con confluence_update_page

Solo agregar información verificada y reutilizable. NO agregar datos específicos de un caso (números de póliza, documentos personales, etc.).

### Alimentación desde código fuente (COBOL, Forms, PL/SQL)

Cuando durante un diagnóstico se lea código fuente de los repositorios locales y se descubra:
- Un flujo de negocio no documentado → documentar en la página del módulo
- Un programa COBOL clave y sus dependencias → documentar en Arquitectura Servicios
- Una validación de Forms que causa errores frecuentes → documentar en Patrones de Problemas
- Relaciones entre tablas descubiertas en el código → documentar en la página del módulo

**Meta:** Que la KB sea tan rica que la mayoría de diagnósticos futuros NO requieran leer código fuente de nuevo. Cada lectura de código es una oportunidad de enriquecer la KB.

## Directriz: Comando Manual "Agregar a Base de Conocimiento"

Cuando el usuario diga "agregar a base de conocimiento", "documentar hallazgo", "agregar al KB", o similar:

1. Preguntar qué información quiere agregar
2. Identificar la página hija correcta:
   - Patrón de problema / lección aprendida / consulta SQL → **Patrones de Problemas** (1688371201)
   - Servicio / paquete / dependencia / arquitectura → **Arquitectura Servicios** (1688338434)
   - Columnas / tablas / relaciones de datos → **Página del módulo** correspondiente
   - Referencia rápida general → **Página principal** (1677787138)
3. Leer la página hija actual desde Confluence
4. Agregar la información manteniendo el formato markdown
5. Actualizar la fecha de última actualización
6. Guardar con confluence_update_page
7. Confirmar al usuario qué se agregó y en qué página

Si el usuario pega código SQL, resultados de queries, o descripciones de procesos, extraer la información relevante y agregarla de forma estructurada.
