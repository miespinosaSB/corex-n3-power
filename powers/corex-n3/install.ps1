# ============================================================
# Instalador interactivo del Power corex-n3 (Windows)
# Pide credenciales y genera la configuración global
# ============================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$KiroDir = Join-Path $env:USERPROFILE ".kiro"
$ServerDir = Join-Path $KiroDir "powers\installed\corex-n3"
$AgentDir = Join-Path $KiroDir "agents"
$SettingsDir = Join-Path $KiroDir "settings"
$ServerPath = Join-Path $ServerDir "server.py"
$McpFile = Join-Path $SettingsDir "mcp.json"

Write-Host ""
Write-Host "🔧 Instalador del Power corex-n3 — Tribu Corex" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Copiar server.py
New-Item -ItemType Directory -Force -Path $ServerDir | Out-Null
Copy-Item "$ScriptDir\server.py" $ServerPath -Force
Write-Host "✅ server.py instalado" -ForegroundColor Green

# 2. Copiar agente global
New-Item -ItemType Directory -Force -Path $AgentDir | Out-Null
$RepoRoot = Split-Path (Split-Path $ScriptDir)
$AgentSource = Join-Path $RepoRoot ".kiro\agents\corex-incident-diagnostics.md"
if (Test-Path $AgentSource) {
    Copy-Item $AgentSource (Join-Path $AgentDir "corex-incident-diagnostics.md") -Force
    Write-Host "✅ Agente de diagnóstico instalado (global)" -ForegroundColor Green
}

# 3. Pedir credenciales interactivamente
Write-Host ""
Write-Host "📋 Configuración de credenciales" -ForegroundColor Yellow
Write-Host "   (se guardan en $McpFile)" -ForegroundColor Gray
Write-Host ""

$JiraEmail = Read-Host "   Email corporativo (ej: nombre@segurosbolivar.com)"
if ([string]::IsNullOrEmpty($JiraEmail)) { Write-Host "❌ Email es obligatorio" -ForegroundColor Red; exit 1 }

Write-Host "   API Token de Atlassian (crear en https://id.atlassian.com/manage-profile/security/api-tokens)" -ForegroundColor Gray
$JiraToken = Read-Host "   Token" -AsSecureString
$JiraTokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($JiraToken))
if ([string]::IsNullOrEmpty($JiraTokenPlain)) { Write-Host "❌ Token es obligatorio" -ForegroundColor Red; exit 1 }

$OraUser = Read-Host "   Usuario Oracle dev (ej: DEV_1072660049)"
if ([string]::IsNullOrEmpty($OraUser)) { Write-Host "❌ Usuario Oracle es obligatorio" -ForegroundColor Red; exit 1 }

$OraPass = Read-Host "   Password Oracle" -AsSecureString
$OraPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($OraPass))
if ([string]::IsNullOrEmpty($OraPassPlain)) { Write-Host "❌ Password Oracle es obligatorio" -ForegroundColor Red; exit 1 }

# 4. Generar mcp.json global
New-Item -ItemType Directory -Force -Path $SettingsDir | Out-Null

# Escapar backslashes para JSON
$ServerPathJson = $ServerPath.Replace('\', '\\')

$mcpContent = @"
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "uvx",
      "args": ["mcp-atlassian"],
      "env": {
        "UV_NATIVE_TLS": "true",
        "JIRA_URL": "https://jirasegurosbolivar.atlassian.net",
        "JIRA_USERNAME": "$JiraEmail",
        "JIRA_API_TOKEN": "$JiraTokenPlain",
        "CONFLUENCE_URL": "https://jirasegurosbolivar.atlassian.net/wiki",
        "CONFLUENCE_USERNAME": "$JiraEmail",
        "CONFLUENCE_API_TOKEN": "$JiraTokenPlain"
      }
    },
    "oracle-readonly": {
      "command": "uv",
      "args": ["run", "$ServerPathJson"],
      "env": {
        "UV_NATIVE_TLS": "true",
        "ORACLE_HOST": "10.1.2.76",
        "ORACLE_PORT": "1521",
        "ORACLE_SID": "tron",
        "ORACLE_USER": "$OraUser",
        "ORACLE_PASSWORD": "$OraPassPlain"
      }
    },
    "oracle-stage": {
      "command": "uv",
      "args": ["run", "$ServerPathJson"],
      "env": {
        "UV_NATIVE_TLS": "true",
        "ORACLE_HOST": "10.7.2.14",
        "ORACLE_PORT": "1521",
        "ORACLE_SID": "tron",
        "ORACLE_USER": "consulta_puma",
        "ORACLE_PASSWORD": "P4m4C0ns4lt4"
      }
    }
  }
}
"@

Set-Content -Path $McpFile -Value $mcpContent -Encoding UTF8
Write-Host ""
Write-Host "✅ Configuración MCP generada en: $McpFile" -ForegroundColor Green

# 5. Resumen
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "✅ Instalación completa!" -ForegroundColor Green
Write-Host ""
Write-Host "   Siguiente paso:" -ForegroundColor White
Write-Host "   → En Kiro: Command Palette → 'Install Power from local directory'" -ForegroundColor White
Write-Host "     Selecciona: $ScriptDir" -ForegroundColor Gray
Write-Host ""
Write-Host "   El power funciona GLOBALMENTE desde cualquier workspace." -ForegroundColor White
Write-Host "   Puedes cambiar de rama tranquilo." -ForegroundColor White
Write-Host ""
Write-Host "   Para actualizar credenciales después:" -ForegroundColor White
Write-Host "   → Editar: $McpFile" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Cyan
