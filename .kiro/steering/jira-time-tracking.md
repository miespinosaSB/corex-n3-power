---
inclusion: manual
---

# Reporte de Tiempos en Jira (Clockwork)

## Reglas Generales

- Herramienta de tracking: **Clockwork** (plugin de Jira)
- Horario laboral: **8:00 AM - 5:00 PM** (Colombia, America/Bogota)
- Almuerzo: **1 hora** (generalmente 12:00 - 1:00 PM)
- Horas efectivas por día: **8 horas**
- Jornada semanal: Lunes a Viernes

## Distribución de Tiempos

### Respetar reuniones
- Antes de reportar tiempos de un día, el usuario debe indicar las reuniones/bloques ocupados del día
- Las reuniones ya están sincronizadas en Clockwork desde el calendario
- Los worklogs de trabajo se distribuyen en los espacios libres entre reuniones
- NUNCA solapar worklogs con reuniones

### Ejemplo de distribución
Si un día tiene:
- 9:00-10:00 Daily standup
- 2:00-3:00 Refinamiento

Entonces hay 6h disponibles para trabajo:
- 8:00-9:00 (1h)
- 10:00-12:00 (2h)
- 1:00-2:00 (1h) (después de almuerzo)
- 3:00-5:00 (2h)

## Tipo de Actividad (Work Attribute de Clockwork)

El campo "Actividad" es OBLIGATORIO en Clockwork. Catálogo disponible:

| Actividad | Cuándo usar |
|---|---|
| Arquitectura | Diseño de solución, definición técnica, PoC, evaluación de tecnologías |
| Desarrollo | Codificación, implementación de features, bug fixes, refactoring |
| QA | Pruebas manuales, validación funcional |
| QA - Automatización | Pruebas automatizadas, scripts de testing |
| QA - Pruebas no funcionales | Performance, seguridad, carga |
| Procesos | Documentación, estandarización, configuración de herramientas |
| Planning | Planificación de sprint, estimación, grooming/refinamiento |
| Review | Code review, revisión de PRs, revisión técnica |
| Retrospectiva | Ceremonias de retrospectiva |

### Cómo registrar la actividad

Como la API de Jira no soporta el campo "Actividad" de Clockwork directamente, se usa esta convención:

1. Incluir el tipo de actividad como **prefijo en el comentario** del worklog:
   - Formato: `[TipoActividad] Descripción del trabajo realizado`
   - Ejemplo: `[Desarrollo] Implementación endpoints REST para cotizador autos`
   - Ejemplo: `[Arquitectura] Diseño de la integración SOAP con servicios legacy`
   - Ejemplo: `[Procesos] Configuración steering docs y hooks en Kiro`

2. El usuario luego selecciona el tipo de actividad correspondiente en la UI de Clockwork

## Formato del Worklog

Al registrar un worklog vía `jira_add_worklog`:

- **time_spent**: En formato Jira (ej: "2h", "1h 30m", "1d")
- **started**: Fecha y hora ISO 8601 con timezone Colombia (ej: "2026-04-21T08:00:00.000-0500")
- **comment**: `[TipoActividad] Descripción concisa del trabajo`

## Flujo de Reporte

1. El usuario indica el período a reportar (día, semana, etc.)
2. El usuario indica las reuniones/bloques ocupados de cada día
3. El usuario indica qué issues trabajó y qué hizo en cada uno
4. Se calcula el tiempo disponible descontando reuniones y almuerzo
5. Se distribuyen las horas entre los issues
6. Se registran los worklogs con hora de inicio real (no todo a las 9:00)
7. Cada worklog lleva el prefijo de tipo de actividad en el comentario

## Consideraciones

- 1 día Jira = 7h (configuración estándar Jira)
- Si el usuario no especifica tipo de actividad, inferirlo del contexto:
  - Trabajo en código → Desarrollo
  - Diseño de solución → Arquitectura
  - Documentación/herramientas → Procesos
  - Revisión de código → Review
  - Pruebas → QA
- Las reuniones de planning, daily, refinamiento se reportan como Planning
- Las retrospectivas se reportan como Retrospectiva
