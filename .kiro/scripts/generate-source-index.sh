#!/bin/bash
# generate-source-index.sh
# Genera un índice ligero de programas COBOL y Forms disponibles en los repos hermanos.
# Ejecutar desde la raíz de tronador-oracle-db o con TRONADOR_BASE configurado.
#
# Uso: bash .kiro/scripts/generate-source-index.sh
#
# Output: .kiro/shared-knowledge/source-index.json

set -euo pipefail

# Determinar ruta base
if [ -n "${TRONADOR_BASE:-}" ]; then
    BASE="$TRONADOR_BASE"
else
    BASE="$(cd "$(dirname "$0")/../../.." && pwd)"
fi

COBOL_DIR="$BASE/tronador-core-cobol"
FORMS_DIR="$BASE/tronador-forms/FMT"
OUTPUT_DIR="$(cd "$(dirname "$0")/../shared-knowledge" && pwd)"
OUTPUT_FILE="$OUTPUT_DIR/source-index.json"

echo "🔍 Generando índice de fuentes..."
echo "   Base: $BASE"
echo "   COBOL: $COBOL_DIR"
echo "   Forms: $FORMS_DIR"
echo "   Output: $OUTPUT_FILE"

# Iniciar JSON
echo '{' > "$OUTPUT_FILE"
echo '  "generated_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",' >> "$OUTPUT_FILE"
echo '  "cobol": {' >> "$OUTPUT_FILE"
echo '    "available": '$([ -d "$COBOL_DIR" ] && echo "true" || echo "false")',' >> "$OUTPUT_FILE"

# Indexar COBOL
if [ -d "$COBOL_DIR" ]; then
    echo '    "programs": [' >> "$OUTPUT_FILE"
    FIRST=true
    find "$COBOL_DIR" -name "*.pco" -type f | sort | while read -r file; do
        name=$(basename "$file" .pco)
        # Extraer módulo del nombre (primeros 2 chars = tipo, siguientes 3 = módulo)
        tipo="${name:0:2}"
        modulo="${name:2:3}"
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            echo ',' >> "$OUTPUT_FILE"
        fi
        printf '      {"name": "%s", "type": "%s", "module": "%s", "path": "%s"}' "$name" "$tipo" "$modulo" "$file" >> "$OUTPUT_FILE"
    done
    echo '' >> "$OUTPUT_FILE"
    echo '    ],' >> "$OUTPUT_FILE"
    COBOL_COUNT=$(find "$COBOL_DIR" -name "*.pco" -type f | wc -l | tr -d ' ')
    echo "    \"count\": $COBOL_COUNT" >> "$OUTPUT_FILE"
else
    echo '    "programs": [],' >> "$OUTPUT_FILE"
    echo '    "count": 0' >> "$OUTPUT_FILE"
fi

echo '  },' >> "$OUTPUT_FILE"
echo '  "forms": {' >> "$OUTPUT_FILE"
echo '    "available": '$([ -d "$FORMS_DIR" ] && echo "true" || echo "false")',' >> "$OUTPUT_FILE"

# Indexar Forms
if [ -d "$FORMS_DIR" ]; then
    echo '    "screens": [' >> "$OUTPUT_FILE"
    FIRST=true
    find "$FORMS_DIR" -name "*.fmt" -type f | sort | while read -r file; do
        name=$(basename "$file" .fmt)
        tipo="${name:0:2}"
        modulo="${name:2:3}"
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            echo ',' >> "$OUTPUT_FILE"
        fi
        printf '      {"name": "%s", "type": "%s", "module": "%s", "path": "%s"}' "$name" "$tipo" "$modulo" "$file" >> "$OUTPUT_FILE"
    done
    echo '' >> "$OUTPUT_FILE"
    echo '    ],' >> "$OUTPUT_FILE"
    FORMS_COUNT=$(find "$FORMS_DIR" -name "*.fmt" -type f | wc -l | tr -d ' ')
    echo "    \"count\": $FORMS_COUNT" >> "$OUTPUT_FILE"
else
    echo '    "screens": [],' >> "$OUTPUT_FILE"
    echo '    "count": 0' >> "$OUTPUT_FILE"
fi

echo '  },' >> "$OUTPUT_FILE"

# Módulos conocidos
cat >> "$OUTPUT_FILE" << 'MODULES'
  "module_map": {
    "200": "Emisión Individual",
    "226": "Emisión Colectivas",
    "270": "Salud",
    "299": "Cartera/Cancelaciones",
    "300": "Siniestros",
    "502": "Recaudo",
    "503": "Tesorería",
    "850": "Reaseguros",
    "900": "Contabilidad",
    "902": "Siniestros (reportes)"
  },
  "type_map": {
    "CB": "Batch (proceso nocturno/programado)",
    "CR": "Batch Report (generación de reportes)",
    "AP": "Alta de Póliza (emisión)",
    "CP": "Consulta de Póliza",
    "CC": "Consulta/Cambio",
    "AC": "Alta/Cambio",
    "AS": "Alta Siniestro",
    "AR": "Alta Reaseguro"
  }
}
MODULES

echo ""
echo "✅ Índice generado: $OUTPUT_FILE"
if [ -d "$COBOL_DIR" ]; then
    echo "   COBOL: $COBOL_COUNT programas indexados"
fi
if [ -d "$FORMS_DIR" ]; then
    echo "   Forms: $FORMS_COUNT pantallas indexadas"
fi
