# Shared Knowledge — Tronador Oracle DB

Este directorio contiene conocimiento compartido entre el equipo, generado automáticamente o manualmente.

## Archivos

| Archivo | Descripción | Generado por |
|---|---|---|
| `source-index.json` | Índice de programas COBOL y pantallas Forms disponibles | `scripts/generate-source-index.sh` |

## Cómo regenerar el índice de fuentes

```bash
bash .kiro/scripts/generate-source-index.sh
```

**Prerrequisito:** Los repos `tronador-core-cobol` y `tronador-forms` deben estar clonados en el mismo directorio padre que `tronador-oracle-db`.

## Uso por el agente

El agente usa `source-index.json` para:
1. Saber qué programas COBOL/Forms existen sin hacer `find` cada vez
2. Mapear nombres de programas a módulos funcionales
3. Determinar rápidamente si un programa mencionado en un caso Jira tiene código fuente disponible

## Actualización

Ejecutar el script después de hacer `git pull` en los repos de COBOL o Forms para mantener el índice actualizado.
