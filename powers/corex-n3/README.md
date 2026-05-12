# Power corex-n3 — Agente N3 Tribu Corex

Asistente de soporte nivel 3 para la Tribu Corex en Seguros Bolívar. Integra Jira, Confluence, Oracle (Tronador), Engram (memoria persistente) y Context7 (documentación actualizada) para diagnóstico de incidentes, gestión de backlog, documentación técnica, y generación de microservicios.

## Instalación rápida

```bash
# 1. Prerrequisitos (credenciales, Engram, agentes, skills)
bash powers/corex-n3/install.sh

# 2. Instalar el power en Kiro
#    Command Palette → "Install Power from local directory" → powers/corex-n3/

# 3. Reiniciar Kiro
```

## Qué incluye

### 5 Servidores MCP

| Servidor | Función |
|---|---|
| `mcp-atlassian` | Jira + Confluence (gestión de incidentes, documentación) |
| `oracle-readonly` | BD desarrollo (10.1.2.76) — consultas, código PL/SQL |
| `oracle-stage` | BD stage (10.7.2.14) — validación pre-producción |
| `engram` | Memoria persistente entre sesiones (SQLite local) |
| `context7` | Documentación actualizada de librerías (Spring Boot, etc.) |

### 3 Sub-agentes especializados

| Agente | Shortcut | Uso |
|---|---|---|
| `corex-incident-diagnostics` | `Ctrl+Shift+D` | "Diagnostica el caso MDSB-XXXXX" |
| `corex-implementation` | — | "Implementa el fix para GD986-XXXX" |
| `corex-retrospective` | — | "Retrospectiva" / "Mejora el power" |

### 4 Skills (carga progresiva)

| Skill | Se activa cuando... |
|---|---|
| `corex-oracle-diagnostics` | Casos MDSB, errores en pólizas, consultas Oracle |
| `corex-jira-workflow` | Crear HU, registrar tiempos, gestionar backlog |
| `corex-confluence-docs` | Documentar hallazgos, crear páginas técnicas |
| `corex-adapter-v3` | Crear microservicios, nuevos endpoints, scaffold |

### 26 Steering files

Convenciones Oracle, workflows Jira, templates Confluence, estándares Adapter V3, políticas DML, diagnóstico eficiente, detección de colisiones, y más.

### Hooks de protección

| Hook | Función |
|---|---|
| `oracle-query-safety` | Valida SELECT-only + ROWNUM antes de ejecutar |
| `engram-first-diagnostic` | Busca en Engram antes de consultar Oracle |
| `cobol-forms-lookup` | Enriquece diagnósticos con código fuente legacy |
| `usage-metrics` | Registra uso de herramientas para métricas |
| `session-end-metrics` | Persiste métricas al terminar sesión |

### Scripts de utilidad

| Script | Uso |
|---|---|
| `engram-sync.sh export` | Exportar memorias para compartir con el equipo |
| `engram-sync.sh import` | Importar memorias de compañeros |
| `metrics-report.sh` | Reporte de uso (diagnósticos, tiempos, herramientas) |
| `generate-source-index.sh` | Indexar repos COBOL/Forms para diagnóstico |

## Comandos principales

| Comando | Qué hace |
|---|---|
| "Atiende el caso MDSB-XXXXX" | Ciclo completo: diagnóstico → documentación → HU → tiempos |
| "Diagnostica el caso MDSB-XXXXX" | Solo diagnóstico profundo con reporte |
| "Implementa el fix para GD986-XXXX" | Rama → cambios PL/SQL → colisiones → PR |
| "Crea una HU" | Historia de usuario con estructura BDD |
| "Retrospectiva" | Análisis de últimos 30 días + propuestas de mejora |
| "Consulta en prod" | Genera MDSB con SQL para bot AIOps |
| "Pre-diagnostica los pendientes" | Diagnóstico ligero de MDSB sin asignar |

## Actualización

