# Review scenery lanjutan — 16 November 2026, 19:30–20:50 WIB

Ini lanjutan dari sweep lima ketinggian (screenshot `before_*`). Pengguna minta semua temuan dikerjakan: "Iya, kerjakan semuanya".

## Fixture

- Mode Edit. `ReplicatedStorage.FlyHigh.Modules.BiomeScenery` disalin ke `_QA_BiomeScenery`, lalu `Build(zona)` dipanggil bersama fungsi update pada km 900, 3.000, 5.100, 7.000 dan 8.630 (opacity 1).
- Lighting diambil dari `BIOME_SETTINGS` di BiomeLightingController: Lighting, Atmosphere, Sky dan ColorCorrection.
- **Pembersihan:** `_SweepQA`, `_QA_BiomeScenery` dan `_SweepGrade` dihapus, 0 sisa.
- **Lighting, Atmosphere dan Sky dipulihkan ke nilai file sebelum sesi.** Nilainya diambil dari `Fly High.rbxl` yang disimpan pengguna pukul 19:20 dengan parser PROP:
  - TimeOfDay 14:30:00, Ambient/OutdoorAmbient 70, FogEnd 100000
  - Atmosphere Density 0,3 / Offset 0,25 / Color 199 / Decay 106,112,125
  - Sky Sun/Moon 11

## Perubahan

| Temuan | Perbaikan | Bukti |
|---|---|---|
| Garis putih di horizon Dawn (tepi kotak air ±2.048) | Tepi air itu sendiri yang tergambar sebagai garis abu-abu/putih, jadi skirt part tidak bisa menutupnya. Terrain Water diperluas (lapisan 4 stud di y −4…0) sampai ±16.384, dan `OceanHorizonSkirt` dihapus. Air tetap memudar lewat `updateWaterHorizon`. | `after0_horizon_edge_before/after`, `after1_low_horizon`, `after1_dawn` |
| Bulan raksasa di zona badai | `BIOME_SETTINGS[2].MoonAngularSize = 3` | `after2_storm_moon` |
| "Strip sunshaft" Gateway terlihat seperti tiang kaca | Bukan bug. Itu `VistaWaterfall` milik siluet istana yang di game ikut tersembunyi atau muncul bersama siluet. Artefaknya hanya muncul di fixture lama yang tidak memanggil update. | — |
| Awan kartun bergaris putih | Shell `CloudLobeSoftEdge` diganti dari Neon (bloom membuat outline) ke SmoothPlastic, ukuran ×1,07, transparansi 0,78 | `after1_cloud_rim` |
| Pulau laut Dawn dan headland low-poly | Diganti `kitTopSwap`. Detail ada di bawah tabel. | `after1_sea_islet`, `after1_dawn` |
| Lempeng segitiga di sisi pulau Sunset, dan lengkung kotak-kotak | Saat kit pulau dipakai, mesh TerraCotta/Sandstone/Ivory/Gold dari landmark lama dihapus. Pulau kuil kini mendapat `RuinArch` baru. Detail ada di bawah tabel. | `after3_sunset`, `after3_ruin_arch_sakura` |
| Peti batu di depan kuil | `ProcessionalMarker` diganti batu besar alami | `after3_sunset` |
| Sakura bola merah muda | `SakuraTree` baru dipakai di `buildBlossomTree`. Detail ada di bawah tabel. | `after3_sakura_close` |
| Sunset terlalu merah | Zona 3: OutdoorAmbient 180,96,78 → 182,148,136; Ambient → 136,124,122; Tint 255,224,204 → 255,234,220 | `after3_sunset` |
| Rumput kosmik tetap hijau | `palette.turfLift = 0.08` pada pulau kristal dan observatorium, sehingga tint teal kuat | `after4_cosmic` |
| Sisi kiri/kanan kosmik kosong | 4 pulau kristal pengapit, skala 0,52–0,66 | `after4_cosmic_side` |
| Planet bertabrakan dengan pulau di frame | Planet dinaikkan 520 stud dan digeser ke (−1.650, …, −2.700) | `after4_cosmic` |
| Paviliun identik bertumpuk di Gateway | 4 posisi di `palaceHorizon` dipindah atau diganti tipe. Kolom kiri tidak lagi berisi empat paviliun sekaligus. | `after5_gateway` |
| Kapal menembus awan | Tiga rute rendah dipindah ke udara terbuka. Cek overlap bounding box: 0 tumbukan untuk 6 kapal. | — |
| Kapal polos | Material template: lambung WoodPlanks, layar Fabric, kuningan Metal | — |

