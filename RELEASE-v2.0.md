# 🚀 Power corex-n3 — Actualización Mayor (v2.0)

## Nuevo repositorio dedicado

El power se migró a su propio repositorio. **Ya no vive en `tronador-oracle-db`.**

```
📦 Repo: git@github.com:miespinosaSB/corex-n3-power.git
🌐 URL:  https://github.com/miespinosaSB/corex-n3-power
```

## Instalación (primera vez)

```bash
# 1. Clonar
git clone git@github.com:miespinosaSB/corex-n3-power.git
cd corex-n3-power

# 2. Instalar (pide credenciales una sola vez)
bash powers/corex-n3/install.sh      # macOS/Linux
# o
powershell powers/corex-n3/install.ps1  # Windows

# 3. En Kiro: Command Palette → "Install Power from local directory"
#    Seleccionar: powers/corex-n3/

# 4. Reiniciar Kiro
```

## Actualización (si ya lo tenías)

```bash
cd corex-n3-power
git pull
bash powers/corex-n3/update.sh       # macOS/Linux
# o
powershell powers/corex-n3/update.ps1   # Windows
# Reiniciar Kiro
```

No pide credenciales de nuevo — las mantiene del `.env` existente.

---

## Cambios y mejoras incluidos

### 🧠 Diagnóstico más preciso

- **Política CERO SUPOSICIONES** — Toda afirmación del agente debe estar respaldada por código fuente leído o datos verificados. Si no lo leyó, no lo afirma.
- **Tabla de evidencia obligatoria** en el reporte final (archivo + línea + query ejecutada).
- **Sección "No Verificado"** cuando algo no se pudo confirmar — ya no se mezclan conclusiones con hipótesis.

### 📂 Repositorios como fuente de verdad

- **Nuevo flujo de diagnóstico:** Engram → Confluence/Jira → Repo Oracle DB → Repo COBOL → Repo Forms → Oracle (solo datos)
- **Repo primero, `get_source` después** — Los packages se leen del repositorio local (`Base Datos/Packages/*.pkb`) antes de consultar Oracle. Sin truncamiento, sin límite de tamaño, sin créditos extra.
- **Los 3 repos son la lógica de negocio** — PL/SQL + COBOL (batch) + Forms (pantallas) = flujo completo. El agente busca en los 3 antes de hacer queries de datos.

### ⚡ Menos consumo de créditos

- **6 steering files de reglas** (tech-stack, libraries, security, code-style, architecture, ai-generated-code) ahora solo se cargan cuando estás editando código. En sesiones de soporte/preguntas → ~60-70% menos tokens por turno.
- **Engram no se activa automáticamente** al inicio de cada sesión. Solo cuando hay trabajo significativo.
- **Meta: ≤ 4 queries Oracle por caso** con templates SQL pre-armados y JOINs consolidados.

### 🔧 Consulta a producción arreglada

- El script de creación de MDSB ahora funciona correctamente — lee credenciales de `~/.kiro/settings/.env` (macOS/Linux) o `~/.kiro/settings/mcp.json` (Windows). Ya no falla con "credenciales no disponibles".

### 🖥️ Soporte cross-platform

- `install.sh` + `install.ps1` (macOS/Linux/Windows)
- `update.sh` + `update.ps1` (macOS/Linux/Windows)
- Script de consulta producción detecta automáticamente el OS

### 📦 Qué incluye el power

| Componente | Cantidad |
|---|---|
| MCP Servers | 5 (Jira, Confluence, Oracle dev, Oracle stage, Engram, Context7) |
| Sub-agentes | 3 (diagnóstico, implementación, retrospectiva) |
| Skills | 4 (oracle-diagnostics, jira-workflow, confluence-docs, adapter-v3) |
| Hooks | 17 (protección, automatización, métricas) |
| Steering files | 27 |
| Scripts | 3 (engram-sync, metrics-report, generate-source-index) |

---

## Comandos principales

| Dices... | El power hace... |
|---|---|
| "Atiende el caso MDSB-XXXXX" | Ciclo completo: diagnóstico → docs → HU → tiempos |
| "Diagnostica el caso MDSB-XXXXX" | Solo diagnóstico profundo |
| "Crea una HU" | Historia con estructura BDD (Dado-Cuando-Entonces) |
| "Consulta en prod" | Genera MDSB con SQL para bot AIOps |
| "Retrospectiva" | Análisis 30 días + propuestas de mejora |

---

## Requisitos

- **Kiro IDE** instalado
- **uv** (Python): `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **API Token Atlassian**: [Crear aquí](https://id.atlassian.com/manage-profile/security/api-tokens)
- **Usuario Oracle dev** (solicitar a DBA o líder técnico)
- **VPN corporativa** activa

---

¿Dudas? Escribir a Michael Espinosa o probar directamente en Kiro con "atiende el caso MDSB-XXXXX".
