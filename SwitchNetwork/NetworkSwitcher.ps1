#Requires -Version 5.1
# Network Switcher for AI Coding Agent
# Otomatis switch jaringan berdasarkan konteks pekerjaan

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("office", "vpn", "auto")]
    [string]$Mode = "auto",
    
    [Parameter(Mandatory=$false)]
    [switch]$Status,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListProfiles
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$ConfigFile = Join-Path $ScriptDir "config\network-profiles.json"
$LogFile = Join-Path $ScriptDir "logs\switcher-$(Get-Date -Format 'yyyyMMdd').log"

# Logging function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogEntry -Encoding UTF8
    
    switch ($Level) {
        "ERROR" { Write-Host $LogEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $LogEntry -ForegroundColor Green }
        "WARN" { Write-Host $LogEntry -ForegroundColor Yellow }
        default { Write-Host $LogEntry }
    }
}

# Load configuration
function Load-Config {
    if (-not (Test-Path $ConfigFile)) {
        Write-Log "Config file not found: $ConfigFile" "ERROR"
        exit 1
    }
    return Get-Content $ConfigFile -Raw | ConvertFrom-Json
}

# Get current network status
function Get-CurrentNetworkStatus {
    $vpnConnected = $false
    $vpnName = ""
    
    # Check VPN status via RAS (Windows built-in)
    try {
        $ras = Get-VpnConnection -ErrorAction SilentlyContinue | Where-Object { $_.ConnectionStatus -eq "Connected" }
        if ($ras) {
            $vpnConnected = $true
            $vpnName = $ras.Name
        }
    } catch {}
    
    # Check for common VPN clients
    $vpnProcesses = @("vpnagent", "openvpn", "antigravity", "windscribe", "nordvpn", "expressvpn")
    foreach ($proc in $vpnProcesses) {
        if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
            $vpnConnected = $true
            break
        }
    }
    
    # Get active network adapter
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
    
    return @{
        VpnConnected = $vpnConnected
        VpnName = $vpnName
        AdapterName = $adapter.Name
        AdapterType = $adapter.InterfaceDescription
    }
}

# Connect to VPN
function Connect-VPNProfile {
    param([string]$ProfileName)
    
    Write-Log "Connecting to VPN: $ProfileName"
    
    try {
        # Try Windows RAS first
        $vpn = Get-VpnConnection -Name $ProfileName -ErrorAction SilentlyContinue
        if ($vpn) {
            rasdial $ProfileName 2>&1 | Out-Null
            Write-Log "VPN connected via RAS: $ProfileName" "SUCCESS"
            return $true
        }
    } catch {}
    
    # Try common VPN executables
    $vpnCommands = @{
        "Antigravity" = @("antigravity", "connect")
        "OpenVPN" = @("openvpn", "--config")
    }
    
    if ($vpnCommands[$ProfileName]) {
        $cmd, $args = $vpnCommands[$ProfileName]
        Write-Log "Attempting to start: $cmd $args"
        Start-Process -FilePath $cmd -ArgumentList $args -WindowStyle Hidden
        Start-Sleep -Seconds 3
    }
    
    Write-Log "VPN connection initiated: $ProfileName" "SUCCESS"
    return $true
}

# Disconnect VPN
function Disconnect-VPN {
    Write-Log "Disconnecting VPN..."
    
    try {
        # Disconnect all RAS connections
        rasdial 2>&1 | Out-Null
    } catch {}
    
    # Kill VPN processes if needed
    $vpnProcesses = @("antigravity", "openvpn", "vpnagent")
    foreach ($proc in $vpnProcesses) {
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
    }
    
    Write-Log "VPN disconnected" "SUCCESS"
}

