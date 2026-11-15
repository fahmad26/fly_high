# Publish experience privat dan parity source — 15 November 2026

Tugas dokumentasi dan pemeriksaan read-only oleh Claude. Tidak ada edit game, Playtest, simpan place, commit atau push dari sesi ini.

## Urutan kejadian (WIB)

1. ±21:05 — MCP Roblox Studio dan Blender tersambung ke sesi Claude melalui aplikasi desktop.
2. ±21:07 — Studio sempat membuka place cloud lain, **"Fly High: Cloud Palace"** (place 107361757876418 / universe 10773510320). Place ini tidak tercatat di dokumentasi proyek dan tidak disentuh.
3. ±21:10 — Studio membuka place cloud 97043730132219 / universe 10776821830 dari cloud. Isinya **lebih lama**: 52 source, tanpa `ObstacleVisuals` dan `SceneryHabitatArt` (checkpoint 17:50 dan 18:25 WIB). Tidak disimpan ke file lokal.
4. ±21:13 — **Pengguna** membuka `E:/Antigravity/Fly High/Fly High.rbxl` lalu mem-publish-nya ke place 97043730132219 (experience privat). Publish dilakukan pengguna di Studio, bukan oleh alat.
5. 21:19:58 WIB — [state Studio](studio-parity.json) sesudah publish: Edit, file `Fly High.rbxl`, persistedToCloud, PlaceId 97043730132219, GameId 10776821830, 54 source, 0 pemain. `game.CreatorId` terbaca 0 pada sesi file ini (pada sesi buka-dari-cloud sebelumnya 8635452105).

## Hasil

- [Perbandingan](comparison.json): 54 source Studio (dibaca dengan `ScriptEditorService:GetEditorSource`) vs 54 file mirror `audit/sources`; **0 selisih**, tidak ada source yang hanya ada di salah satu sisi. Normalisasi UTF-8, CRLF→LF, LF akhir dihapus. Metode panjang byte + FNV-1a 32-bit: **pemeriksaan checksum**, bukan bukti kesamaan isi persis. SHA-256 sisi mirror dicatat; sisi Studio tidak di-hash kriptografis.
- File lokal tidak berubah oleh publish: 2.164.854 B, SHA-256 `EA632B7B6AE0219EE5802DB6843203734AB33D79E32C5EE16D0B3E3B0D072495`, mtime 2026-11-15T11:25:42Z (18:25 WIB).
- Git: main `969892d`, origin/main lokal sama (tidak di-fetch), 60 entri working tree belum commit.

## Batas

- Versi cloud tidak diunduh/dibuka ulang terpisah setelah publish. Kesamaan cloud ↔ file lokal disimpulkan dari sesi Studio yang terbuka dari file lalu di-publish, ditambah parity source di atas. Terrain, model, atribut dan properti non-script tidak dibandingkan.
- Binary `.rbxl` tidak dibuka ulang. Belum ada uji DataStore/produk pada universe ini.
