# Shared Knowledge

Memorias Engram exportadas por el equipo. Se sincronizan via Git.

## Contenido

| Archivo | Descripción | Memorias |
|---|---|---|
| `decisions.md` | Decisiones técnicas y de arquitectura del power | #53, #47, #28, #17 |
| `architecture-facturacion.md` | Flujo completo de facturación de endosos en Tronador | #50, #55, #61 |
| `patterns-bugfixes.md` | Patrones de problemas conocidos y bugfixes resueltos | #65, #63, #37, #56 |
| `sessions-summary.md` | Resúmenes de sesiones significativas | #64, #57 |

## Estadísticas

- **Proyecto:** tronador-oracle-db
- **Total observaciones:** 65
- **Total sesiones:** 17
- **Última exportación:** 2026-05-12

## Uso

El comando "actualiza conocimiento" en Kiro exporta aquí automáticamente.

Manualmente:
```bash
bash powers/corex-n3/scripts/engram-sync.sh export
git add shared-knowledge/
git commit -m "docs: sync engram"
git push
```
