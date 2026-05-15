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
Write-Host "[+] Instalador del Power corex-n3 -- Tribu Corex" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Copiar server.py
New-Item -ItemType Directory -Force -Path $ServerDir | Out-Null
Copy-Item "$ScriptDir\server.py" $ServerPath -Force
Write-Host "[OK] server.py instalado" -ForegroundColor Green

# 2. Copiar agentes globales
New-Item -ItemType Directory -Force -Path $AgentDir | Out-Null
$AgentSrcDir = Join-Path $ScriptDir "agents"
if (Test-Path $AgentSrcDir) {
    $agentFiles = Get-ChildItem -Path $AgentSrcDir -File -Include "*.json","*.md" -Recurse
    foreach ($f in $agentFiles) {
        Copy-Item $f.FullName (Join-Path $AgentDir $f.Name) -Force
    }
    Write-Host ('[OK] ' + $agentFiles.Count + ' archivos de agentes instalados (global: ~/.kiro/agents/)') -ForegroundColor Green
} else {
    Write-Host "[!!] Carpeta agents/ no encontrada en el power, saltando..." -ForegroundColor Yellow
}

# 3. Pedir credenciales interactivamente
Write-Host ""
Write-Host "[*] Configuracion de credenciales" -ForegroundColor Yellow
Write-Host ('   (se guardan en ' + $McpFile + ')') -ForegroundColor Gray
Write-Host ""

$JiraEmail = Read-Host '   Email corporativo (ej: nombre@segurosbolivar.com)'
if ([string]::IsNullOrEmpty($JiraEmail)) { Write-Host "[X] Email es obligatorio" -ForegroundColor Red; exit 1 }

Write-Host '   API Token de Jira (crear en https://id.atlassian.com/manage-profile/security/api-tokens)' -ForegroundColor Gray
$JiraToken = Read-Host "   Token Jira" -AsSecureString
$JiraTokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($JiraToken))
if ([string]::IsNullOrEmpty($JiraTokenPlain)) { Write-Host "[X] Token de Jira es obligatorio" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "   [i] Confluence ahora requiere credenciales separadas." -ForegroundColor Yellow
$ConfluenceEmail = Read-Host ('   Email para Confluence (Enter para usar el mismo: ' + $JiraEmail + ')')
if ([string]::IsNullOrEmpty($ConfluenceEmail)) { $ConfluenceEmail = $JiraEmail }

Write-Host '   API Token de Confluence (puede ser el mismo token de Atlassian)' -ForegroundColor Gray
$ConfluenceToken = Read-Host '   Token Confluence (Enter para usar el mismo)' -AsSecureString
$ConfluenceTokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ConfluenceToken))
if ([string]::IsNullOrEmpty($ConfluenceTokenPlain)) { $ConfluenceTokenPlain = $JiraTokenPlain }

$OraUser = Read-Host '   Usuario Oracle dev (ej: DEV_1072660049)'
if ([string]::IsNullOrEmpty($OraUser)) { Write-Host "[X] Usuario Oracle es obligatorio" -ForegroundColor Red; exit 1 }

$OraPass = Read-Host "   Password Oracle" -AsSecureString
$OraPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($OraPass))
if ([string]::IsNullOrEmpty($OraPassPlain)) { Write-Host "[X] Password Oracle es obligatorio" -ForegroundColor Red; exit 1 }

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
        "CONFLUENCE_USERNAME": "$ConfluenceEmail",
        "CONFLUENCE_API_TOKEN": "$ConfluenceTokenPlain"
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
Write-Host "[OK] Configuracion MCP generada en: $McpFile" -ForegroundColor Green

# 5. Resumen
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "[OK] Instalacion completa!" -ForegroundColor Green
Write-Host ""
Write-Host "   Siguiente paso:" -ForegroundColor White
Write-Host "   -> En Kiro: Command Palette -> 'Install Power from local directory'" -ForegroundColor White
Write-Host "     Selecciona: $ScriptDir" -ForegroundColor Gray
Write-Host ""
Write-Host "   El power funciona GLOBALMENTE desde cualquier workspace." -ForegroundColor White
Write-Host "   Puedes cambiar de rama tranquilo." -ForegroundColor White
Write-Host ""
Write-Host "   Para actualizar credenciales después:" -ForegroundColor White
Write-Host "   -> Editar: $McpFile" -ForegroundColor Gray
Write-Host "================================================" -ForegroundColor Cyan
