#Requires -Version 5.1
# Smart Launcher - Auto-switch network before running commands
# Usage: .\launcher.ps1 <command> [args...]

param(
    [Parameter(Mandatory=$true)]
    [string]$Command,
    
    [Parameter(Mandatory=$false)]
    [string[]]$Arguments = @()
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $PSScriptRoot
$SwitcherScript = Join-Path $ScriptDir "NetworkSwitcher.ps1"

# Detect context from command
function Get-CommandContext {
    $cmd = $Command.ToLower()
    $argsStr = ($Arguments -join " ").ToLower()
    $fullCmd = "$cmd $argsStr"
    
    # Oracle/Database keywords - Kantor
    $oracleKeywords = @("oracle", "sqlplus", "toad", "plsql", "exp", "imp", "oracle", "tns")
    
    # MCP/Database keywords - Kantor
    $mcpKeywords = @("postgres", "mysql", "mongodb", "database", "db", "sql", "mcp", "psql", "mysql.exe", "mongod")
    
    # Web/API/Coding Agent keywords - External
    $webKeywords = @("codex", "claude", "gpt", "api", "http", "curl", "wget", "npm", "node", "python", "pip", "git", "github")
    
    # Check Oracle first
    foreach ($kw in $oracleKeywords) {
        if ($fullCmd -match $kw) {
            return "office"
        }
    }
    
    # Then other database
    foreach ($kw in $mcpKeywords) {
        if ($fullCmd -match $kw) {
            return "office"
        }
    }
    
    # Then external
    foreach ($kw in $webKeywords) {
        if ($fullCmd -match $kw) {
            return "external"
        }
    }
    
    return "external" # Default to external
}

# Main execution
Write-Host "[Launcher] Analyzing command: $Command $($Arguments -join ' ')" -ForegroundColor Cyan

$context = Get-CommandContext

$contextName = if ($context -eq "office") { "Kantor (Oracle)" } else { "External (Tethering HP)" }
Write-Host "[Launcher] Detected context: $contextName" -ForegroundColor Yellow

# Switch network based on context
switch ($context) {
    "office" {
        Write-Host "[Launcher] Switching to KANTOR network..." -ForegroundColor Yellow
        & $SwitcherScript -Mode office
    }
    "external" {
        Write-Host "[Launcher] Switching to EXTERNAL network..." -ForegroundColor Yellow
        & $SwitcherScript -Mode external
    }
}

# Execute the actual command
Write-Host "[Launcher] Executing: $Command $($Arguments -join ' ')" -ForegroundColor Green
& $Command $Arguments

$exitCode = $LASTEXITCODE

Write-Host "[Launcher] Command completed with exit code: $exitCode" -ForegroundColor Cyan
exit $exitCode
