---
name: corex-confluence-docs
description: Documentación técnica en Confluence para Tribu Corex. Usar cuando el usuario pide documentar hallazgos, crear páginas técnicas, actualizar la base de conocimiento, o generar documentación de incidentes.
---

# Confluence Docs — Tribu Corex

## Espacio y páginas

- **Espacio:** BDCT (Vicepresidencia de TI)
- **KB principal:** Page ID 1677787138
- **Página padre HUs:** ID 1441136649

### Módulos documentados (páginas hijas de KB)

| Módulo | Page ID | Prefijo |
|---|---|---|
| Parámetros Generales y Terceros | 1677885457 | A1xxx |
| Emisión | 1679654913 | A2xxx |
| Siniestros e Indemnizaciones | 1678475266 | A4xxx |
| Tesorería y Recaudo | 1678311427 | A5xxx |
| Reaseguros | 1679556610 | A8xxx |
| Fondos Vida | 1677819908 | A9xxx |
| VPA Fondos | 1678311447 | SB_xxx |

## Template estándar para documentar hallazgos

```markdown
# [Título del hallazgo]

## Contexto
- **Caso(s) Jira:** MDSB-XXXXX
- **Módulo:** [Emisión/Recaudo/Siniestros/etc.]
- **Fecha:** YYYY-MM-DD

## Problema
[Descripción del problema encontrado]

## Análisis
[Qué se investigó, tablas consultadas, código revisado]

## Causa raíz
[Explicación técnica de la causa]

## Solución
[Qué se hizo o qué se recomienda hacer]

## Tablas/Objetos involucrados
| Objeto | Tipo | Rol |
|---|---|---|
| ... | TABLE/PACKAGE/PROCEDURE | ... |

## Lecciones aprendidas
- [Punto 1]
- [Punto 2]
```

## Flujo de documentación

1. Crear página con `confluence_create_page`
   - `space_key`: "BDCT"
   - `parent_page_id`: ID del módulo correspondiente
2. Vincular desde Jira con `jira_create_remote_issue_link`
3. Actualizar KB si se descubrió un patrón nuevo

## Sincronización con Engram

- Persistir primero en Engram (inmediato, local)
- Subir a Confluence cuando el diagnóstico está completo
- Confluence = fuente canónica del equipo
