#Requires -Version 5.1
# Quick Setup - Configure network profiles interactively

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    Network Switcher - Setup Wizard     ║" -ForegroundColor Cyan
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
Write-Host "📍 Step 1/4: Jaringan Kantor (WiFi/Ethernet)" -ForegroundColor White
Write-Host ""

Write-Host "  Nama WiFi (SSID):" -NoNewline
$officeSSID = Read-Host " (contoh: OFFICE_WIFI)"
if ([string]::IsNullOrWhiteSpace($officeSSID)) { $officeSSID = "OFFICE_WIFI" }

Write-Host "  MCP/Database Host:" -NoNewline
$mcpHost = Read-Host " (contoh: db-server.kantor.local)"
if ([string]::IsNullOrWhiteSpace($mcpHost)) { $mcpHost = "db-server.kantor.local" }

Write-Host "  MCP/Database Port:" -NoNewline
$mcpPort = Read-Host " (contoh: 5432)"
if ([string]::IsNullOrWhiteSpace($mcpPort)) { $mcpPort = "5432" }

Write-Host "  Gateway IP:" -NoNewline
$gateway = Read-Host " (contoh: 192.168.1.1)"
if ([string]::IsNullOrWhiteSpace($gateway)) { $gateway = "192.168.1.1" }

Write-Host "  DNS Servers (pisahkan dengan koma):" -NoNewline
$dns = Read-Host " (contoh: 192.168.1.100,192.168.1.101)"
if ([string]::IsNullOrWhiteSpace($dns)) { $dns = "192.168.1.100,192.168.1.101" }

# Step 2: External Network Config
Write-Host ""
Write-Host "📍 Step 2/4: Jaringan External (WiFi Tethering HP)" -ForegroundColor White
Write-Host ""

Write-Host "  Nama WiFi HP (SSID):" -NoNewline
$externalSSID = Read-Host " (contoh: Hotspot-Androi)"
if ([string]::IsNullOrWhiteSpace($externalSSID)) { $externalSSID = "Hotspot-Android" }

# Step 3: Review and Save
Write-Host ""
Write-Host "📍 Step 3/4: Review Konfigurasi" -ForegroundColor White
Write-Host ""

Write-Host "Jaringan Kantor:" -ForegroundColor Green
Write-Host "  WiFi SSID: $officeSSID"
Write-Host "  MCP Host: $mcpHost"
Write-Host "  MCP Port: $mcpPort"
Write-Host "  Gateway: $gateway"
Write-Host "  DNS: $dns"
Write-Host ""
Write-Host "Jaringan External:" -ForegroundColor Green
Write-Host "  WiFi SSID: $externalSSID"
Write-Host "  DNS: 1.1.1.1, 8.8.8.8"
Write-Host ""

$confirm = Read-Host "Simpan konfigurasi? (Y/n)"
if ($confirm -ne "n" -and $confirm -ne "N") {
    # Create config object
    $config = @{
        profiles = @{
            office = @{
                name = "WiFi Kantor"
                description = "Jaringan kantor LAN / Ethernet"
                type = "wifi"
                ssid = $officeSSID
                gateway = $gateway
                dns = @($dns -split ",")
                routes = @("10.0.0.0/8", "172.16.0.0/12")
                mcpHost = $mcpHost
                mcpPort = [int]$mcpPort
            }
            external = @{
                name = "WiFi Tethering HP"
                description = "Hotspot dari HP untuk akses internet luar"
                type = "wifi"
                ssid = $externalSSID
                gateway = "192.168.43.1"
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
    Write-Host "✅ Konfigurasi tersimpan!" -ForegroundColor Green
    Write-Host "   File: $ConfigFile"
    Write-Host ""
    Write-Host "📍 Step 4/4: Cara Pakai" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Manual switch:"
    Write-Host "     .\NetworkSwitcher.ps1 -Mode office      # Ke WiFi Kantor"
    Write-Host "     .\NetworkSwitcher.ps1 -Mode external    # Ke WiFi Tethering HP"
    Write-Host ""
    Write-Host "  2. Lewat launcher:"
    Write-Host "     .\launcher.ps1 -Agent auto              # Coding agent"
    Write-Host "     .\launcher.ps1 -MCP                   # Untuk database"
    Write-Host ""
    Write-Host "  3. Cek status:"
    Write-Host "     .\NetworkSwitcher.ps1 -Status"
    Write-Host ""
} else {
    Write-Host "Setup dibatalkan." -ForegroundColor Yellow
}
