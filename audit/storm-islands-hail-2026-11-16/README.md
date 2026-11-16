# Awan badai, bawah pulau, Hailstone — 16 November 2026, 22:20–22:40 WIB

Masukan pengguna dari screenshot playtest (`storm_clouds_before_user.png`, `islands_before_user.png`):

1. "Apakah bentuk awan ini intentional?"
2. "Bagian bawah pulau punya bentuk runcing yang agak aneh."
3. "Hailstone… tolong improve ya."

## Perubahan

| Temuan | Perbaikan |
|---|---|
| Piring gelap di bawah tiap menara awan badai | `gustShelf` tidak lagi dibuat. Dasar awan kini hanya CloudBaseMist. |
| Lempeng anvil datar bergaris tepi | `VEIL_SIDE_T` 0,55 → 0,72; `VEIL_TOP_T` 0,86 → 0,90 |
| Dek awan rendah seperti pancake | Congestus dek diubah dari 1,2 × 0,32 × 2,2 menjadi 1,2 × 0,55 × 1,6 |
| Bawah pulau berujung jarum + stalaktit | Mesh batu IslandKit v3 (aset 77785941045525). Detail di bawah tabel. |
| Hailstone berupa telur kaca bersegi | Hailstone v5 (aset 95048105166805), tiga varian. Detail di bawah tabel. |

**IslandKit v3:** stalaktit lepas dihapus, bagian bawah dibuat lebih lebar dan membulat, tinggi lunas dikurangi ±27%, dan ujungnya dihaluskan. SurfaceAppearance dan atribut dipindahkan dari part lama, sedangkan SourceCenter diperbarui. Template lama disimpan di `ServerStorage.IslandKit_Legacy`. Generator: `tools/fix_island_undersides.py`.

**Hailstone v5:**
- Cangkang Glass tembus dengan cincin pertumbuhan.
- Inti beku `FrostCore` (Ice) yang terlihat dari luar.
- Kristal es heksagonal yang mencuat.
- Template lama disimpan di `ServerStorage.ObstacleMeshes_Legacy`. Generator: `tools/build_hailstone.py`.

Garis hijau horizontal di screenshot pengguna adalah artefak saat screenshot, bukan bagian dari game (konfirmasi pengguna).

## Verifikasi

- **Viewport:** sempat tidak merender (layar gelap), lalu kembali normal setelah pengguna mengkliknya.
- **Fixture Edit:** kelima zona di-build tanpa error (1.675 / 770 / 1.610 / 1.153 / 1.035 instance).
- **Screenshot sudut balon:** `storm_clouds_after.jpg` (km ±2.670) dan `islands_after.jpg` (km 1.200).
- **Galeri Hailstone:** `hailstone_v5.jpg` (3 varian lewat `ObstacleArt.Enemy`), dibandingkan dengan `hailstone_old.jpg`.
- **Pembersihan:** fixture dihapus (0 sisa), Lighting dipulihkan.
- **Penyimpanan:** `save_place` ke Roblox **Cloud v15/v16**. `Fly High.rbxl` lokal belum diperbarui. Belum commit.
- **Belum diuji:** ponsel dan grafik rendah, serta Play Solo setelah putaran ini.
