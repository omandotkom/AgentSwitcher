#Requires -Version 5.1
# Quick Setup - Configure network profiles interactively

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    Network Switcher - Setup Wizard        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = $PSScriptRoot
$ConfigFile = Join-Path $ScriptDir "config\network-profiles.json"

function Write-Step {
    param([string]$Message, [string]$Color = "Yellow")
    Write-Host "[$Message]" -ForegroundColor $Color
}

# Step 1: Office Network Config
Write-Host ""
Write-Step "1/4" "Cyan"
Write-Host "Konfigurasi Jaringan Kantor" -ForegroundColor White

Write-Host "  MCP/Database Host:" -NoNewline
$mcpHost = Read-Host " (contoh: db-server-kantor.internal)"
if ([string]::IsNullOrWhiteSpace($mcpHost)) { $mcpHost = "db-server-kantor.internal" }

Write-Host "  MCP/Database Port:" -NoNewline
$mcpPort = Read-Host " (contoh: 5432)"
if ([string]::IsNullOrWhiteSpace($mcpPort)) { $mcpPort = "5432" }

Write-Host "  Gateway IP:" -NoNewline
$gateway = Read-Host " (contoh: 192.168.1.1)"
if ([string]::IsNullOrWhiteSpace($gateway)) { $gateway = "192.168.1.1" }

Write-Host "  DNS Servers (pisahkan dengan koma):" -NoNewline
$dns = Read-Host " (contoh: 192.168.1.100,192.168.1.101)"
if ([string]::IsNullOrWhiteSpace($dns)) { $dns = "192.168.1.100,192.168.1.101" }

# Step 2: VPN Config
Write-Host ""
Write-Step "2/4" "Cyan"
Write-Host "Konfigurasi VPN" -ForegroundColor White

Write-Host "  VPN Profile Name (di Windows VPN Settings):" -NoNewline
$vpnName = Read-Host " (contoh: Antigravity)"
if ([string]::IsNullOrWhiteSpace($vpnName)) { $vpnName = "Antigravity" }

# Step 3: Auto-detect keywords
Write-Host ""
Write-Step "3/4" "Cyan"
Write-Host "Keywords Auto-Detect (optional)" -ForegroundColor White

Write-Host "  Tekan Enter untuk defaults, atau masukkan keywords baru" -ForegroundColor Gray

# Step 4: Review and Save
Write-Host ""
Write-Step "4/4" "Cyan"
Write-Host "Review Konfigurasi" -ForegroundColor White

Write-Host ""
Write-Host "Jaringan Kantor:" -ForegroundColor Green
Write-Host "  MCP Host: $mcpHost"
Write-Host "  MCP Port: $mcpPort"
Write-Host "  Gateway: $gateway"
Write-Host ""
Write-Host "VPN:" -ForegroundColor Green
Write-Host "  Profile Name: $vpnName"
Write-Host ""

$confirm = Read-Host "Simpan konfigurasi? (Y/n)"
if ($confirm -ne "n" -and $confirm -ne "N") {
    # Create config object
    $config = @{
        profiles = @{
            office = @{
                name = "Jaringan Kantor"
                description = "Untuk koneksi ke database dan MCP server"
                vpnEnabled = $false
                gateway = $gateway
                dns = @($dns -split ",")
                routes = @("10.0.0.0/8", "172.16.0.0/12")
                mcpHost = $mcpHost
                mcpPort = [int]$mcpPort
            }
            vpn = @{
                name = "VPN External"
                description = "Untuk akses coding agent dan internet external"
                vpnEnabled = $true
                vpnProfileName = $vpnName
                gateway = "10.8.0.1"
                dns = @("1.1.1.1", "8.8.8.8")
                excludeRoutes = @("10.0.0.0/8", "172.16.0.0/12")
            }
        }
        autoDetect = @{
            mcpKeywords = @("database", "db", "postgres", "mysql", "mongodb", "sql", "mcp")
            webKeywords = @("api", "http", "localhost", "web", "frontend", "backend", "html", "css", "js")
        }
    }
    
    # Save config
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigFile -Encoding UTF8
    
    Write-Host ""
    Write-Host "Konfigurasi tersimpan!" -ForegroundColor Green
    Write-Host "File: $ConfigFile"
    Write-Host ""
    Write-Host "下一步:" -ForegroundColor Cyan
    Write-Host "  1. Test manual switch: .\NetworkSwitcher.ps1 -Mode vpn"
    Write-Host "  2. Jalankan launcher: .\launcher.ps1 -Agent auto"
    Write-Host ""
} else {
    Write-Host "Setup dibatalkan." -ForegroundColor Yellow
}
