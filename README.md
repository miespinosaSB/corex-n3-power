# corex-n3-power

Power de Kiro para la Tribu Corex — Seguros Bolívar. Asistente de soporte nivel 3 que integra Jira, Confluence, Oracle (Tronador), Engram (memoria persistente) y Context7 (documentación actualizada).

## Instalación rápida

```bash
# 1. Clonar este repo
git clone git@github.com:miespinosaSB/corex-n3-power.git
cd corex-n3-power

# 2. Ejecutar instalador (pide credenciales, instala Engram, agentes, skills)
bash powers/corex-n3/install.sh

# 3. En Kiro: Command Palette → "Install Power from local directory"
#    Seleccionar: <ruta>/corex-n3-power/powers/corex-n3/

# 4. Reiniciar Kiro

# 5. Importar conocimiento del equipo
bash .kiro/scripts/engram-sync.sh import
```

## Qué incluye

- **5 MCP Servers**: Atlassian, Oracle dev, Oracle stage, Engram, Context7
- **3 Sub-agentes**: Diagnóstico (`Ctrl+Shift+D`), Implementación, Retrospectiva
- **4 Skills**: Oracle Diagnostics, Jira Workflow, Confluence Docs, Adapter V3
- **26 Steering files**: Convenciones, workflows, políticas
- **17 Hooks**: Protección Oracle, métricas, Engram-first
- **3 Scripts**: Sync Engram, métricas, índice COBOL/Forms

## Documentación

- [README del power](powers/corex-n3/README.md) — Referencia técnica completa
- [Guía de uso](powers/corex-n3/GUIA-USO.md) — Guía práctica para el día a día
- [POWER.md](powers/corex-n3/POWER.md) — Documentación interna del power

## Comandos principales

| Comando | Qué hace |
|---|---|
| "Atiende el caso MDSB-XXXXX" | Ciclo completo: diagnóstico → docs → HU → tiempos |
| "Diagnostica el caso MDSB-XXXXX" | Solo diagnóstico profundo |
| "Implementa el fix para GD986-XXXX" | Rama → cambios → colisiones → PR |
| "Crea una HU" | Historia de usuario con estructura BDD |
| "Retrospectiva" | Análisis 30 días + propuestas de mejora |

## Memoria compartida (Engram)

```bash
# Exportar tu conocimiento para el equipo
bash .kiro/scripts/engram-sync.sh export
git add .kiro/shared-knowledge/
git commit -m "docs: sync engram knowledge"
git push

# Importar conocimiento de compañeros
git pull
bash .kiro/scripts/engram-sync.sh import
```

## Actualización

```bash
git pull
bash powers/corex-n3/update.sh
```

## Requisitos

- Kiro IDE
- uv (Python): `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Node.js 20+ (para Context7)
- API Token Atlassian
- Usuario Oracle dev
- VPN corporativa
