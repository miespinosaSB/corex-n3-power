#!/bin/bash
# ============================================================================
# engram-sync.sh — Sincronización de conocimiento Engram entre compañeros
#
# Uso:
#   ./engram-sync.sh export   → Exporta memorias locales a .kiro/shared-knowledge/
#   ./engram-sync.sh import   → Importa memorias de compañeros desde Git
#   ./engram-sync.sh status   → Muestra estado de sincronización
#
# Flujo:
#   1. Cada dev exporta sus memorias relevantes (tipo: pattern, architecture, decision, bugfix)
#   2. Se commitean en .kiro/shared-knowledge/<usuario>.json
#   3. Al hacer pull, cada dev importa las memorias nuevas de los demás
#
# Requisitos:
#   - engram CLI instalado (viene con el power corex-n3)
#   - Git configurado en el repo
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SHARED_DIR="$REPO_ROOT/shared-knowledge"
CURRENT_USER=$(git config user.name 2>/dev/null || echo "unknown")
CURRENT_USER_SLUG=$(echo "$CURRENT_USER" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
EXPORT_FILE="$SHARED_DIR/${CURRENT_USER_SLUG}.json"
PROJECT="tronador-oracle-db"

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

ensure_shared_dir() {
    mkdir -p "$SHARED_DIR"
    if [ ! -f "$SHARED_DIR/.gitkeep" ]; then
        touch "$SHARED_DIR/.gitkeep"
    fi
    if [ ! -f "$SHARED_DIR/README.md" ]; then
        cat > "$SHARED_DIR/README.md" << 'EOF'
# Shared Knowledge — Engram Sync

Este directorio contiene memorias exportadas por cada miembro del equipo.
Se sincroniza vía Git para compartir conocimiento entre sesiones y personas.

## Estructura

```
<usuario>.json    — Memorias exportadas por cada dev
manifest.json     — Registro de última sincronización
```

## Tipos de memorias compartidas

Solo se exportan memorias de tipo:
- `pattern` — Patrones técnicos reutilizables
- `architecture` — Decisiones de arquitectura
- `decision` — Decisiones técnicas del equipo
- `bugfix` — Bugs resueltos con causa raíz

NO se exportan: `manual`, `learning`, `discovery`, `config` (son personales).

## Cómo usar

```bash
# Exportar tus memorias al repo
.kiro/scripts/engram-sync.sh export

# Importar memorias de compañeros
.kiro/scripts/engram-sync.sh import

# Ver estado
.kiro/scripts/engram-sync.sh status
```
EOF
    fi
}

do_export() {
    log_info "Exportando memorias de '$CURRENT_USER' para proyecto '$PROJECT'..."
    ensure_shared_dir

    # Usar engram CLI para buscar memorias compartibles
    # Solo tipos: pattern, architecture, decision, bugfix
    local TYPES=("pattern" "architecture" "decision" "bugfix")
    local MEMORIES="[]"
    local COUNT=0

    for TYPE in "${TYPES[@]}"; do
        # Buscar memorias por tipo usando engram search
        local RESULTS
        RESULTS=$(engram search --project "$PROJECT" --type "$TYPE" --json --limit 50 2>/dev/null || echo "[]")

        if [ "$RESULTS" != "[]" ] && [ -n "$RESULTS" ]; then
            # Merge results into MEMORIES array
            MEMORIES=$(echo "$MEMORIES" "$RESULTS" | python3 -c "
import json, sys
parts = sys.stdin.read().split(']')
all_items = []
for part in parts:
    part = part.strip().lstrip('[').strip()
    if part:
        try:
            items = json.loads('[' + part + ']')
            all_items.extend(items)
        except:
            pass
# Deduplicate by title
seen = set()
unique = []
for item in all_items:
    title = item.get('title', '')
    if title not in seen:
        seen.add(title)
        unique.append(item)
        
print(json.dumps(unique, ensure_ascii=False))
" 2>/dev/null || echo "$MEMORIES")
            COUNT=$(echo "$MEMORIES" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
        fi
    done

    # Si engram CLI no está disponible, crear export vacío con metadata
    if [ "$COUNT" = "0" ]; then
        log_warn "No se encontraron memorias exportables (o engram CLI no disponible)"
        log_info "Creando archivo de export con metadata..."
        MEMORIES="[]"
    fi

    # Escribir archivo de export
    python3 -c "
import json
from datetime import datetime

data = {
    'version': '1.0.0',
    'exported_by': '$CURRENT_USER',
    'exported_at': datetime.utcnow().isoformat() + 'Z',
    'project': '$PROJECT',
    'memories': json.loads('''$MEMORIES''') if '''$MEMORIES''' != '[]' else []
}

with open('$EXPORT_FILE', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f'Exportadas {len(data[\"memories\"])} memorias')
" 2>/dev/null || {
        # Fallback si python falla
        cat > "$EXPORT_FILE" << EOJSON
{
  "version": "1.0.0",
  "exported_by": "$CURRENT_USER",
  "exported_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "project": "$PROJECT",
  "memories": []
}
EOJSON
        log_warn "Export creado vacío (python3 no disponible para serializar)"
    }

    log_ok "Archivo exportado: $EXPORT_FILE"
    log_info "Recuerda hacer commit: git add .kiro/shared-knowledge/ && git commit -m 'chore: sync engram knowledge'"
}

do_import() {
    log_info "Importando memorias de compañeros..."
    ensure_shared_dir

    local IMPORTED=0
    local SKIPPED=0

    for FILE in "$SHARED_DIR"/*.json; do
        [ -f "$FILE" ] || continue

        # Skip own file
        if [ "$FILE" = "$EXPORT_FILE" ]; then
            continue
        fi

        local AUTHOR
        AUTHOR=$(python3 -c "
import json
with open('$FILE') as f:
    data = json.load(f)
print(data.get('exported_by', 'unknown'))
" 2>/dev/null || echo "unknown")

        local MEM_COUNT
        MEM_COUNT=$(python3 -c "
import json
with open('$FILE') as f:
    data = json.load(f)
print(len(data.get('memories', [])))
" 2>/dev/null || echo "0")

        if [ "$MEM_COUNT" = "0" ]; then
            log_warn "  $AUTHOR: sin memorias para importar"
            continue
        fi

        log_info "  Importando $MEM_COUNT memorias de $AUTHOR..."

        # Importar cada memoria via engram save (skip duplicates)
        python3 -c "
import json, subprocess, sys

with open('$FILE') as f:
    data = json.load(f)

imported = 0
skipped = 0

for mem in data.get('memories', []):
    title = mem.get('title', '')
    content = mem.get('content', '')
    mem_type = mem.get('type', 'pattern')
    
    # Check if already exists (search by title)
    try:
        result = subprocess.run(
            ['engram', 'search', '--project', '$PROJECT', '--query', title, '--json', '--limit', '1'],
            capture_output=True, text=True, timeout=10
        )
        if title.lower() in result.stdout.lower():
            skipped += 1
            continue
    except:
        pass
    
    # Save new memory
    try:
        subprocess.run(
            ['engram', 'save', '--project', '$PROJECT', '--title', title, '--type', mem_type, '--content', content],
            capture_output=True, text=True, timeout=10
        )
        imported += 1
    except:
        skipped += 1

print(f'{imported} importadas, {skipped} omitidas (duplicadas)')
" 2>/dev/null || log_warn "  No se pudo importar de $AUTHOR (engram CLI no disponible)"

        IMPORTED=$((IMPORTED + 1))
    done

    if [ "$IMPORTED" = "0" ]; then
        log_info "No hay archivos de compañeros para importar"
    else
        log_ok "Importación completada de $IMPORTED archivos"
    fi
}

do_status() {
    log_info "Estado de sincronización Engram"
    echo ""
    ensure_shared_dir

    echo "📁 Directorio: $SHARED_DIR"
    echo "👤 Usuario actual: $CURRENT_USER ($CURRENT_USER_SLUG)"
    echo ""

    if [ -f "$EXPORT_FILE" ]; then
        local LAST_EXPORT
        LAST_EXPORT=$(python3 -c "
import json
with open('$EXPORT_FILE') as f:
    data = json.load(f)
print(f\"{data.get('exported_at', 'nunca')} — {len(data.get('memories', []))} memorias\")
" 2>/dev/null || echo "error leyendo")
        echo "📤 Último export: $LAST_EXPORT"
    else
        echo "📤 Último export: nunca (ejecuta './engram-sync.sh export')"
    fi

    echo ""
    echo "📥 Archivos de compañeros:"
    local HAS_FILES=false
    for FILE in "$SHARED_DIR"/*.json; do
        [ -f "$FILE" ] || continue
        [ "$FILE" = "$EXPORT_FILE" ] && continue
        HAS_FILES=true

        local INFO
        INFO=$(python3 -c "
import json
with open('$FILE') as f:
    data = json.load(f)
print(f\"  {data.get('exported_by', '?'):20s} | {data.get('exported_at', '?'):25s} | {len(data.get('memories', []))} memorias\")
" 2>/dev/null || echo "  $(basename "$FILE")")
        echo "$INFO"
    done

    if [ "$HAS_FILES" = "false" ]; then
        echo "  (ninguno — tus compañeros aún no han exportado)"
    fi
}

# Main
case "${1:-help}" in
    export)
        do_export
        ;;
    import)
        do_import
        ;;
    status)
        do_status
        ;;
    *)
        echo "Uso: $0 {export|import|status}"
        echo ""
        echo "  export  — Exporta tus memorias compartibles al repo"
        echo "  import  — Importa memorias de compañeros"
        echo "  status  — Muestra estado de sincronización"
        exit 1
        ;;
esac
