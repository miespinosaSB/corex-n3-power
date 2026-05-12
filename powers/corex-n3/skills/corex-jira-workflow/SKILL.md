---
name: corex-jira-workflow
description: Gestión de Jira para Tribu Corex. Usar cuando el usuario pide crear historias de usuario (HU), registrar tiempos, gestionar backlog, transicionar issues, vincular casos, o trabajar con tableros GD980-GD989.
---

# Jira Workflow — Tribu Corex

## Crear Historia de Usuario (HU)

### Estructura BDD obligatoria

```
Como [rol]
Quiero [funcionalidad]
Para [valor de negocio]
```

Con mínimo 2 escenarios Dado-Cuando-Entonces (camino feliz + error).

### Campos obligatorios (GD986)

| Campo | ID | Formato |
|---|---|---|
| Tipo trabajo | customfield_13801 | `{"value": "Funcional"}` |
| Criterios aceptación | customfield_10332 | ADF |
| Aplicación CMDB | customfield_31136 | CMDB Tronador |
| Parent (Epic) | parent | `"<EPIC_KEY>"` — **preguntar al usuario** |

### CMDB Tronador
```json
[{"workspaceId": "07e9b295-4dbf-4d90-a54e-3498d6f16eb4", "id": "07e9b295-4dbf-4d90-a54e-3498d6f16eb4:419497", "objectId": "419497"}]
```

### Formato ADF para criterios
```json
{"version": 1, "type": "doc", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "CA1: ..."}]}]}
```

## Registrar tiempos

- Tiempo SIEMPRE en Sub-tareas (nunca en Historia)
- Sub-tarea con estimación (`originalEstimate`)
- Worklog con descripción de lo realizado
- Formato: `"1h 30m"`, `"2h"`, `"30m"`

## Tableros disponibles

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

## Vincular issues

- Link type: `"Relacionado"` (id: 10003) — NO "Relates to"
- Remote links para Confluence: `jira_create_remote_issue_link`

## Gestión de backlog

1. Traer casos con JQL (lotes de 45)
2. Categorizar y encontrar duplicados
3. Cerrar duplicados con comentario + vínculo al padre
