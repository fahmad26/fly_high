# Figma dan Blender MCP — 11 November 2026

## Pemeriksaan ulang 15 November 2026 — Codex

Plugin Figma masih terdaftar aktif, tetapi panggilan native chat (`figma.whoami` dan `figma.create_session`) gagal dengan `Unknown tool`. Status terpasang dan hasil `whoami` lama di bawah tidak membuktikan koneksi chat saat ini berfungsi.

Pemulihan: menambahkan server remote resmi bernama `figma` melalui `codex mcp add figma --url https://mcp.figma.com/mcp`. Login OAuth berhasil. Probe app-server Codex yang baru diinisialisasi berhasil menemukan **Figma MCP Server 1.0.0**, `authStatus=oAuth`, **47 tool**, `toolsError=null`. [Bukti dan batas pemeriksaan](../../audit/figma-reconnect-2026-11-15/README.md).

Konfigurasi sebelum perubahan dicadangkan di `C:/Users/fahma/.codex/config.before-figma-reconnect-20261115.toml`. Konfigurasi Roblox dan Blender tetap sama. Entri `node_repl.args` terdeteksi berbeda saat pemeriksaan setelah login; tidak dipulihkan dari backup agar perubahan sesi tidak tertimpa. Tidak mengubah scene, source, atau place.

**Pemeriksaan lanjutan 15 November, 12:33 WIB:** server `mcp__figma` tersedia di chat; `whoami` berhasil, session `338471a6-da08-494e-9931-1f4940034888` dibuat, dan `get_design_context` berhasil membaca file `hsDf2FbnHnlSViAOq5DPJt` node `6:2`, panel `6:428`, serta glyph `6:439`. Respons panel memuat screenshot dan konteks detail. Koneksi baca Figma kini terverifikasi. [Implementasi dan QA ikon Daily Login](../../audit/daily-dock-icon-2026-11-15/README.md). Koneksi lama `codex_apps/figma.*` sebelumnya gagal; gunakan namespace server baru, bukan menganggap semua jalur plugin telah pulih.

## Status historis 11–14 November

- **Figma (Antigravity & Codex):**
  - **Antigravity (14 November 2026):** plugin resmi **Figma** (`antigravity-plugins-partners/plugin/figma`, terpasang di `C:/Users/fahma/.gemini/config/plugins/figma`) dan server MCP `figma_figma` beserta 17 skill Figma sudah aktif. Panggilan verifikasi `whoami` berhasil (`handle: "Fikri Ahmad"`, `user_id: "1702381256978829211"`, `plans: "Fikri Ahmad's team"`, `code_layers_enabled: true`, `specs_enabled: true`).
  - **Codex (11 November 2026):** integrasi resmi Figma pada Codex sudah dihubungkan pengguna (`whoami` lulus). Tidak membuat/mengubah file desain untuk tes koneksi; izin edit per file tetap mengikuti akun. Tidak memasang server desktop duplikat atau memasukkan token ke repo.
- **Blender:** add-on aktif di Blender 5.3.0 yang sudah terbuka, listener localhost:9876. Server stdio terdaftar global pada Codex sebagai blender. Handshake, daftar sembilan tool, get_addon_status dan get_scene_info lulus melalui SDK MCP terpisah. Scene masih Cube/Camera/Light; geometri tidak diubah.
- **Batas sesi:** Blender belum menjadi tool native pada chat yang sudah berjalan sebelum konfigurasi ditambahkan. Tutup dan buka ulang Codex untuk memuat server; Blender boleh tetap terbuka.

## Instalasi lokal

- Config: C:/Users/fahma/.codex/config.toml. Backup sebelum perubahan: C:/Users/fahma/.codex/config.before-blender-mcp-20261111.toml. Konfigurasi Roblox dan plugin lain dipertahankan.
- Executable: E:/Antigravity/Fly High/.local-tools/blender-mcp-env/Scripts/mcp-for-blender.exe. Tidak memerlukan uvx global.
- Add-on: C:/Users/fahma/AppData/Roaming/Blender Foundation/Blender/5.3/scripts/addons/blender_mcp.py.
- Add-on diaktifkan dan preferensi enable disimpan setelah pengguna memberi persetujuan eksplisit. Listener dimulai di aplikasi yang sudah terbuka, lalu editor dikembalikan ke 3D Viewport. Scene unsaved pengguna tidak disimpan/ditimpa.
- Source checkout, wheel, dan venv berada di .local-tools/ yang diabaikan Git. Jangan pindahkan/hapus folder itu tanpa memperbarui command MCP.

Konfigurasi:

```toml
[mcp_servers.blender]
command = "E:/Antigravity/Fly High/.local-tools/blender-mcp-env/Scripts/mcp-for-blender.exe"

[mcp_servers.blender.env]
BLENDER_HOST = "127.0.0.1"
BLENDER_PORT = "9876"
BLENDER_MCP_SAFE_MODE = "1"
DISABLE_TELEMETRY = "true"
```

Saat membuka Blender lagi, buka sidebar N → BlenderMCP dan mulai koneksi bila belum berjalan. Verifikasi status sebelum memodifikasi scene. Figma dapat digunakan melalui integrasi resmi tanpa localhost:3845. Server desktop Figma memiliki persyaratan plan/seat tersendiri dan tidak dipasang dalam pekerjaan ini.

