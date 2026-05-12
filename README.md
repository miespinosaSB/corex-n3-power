# corex-n3-power

Power de Kiro para la Tribu Corex — Seguros Bolívar. Asistente de soporte nivel 3 que integra Jira, Confluence, Oracle (Tronador), Engram (memoria persistente) y Context7 (documentación actualizada).

## Instalación

```bash
# 1. Clonar este repo
git clone git@github.com:miespinosaSB/corex-n3-power.git
cd corex-n3-power

# 2. Ejecutar instalador (pide credenciales, instala Engram, agentes, skills)
bash powers/corex-n3/install.sh

# 3. En Kiro: Command Palette → "Install Power from local directory"
#    Seleccionar la carpeta: powers/corex-n3/

# 4. Reiniciar Kiro

# 5. Importar conocimiento del equipo
#    Decir en el chat: "actualiza conocimiento"
#    O usar el botón "Importar Engram" en el panel de hooks
```

## Qué incluye

### Power (5 MCP Servers)

| Servidor | Función |
|---|---|
| mcp-atlassian | Jira + Confluence |
| oracle-readonly | BD desarrollo (10.1.2.76) |
| oracle-stage | BD stage (10.7.2.14) |
| engram | Memoria persistente entre sesiones |
| context7 | Documentación actualizada de librerías |

### 3 Sub-agentes

| Agente | Shortcut | Comando |
|---|---|---|
| Diagnóstico | `Ctrl+Shift+D` | "Diagnostica el caso MDSB-XXXXX" |
| Implementación | — | "Implementa el fix para GD986-XXXX" |
| Retrospectiva | — | "Retrospectiva" |

### 4 Skills (carga progresiva)

| Skill | Se activa cuando... |
|---|---|
| corex-oracle-diagnostics | Casos MDSB, errores en pólizas, consultas Oracle |
| corex-jira-workflow | Crear HU, registrar tiempos, gestionar backlog |
| corex-confluence-docs | Documentar hallazgos, crear páginas técnicas |
| corex-adapter-v3 | Crear microservicios, nuevos endpoints |

### 19 Hooks de automatización

- Protección Oracle (solo SELECT, ROWNUM obligatorio)
- Engram-first (busca diagnósticos previos antes de consultar Oracle)
- Métricas de uso (registra actividad automáticamente)
- Detección de código COBOL/Forms
- **Botones**: Exportar Engram / Importar Engram

### 3 Scripts

| Script | Uso |
|---|---|
| `engram-sync.sh export` | Exportar memorias para el equipo |
| `engram-sync.sh import` | Importar memorias de compañeros |
| `metrics-report.sh` | Reporte de uso del equipo |
| `generate-source-index.sh` | Indexar repos COBOL/Forms |

## Comandos principales

| Comando | Qué hace |
|---|---|
| "Atiende el caso MDSB-XXXXX" | Ciclo completo: diagnóstico → docs → HU → tiempos |
| "Diagnostica el caso MDSB-XXXXX" | Solo diagnóstico profundo |
| "Implementa el fix para GD986-XXXX" | Rama → cambios → colisiones → PR |
| "Crea una HU" | Historia de usuario con estructura BDD |
| "Retrospectiva" | Análisis 30 días + propuestas de mejora |
| "Consulta en prod" | Genera MDSB con SQL para bot AIOps |
| **"Actualiza conocimiento"** | Export Engram → git push → propone Confluence |

## Memoria compartida (Engram)

El equipo comparte conocimiento automáticamente:

```
Tú resuelves un caso → Engram guarda el diagnóstico
    → Dices "actualiza conocimiento"
        → Export + push + propone Confluence
            → Compañero hace pull → tiene tu conocimiento
```

O usa los botones en el panel de hooks: **Exportar Engram** / **Importar Engram**

## Actualización

```bash
git pull
bash powers/corex-n3/update.sh
```

## Estructura

```
corex-n3-power/
├── powers/corex-n3/         # El power source
│   ├── POWER.md             # Documentación interna
│   ├── GUIA-USO.md          # Guía práctica
│   ├── mcp.json             # 5 servidores MCP
│   ├── server.py            # Servidor Oracle
│   ├── install.sh           # Instalación completa
│   ├── update.sh            # Actualización
│   ├── agents/              # Agentes (install.sh → ~/.kiro/agents/)
│   ├── skills/              # Skills (install.sh → ~/.kiro/skills/)
│   ├── steering/            # 27 steering del power
│   └── steering-global/     # Política Engram (→ ~/.kiro/steering/)
├── README.md
└── CHANGELOG.md
```

## Requisitos

- Kiro IDE
- uv (Python): `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Node.js 20+ (para Context7)
- API Token Atlassian: [Crear aquí](https://id.atlassian.com/manage-profile/security/api-tokens)
- Usuario Oracle dev (solicitar a DBA)
- VPN corporativa

## Documentación detallada

- [GUIA-USO.md](powers/corex-n3/GUIA-USO.md) — Guía práctica para el día a día
- [POWER.md](powers/corex-n3/POWER.md) — Documentación técnica completa del power
- [README del power](powers/corex-n3/README.md) — Referencia técnica
