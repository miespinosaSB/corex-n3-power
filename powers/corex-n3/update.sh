#!/bin/bash
# ============================================================
# Actualizador del Power corex-n3 (macOS / Linux)
# Actualiza server.py, scripts, agentes, skills y steering
# sin pedir credenciales (las mantiene del .env existente)
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

# 1b. Actualizar steering del power (Kiro los lee de aquí)
STEERING_SRC="$SCRIPT_DIR/steering"
if [ -d "$STEERING_SRC" ]; then
    mkdir -p "$SERVER_DIR/steering"
    STEER_POWER_COUNT=0
    for steer_file in "$STEERING_SRC"/*.md; do
        [ -f "$steer_file" ] && cp "$steer_file" "$SERVER_DIR/steering/" && STEER_POWER_COUNT=$((STEER_POWER_COUNT + 1))
    done
    echo "✅ $STEER_POWER_COUNT steering files del power actualizados"
fi

# 2. Actualizar scripts del power
SCRIPTS_SRC="$SCRIPT_DIR/scripts"
if [ -d "$SCRIPTS_SRC" ]; then
    mkdir -p "$SERVER_DIR/scripts"
    SCRIPT_COUNT=0
    for script_file in "$SCRIPTS_SRC"/*; do
        [ -f "$script_file" ] && cp "$script_file" "$SERVER_DIR/scripts/" && SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
    done
    echo "✅ $SCRIPT_COUNT scripts actualizados"
fi

# 2b. Actualizar hooks globales
HOOKS_SRC="$SCRIPT_DIR/../../.kiro/hooks"
HOOKS_DIR="$KIRO_DIR/hooks"
if [ -d "$HOOKS_SRC" ]; then
    mkdir -p "$HOOKS_DIR"
    HOOK_COUNT=0
    for hook_file in "$HOOKS_SRC"/*.kiro.hook; do
        [ -f "$hook_file" ] && cp "$hook_file" "$HOOKS_DIR/" && HOOK_COUNT=$((HOOK_COUNT + 1))
    done
    [ $HOOK_COUNT -gt 0 ] && echo "✅ $HOOK_COUNT hooks actualizados"
fi

# 3. Actualizar TODOS los agentes (dinámico)
mkdir -p "$AGENT_DIR"
AGENT_SRC_DIR="$SCRIPT_DIR/agents"
if [ -d "$AGENT_SRC_DIR" ]; then
    AGENT_COUNT=0
    for agent_file in "$AGENT_SRC_DIR"/*.json "$AGENT_SRC_DIR"/*.md; do
        [ -f "$agent_file" ] && cp "$agent_file" "$AGENT_DIR/" && AGENT_COUNT=$((AGENT_COUNT + 1))
    done
    echo "✅ $AGENT_COUNT archivos de agentes actualizados"
else
    echo "⚠️  Carpeta agents/ no encontrada, saltando..."
fi

# 4. Actualizar skills
SKILLS_SRC="$SCRIPT_DIR/skills"
if [ -d "$SKILLS_SRC" ]; then
    SKILL_COUNT=0
    for skill_dir in "$SKILLS_SRC"/*/; do
        [ -d "$skill_dir" ] || continue
        skill_name=$(basename "$skill_dir")
        mkdir -p "$SKILLS_DIR/$skill_name"
        cp "$skill_dir/SKILL.md" "$SKILLS_DIR/$skill_name/SKILL.md" 2>/dev/null && SKILL_COUNT=$((SKILL_COUNT + 1))
    done
    echo "✅ $SKILL_COUNT skills actualizadas"
fi

# 5. Actualizar steering global
GLOBAL_STEERING_SRC="$SCRIPT_DIR/steering-global"
if [ -d "$GLOBAL_STEERING_SRC" ]; then
    mkdir -p "$STEERING_DIR"
    STEER_COUNT=0
    for steer_file in "$GLOBAL_STEERING_SRC"/*.md; do
        [ -f "$steer_file" ] && cp "$steer_file" "$STEERING_DIR/" && STEER_COUNT=$((STEER_COUNT + 1))
    done
    echo "✅ $STEER_COUNT steering files globales actualizados"
else
    echo "⚠️  Carpeta steering-global/ no encontrada, saltando..."
fi

# 6. Actualizar Engram si hay versión nueva
ENGRAM_BIN="$HOME/.local/bin/engram"
if [ -f "$ENGRAM_BIN" ]; then
    CURRENT_VERSION=$($ENGRAM_BIN version 2>/dev/null || echo "unknown")
    echo "   Engram actual: $CURRENT_VERSION"

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
else
    echo "⚠️  Engram no encontrado. Ejecuta install.sh para instalarlo."
fi

# 7. Resumen
echo ""
echo "================================================"
echo "✅ Actualización completa!"
echo ""
echo "   Credenciales: sin cambios (usa $ENV_FILE existente)"
echo ""
echo "   Siguiente paso:"
echo "   → Reiniciar Kiro (o reconectar MCP servers desde el panel)"
echo ""
echo "   Si cambiaste el mcp.json del power:"
echo "   → Desinstalar y reinstalar el power desde Kiro"
echo "================================================"
