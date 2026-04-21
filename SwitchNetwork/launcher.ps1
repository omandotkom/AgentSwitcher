#Requires -Version 5.1
# AI Coding Agent Launcher with Auto Network Switch
# Supports: Claude Code, Codex, Cursor, Windsurf
# Auto-switch antara WiFi Kantor (Oracle) dan Tethering HP

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("claude", "codex", "cursor", "windsurf", "auto")]
    [string]$Agent = "auto",
    
    [Parameter(Mandatory=$false)]
    [switch]$MCP,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("oracle", "postgres", "mysql", "mongodb")]
    [string]$DBType = "oracle",
    
    [Parameter(Mandatory=$false)]
    [string[]]$ExtraArgs = @()
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$SwitcherScript = Join-Path $ScriptDir "NetworkSwitcher.ps1"

# Banner
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   AI Coding Agent Launcher with Network     ║" -ForegroundColor Cyan
Write-Host "  ║            Auto-Switch                      ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Detect agent
function Get-AutoAgent {
    $agents = @{
        "claude" = @("claude", "claude-code")
        "codex" = @("codex", "codex-cli")
        "cursor" = @("cursor")
        "windsurf" = @("windsurf")
    }
    
    foreach ($agent in $agents.Keys) {
        foreach ($cmd in $agents[$agent]) {
            if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                return $cmd
            }
        }
    }
    
    return "codex"
}

# Get network mode based on selection
function Get-NetworkMode {
    param([string]$AgentName, [string]$DatabaseType)
    
    if ($MCP) {
        return "office"  # Kantor for database
    }
    
    # Coding agents need external
    $externalAgents = @("claude", "codex", "cursor", "windsurf")
    
    if ($externalAgents -contains $AgentName) {
        return "external"  # WiFi tethering HP
    }
    
    return "external"
}

# Get database config from config
function Get-DatabaseConfig {
    $configFile = Join-Path $ScriptDir "config\network-profiles.json"
    if (Test-Path $configFile) {
        $config = Get-Content $configFile -Raw | ConvertFrom-Json
        return $config.profiles.office
    }
    return $null
}

# Main execution
Write-Host "[1/4] Detecting agent..." -ForegroundColor Yellow

if ($Agent -eq "auto") {
    $detectedAgent = Get-AutoAgent
    Write-Host "      Found: $detectedAgent" -ForegroundColor Green
} else {
    $detectedAgent = $Agent
    Write-Host "      Using: $detectedAgent" -ForegroundColor Green
}

Write-Host "[2/4] Determining network mode..." -ForegroundColor Yellow
$networkMode = Get-NetworkMode -AgentName $detectedAgent

if ($networkMode -eq "office") {
    $dbConfig = Get-DatabaseConfig
    $networkName = "Kantor ($($dbConfig.dbType) - $($dbConfig.mcpHost)/$($dbConfig.serviceName))"
} else {
    $networkName = "External (Tethering HP)"
}
Write-Host "      Mode: $networkName" -ForegroundColor Green

Write-Host "[3/4] Switching network..." -ForegroundColor Yellow
& $SwitcherScript -Mode $networkMode

Write-Host ""
Write-Host "[4/4] Launching agent..." -ForegroundColor Yellow
Write-Host ""

$agentCmd = $detectedAgent
$args = $ExtraArgs

# For MCP/DB mode, show connection info
if ($MCP) {
    $dbConfig = Get-DatabaseConfig
    Write-Host "[Database] Connection Info:" -ForegroundColor Cyan
    Write-Host "  Type: $($dbConfig.dbType)"
    Write-Host "  Host: $($dbConfig.mcpHost)"
    Write-Host "  Port: $($dbConfig.mcpPort)"
    Write-Host "  Service: $($dbConfig.serviceName)"
    Write-Host ""
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Starting: $agentCmd $args" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$cmdPath = Get-Command $agentCmd -ErrorAction SilentlyContinue
if (-not $cmdPath) {
    Write-Host "ERROR: '$agentCmd' not found in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure your coding agent is installed:" -ForegroundColor Yellow
    switch ($detectedAgent) {
        "claude" { Write-Host "  npm install -g @anthropic-ai/claude-code" }
        "codex" { Write-Host "  pip install openai-codex" }
        "cursor" { Write-Host "  Download from https://cursor.sh" }
        "windsurf" { Write-Host "  Download from https://codeium.com/windsurf" }
    }
    exit 1
}

& $agentCmd $args