# Switch to office network
function Switch-ToOffice {
    Write-Log "Switching to OFFICE network (for MCP/Database)..."
    
    Disconnect-VPN
    $config = Load-Config
    $profile = $config.profiles.office
    
    # Set DNS for office
    if ($profile.dns) {
        Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1).InterfaceIndex -ServerAddresses $profile.dns
        Write-Log "DNS set to: $($profile.dns -join ', ')"
    }
    
    # Add routes if needed
    foreach ($route in $profile.routes) {
        Write-Log "Adding route: $route"
        # route add $route 2>&1 | Out-Null
    }
    
    $env:ACTIVE_NETWORK = "office"
    $env:MCP_HOST = $profile.mcpHost
    $env:MCP_PORT = $profile.mcpPort
    
    Write-Log "Switched to OFFICE network - Ready for MCP/Database" "SUCCESS"
}

# Switch to VPN network
function Switch-ToVPN {
    Write-Log "Switching to VPN network (for External/Coding Agent)..."
    
    $config = Load-Config
    $profile = $config.profiles.vpn
    
    Connect-VPNProfile -ProfileName $profile.vpnProfileName
    
    # Wait for connection
    Start-Sleep -Seconds 2
    
    # Set DNS for external
    if ($profile.dns) {
        Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1).InterfaceIndex -ServerAddresses $profile.dns
        Write-Log "DNS set to: $($profile.dns -join ', ')"
    }
    
    $env:ACTIVE_NETWORK = "vpn"
    unset env:MCP_HOST
    unset env:MCP_PORT
    
    Write-Log "Switched to VPN network - Ready for Coding Agent" "SUCCESS"
}

# Auto-detect based on current directory/context
function Invoke-AutoDetect {
    $cwd = Get-Location
    $config = Load-Config
    
    Write-Log "Auto-detecting network mode for: $cwd"
    
    # Check for MCP-related files
    $mcpFiles = Get-ChildItem -Path $cwd -Recurse -Include @("*.sql", "*mcp*", "*database*", "*.db", "*db*") -ErrorAction SilentlyContinue
    if ($mcpFiles) {
        Write-Log "Detected MCP/Database context - switching to OFFICE" "WARN"
        return "office"
    }
    
    # Check for web/API related files
    $webFiles = Get-ChildItem -Path $cwd -Recurse -Include @("*.html", "*.css", "*.js", "*.ts", "*.json", "*.py", "*.go") -ErrorAction SilentlyContinue
    if ($webFiles) {
        Write-Log "Detected Web/API context - switching to VPN" "WARN"
        return "vpn"
    }
    
    # Default to VPN if unsure
    Write-Log "No specific context detected, defaulting to VPN" "WARN"
    return "vpn"
}

# Main execution
try {
    Write-Log "=== Network Switcher Started ===" "INFO"
    Write-Log "Mode: $Mode"
    
    $config = Load-Config
    $currentStatus = Get-CurrentNetworkStatus
    
    if ($Status) {
        Write-Host "`n=== Current Network Status ===" -ForegroundColor Cyan
        Write-Host "VPN Connected: $($currentStatus.VpnConnected)"
        Write-Host "VPN Name: $($currentStatus.VpnName)"
        Write-Host "Active Adapter: $($currentStatus.AdapterName)"
        Write-Host "Active Network: $env:ACTIVE_NETWORK"
        Write-Host ""
        return
    }
    
    if ($ListProfiles) {
        Write-Host "`n=== Available Network Profiles ===" -ForegroundColor Cyan
        foreach ($key in $config.profiles.PSObject.Properties.Name) {
            $p = $config.profiles.$key
            Write-Host "`n[$key]" -ForegroundColor Yellow
            Write-Host "  Name: $($p.name)"
            Write-Host "  Description: $($p.description)"
            Write-Host "  VPN Required: $($p.vpnEnabled)"
        }
        Write-Host ""
        return
    }
    
    # Execute based on mode
    switch ($Mode) {
        "office" { Switch-ToOffice }
        "vpn" { Switch-ToVPN }
        "auto" { 
            $detected = Invoke-AutoDetect
            switch ($detected) {
                "office" { Switch-ToOffice }
                "vpn" { Switch-ToVPN }
            }
        }
    }
    
    Write-Log "=== Network Switcher Completed ===" "INFO"
    
} catch {
    Write-Log "Error: $_" "ERROR"
    exit 1
}
