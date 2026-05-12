# Workflow de Registro de Tiempos en Jira — Tribu Corex

## Regla Fundamental: Preguntar Proyecto y Epic

⚠️ **NUNCA asumir el proyecto ni el epic.** Cada miembro del equipo trabaja en tableros distintos:
- Emisión (GD986), Modificación (GD980), Cotización (GD981), Siniestros (GD987), etc.
- Cada proyecto tiene sus propios epics.

**SIEMPRE preguntar al usuario** en qué proyecto y bajo qué epic crear la Historia, a menos que ya lo haya indicado en la sesión actual.

## Estructura obligatoria

```
Epic (<PROJECT_KEY>-XXX — indicado por el usuario)
  └── Historia (ej: GD986-1254)
        ├── Vínculos: MDSB-XXXXX (casos origen)
        ├── Link Confluence: página técnica
        └── Sub-tarea (ej: GD986-1258 "Análisis causa raíz")
              ├── Estimación: Xh (originalEstimate)
              └── Worklogs: tiempo real trabajado
```

## Pasos para crear un caso nuevo

### 0. Identificar el usuario actual (OBLIGATORIO antes de crear issues)

Antes de crear cualquier Historia o Sub-tarea, obtener el perfil del usuario:

```
jira_get_user_profile(user_identifier="<email del usuario>")
```

Guardar el `accountId` o `email` para usarlo como `assignee` en todos los issues de la sesión.

**REGLA:** Toda Historia y Sub-tarea creada DEBE tener `assignee` = el usuario que está trabajando. NUNCA dejar el assignee por defecto del proyecto.

### 1. Crear la Historia

```json
{
  "project_key": "<PROJECT_KEY>",
  "issue_type": "Historia",
  "assignee": "<email del usuario>",
  "additional_fields": {
    "parent": {"key": "<EPIC_KEY>"},
    "customfield_13801": {"value": "Funcional"},
    "customfield_10332": {"version": 1, "type": "doc", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "CA1: ..."}]}]},
    "customfield_31136": [{"workspaceId": "07e9b295-4dbf-4d90-a54e-3498d6f16eb4", "id": "07e9b295-4dbf-4d90-a54e-3498d6f16eb4:419497", "objectId": "419497"}]
  }
}
```

### 2. Vincular los MDSB relacionados

```
Link type: "Relacionado"
```

### 3. Crear Sub-tarea con estimación

```json
{
  "project_key": "<PROJECT_KEY>",
  "issue_type": "Sub-tarea",
  "assignee": "<email del usuario>",
  "additional_fields": {
    "parent": {"key": "<HU_KEY>"},
    "timetracking": {"originalEstimate": "Xh"}
  }
}
```

Subtareas típicas:
- "Análisis causa raíz" (4h)
- "Desarrollo/Codificación" (8h)
- "Pruebas" (4h)
- "Documentación Confluence" (2h)
- "Despliegue y validación" (2h)

### 4. Registrar tiempo en la Sub-tarea

```
SIEMPRE en la sub-tarea, NUNCA en la historia.
Incluir descripción de lo realizado.
```

## Recordatorio al final de cada sesión

1. ¿Registramos el tiempo de esta sesión?
2. ¿Sub-tarea existente o nueva?
3. ¿Cuánto tiempo estimás? (sugerir basado en la sesión)
