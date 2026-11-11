# Figma dan Blender MCP — 11 November 2026

## Status

- **Figma:** integrasi resmi Figma pada Codex sudah dihubungkan pengguna. Tool whoami berhasil dan tool Figma tersedia di sesi ini. Tidak membuat/mengubah file desain untuk tes koneksi; izin edit per file tetap mengikuti akun. Tidak memasang server desktop duplikat atau memasukkan token ke repo.
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
