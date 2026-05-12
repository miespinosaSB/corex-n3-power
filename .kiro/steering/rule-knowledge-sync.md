---
inclusion: manual
---

# Knowledge Base Sync — Engram + Confluence

## Arquitectura de Conocimiento

```
Confluence (fuente canónica)
    ↕ sincronización bidireccional
Engram (caché local inteligente)
    ↕ consulta/persistencia automática
Agente Kiro (sesión activa)
```

## Roles

| Componente | Rol | Retención |
|---|---|---|
| Confluence | Fuente de verdad. KB oficial del equipo. | Permanente |
| Engram | Memoria de trabajo. Contexto rápido entre sesiones. | Local, se puede reconstruir |

## Política de Sincronización

### Confluence → Engram (lectura)

Cuando el agente necesita contexto sobre:
- Runbooks de incidentes conocidos
- Patrones de packages Oracle documentados
- Decisiones de arquitectura del equipo
- Procedimientos de soporte N3

**Flujo:**
1. Buscar primero en Engram (rápido, local)
2. Si no hay resultado o el dato tiene más de 7 días → consultar Confluence
3. Persistir el resultado actualizado en Engram con metadata de origen

### Engram → Confluence (escritura)

Cuando se resuelve un incidente o se descubre un patrón nuevo:
1. Persistir inmediatamente en Engram (para la sesión actual)
2. Proponer al usuario crear/actualizar página en Confluence
3. Si el usuario aprueba → crear/actualizar en Confluence con el contenido estructurado

### Qué guardar en Engram

- Diagnósticos de incidentes resueltos (resumen + causa raíz + solución)
- Mapeo de packages Oracle relevantes (nombre → propósito → dependencias clave)
- Queries útiles reutilizables
- Decisiones técnicas tomadas en sesión
- Contexto de proyecto activo (qué estamos trabajando)

### Qué NO guardar en Engram

- Credenciales o tokens
- Datos PII de clientes
- Contenido completo de packages (demasiado grande, consultar Oracle directo)
- Información temporal sin valor de reuso

## Formato de Memoria en Engram

```json
{
  "category": "incident|pattern|decision|query|context",
  "source": "confluence|session|oracle",
  "confluence_page_id": "123456789",
  "created": "2026-05-12",
  "summary": "Descripción corta",
  "content": "Detalle estructurado"
}
```

## Cadencia de Refresco

- **Inicio de sesión**: consultar Engram para contexto previo
- **Cada incidente resuelto**: persistir en Engram + proponer Confluence
- **Semanal (manual)**: el usuario puede pedir "sincroniza KB" para refrescar Engram con las últimas páginas de Confluence del espacio Corex