```bash
# Actualizar sin reinstalar (mantiene credenciales)
bash powers/corex-n3/update.sh
```

Si se modificó el `mcp.json` del power (nuevos servidores), hay que desinstalar y reinstalar desde Kiro.

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                         KIRO IDE                             │
├─────────────────────────────────────────────────────────────┤
│  Power corex-n3                                             │
│  ├── MCP Servers (Atlassian, Oracle×2, Engram, Context7)    │
│  ├── Steering (26 archivos de convenciones)                 │
│  └── Skills (4 skills con carga progresiva)                 │
├─────────────────────────────────────────────────────────────┤
│  Sub-agentes                                                │
│  ├── corex-incident-diagnostics (Ctrl+Shift+D)              │
│  ├── corex-implementation                                   │
│  └── corex-retrospective                                    │
├─────────────────────────────────────────────────────────────┤
│  Hooks (17 hooks de protección y automatización)            │
├─────────────────────────────────────────────────────────────┤
│  Scripts (sync, métricas, índice de fuentes)                │
├─────────────────────────────────────────────────────────────┤
│  Engram (memoria persistente — ~/.engram/engram.db)         │
│  └── Seed: tablas, packages, patrones de problemas          │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
   Oracle Tronador      Jira/Confluence      Context7 Docs
   (OPS$PUMA)           (Atlassian Cloud)    (Spring Boot, etc.)
```

## Memoria compartida (Engram)

Engram es la memoria persistente del equipo. Cada diagnóstico resuelto, patrón descubierto, o decisión técnica se guarda automáticamente.

```bash
# Exportar tu conocimiento para el equipo
bash powers/corex-n3/scripts/engram-sync.sh export

# Importar conocimiento de compañeros
bash powers/corex-n3/scripts/engram-sync.sh import
```

La carpeta `shared-knowledge/` contiene las memorias exportadas que se comparten via Git.

## Métricas

```bash
# Reporte de la última semana
bash powers/corex-n3/scripts/metrics-report.sh --period week

# Reporte del último mes
bash powers/corex-n3/scripts/metrics-report.sh --period month
```

## Estructura del power

```
powers/corex-n3/
├── POWER.md              # Documentación completa del power
├── README.md             # Este archivo
├── mcp.json              # 5 servidores MCP (portable con .env)
├── server.py             # Servidor Oracle MCP (Python)
├── install.sh            # Instalación completa (macOS/Linux)
├── install.ps1           # Instalación (Windows)
├── update.sh             # Actualización sin reinstalar
├── agents/               # 3 sub-agentes (diagnóstico, implementación, retrospectiva)
├── skills/               # 4 skills (Oracle, Jira, Confluence, Adapter V3)
├── steering/             # 26 archivos de convenciones y workflows
└── steering-global/      # Política de Engram (se instala en ~/.kiro/steering/)
```

## Requisitos

- **Kiro IDE** instalado
- **uv** (gestor Python): `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **Node.js 20+** (para Context7): via nvm o instalador
- **API Token Atlassian**: [Crear aquí](https://id.atlassian.com/manage-profile/security/api-tokens)
- **Usuario Oracle** dev (solicitar a DBA)
- **VPN corporativa** activa (para acceso a Oracle)

## Troubleshooting

| Problema | Solución |
|---|---|
| Oracle no conecta | Verificar VPN + credenciales en `~/.kiro/settings/.env` |
| Engram no responde | Verificar `~/.local/bin/engram version` |
| Context7 falla | Verificar `npx -y @upstash/context7-mcp@latest --help` |
| Power no aparece en Kiro | Reinstalar: Command Palette → "Install Power from local directory" |
| server.py no existe | Ejecutar `bash update.sh` o copiar manualmente |

## Contribuir

1. Crear rama desde `powers` (no `master`)
2. Hacer cambios en `powers/corex-n3/`
3. Probar con `bash update.sh`
4. PR hacia `powers`
