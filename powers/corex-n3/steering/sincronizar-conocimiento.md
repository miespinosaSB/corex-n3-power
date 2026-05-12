---
inclusion: auto
---

# Sincronizar Conocimiento

## Activación

Cuando el usuario diga: "actualiza conocimiento", "sincroniza KB", "comparte lo aprendido", "exporta engram", o variantes similares.

## Flujo

### Paso 1 — Exportar Engram

Ejecutar el script de export:

```bash
bash .kiro/scripts/engram-sync.sh export
```

Si el script no existe en el proyecto actual, usar directamente:

```bash
engram export ~/.kiro/shared-knowledge/engram-export.json
```

### Paso 2 — Commit y push

```bash
git -C <ruta-repo-corex-n3-power> add .kiro/shared-knowledge/
git -C <ruta-repo-corex-n3-power> commit -m "docs: sync engram knowledge - $(date +%Y-%m-%d)"
git -C <ruta-repo-corex-n3-power> push
```

Si no se conoce la ruta del repo, preguntar al usuario.

### Paso 3 — Proponer actualización de Confluence

Revisar las memorias exportadas. Si hay:
- Diagnósticos resueltos con causa raíz confirmada
- Patrones nuevos no documentados en la KB
- Decisiones técnicas que afectan al equipo

Entonces proponer al usuario crear/actualizar la página correspondiente en Confluence:
- KB principal: page_id 1677787138
- Módulos hijos según el tema (ver IDs en POWER.md)

### Paso 4 — Confirmar

Reportar al usuario:
- ✅ Memorias exportadas (N observaciones)
- ✅ Push realizado a corex-n3-power
- ✅/❌ Confluence actualizado (si aplica)

## Reglas

- NUNCA hacer push sin confirmación del usuario
- NUNCA subir credenciales o datos PII a shared-knowledge
- Si hay conflictos en git, avisar al usuario y no forzar
