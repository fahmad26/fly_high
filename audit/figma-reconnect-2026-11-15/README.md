# Pemulihan koneksi Figma MCP — 15 November 2026

- Lingkungan: Windows, Codex CLI bawaan desktop `26.1111.2228.0`; workspace Fly High, baseline Git `969892d` dengan perubahan dokumentasi dari pekerjaan sebelumnya dipertahankan. Tidak menjalankan Playtest atau fixture game.
- Masalah: plugin terpasang, tetapi panggilan native chat `figma.whoami`/`figma.create_session` mengembalikan `Unknown tool`, sebelum akses file diperiksa.
- Tindakan: backup konfigurasi global; tambahkan server `figma` ke endpoint resmi `https://mcp.figma.com/mcp`; alur OAuth CLI selesai dengan `Successfully logged in`. Tidak menyimpan token atau URL otorisasi ke repo.
- Hasil aktual: probe app-server Codex terpisah, tanpa menjalankan agen/model, melakukan `initialize` dan `mcpServerStatus/list` untuk server `figma`. [Respons mentah](mcp-status.json): Figma MCP Server `1.0.0`, `authStatus=oAuth`, 47 tool, `toolsError=null`.
- Pemeriksaan konfigurasi: entri Roblox_Studio dan blender sama dengan backup. Bagian konfigurasi di luar `mcp_servers` sama. `node_repl.args` berubah selama interval pemeriksaan, tidak ditimpa dari backup. Satu nama server baru: `figma`.
- Batas: handshake/list tool lulus; `whoami` melalui koneksi baru dan pembacaan file desain belum diuji. Chat masih memiliki tool plugin lama. Perlu buka ulang Codex, temukan server baru, lalu verifikasi akun/session/metadata/screenshot sebelum melanjutkan ikon Daily Login.
- Cleanup: proses probe app-server dihentikan. Studio/place/source/aset tidak diubah. Tidak commit/push pada pekerjaan reconnect ini.

Rujukan: [setup resmi Figma untuk Codex](https://help.figma.com/hc/en-us/articles/39888629089175-Codex-and-Figma-Set-up-the-MCP-server), [konfigurasi MCP Codex](https://learn.chatgpt.com/docs/extend/mcp?surface=cli).

## Pemeriksaan lanjutan pada sesi berikutnya

Server native `mcp__figma` tersedia. `whoami` berhasil dan session `338471a6-da08-494e-9931-1f4940034888` dibuat untuk file referensi. Pembacaan `get_design_context` panel `6:428` berhasil beserta screenshot; glyph `6:439` berhasil diekspor. Batas akses file pada run handshake di atas sudah ditindaklanjuti oleh [run ikon Daily Login](../daily-dock-icon-2026-11-15/README.md). Jalur plugin lama tidak digunakan untuk implementasi ini.
