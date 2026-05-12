#!/bin/bash
# ============================================================
# Actualizador del Power corex-n3 (macOS / Linux)
# Actualiza server.py, agente, skills y steering sin pedir
# credenciales de nuevo (las mantiene del .env existente)
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KIRO_DIR="$HOME/.kiro"
SERVER_DIR="$KIRO_DIR/powers/installed/corex-n3"
AGENT_DIR="$KIRO_DIR/agents"
SKILLS_DIR="$KIRO_DIR/skills"
STEERING_DIR="$KIRO_DIR/steering"
SETTINGS_DIR="$KIRO_DIR/settings"
ENV_FILE="$SETTINGS_DIR/.env"

echo ""
echo "🔄 Actualizador del Power corex-n3 — Tribu Corex"
echo "================================================"
echo ""

# Verificar que ya está instalado
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ No se encontró $ENV_FILE"
    echo "   Parece que el power no está instalado. Ejecuta install.sh primero."
    exit 1
fi

# 1. Actualizar server.py
mkdir -p "$SERVER_DIR"
cp "$SCRIPT_DIR/server.py" "$SERVER_DIR/server.py"
echo "✅ server.py actualizado"

# 2. Actualizar agente
mkdir -p "$AGENT_DIR"
AGENT_SRC_DIR="$SCRIPT_DIR/agents"
if [ -d "$AGENT_SRC_DIR" ]; then
    cp "$AGENT_SRC_DIR/corex-incident-diagnostics.json" "$AGENT_DIR/" 2>/dev/null
    cp "$AGENT_SRC_DIR/corex-incident-diagnostics.md" "$AGENT_DIR/" 2>/dev/null
    cp "$AGENT_SRC_DIR/corex-incident-diagnostics.prompt.md" "$AGENT_DIR/" 2>/dev/null
    echo "✅ Agente de diagnóstico actualizado"
fi

# 3. Actualizar skills
SKILLS_SRC="$SCRIPT_DIR/skills"
if [ -d "$SKILLS_SRC" ]; then
    for skill_dir in "$SKILLS_SRC"/*/; do
        skill_name=$(basename "$skill_dir")
        mkdir -p "$SKILLS_DIR/$skill_name"
        cp "$skill_dir/SKILL.md" "$SKILLS_DIR/$skill_name/SKILL.md" 2>/dev/null
    done
    echo "✅ Skills actualizadas"
fi

# 4. Actualizar steering global
ENGRAM_STEERING="$SCRIPT_DIR/steering-global/engram-knowledge-sync.md"
if [ -f "$ENGRAM_STEERING" ]; then
    mkdir -p "$STEERING_DIR"
    cp "$ENGRAM_STEERING" "$STEERING_DIR/engram-knowledge-sync.md"
    echo "✅ Steering global actualizado"
fi

# 5. Actualizar Engram si hay versión nueva
ENGRAM_BIN="$HOME/.local/bin/engram"
if [ -f "$ENGRAM_BIN" ]; then
    CURRENT_VERSION=$($ENGRAM_BIN version 2>/dev/null || echo "unknown")
    echo "   Engram actual: $CURRENT_VERSION"

    # Intentar descargar la última versión
    ARCH="$(uname -m)"
    OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
    if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        ENGRAM_ARCH="arm64"
    else
        ENGRAM_ARCH="amd64"
    fi
    ENGRAM_URL="https://github.com/Gentleman-Programming/engram/releases/latest/download/engram_${OS}_${ENGRAM_ARCH}.tar.gz"

    if curl -fsSL "$ENGRAM_URL" -o /tmp/engram_update.tar.gz 2>/dev/null; then
        tar -xzf /tmp/engram_update.tar.gz -C /tmp/ 2>/dev/null
        if [ -f /tmp/engram ]; then
            NEW_VERSION=$(/tmp/engram version 2>/dev/null || echo "unknown")
            if [ "$NEW_VERSION" != "$CURRENT_VERSION" ]; then
                mv /tmp/engram "$ENGRAM_BIN"
                chmod +x "$ENGRAM_BIN"
                echo "✅ Engram actualizado: $CURRENT_VERSION → $NEW_VERSION"
            else
                echo "✅ Engram ya está en la última versión ($CURRENT_VERSION)"
                rm -f /tmp/engram
            fi
        fi
        rm -f /tmp/engram_update.tar.gz
    else
        echo "⚠️  No se pudo verificar actualización de Engram (sin conexión?)"
    fi
fi

# 6. Resumen
echo ""
echo "================================================"
echo "✅ Actualización completa!"
echo ""
echo "   Credenciales: sin cambios (usa $ENV_FILE existente)"
echo ""
echo "   Si cambiaste el mcp.json del power:"
echo "   → Desinstalar y reinstalar el power desde Kiro"
echo "   → Reiniciar Kiro"
echo ""
echo "   Si solo actualizaste server.py/agente/skills:"
echo "   → Reiniciar Kiro es suficiente"
echo "================================================"
