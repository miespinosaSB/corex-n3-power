#!/bin/bash
# ============================================================================
# engram-sync.sh — Export de conocimiento Engram a shared-knowledge/
#
# Engram es a nivel de USUARIO (SQLite local en ~/.engram/), no por proyecto.
# Este script exporta TODO el conocimiento relevante de todos los proyectos
# a archivos markdown versionables en Git.
#
# Uso:
#   ./engram-sync.sh export              → Exporta TODOS los proyectos
#   ./engram-sync.sh export <proyecto>   → Exporta solo un proyecto
#   ./engram-sync.sh status              → Muestra estadísticas
#
# Requisitos:
#   - Python 3 con sqlite3 (viene con macOS/Linux)
#   - Engram DB en ~/.engram/engram.db
#
# Destino:
#   El export se genera en shared-knowledge/ del repo donde se ejecute.
#   Puede ejecutarse desde CUALQUIER directorio — busca el repo root via git.
# ============================================================================

set -euo pipefail

# Detectar repo root (funciona desde cualquier subdirectorio)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SHARED_DIR="$REPO_ROOT/shared-knowledge"
ENGRAM_DB="$HOME/.engram/engram.db"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_engram_db() {
    if [ ! -f "$ENGRAM_DB" ]; then
        log_error "No se encontró Engram DB en $ENGRAM_DB"
        log_info "Engram almacena todo en ~/.engram/engram.db (nivel usuario, no proyecto)"
        exit 1
    fi
    log_info "Engram DB: $ENGRAM_DB"
}

do_export() {
    local PROJECT_FILTER="${1:-}"
    check_engram_db
    mkdir -p "$SHARED_DIR"

    local DATE_NOW
    DATE_NOW=$(date +%Y-%m-%d)

    local WHERE_CLAUSE=""
    if [ -n "$PROJECT_FILTER" ]; then
        WHERE_CLAUSE="AND project = '$PROJECT_FILTER'"
        log_info "Exportando proyecto: $PROJECT_FILTER"
    else
        log_info "Exportando TODOS los proyectos"
    fi

    # Export usando Python + sqlite3 (disponible en cualquier sistema)
    python3 << PYTHON_SCRIPT
import sqlite3
import os
from datetime import datetime

db_path = "$ENGRAM_DB"
shared_dir = "$SHARED_DIR"
date_now = "$DATE_NOW"
project_filter = "$PROJECT_FILTER"

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row

# Obtener todas las observaciones activas (no borradas)
where = "WHERE deleted_at IS NULL"
if project_filter:
    where += f" AND project = '{project_filter}'"

rows = conn.execute(f"""
    SELECT id, title, type, content, project, scope, topic_key, created_at
    FROM observations
    {where}
    ORDER BY project, type, created_at DESC
""").fetchall()

if not rows:
    print(f"⚠️  No se encontraron observaciones")
    exit(0)

# Agrupar por categoría
decisions = []
architecture = []
patterns_bugfixes = []
sessions = []
other = []

for row in rows:
    entry = dict(row)
    t = entry.get('type', '')
    if t == 'decision':
        decisions.append(entry)
    elif t == 'architecture':
        architecture.append(entry)
    elif t in ('pattern', 'bugfix'):
        patterns_bugfixes.append(entry)
    elif t == 'session_summary':
        sessions.append(entry)
    else:
        other.append(entry)

# Contar por proyecto
projects = {}
for row in rows:
    p = dict(row).get('project', 'unknown')
    projects[p] = projects.get(p, 0) + 1

project_summary = ", ".join(f"{k} ({v})" for k, v in sorted(projects.items()))

def write_section(f, entries, show_project=True):
    for entry in entries:
        f.write(f"\n## #{entry['id']} — {entry['title']}\n\n")
        proj_tag = f" | **Proyecto:** {entry['project']}" if show_project and not project_filter else ""
        topic_tag = f" | **Topic:** {entry.get('topic_key', '')}" if entry.get('topic_key') else ""
        f.write(f"**Tipo:** {entry['type']} | **Fecha:** {entry['created_at'][:10]}{proj_tag}{topic_tag}\n\n")
        f.write(f"{entry['content']}\n\n")
        f.write("---\n")

# 1. Decisiones
if decisions:
    path = os.path.join(shared_dir, "decisions.md")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(f"# Decisiones Técnicas — Engram Export\n\n")
        f.write(f"> Exportado: {date_now} | Proyectos: {project_summary} | {len(rows)} observaciones totales\n\n")
        f.write("---\n")
        write_section(f, decisions)
    print(f"  ✅ decisions.md — {len(decisions)} entradas")

# 2. Arquitectura
if architecture:
    path = os.path.join(shared_dir, "architecture-facturacion.md")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(f"# Arquitectura y Diseño — Engram Export\n\n")
        f.write(f"> Exportado: {date_now} | Proyectos: {project_summary}\n\n")
        f.write("---\n")
        write_section(f, architecture)
    print(f"  ✅ architecture-facturacion.md — {len(architecture)} entradas")

# 3. Patrones y Bugfixes
if patterns_bugfixes:
    path = os.path.join(shared_dir, "patterns-bugfixes.md")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(f"# Patrones y Bugfixes — Engram Export\n\n")
        f.write(f"> Exportado: {date_now} | Proyectos: {project_summary}\n\n")
        f.write("---\n")
        write_section(f, patterns_bugfixes)
    print(f"  ✅ patterns-bugfixes.md — {len(patterns_bugfixes)} entradas")

# 4. Sesiones
if sessions:
    path = os.path.join(shared_dir, "sessions-summary.md")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(f"# Resúmenes de Sesión — Engram Export\n\n")
        f.write(f"> Exportado: {date_now} | Proyectos: {project_summary}\n\n")
        f.write("---\n")
        write_section(f, sessions)
    print(f"  ✅ sessions-summary.md — {len(sessions)} entradas")

# 5. Otros (discovery, learning, config, manual)
if other:
    path = os.path.join(shared_dir, "discoveries-other.md")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(f"# Descubrimientos y Otros — Engram Export\n\n")
        f.write(f"> Exportado: {date_now} | Proyectos: {project_summary}\n\n")
        f.write("---\n")
        write_section(f, other)
    print(f"  ✅ discoveries-other.md — {len(other)} entradas")

# Resumen
print(f"\n📊 Total: {len(rows)} observaciones de {len(projects)} proyecto(s)")
print(f"   Decisiones: {len(decisions)} | Arquitectura: {len(architecture)} | Patrones/Bugs: {len(patterns_bugfixes)} | Sesiones: {len(sessions)} | Otros: {len(other)}")

conn.close()
PYTHON_SCRIPT

    echo ""
    log_ok "Export completado en: $SHARED_DIR/"
    log_info "Para commitear: git add shared-knowledge/ && git commit -m 'docs: actualizar export Engram'"
}

