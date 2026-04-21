# AgentSwitcher - Auto Network Switcher for AI Coding Agents

## Apa Itu AgentSwitcher?

AgentSwitcher adalah tool untuk **otomatis switch jaringan** berdasarkan konteks pekerjaan:

| Konteks Pekerjaan | Jaringan |
|------------------|----------|
| Coding Agent (codex, claude, cursor) | VPN (External) |
| Web/API Development | VPN (External) |
| Database/MCP Connection | Kantor (LAN) |

**Masalah yang diselesaikan:**
- Coding agent di blok saat pake jaringan kantor
- Database tidak bisa diakses saat pake VPN
- Harus手动 switch network setiap kali ganti kerjaan

## Prerequisites

- Windows 10/11 dengan PowerShell 5.1+
- VPN profile sudah terkonfigurasi (contoh: Antigravity)
- Access ke jaringan kantor dan VPN

## Struktur File

```
AgentSwitcher/
├── config/
│   └── network-profiles.json    # Konfigurasi jaringan
├── scripts/
│   ├── setup-wizard.ps1         # Setup interaktif
│   ├── launcher.ps1            # Auto-switch launcher
│   └── context-watcher.ps1    # Background context monitor
├── NetworkSwitcher.ps1         # Core switcher script
├── launcher.ps1                 # AI Agent launcher
└── README.md                   # Dokumentasi ini
```

## Instalasi

### Clone Repository

```bash
git clone https://github.com/omandotkom/AgentSwitcher.git
cd AgentSwitcher
```

### Setup Konfigurasi (WAJIB)

Jalankan wizard untuk setup konfigurasi jaringan Anda:

```powershell
.\scripts\setup-wizard.ps1
```

**Contoh input:**
```
⊙ Konfigurasi Jaringan Kantor
  MCP/Database Host: db-kantor.company.local
  MCP/Database Port: 5432
  Gateway IP: 192.168.1.1
  DNS Servers: 192.168.1.100,192.168.1.101

⊙ Konfigurasi VPN  
  VPN Profile Name: Antigravity

⊙ Konfigurasi tersimpan!
```

File konfigurasi tersimpan di `config/network-profiles.json`.

## Cara Pakai

### Cara 1: Launcher ( Paling Mudah )

Gunakan `launcher.ps1` untuk langsung jalankan coding agent dengan network sudah otomatis switch.

```powershell
# Untuk Coding Agent (otomatis ke VPN)
.\launcher.ps1 -Agent auto

# Untuk MCP/Database (otomatis ke Kantor)
.\launcher.ps1 -MCP
```

**Output contoh:**
```
⊙ AI Coding Agent Launcher with Network Auto-Switch

[1/4] Detecting agent...
      Found: codex
[2/4] Determining network mode...
      Mode: vpn
[3/4] Switching network...
      VPN connected
      DNS set to: 1.1.1.1, 8.8.8.8
[4/4] Launching agent...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Starting: codex
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Cara 2: Manual Switch

Switch jaringan secara manual:

```powershell
# Switch ke VPN (untuk coding agent)
.\NetworkSwitcher.ps1 -Mode vpn

# Switch ke Kantor (untuk database)
.\NetworkSwitcher.ps1 -Mode office

# Auto-detect berdasarkan direktori kerja
.\NetworkSwitcher.ps1 -Mode auto
```

**Cek status jaringan:**
```powershell
.\NetworkSwitcher.ps1 -Status
```

**Output contoh:**
```
=== Current Network Status ===
VPN Connected: True
VPN Name: Antigravity
Active Adapter: Wi-Fi
Active Network: vpn
```

**Lihat semua profile:**
```powershell
.\NetworkSwitcher.ps1 -ListProfiles
```

### Cara 3: Context Watcher (Real-time)

Jalankan di background untuk auto-switch实时:

```powershell
# Monitor direktori project secara real-time
.\scripts\context-watcher.ps1 -WatchPath "C:\project\saya" -PollingInterval 5
```

**Output contoh:**
```
========================================
  Context Watcher - Auto Network Switch
========================================
Watch Path: C:\project\saya
Polling Interval: 5 seconds
Press Ctrl+C to stop

[Watcher] 09:15:30 - Starting context detection...
[Watcher] 09:15:35 - Context changed: vpn -> office
[Watcher] Switching to OFFICE network...
[Watcher] Office network activated
[Watcher] Network switched to: office
```

## Penjelasan Setiap Mode

### Mode VPN (External)

- Connect ke VPN profile (contoh: Antigravity)
- DNS: 1.1.1.1, 8.8.8.8 (Cloudflare/Google)
- Cocok untuk: coding agent, web API, npm install, git push

### Mode Kantor (Office/LAN)

- Disconnect VPN
- DNS: sesuai konfigurasi kantor
- Add routes: 10.0.0.0/8, 172.16.0.0/12
- Set environment: MCP_HOST, MCP_PORT
- Cocok untuk: koneksi database, MCP server

## Environment Variables

Setelah switch, variable berikut akan di-set:

| Variable | Mode | Contoh |
|----------|-----|---------|
| ACTIVE_NETWORK | all | "vpn" / "office" |
| MCP_HOST | office only | "db-kantor.company.local" |
| MCP_PORT | office only | 5432 |

## Troubleshooting

### VPN tidak konek

1. Cek nama VPN profile:
   ```powershell
   Get-VpnConnection
   ```
2. Pastikan profile name sama dengan di `network-profiles.json`
3. Buka Windows Settings > Network > VPN untuk test manual

### Script error "Access Denied"

1. Klik kanan PowerShell
2. Pilih "Run as Administrator"
3. Jalankan script lagi

### DNS tidak berubah

1. Jalankan sebagai Administrator
2. Cek nama network adapter:
   ```powershell
   Get-NetAdapter | Where-Object Status -eq "Up"
   ```
3. Sesuaikan nama adapter di script jika perlu

### Coding agent tidak ditemukan

Pastikan coding agent sudah terinstall:
- Codex: `pip install openai-codex`
- Claude Code: `npm install -g @anthropic-ai/claude-code`
- Cursor: download dari https://cursor.sh

## Fitur Tambahan

### Auto-Detection Keywords

Script会自动 detect context dari keywords:

| Keywords | Switch ke |
|----------|-----------|
| database, db, sql, mcp, postgres | Office |
| api, http, web, html, js, ts | VPN |

### Logging

Semua activity di-log ke:
```
logs\switcher-YYYYMMDD.log
```

## Lisensi

MIT License - Bebas pakai dan modifikasi.

## Kontribusi

PR welcome! https://github.com/omandotkom/AgentSwitcher
