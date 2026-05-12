#!/bin/bash
# ============================================================
# Instalador interactivo del Power corex-n3 (macOS / Linux)
# Pide credenciales y genera la configuración completa
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KIRO_DIR="$HOME/.kiro"
SERVER_DIR="$KIRO_DIR/powers/installed/corex-n3"
AGENT_DIR="$KIRO_DIR/agents"
SETTINGS_DIR="$KIRO_DIR/settings"
SERVER_PATH="$SERVER_DIR/server.py"
MCP_FILE="$SETTINGS_DIR/mcp.json"
ENV_FILE="$SETTINGS_DIR/.env"

echo ""
echo "🔧 Instalador del Power corex-n3 — Tribu Corex"
echo "================================================"
echo ""

# 1. Copiar server.py
mkdir -p "$SERVER_DIR"
cp "$SCRIPT_DIR/server.py" "$SERVER_PATH"
echo "✅ server.py instalado en $SERVER_PATH"

# 2. Copiar agente de diagnóstico (global)
mkdir -p "$AGENT_DIR"
AGENT_SRC_DIR="$SCRIPT_DIR/agents"
if [ -d "$AGENT_SRC_DIR" ]; then
    cp "$AGENT_SRC_DIR/corex-incident-diagnostics.json" "$AGENT_DIR/" 2>/dev/null
    cp "$AGENT_SRC_DIR/corex-incident-diagnostics.md" "$AGENT_DIR/" 2>/dev/null
    cp "$AGENT_SRC_DIR/corex-incident-diagnostics.prompt.md" "$AGENT_DIR/" 2>/dev/null
    echo "✅ Agente de diagnóstico instalado (global: ~/.kiro/agents/)"
else
    echo "⚠️  Carpeta agents/ no encontrada en el power, saltando..."
fi

# 3. Instalar Engram (memoria persistente)
ENGRAM_BIN="$HOME/.local/bin/engram"
if [ -f "$ENGRAM_BIN" ]; then
    echo "✅ Engram ya instalado ($($ENGRAM_BIN version 2>/dev/null))"
else
    echo ""
    echo "📦 Instalando Engram (memoria persistente entre sesiones)..."
    ARCH="$(uname -m)"
    OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
    if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        ENGRAM_ARCH="arm64"
    else
        ENGRAM_ARCH="amd64"
    fi
    ENGRAM_URL="https://github.com/Gentleman-Programming/engram/releases/latest/download/engram_${OS}_${ENGRAM_ARCH}.tar.gz"
    mkdir -p "$HOME/.local/bin"
    if curl -fsSL "$ENGRAM_URL" -o /tmp/engram.tar.gz 2>/dev/null; then
        tar -xzf /tmp/engram.tar.gz -C /tmp/ 2>/dev/null
        if [ -f /tmp/engram ]; then
            mv /tmp/engram "$ENGRAM_BIN"
            chmod +x "$ENGRAM_BIN"
            rm -f /tmp/engram.tar.gz
            echo "✅ Engram instalado ($($ENGRAM_BIN version 2>/dev/null))"
        else
            echo "⚠️  No se pudo extraer Engram. Instalar manualmente: brew install gentleman-programming/tap/engram"
        fi
    else
        echo "⚠️  No se pudo descargar Engram. Instalar manualmente: brew install gentleman-programming/tap/engram"
    fi
fi

# 4. Copiar steering global de Engram
STEERING_DIR="$KIRO_DIR/steering"
mkdir -p "$STEERING_DIR"
ENGRAM_STEERING="$SCRIPT_DIR/steering-global/engram-knowledge-sync.md"
if [ -f "$ENGRAM_STEERING" ]; then
    cp "$ENGRAM_STEERING" "$STEERING_DIR/engram-knowledge-sync.md"
    echo "✅ Steering de Engram instalado (global)"
fi