do_status() {
    check_engram_db

    echo ""
    log_info "📊 Estado de Engram (nivel usuario)"
    echo ""

    python3 << PYTHON_SCRIPT
import sqlite3
import os
from datetime import datetime

db_path = "$ENGRAM_DB"
shared_dir = "$SHARED_DIR"

conn = sqlite3.connect(db_path)

# Stats globales
total = conn.execute("SELECT COUNT(*) FROM observations WHERE deleted_at IS NULL").fetchone()[0]
projects = conn.execute("SELECT DISTINCT project FROM observations WHERE deleted_at IS NULL").fetchall()
sessions = conn.execute("SELECT COUNT(*) FROM sessions").fetchone()[0]

print(f"  DB: {db_path}")
print(f"  Observaciones: {total}")
print(f"  Sesiones: {sessions}")
print(f"  Proyectos: {len(projects)}")
print()

# Por proyecto
print("  📁 Por proyecto:")
for (proj,) in projects:
    count = conn.execute("SELECT COUNT(*) FROM observations WHERE project = ? AND deleted_at IS NULL", (proj,)).fetchone()[0]
    types = conn.execute("""
        SELECT type, COUNT(*) FROM observations 
        WHERE project = ? AND deleted_at IS NULL 
        GROUP BY type ORDER BY COUNT(*) DESC
    """, (proj,)).fetchall()
    type_str = ", ".join(f"{t}:{c}" for t, c in types)
    print(f"     {proj}: {count} obs ({type_str})")

# Último export
print()
if os.path.isdir(shared_dir):
    files = [f for f in os.listdir(shared_dir) if f.endswith('.md') and f != 'README.md']
    if files:
        newest = max(os.path.getmtime(os.path.join(shared_dir, f)) for f in files)
        newest_date = datetime.fromtimestamp(newest).strftime('%Y-%m-%d %H:%M')
        print(f"  📤 Último export: {newest_date}")
        print(f"     Archivos: {', '.join(sorted(files))}")
    else:
        print("  📤 Último export: nunca")
else:
    print("  📤 Último export: nunca (directorio no existe)")

conn.close()
PYTHON_SCRIPT
}

# Main
case "${1:-help}" in
    export)
        do_export "${2:-}"
        ;;
    status)
        do_status
        ;;
    *)
        echo "Uso: $0 {export|status} [proyecto]"
        echo ""
        echo "  export              — Exporta TODAS las memorias a shared-knowledge/"
        echo "  export <proyecto>   — Exporta solo un proyecto específico"
        echo "  status              — Muestra estadísticas de Engram"
        echo ""
        echo "Engram es a nivel de USUARIO (~/.engram/engram.db)."
        echo "Puedes ejecutar este script desde cualquier repo con Git."
        echo ""
        echo "Proyectos disponibles (según última sesión):"
        echo "  - tronador-oracle-db"
        echo "  - corex-n3-power"
        echo "  - simon-cotizadores-core-wl"
        exit 1
        ;;
esac
