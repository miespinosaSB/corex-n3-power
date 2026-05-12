# Template Confluence - Documentación Técnica Corex

## Configuración

- **Espacio:** BDCT
- **Página padre HUs:** ID 1441136649
- **Formato:** markdown (content_format: "markdown")
- **Vincular al Jira:** `create_remote_issue_link` con relationship "documentation"

## Template

```markdown
---

### Identificación

| Campo | Descripción |
| --- | --- |
| **Código HU:** | GD986-XXXX |
| **Título:** | [Título descriptivo] |
| **Área de Desarrollo:** | Corex - Emisión |
| **Proyecto Relacionado:** | [Incidente productivo / Mejora / Optimización] |
| **Fecha de Creación:** | DD/MM/YYYY |
| **Autor:** | [Nombre] - Tribu Corex |

---

### Descripción General

> **Propósito:**
> [Qué se busca resolver]

### El Problema Detectado

[Descripción técnica con evidencia]

---

### Requerimientos o Solución Propuesta

> [Cambio propuesto con código]

### Descripción del Cambio Realizado

> [Código antes/después]

---

### Casos de Prueba Sugeridos

| Caso | Descripción | Resultado Esperado | Estado |
| --- | --- | --- | --- |
| ✅ 1 | [Escenario] | [Resultado] | 🟢/🔴 |

---

### Consultas SQL / Código Ajustado

> [Queries de validación]

---

### Casos Jira Relacionados

| Jira | Resumen |
| --- | --- |
| [MDSB-XXXXX](url) | [Descripción] |

---

### Revisión de Pares

| Campo | Información |
| --- | --- |
| **Revisado por:** | [Nombre] |
| **Fecha Revisión:** | DD/MM/YYYY |
| **Centro de Desarrollo:** | Corex |

---

### Enlaces Relacionados

- [Ticket Jira](url)
- [PR GitHub](url)

---

### Última Modificación

> **Fecha:** DD/MM/YYYY
> **Responsable:** [Nombre] - Tribu Corex
```