# 4b. Copiar skills globales
SKILLS_DIR="$KIRO_DIR/skills"
SKILLS_SRC="$SCRIPT_DIR/skills"
if [ -d "$SKILLS_SRC" ]; then
    for skill_dir in "$SKILLS_SRC"/*/; do
        skill_name=$(basename "$skill_dir")
        mkdir -p "$SKILLS_DIR/$skill_name"
        cp "$skill_dir/SKILL.md" "$SKILLS_DIR/$skill_name/SKILL.md" 2>/dev/null
    done
    echo "✅ Skills instaladas (global: ~/.kiro/skills/)"
fi

# 5. Pedir credenciales interactivamente
echo ""
echo "📋 Configuración de credenciales"
echo ""

read -p "   Email corporativo (ej: nombre@segurosbolivar.com): " JIRA_EMAIL
if [ -z "$JIRA_EMAIL" ]; then
    echo "❌ Email es obligatorio"; exit 1
fi

echo "   API Token de Atlassian (crear en https://id.atlassian.com/manage-profile/security/api-tokens)"
read -sp "   Token: " JIRA_TOKEN
echo ""
if [ -z "$JIRA_TOKEN" ]; then
    echo "❌ Token es obligatorio"; exit 1
fi

read -p "   Usuario Oracle dev (ej: DEV_1072660049): " ORA_USER
if [ -z "$ORA_USER" ]; then
    echo "❌ Usuario Oracle es obligatorio"; exit 1
fi

read -sp "   Password Oracle: " ORA_PASS
echo ""
if [ -z "$ORA_PASS" ]; then
    echo "❌ Password Oracle es obligatorio"; exit 1
fi

# 6. Generar .env con credenciales
mkdir -p "$SETTINGS_DIR"
cat > "$ENV_FILE" << ENVEOF
JIRA_USERNAME=$JIRA_EMAIL
JIRA_API_TOKEN=$JIRA_TOKEN
ORACLE_USER=$ORA_USER
ORACLE_PASSWORD=$ORA_PASS
ENVEOF
chmod 600 "$ENV_FILE"
echo "✅ Credenciales guardadas en $ENV_FILE"

# 7. Generar mcp.json (solo servidores globales de usuario)
# NOTA: La sección "powers" la genera Kiro automáticamente al instalar el power.
# Aquí solo ponemos Engram a nivel usuario (disponible en cualquier sesión).
if [ -f "$MCP_FILE" ]; then
    echo "⚠️  $MCP_FILE ya existe. No se sobrescribe."
    echo "   Si necesitas regenerarlo, bórralo primero y vuelve a ejecutar."
else
    cat > "$MCP_FILE" << MCPEOF
{
  "mcpServers": {
    "engram": {
      "command": "$HOME/.local/bin/engram",
      "args": ["mcp"],
      "env": {},
      "disabled": false,
      "autoApprove": ["mem_save", "mem_search", "mem_context", "mem_session_start", "mem_session_end", "mem_session_summary", "mem_timeline", "mem_stats", "mem_get_observation", "mem_update", "mem_delete", "mem_judge", "mem_compare", "mem_suggest_topic_key", "mem_save_prompt", "mem_capture_passive", "mem_current_project"]
    }
  }
}
MCPEOF
    echo "✅ Configuración MCP base generada en: $MCP_FILE"
fi

# 8. Resumen
echo ""
echo "================================================"
echo "✅ Prerrequisitos instalados!"
echo ""
echo "   Siguiente paso:"
echo "   → En Kiro: Command Palette → 'Install Power from local directory'"
echo "     Selecciona: $SCRIPT_DIR"
echo "   → Reiniciar Kiro"
echo ""
echo "   El power registra automáticamente:"
echo "   • mcp-atlassian (Jira + Confluence)"
echo "   • oracle-readonly (BD desarrollo)"
echo "   • oracle-stage (BD stage)"
echo "   • engram (memoria persistente)"
echo "   • context7 (documentación actualizada)"
echo ""
echo "   Para actualizar credenciales:"
echo "   → Editar: $ENV_FILE"
echo "================================================"
