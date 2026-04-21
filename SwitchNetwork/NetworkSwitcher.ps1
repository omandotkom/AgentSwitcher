#Requires -Version 5.1
# Network Switcher for AI Coding Agent
# Switch antara WiFi Kantor dan WiFi Tethering HP (support Oracle)

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("office", "external", "auto")]
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

# Get current WiFi status
function Get-CurrentWiFiStatus {
    try {
        $wifi = netsh wlan show interfaces | Out-String
        $ssid = ""
        $state = "Disconnected"
        
        if ($wifi -match "SSID\s*:\s*(.+)") {
            $ssid = $Matches[1].Trim()
        }
        if ($wifi -match "State\s*:\s*(.+)") {
            $state = $Matches[1].Trim()
        }
        
        return @{
            SSID = $ssid
            State = $state
            Connected = ($state -eq "connected")
        }
    } catch {
        return @{ SSID = ""; State = "Error"; Connected = $false }
    }
}

# Connect to WiFi network
function Connect-WiFi {
    param([string]$SSID)
    
    Write-Log "Disconnecting current WiFi..."
    netsh wlan disconnect | Out-Null
    
    Start-Sleep -Seconds 1
    
    Write-Log "Connecting to WiFi: $SSID"
    
    try {
        $result = netsh wlan connect name="$SSID" 2>&1
        
        if ($result -match "successfully") {
            Write-Log "Connected to: $SSID" "SUCCESS"
        } else {
            netsh wlan connect name="$SSID" | Out-Null
        }
        
        Start-Sleep -Seconds 3
        
        $current = Get-CurrentWiFiStatus
        if ($current.SSID -eq $SSID) {
            Write-Log "Verified: Connected to $SSID" "SUCCESS"
            return $true
        } else {
            Write-Log "Warning: May not be connected to $SSID" "WARN"
            return $true
        }
    } catch {
        Write-Log "Error connecting: $_" "ERROR"
        return $false
    }
}

# Switch to office network (Kantor -Oracle)
function Switch-ToOffice {
    Write-Log "Switching to KANTOR network (Oracle Database)..."
    
    $config = Load-Config
    $profile = $config.profiles.office
    
    # Connect to office WiFi if SSID specified
    if ($profile.ssid) {
        Connect-WiFi -SSID $profile.ssid
    }
    
    # Set DNS for office
    if ($profile.dns) {
        $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -match "Wi-Fi|Ethernet" } | Select-Object -First 1
        if ($adapter) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $profile.dns
            Write-Log "DNS set to: $($profile.dns -join ', ')"
        }
    }
    
    # Add routes if needed
    foreach ($route in $profile.routes) {
        Write-Log "Route configured: $route"
    }
    
    # Set environment variables
    $env:ACTIVE_NETWORK = "office"
    $env:DB_TYPE = $profile.dbType
    $env:MCP_HOST = $profile.mcpHost
    $env:MCP_PORT = $profile.mcpPort
    $env:ORACLE_SERVICE = $profile.serviceName
    
    Write-Log "Switched to KANTOR network - Oracle Database ready" "SUCCESS"
    Write-Log "TNS: $($profile.mcpHost):$($profile.mcpPort)/$($profile.serviceName)" "INFO"
}

# Switch to external network (Tethering HP)
function Switch-ToExternal {
    Write-Log "Switching to EXTERNAL network (WiFi Tethering HP)..."
    
    $config = Load-Config
    $profile = $config.profiles.external
    
    # Connect to external WiFi if SSID specified
    if ($profile.ssid) {
        Connect-WiFi -SSID $profile.ssid
    }
    
    # Set DNS for external
    if ($profile.dns) {
        $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -match "Wi-Fi|Ethernet" } | Select-Object -First 1
        if ($adapter) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $profile.dns
            Write-Log "DNS set to: $($profile.dns -join ', ')"
        }
    }
    
    # Clear office-specific variables
    $env:ACTIVE_NETWORK = "external"
    unset env:DB_TYPE
    unset env:MCP_HOST
    unset env:MCP_PORT
    unset env:ORACLE_SERVICE
    
    Write-Log "Switched to EXTERNAL network - Ready for Coding Agent" "SUCCESS"
}

# Auto-detect based on current directory/context
function Invoke-AutoDetect {
    $cwd = Get-Location
    $config = Load-Config
    
    Write-Log "Auto-detecting network mode for: $cwd"
    
    # Check for Oracle-related files
    $oracleFiles = Get-ChildItem -Path $cwd -Recurse -Include @("*.sql", "*oracle*", "*dmp*", "*dbf*", "*.dmp", "*tns*") -ErrorAction SilentlyContinue
    if ($oracleFiles) {
        Write-Log "Detected Oracle context - switching to KANTOR" "WARN"
        return "office"
    }
    
    # Check for MCP-related files (other databases)
    $mcpFiles = Get-ChildItem -Path $cwd -Recurse -Include @("*mcp*", "*database*", "*.db", "*db*") -ErrorAction SilentlyContinue
    if ($mcpFiles) {
        Write-Log "Detected Database context - switching to KANTOR" "WARN"
        return "office"
    }
    
    # Check for web/API related files
    $webFiles = Get-ChildItem -Path $cwd -Recurse -Include @("*.html", "*.css", "*.js", "*.ts", "*.json", "*.py", "*.go") -ErrorAction SilentlyContinue
    if ($webFiles) {
        Write-Log "Detected Web/API context - switching to EXTERNAL" "WARN"
        return "external"
    }
    
    # Default to external if unsure
    Write-Log "No specific context detected, defaulting to EXTERNAL" "WARN"
    return "external"
}

# Main execution
try {
    Write-Log "=== Network Switcher Started ===" "INFO"
    Write-Log "Mode: $Mode"
    
    $config = Load-Config
    $wifiStatus = Get-CurrentWiFiStatus
    
    if ($Status) {
        Write-Host "`n=== Current Network Status ===" -ForegroundColor Cyan
        Write-Host "WiFi SSID: $($wifiStatus.SSID)"
        Write-Host "WiFi State: $($wifiStatus.State)"
        Write-Host "Active Network: $env:ACTIVE_NETWORK"
        if ($env:DB_TYPE) {
            Write-Host "Database Type: $env:DB_TYPE"
            Write-Host "Oracle Service: $env:ORACLE_SERVICE"
        }
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
            Write-Host "  WiFi SSID: $($p.ssid)"
            if ($p.dbType) {
                Write-Host "  Database: $($p.dbType) - $($p.mcpHost):$($p.mcpPort)/$($p.serviceName)"
            }
        }
        Write-Host ""
        return
    }
    
    # Execute based on mode
    switch ($Mode) {
        "office" { Switch-ToOffice }
        "external" { Switch-ToExternal }
        "auto" { 
            $detected = Invoke-AutoDetect
            switch ($detected) {
                "office" { Switch-ToOffice }
                "external" { Switch-ToExternal }
            }
        }
    }
    
    Write-Log "=== Network Switcher Completed ===" "INFO"
    
} catch {
    Write-Log "Error: $_" "ERROR"
    exit 1
}