## Sumber dan pemeriksaan keamanan

Blender adalah integrasi komunitas, bukan produk Blender Foundation. Source ditinjau pada commit 2e4b0bc294694b1570d76ed01be657c22e6d02a0 dari ahujasid/mcp-for-blender, versi paket 2.2.7. Wheel rilis PyPI 2.2.7 dibandingkan dengan source: seluruh file blender_mcp sama setelah normalisasi CRLF/LF kecuali satu modul tambahan config.py. Modul itu diperiksa secara AST: hanya dataclass konfigurasi; tidak ada downloader/exec/subprocess. Wheel resmi dipakai karena build source tidak menyertakan config.py yang diperlukan jalur telemetry/status.

SHA-256 wheel: 2FD2AD6F9304F8217167C08DC61C18642BC08A9F43FB2C3988EEE4851640472C.

SHA-256 add-on terpasang: 238C1FE8496D01CE8F44EBF0CEC3C0F0D0009E225D2D9BBEF835A697F937341C.

Pemeriksaan: entrypoint dan dependencies, addon register/start socket, listener default localhost/remote false, telemetry consent false, server DISABLE_TELEMETRY, validator safe mode, download/eksekusi opsional. Tidak menjalankan script installer dari internet. Dependensi dicatat di [requirements.lock.txt](../../tools/mcp/requirements.lock.txt); bukan audit lengkap semua dependency.

Safe mode menerima contoh pembacaan bpy dan menolak import os dalam verifikasi lokal. Ini membatasi jalur execute_blender_code MCP; **bukan sandbox penuh Blender**. Socket addon tidak memiliki autentikasi, sehingga harus tetap loopback. Tidak memasang API key, tidak mengaktifkan penyedia aset/generasi berbayar. Status akhir melaporkan Poly Haven/Sketchfab/Poly Pizza dan semua generator off, telemetry_consent=false.

## Bukti dan pemulihan

[Probe MCP](../../tools/mcp/check_blender.py) memakai stdio resmi, bukan hanya tes port. [Hasil](../../audit/mcp-setup-2026-11-11/blender-probe.jsonl) dan [log](../../audit/mcp-setup-2026-11-11/blender-probe.log). Protokol add-on 15 cocok; warning telemetry disabled adalah hasil pengaturan yang disengaja.

Tes pertama sebelum aktivasi berhasil menemukan tool tetapi belum dapat terhubung ke addon; tes akhir sudah berhasil. Peringatan runpy pada entrypoint python -m diatasi dengan memakai executable console paket. Probe awal dalam sandbox tidak selesai; dihentikan dan diulang dengan izin subprocess/localhost yang disetujui. Tidak mengklaim pengujian desain Figma, ekspor GLB atau pemodelan Blender sudah dilakukan.

Jika MCP tidak muncul setelah restart Codex: cek server blender pada Settings → MCP servers, pastikan path executable masih ada, lalu cek listener melalui sidebar Blender. Untuk membatalkan setup, hapus hanya entri mcp_servers.blender, disable add-on Blender, dan hapus file add-on hanya setelah memastikan tidak ada modifikasi pengguna. Jangan menimpa seluruh config dari backup jika ada perubahan lain sesudahnya.

Rujukan primer: [Konfigurasi MCP Codex](https://learn.chatgpt.com/docs/extend/mcp?surface=cli), [Figma desktop MCP](https://developers.figma.com/docs/figma-mcp-server/local-server-installation/), [MCP for Blender](https://github.com/ahujasid/mcp-for-blender).

## Unggah model Roblox — 15 November 2026

Atas persetujuan pengguna dibuat experience development privat: universe `10776821830`, place `97043730132219`, akun `8635452105`. PRIVATE terverifikasi lewat Open Cloud. Scope `asset:read` dan `asset:write` aktif dan izin direktori `E:/Antigravity/Fly High/assets/models/obstacles/generated` disetujui pengguna. Jangan memperluas ke seluruh workspace.

Di Assistant Settings → MCP Permissions, penambahan direktori belum berlaku sampai tombol **Save di bagian paling bawah panel** ditekan. Mengklik Select Folder saja hanya menambah draft. Bila unggahan masih ditolak, buka ulang panel dan verifikasi persistensi sebelum mencoba ulang; jangan mengubah format path, memindah file atau memakai endpoint lain untuk melewati penolakan.

Paket model `99873351598859` berhasil diunggah/Approved dan dipasang. [Bukti, struktur impor dan batas QA](../../audit/obstacle-polish-implementation-2026-11-15/README.md). `save_place` pada sesi ini tetap menulis file lokal. Pembuatan experience privat tidak membuktikan bahwa perubahan lokal sesudahnya sudah tersimpan sebagai versi cloud terbaru.

GameId nonzero mengubah jalur DataManager dari mock unpublished ke persistensi. API Services Studio belum diaktifkan, sehingga Play Solo berhenti pada pemuatan data. Jangan mengaktifkan akses data hanya untuk menghindari pesan error; pisahkan pengujian visual terisolasi dari pengujian persistensi yang perlu otorisasi dan fixture tersendiri.
