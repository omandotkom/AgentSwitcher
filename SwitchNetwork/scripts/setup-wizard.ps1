#Requires -Version 5.1
# Quick Setup - Configure network profiles (Oracle support)

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    Network Switcher - Setup Wizard       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = $PSScriptRoot
$ConfigFile = Join-Path $ScriptDir "config\network-profiles.json"

# Step 1: Office Network Config (Oracle)
Write-Host "📍 Step 1/4: Jaringan Kantor (Oracle Database)" -ForegroundColor White
Write-Host ""

Write-Host "  Nama WiFi (SSID):" -NoNewline
$officeSSID = Read-Host " (contoh: OFFICE_WIFI)"
if ([string]::IsNullOrWhiteSpace($officeSSID)) { $officeSSID = "OFFICE_WIFI" }

Write-Host "  Oracle Host (IP/Domain):" -NoNewline
$oracleHost = Read-Host " (contoh: 192.168.1.50)"
if ([string]::IsNullOrWhiteSpace($oracleHost)) { $oracleHost = "192.168.1.50" }

Write-Host "  Oracle Port:" -NoNewline
$oraclePort = Read-Host " (default: 1521)"
if ([string]::IsNullOrWhiteSpace($oraclePort)) { $oraclePort = "1521" }

Write-Host "  Oracle Service Name:" -NoNewline
$serviceName = Read-Host " (contoh: ORCL)"
if ([string]::IsNullOrWhiteSpace($serviceName)) { $serviceName = "ORCL" }

Write-Host "  Gateway IP:" -NoNewline
$gateway = Read-Host " (contoh: 192.168.1.1)"
if ([string]::IsNullOrWhiteSpace($gateway)) { $gateway = "192.168.1.1" }

Write-Host "  DNS Servers:" -NoNewline
$dns = Read-Host " (contoh: 192.168.1.100,192.168.1.101)"
if ([string]::IsNullOrWhiteSpace($dns)) { $dns = "192.168.1.100,192.168.1.101" }

# Step 2: External Network Config
Write-Host ""
Write-Host "📍 Step 2/4: Jaringan External (WiFi Tethering HP)" -ForegroundColor White
Write-Host ""

Write-Host "  Nama WiFi HP (SSID):" -NoNewline
$externalSSID = Read-Host " (contoh: Hotspot-Android)"
if ([string]::IsNullOrWhiteSpace($externalSSID)) { $externalSSID = "Hotspot-Android" }

# Step 3: Review and Save
Write-Host ""
Write-Host "📍 Step 3/4: Review Konfigurasi" -ForegroundColor White
Write-Host ""

Write-Host "Jaringan Kantor (Oracle):" -ForegroundColor Green
Write-Host "  WiFi SSID: $officeSSID"
Write-Host "  Oracle Host: $oracleHost"
Write-Host "  Oracle Port: $oraclePort"
Write-Host "  Service Name: $serviceName"
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
                dbType = "oracle"
                mcpHost = $oracleHost
                mcpPort = [int]$oraclePort
                serviceName = $serviceName
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
            oracleKeywords = @("oracle", "sqlplus", "toad", "plsql", "dmp", "dbf")
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
    Write-Host "     .\NetworkSwitcher.ps1 -Mode office     # Ke WiFi Kantor (Oracle)"
    Write-Host "     .\NetworkSwitcher.ps1 -Mode external  # Ke WiFi Tethering HP"
    Write-Host ""
    Write-Host "  2. Lewat launcher:"
    Write-Host "     .\launcher.ps1 -Agent auto           # Coding agent → External"
    Write-Host "     .\launcher.ps1 -MCP                  # Database → Kantor"
    Write-Host ""
    Write-Host "  3. Oracle connection string:"
    Write-Host "     $oracleHost`:$oraclePort/$serviceName"
    Write-Host ""
    Write-Host "  4. Cek status:"
    Write-Host "     .\NetworkSwitcher.ps1 -Status"
    Write-Host ""
} else {
    Write-Host "Setup dibatalkan." -ForegroundColor Yellow
}
