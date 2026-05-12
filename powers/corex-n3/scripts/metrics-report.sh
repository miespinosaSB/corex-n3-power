#!/bin/bash
# ============================================================================
# metrics-report.sh — Reporte de métricas de uso del power corex-n3
#
# Uso:
#   ./metrics-report.sh           → Reporte completo
#   ./metrics-report.sh today     → Solo hoy
#   ./metrics-report.sh week      → Última semana
#   ./metrics-report.sh summary   → Resumen compacto
#
# Lee de: powers/corex-n3/metrics/usage.log
# Formato del log: TIMESTAMP|TOOL_NAME|SERVER_NAME
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
METRICS_FILE="$REPO_ROOT/powers/corex-n3/metrics/usage.log"

# Colores
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ ! -f "$METRICS_FILE" ]; then
    echo "📊 No hay métricas registradas aún."
    echo "   Las métricas se registran automáticamente al usar herramientas MCP."
    exit 0
fi

PERIOD="${1:-all}"
TODAY=$(date -u +%Y-%m-%d)

filter_by_period() {
    case "$PERIOD" in
        today)
            grep "^$TODAY" "$METRICS_FILE" 2>/dev/null || true
            ;;
        week)
            # Last 7 days
            local WEEK_AGO
            WEEK_AGO=$(date -u -v-7d +%Y-%m-%d 2>/dev/null || date -u -d "7 days ago" +%Y-%m-%d 2>/dev/null || echo "")
            if [ -n "$WEEK_AGO" ]; then
                awk -F'|' -v since="$WEEK_AGO" '$1 >= since' "$METRICS_FILE"
            else
                cat "$METRICS_FILE"
            fi
            ;;
        *)
            cat "$METRICS_FILE"
            ;;
    esac
}

DATA=$(filter_by_period)

if [ -z "$DATA" ]; then
    echo "📊 No hay métricas para el período: $PERIOD"
    exit 0
fi

TOTAL=$(echo "$DATA" | wc -l | tr -d ' ')

echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  📊 Métricas de Uso — Power corex-n3${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Período: ${YELLOW}$PERIOD${NC}"
echo -e "  Total invocaciones: ${GREEN}$TOTAL${NC}"
echo ""

# Top herramientas
echo -e "${BLUE}─── Top Herramientas ───${NC}"
echo "$DATA" | awk -F'|' '{print $2}' | sort | uniq -c | sort -rn | head -10 | while read COUNT TOOL; do
    printf "  %4d  %s\n" "$COUNT" "$TOOL"
done

echo ""

# Por servidor
echo -e "${BLUE}─── Por Servidor MCP ───${NC}"
echo "$DATA" | awk -F'|' '{print $3}' | sort | uniq -c | sort -rn | while read COUNT SERVER; do
    printf "  %4d  %s\n" "$COUNT" "$SERVER"
done

echo ""

# Por día (últimos 7)
echo -e "${BLUE}─── Actividad por Día (últimos 7) ───${NC}"
echo "$DATA" | awk -F'|' '{print substr($1,1,10)}' | sort | uniq -c | tail -7 | while read COUNT DAY; do
    # Simple bar chart
    BAR=""
    BARS=$((COUNT / 2))
    for ((i=0; i<BARS && i<30; i++)); do
        BAR="${BAR}█"
    done
    printf "  %s  %3d  %s\n" "$DAY" "$COUNT" "$BAR"
done

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════${NC}"

# Summary mode: compact output
if [ "$PERIOD" = "summary" ]; then
    ORACLE_COUNT=$(echo "$DATA" | grep -c "oracle" || echo "0")
    JIRA_COUNT=$(echo "$DATA" | grep -c "jira" || echo "0")
    CONFLUENCE_COUNT=$(echo "$DATA" | grep -c "confluence" || echo "0")
    echo ""
    echo "Resumen rápido:"
    echo "  🗄️  Oracle: $ORACLE_COUNT consultas"
    echo "  📋 Jira: $JIRA_COUNT operaciones"
    echo "  📝 Confluence: $CONFLUENCE_COUNT operaciones"
fi
