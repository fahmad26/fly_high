# Sumber ikon dock Harian

- `calendar.svg`: ekspor asli Figma file `hsDf2FbnHnlSViAOq5DPJt`, node `6:439`, diunduh 15 November 2026 dari URL aset yang dikembalikan `get_design_context`. Tidak menggambar ulang atau mengubah path glyph.
- `frame.svg`: bingkai kode vektor, disesuaikan atas permintaan pengguna dengan keluarga HUD game: navy, emas tipis, enamel cyan, gloss kiri atas. Mengadaptasi latar emas mockup panel `6:428` agar konsisten dengan ikon HUD yang sudah dipakai.
- Build: `node tools/build_daily_dock_icon.cjs <path-modul-sharp>`, menghasilkan `generated/daily-shop/icon_daily_dock.png` (256×256 RGBA). Tidak memakai screenshot Figma sebagai aset implementasi.
- Roblox: `rbxassetid://109624962100172`; pemetaan di `roblox-texture-ids.json` dan `HUDAdventureCatalog.luau`. Badge/status/label dirender dinamis oleh UI, tidak dibakar ke PNG.
