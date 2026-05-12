# ============================================================
# Actualizador del Power corex-n3 (Windows)
# Actualiza server.py, agente, skills y steering sin pedir
# credenciales de nuevo (las mantiene del .env existente)
# ============================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$KiroDir = Join-Path $env:USERPROFILE ".kiro"
$ServerDir = Join-Path $KiroDir "powers\installed\corex-n3"
$AgentDir = Join-Path $KiroDir "agents"
$SkillsDir = Join-Path $KiroDir "skills"
$SteeringDir = Join-Path $KiroDir "steering"
$SettingsDir = Join-Path $KiroDir "settings"
$EnvFile = Join-Path $SettingsDir ".env"

Write-Host ""
Write-Host "🔄 Actualizador del Power corex-n3 — Tribu Corex" -ForegroundColor Cyan
Write-Host "================================================"
Write-Host ""

# Verificar que ya está instalado
if (-not (Test-Path $EnvFile)) {
    Write-Host "❌ No se encontró $EnvFile" -ForegroundColor Red
    Write-Host "   Parece que el power no está instalado. Ejecuta install.ps1 primero."
    exit 1
}

# 1. Actualizar server.py
if (-not (Test-Path $ServerDir)) { New-Item -ItemType Directory -Path $ServerDir -Force | Out-Null }
Copy-Item (Join-Path $ScriptDir "server.py") -Destination (Join-Path $ServerDir "server.py") -Force
Write-Host "✅ server.py actualizado" -ForegroundColor Green

# 2. Actualizar agente
if (-not (Test-Path $AgentDir)) { New-Item -ItemType Directory -Path $AgentDir -Force | Out-Null }
$AgentSrcDir = Join-Path $ScriptDir "agents"
if (Test-Path $AgentSrcDir) {
    Get-ChildItem "$AgentSrcDir\corex-incident-diagnostics.*" | ForEach-Object {
        Copy-Item $_.FullName -Destination $AgentDir -Force
    }
    Write-Host "✅ Agente de diagnóstico actualizado" -ForegroundColor Green
}

# 3. Actualizar skills
$SkillsSrc = Join-Path $ScriptDir "skills"
if (Test-Path $SkillsSrc) {
    Get-ChildItem $SkillsSrc -Directory | ForEach-Object {
        $destSkill = Join-Path $SkillsDir $_.Name
        if (-not (Test-Path $destSkill)) { New-Item -ItemType Directory -Path $destSkill -Force | Out-Null }
        $skillFile = Join-Path $_.FullName "SKILL.md"
        if (Test-Path $skillFile) {
            Copy-Item $skillFile -Destination (Join-Path $destSkill "SKILL.md") -Force
        }
    }
    Write-Host "✅ Skills actualizadas" -ForegroundColor Green
}

# 4. Actualizar steering global
$EngramSteering = Join-Path $ScriptDir "steering-global\engram-knowledge-sync.md"
if (Test-Path $EngramSteering) {
    if (-not (Test-Path $SteeringDir)) { New-Item -ItemType Directory -Path $SteeringDir -Force | Out-Null }
    Copy-Item $EngramSteering -Destination (Join-Path $SteeringDir "engram-knowledge-sync.md") -Force
    Write-Host "✅ Steering global actualizado" -ForegroundColor Green
}

# 5. Actualizar Engram si hay versión nueva
$EngramBin = Join-Path $env:USERPROFILE ".local\bin\engram.exe"
if (Test-Path $EngramBin) {
    $CurrentVersion = & $EngramBin version 2>$null
    if (-not $CurrentVersion) { $CurrentVersion = "unknown" }
    Write-Host "   Engram actual: $CurrentVersion"

    $Arch = if ([System.Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }
    $EngramUrl = "https://github.com/Gentleman-Programming/engram/releases/latest/download/engram_windows_${Arch}.zip"

    try {
        $TempZip = Join-Path $env:TEMP "engram_update.zip"
        Invoke-WebRequest -Uri $EngramUrl -OutFile $TempZip -ErrorAction Stop
        $TempExtract = Join-Path $env:TEMP "engram_extract"
        if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
        Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force
        $NewBin = Join-Path $TempExtract "engram.exe"
        if (Test-Path $NewBin) {
            $NewVersion = & $NewBin version 2>$null
            if ($NewVersion -and $NewVersion -ne $CurrentVersion) {
                Copy-Item $NewBin -Destination $EngramBin -Force
                Write-Host "✅ Engram actualizado: $CurrentVersion → $NewVersion" -ForegroundColor Green
            } else {
                Write-Host "✅ Engram ya está en la última versión ($CurrentVersion)" -ForegroundColor Green
            }
        }
        Remove-Item $TempZip -Force -ErrorAction SilentlyContinue
        Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "⚠️  No se pudo verificar actualización de Engram (sin conexión?)" -ForegroundColor Yellow
    }
}

# 6. Resumen
Write-Host ""
Write-Host "================================================"
Write-Host "✅ Actualización completa!" -ForegroundColor Green
Write-Host ""
Write-Host "   Credenciales: sin cambios (usa $EnvFile existente)"
Write-Host ""
Write-Host "   Si cambiaste el mcp.json del power:"
Write-Host "   → Desinstalar y reinstalar el power desde Kiro"
Write-Host "   → Reiniciar Kiro"
Write-Host ""
Write-Host "   Si solo actualizaste server.py/agente/skills:"
Write-Host "   → Reiniciar Kiro es suficiente"
Write-Host "================================================"
