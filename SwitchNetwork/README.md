# AgentSwitcher - Auto Network Switcher for AI Coding Agents

## Apa Itu AgentSwitcher?

AgentSwitcher adalah tool untuk **otomatis switch jaringan WiFi** berdasarkan konteks pekerjaan:

| Konteks Pekerjaan | Jaringan |
|------------------|----------|
| Coding Agent (codex, claude, cursor) | WiFi Tethering HP (External) |
| Web/API Development | WiFi Tethering HP (External) |
| Database/MCP Connection | WiFi Kantor (LAN) |

**Masalah yang diselesaikan:**
- Coding agent di blok saat pake WiFi kantor
- Database tidak bisa diakses saat pake WiFi tethering HP
- Harus手动 switch WiFi setiap kali ganti kerjaan

## Prerequisites

- Windows 10/11 dengan PowerShell 5.1+
- Dua jaringan WiFi:
  - WiFi Kantor / Ethernet
  - WiFi Tethering HP (hotspot)

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
⊙ Step 1/4: Jaringan Kantor (WiFi/Ethernet)
  Nama WiFi (SSID): OFFICE_WIFI
  MCP/Database Host: db-kantor.company.local
  MCP/Database Port: 5432

⊙ Step 2/4: Jaringan External (WiFi Tethering HP)  
  Nama WiFi HP (SSID): Hotspot-Android

⊙ Step 3/4: Review Konfigurasi
  Jaringan Kantor:
    WiFi SSID: OFFICE_WIFI
    MCP Host: db-kantor.company.local
    
  Jaringan External:
    WiFi SSID: Hotspot-Android

⊙ Konfigurasi tersimpan!
```

File konfigurasi tersimpan di `config/network-profiles.json`.

## Cara Pakai

### Cara 1: Launcher ( Paling Mudah )

Gunakan `launcher.ps1` untuk langsung jalankan coding agent dengan network sudah otomatis switch.

```powershell
# Untuk Coding Agent (otomatis ke WiFi Tethering HP)
.\launcher.ps1 -Agent auto

# Untuk MCP/Database (otomatis ke WiFi Kantor)
.\launcher.ps1 -MCP
```

**Output contoh:**
```
⊙ AI Coding Agent Launcher with Network Auto-Switch

[1/4] Detecting agent...
      Found: codex
[2/4] Determining network mode...
      Mode: External (Tethering HP)
[3/4] Switching network...
      Disconnecting current WiFi...
      Connecting to WiFi: Hotspot-Android
      Connected to: Hotspot-Android
[4/4] Launching agent...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Starting: codex
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Cara 2: Manual Switch

Switch jaringan secara manual:

```powershell
# Switch ke WiFi Tethering HP (untuk coding agent)
.\NetworkSwitcher.ps1 -Mode external

# Switch ke WiFi Kantor (untuk database)
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
WiFi SSID: Hotspot-Android
WiFi State: connected
Active Network: external
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
[Watcher] 09:15:35 - Context changed: external -> office
[Watcher] Switching to KANTOR network...
[Watcher] Connected to OFFICE_WIFI
[Watcher] Network switched to: Kantor
```

## Penjelasan Setiap Mode

### Mode External (WiFi Tethering HP)

- Connect ke WiFi hotspot HP
- DNS: 1.1.1.1, 8.8.8.8 (Cloudflare/Google)
- Cocok untuk: coding agent, web API, npm install, git push

### Mode Office (WiFi Kantor/Ethernet)

- Connect ke WiFi kantor
- DNS: sesuai konfigurasi kantor
- Add routes: 10.0.0.0/8, 172.16.0.0/12
- Set environment: MCP_HOST, MCP_PORT
- Cocok untuk: koneksi database, MCP server

## Environment Variables

Setelah switch, variable berikut akan di-set:

| Variable | Mode | Contoh |
|----------|-----|---------|
| ACTIVE_NETWORK | all | "external" / "office" |
| MCP_HOST | office only | "db-kantor.company.local" |
| MCP_PORT | office only | 5432 |

## Troubleshooting

### WiFi tidak konek

1. Cek nama WiFi SSID:
   ```powershell
   netsh wlan show networks mode=bssid
   ```
2. Pastikan SSID sama persis dengan di `network-profiles.json`
3. Coba connect manual dulu

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

### Coding agent tidak ditemukan

Pastikan coding agent sudah terinstall:
- Codex: `pip install openai-codex`
- Claude Code: `npm install -g @anthropic-ai/claude-code`
- Cursor: download dari https://cursor.sh

## Auto-Detection Keywords

Script会自动 detect context dari keywords:

| Keywords | Switch ke |
|----------|-----------|
| database, db, sql, mcp, postgres | WiFi Kantor |
| api, http, web, html, js, ts | WiFi Tethering HP |

## Lisensi

MIT License - Bebas pakai dan modifikasi.

## Kontribusi

PR welcome! https://github.com/omandotkom/AgentSwitcher
