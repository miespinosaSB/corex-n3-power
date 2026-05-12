# Engram — Política de Memoria Persistente

## Regla Principal

Engram es la memoria persistente entre sesiones. Está disponible como servidor MCP (`engram`) con herramientas `mem_*`. Usarlo SIEMPRE que se trabaje en cualquier proyecto.

## Al Inicio de Cada Sesión

1. Llamar `mem_current_project` para detectar el proyecto actual
2. Llamar `mem_context` para recuperar sesiones y observaciones recientes
3. Si hay contexto relevante, usarlo para evitar repetir trabajo

## Durante la Sesión

Guardar en Engram (`mem_save`) cuando ocurra cualquiera de estos eventos:
- Se resuelve un incidente o bug (causa raíz + solución)
- Se descubre un patrón técnico reutilizable
- Se toma una decisión de arquitectura o diseño
- Se encuentra una query Oracle útil
- Se documenta un procedimiento o runbook
- Se identifica un gotcha o edge case

Formato obligatorio para `mem_save`:
```
title: "Descripción corta y buscable"
type: decision | architecture | bugfix | pattern | discovery | learning
content: "**What**: ...\n**Why**: ...\n**Where**: ...\n**Learned**: ..."
```

## Al Finalizar Sesión Significativa

Llamar `mem_session_summary` con el formato Goal/Discoveries/Accomplished/Next Steps cuando:
- Se completó un diagnóstico de incidente
- Se implementó una feature completa
- Se hizo un análisis de impacto extenso
- La sesión duró más de 30 minutos de trabajo activo

## Sincronización con Confluence

Cuando se genera conocimiento que beneficia al equipo (no solo al individuo):
1. Persistir primero en Engram (inmediato, local)
2. Preguntar al usuario si quiere subir a Confluence
3. Si aprueba → usar `confluence_create_page` o `confluence_update_page` con el template del equipo

## Qué NO Guardar

- Credenciales, tokens o secretos
- Datos PII de clientes o pólizas reales
- Contenido completo de packages Oracle (demasiado grande)
- Información efímera sin valor de reuso
