#Requires -Version 5.1
# AI Coding Agent Launcher with Auto Network Switch
# Supports: Claude Code, Codex, dan coding agent lainnya
# Auto-switch antara WiFi Kantor dan Tethering HP

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("claude", "codex", "cursor", "windsurf", "auto")]
    [string]$Agent = "auto",
    
    [Parameter(Mandatory=$false)]
    [switch]$MCP,
    
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
    # Check for available agents
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
    
    # Default to codex if nothing found
    return "codex"
}

# Get network mode based on agent
function Get-NetworkMode {
    param([string]$AgentName)
    
    if ($MCP) {
        return "office"  # Kantor for MCP
    }
    
    # Most coding agents need external (tethering) for external access
    $externalAgents = @("claude", "codex", "cursor", "windsurf")
    
    if ($externalAgents -contains $AgentName) {
        return "external"  # WiFi tethering HP
    }
    
    return "external"
}

# Get MCP database host from config
function Get-MCPHost {
    $configFile = Join-Path $ScriptDir "config\network-profiles.json"
    if (Test-Path $configFile) {
        $config = Get-Content $configFile -Raw | ConvertFrom-Json
        return $config.profiles.office.mcpHost
    }
    return "localhost"
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
$networkName = if ($networkMode -eq "office") { "Kantor" } else { "External (Tethering HP)" }
Write-Host "      Mode: $networkName" -ForegroundColor Green

Write-Host "[3/4] Switching network..." -ForegroundColor Yellow
& $SwitcherScript -Mode $networkMode

Write-Host ""
Write-Host "[4/4] Launching agent..." -ForegroundColor Yellow
Write-Host ""

# Build command arguments
$agentCmd = $detectedAgent
$args = $ExtraArgs

# For MCP mode, set environment variables
if ($MCP) {
    $mcpHost = Get-MCPHost
    $env:MCP_DATABASE_HOST = $mcpHost
    Write-Host "[MCP] Database Host: $mcpHost" -ForegroundColor Cyan
    Write-Host ""
}

# Execute the agent
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Starting: $agentCmd $args" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Check if command exists
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

# Execute with interactive terminal
& $agentCmd $args