**Pulau laut Dawn dan headland (`kitTopSwap`):**
- Batu bersegi dan rumput diganti pasangan batu + turf PBR IslandKit, setinggi beberapa stud di atas laut.
- Plat pasir/karang bersegi diganti gundukan pantai (ellipsoid Sand) dan karang dangkal transparan.
- Pohon dan pakis didudukkan ulang di atas turf (`shiftProps`).

**`RuinArch` di pulau kuil:**
- Lengkung patah dengan pilar, voussoir bevel, plinth bertingkat dan blok runtuh.
- Aset 71021817391731. Generator: `tools/build_sunset_ruins.py`.

**`SakuraTree` (dipakai di `buildBlossomTree`):**
- Batang, enam dahan dan ranting, dengan kanopi kelopak bergerombol dua tone.
- Material Fabric.

**Belum dikerjakan:** jembatan patah dan gerbang lonceng Sunset masih dari part dasar; menara awan di sisi kanan Gateway; model kapal sendiri tidak dimodel ulang.

## Verifikasi

- **Build:** kelima zona di-build di fixture tanpa error (1.675 / 782 / 1.865 / 1.153 / 1.035 instance).
- **Play Solo:**
  - FlightStateSyncEvent dikirim dari Server untuk 500 → 9.990 km (11 langkah). Console bersih, scene terakhir `CelestialGateway`.
  - Play dihentikan dan Studio kembali ke Edit. Tidak ada fixture Play.
- **Source:** Studio sama dengan file tersimpan sama dengan mirror (LF/trimEnd).
  - BiomeScenery 140012 / `c348b6be`
  - BiomeLightingController 12590 / `6e3839eb`
  - ObstacleArt/ObstacleVisuals tidak berubah.
- **File:** `save_place` → LocalFile, `Fly High.rbxl` 2.960.273 B, SHA-256 `bfb369c6…5f83d`. Pengguna sebelumnya memakai Save to File, jadi place kembali berbasis file. Terrain Water yang diperluas hanya menambah ±55 KB.
- **Peringatan tekstur:** sejak ±19:40 WIB, Studio sesi ini gagal memuat (`AssetFetchStatus.Failure`) sebagian peta SurfaceAppearance. Contohnya peta batu/turf IslandKit dan bulu phoenix, padahal asetnya Active/Approved. Tekstur lain seperti cloud deck dan LUT tetap berhasil. Karena itu screenshot pulau setelah jam itu tampil polos tanpa tekstur PBR. **Dicek ulang 20:05 WIB setelah pengguna membuka ulang Studio:** batu/turf IslandKit dan phoenix kembali tampil bertekstur (`texture_check_after_restart.jpg`, `after3_sunset_textured.jpg`). `PreloadAsync` masih melaporkan Failure untuk peta SurfaceAppearance, jadi status itu tidak bisa dipakai sebagai indikator. Yang menjadi acuan adalah tampilan render. Fixture cek dibersihkan (0 sisa) dan Lighting dipulihkan ke nilai file.
- **Belum diuji:** ponsel dan grafik rendah.
  - Penambahan segitiga terbesar: 6 sakura (±5 ribu masing-masing), 4 pulau kristal pengapit, dan 9 pulau laut berbasis kit.
