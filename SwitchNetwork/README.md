# Network Switcher - Dokumentasi

## Overview

Network Switcher adalah solusi untuk switching jaringan otomatis berdasarkan konteks pekerjaan:
- **VPN (External)** → Coding Agent (web/API development)
- **Office (LAN)** → MCP Database connections

## Struktur File

```
SwitchNetwork/
├── config/
│   └── network-profiles.json    # Konfigurasi profile jaringan
├── scripts/
│   ├── launcher.ps1            # Launcher auto-switch
│   └── context-watcher.ps1      # Background watcher
├── NetworkSwitcher.ps1          # Core switcher script
└── launcher.ps1                 # AI Agent launcher
```

## Konfigurasi

Edit file `config/network-profiles.json` untuk menyesuaikan dengan environment Anda:

```json
{
  "profiles": {
    "office": {
      "name": "Jaringan Kantor",
      "mcpHost": "db-server-kantor.internal",  // Host database Anda
      "mcpPort": 5432                         // Port database
    },
    "vpn": {
      "name": "VPN External",
      "vpnProfileName": "Antigravity"        // nama profile VPN Anda
    }
  }
}
```

## Cara Penggunaan

### Mode 1: Manual Switch

```powershell
# Switch ke jaringan kantor (untuk MCP/DB)
.\NetworkSwitcher.ps1 -Mode office

# Switch ke VPN (untuk coding agent)
.\NetworkSwitcher.ps1 -Mode vpn

# Cek status jaringan saat ini
.\NetworkSwitcher.ps1 -Status

# List semua profile
.\NetworkSwitcher.ps1 -ListProfiles
```

### Mode 2: Auto-Detect (Otomatis)

```powershell
# Auto-detect berdasarkan direktori kerja
.\NetworkSwitcher.ps1 -Mode auto
```

### Mode 3: Context Watcher (Real-time)

```powershell
# Jalankan background watcher
.\scripts\context-watcher.ps1 -WatchPath "C:\project\anda" -PollingInterval 5
```

Watcher akan otomatis switch jaringan ketika ada perubahan di direktori project.

### Mode 4: AI Agent Launcher

```powershell
# Launch coding agent dengan auto-switch
.\launcher.ps1 -Agent auto

# Launch untuk MCP mode (otomatis ke office)
.\launcher.ps1 -MCP

# Lewati argument ke agent
.\launcher.ps1 -Agent codex -- --help
```

## Environment Variables

Setelah switch, variabel berikut akan di-set:

- `$env:ACTIVE_NETWORK` - "office" atau "vpn"
- `$env:MCP_HOST` - Host database (hanya untuk mode office)
- `$env:MCP_PORT` - Port database (hanya untuk mode office)

## Tips

1. **Edit konfigurasi dulu** - Pastikan `network-profiles.json` sesuai dengan setup Anda
2. **Cek VPN profile** - Pastikan nama VPN profile sesuai dengan yang ada di sistem Anda
3. **Test manual dulu** - Coba switch manual sebelum menggunakan auto mode

## Troubleshooting

### VPN tidak konek
- Cek nama VPN profile di `config/network-profiles.json`
- Buka Windows VPN settings untuk verifikasi

### DNS tidak berubah
- Jalankan PowerShell sebagai Administrator
- Cek network adapter yang aktif
