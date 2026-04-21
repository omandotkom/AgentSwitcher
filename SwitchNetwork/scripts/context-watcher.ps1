#Requires -Version 5.1
# Context Watcher - Monitor file changes and auto-switch network
# Runs in background and detects context changes

param(
    [Parameter(Mandatory=$false)]
    [string]$WatchPath = (Get-Location),
    
    [Parameter(Mandatory=$false)]
    [int]$PollingInterval = 5
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $PSScriptRoot
$SwitcherScript = Join-Path $ScriptDir "NetworkSwitcher.ps1"
$StateFile = Join-Path $ScriptDir "config\current-state.json"

function Write-StatusLog {
    param([string]$Message)
    Write-Host "[Watcher] $(Get-Date -Format 'HH:mm:ss') - $Message"
}

# Context detection patterns
$OfficePatterns = @(
    "*mcp*", "*database*", "*.sql", "*db*", 
    "*postgres*", "*mysql*", "*mongodb*",
    "*connection*", "*config*db*"
)

$VpnPatterns = @(
    "*.html", "*.css", "*.js", "*.ts", "*.jsx", "*.tsx",
    "*.py", "*.go", "*.rs", "*.java", "*.cs",
    "package.json", "requirements.txt", "go.mod",
    "Dockerfile", "docker-compose.yml"
)

function Get-DetectedContext {
    $files = Get-ChildItem -Path $WatchPath -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 100
    
    $officeScore = 0
    $vpnScore = 0
    
    foreach ($file in $files) {
        $name = $file.Name.ToLower()
        
        foreach ($pattern in $OfficePatterns) {
            if ($name -like $pattern) { $officeScore += 2 }
        }
        
        foreach ($pattern in $VpnPatterns) {
            if ($name -like $pattern) { $vpnScore += 1 }
        }
    }
    
    if ($officeScore -gt $vpnScore -and $officeScore -gt 0) {
        return "office"
    }
    return "vpn"
}

function Load-CurrentState {
    if (Test-Path $StateFile) {
        return Get-Content $StateFile -Raw | ConvertFrom-Json
    }
    return @{ Network = "unknown"; LastSwitch = $null }
}

function Save-CurrentState {
    param([string]$Network)
    
    @{
        Network = $Network
        LastSwitch = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    } | ConvertTo-Json | Out-File -FilePath $StateFile -Encoding UTF8
}

# Main watcher loop
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Context Watcher - Auto Network Switch" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Watch Path: $WatchPath"
Write-Host "Polling Interval: $PollingInterval seconds"
Write-Host "Press Ctrl+C to stop"
Write-Host ""

Write-StatusLog "Starting context detection..."

$currentState = Load-CurrentState
$lastContext = $currentState.Network

while ($true) {
    try {
        $detected = Get-DetectedContext
        
        if ($detected -ne $lastContext) {
            Write-Host ""
            Write-StatusLog "Context changed: $lastContext -> $detected" -ForegroundColor Yellow
            
            # Auto-switch network
            & $SwitcherScript -Mode $detected
            
            $lastContext = $detected
            Save-CurrentState -Network $detected
            
            Write-StatusLog "Network switched to: $detected"
            Write-Host ""
        }
    } catch {
        Write-StatusLog "Error: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds $PollingInterval
}
