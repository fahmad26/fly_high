# Revisi seni semi-realistis Batch A, B dan C (phoenix) — 16 November 2026

Pengguna menyetujui agar semua aset dibawa ke arah semi-realistis dengan polesan rapi, dan agar phoenix diperbaiki. Gambar QA ada di `qa/`. Skin balon pemain tidak diubah.

## Batch A — pulau

- **Kit pulau v2:** `EnvironmentAssets.IslandKit`, dengan 3 varian:

  | Varian | Batu | Rumput |
  |---|---|---|
  | Shelf | `IslandShelfRock` | `IslandShelfTurf` |
  | Crag | `IslandCragRock` | `IslandCragTurf` |
  | Twin | `IslandTwinRock` | `IslandTwinTurf` |

  Mesh dari Blender: tebing atas dengan lancip lembut berpilar, ditambah stalaktit dan akar yang meruncing. Model aset 75898866315816.
- **Material PBR (SurfaceAppearance):**

  | Material | Color | Normal | Rough | Catatan |
  |---|---|---|---|---|
  | Batu berlapis | 108139953005051 | 104682599001298 | 70736001138385 | Pinggir tanah/rumput di bagian atas |
  | Rumput | 113678683600687 | 112114978440980 | 101212349586514 | |

- **Pemasangan:** `buildSculptedIslandTerrain` mengganti Basalt dan Moss lama dengan pasangan batu + rumput. Varian dipilih secara deterministik dari posisi pulau. Ukurannya mengikuti tapak Moss lama, dan warnanya di-tint lewat SurfaceAppearance.Color dari palet zona. Ini berlaku di Dawn, Sunset, Cosmic dan observatorium.
- **Laut Dawn:** `OceanHorizonSkirt`, 8×8 tile (2.112 stud) di luar kotak air Terrain. Tile ini menutup tepi air yang keras dan sudutnya, lalu memudar bersama air (1.550–2.210 km).
- **Bulan Sunset:** MoonAngularSize 4 di zona 3 (dipulihkan saat keluar zona). Sebelumnya bulan memenuhi horizon.

## Batch B — kastil Gateway

- **Model baru:** `HorizonSpire`, `HorizonPavilion` dan `HorizonArch`. Isinya menara dengan alas, string course emas, jendela lengkung kaca, balustrade, drum dan kubah bawang atau spire, ditambah arkade berkolom dan gapura batu berkunci emas. Model aset 140610567275679.
- **Material PBR:**

  | Material | Color | Normal | Rough | Metal |
  |---|---|---|---|---|
  | Marmer ashlar | 109345286682443 | 93953369334412 | 72731546575573 | |
  | Emas | 72942824159053 | | 125203276960844 | 115824869171266 |

- **Template:** template `BiomeLandmarkMeshes` diganti in-place (`HorizonStone/Gold/Glass`). Bagian awan (`VistaIvory/Shadow`) tetap. Template lama di-backup di `ServerStorage.BiomeLandmarkMeshes_Legacy`.
- **Kode:** helper `tintPiece` membuat kabut jarak dan tint Cosmic juga mengenai SurfaceAppearance. Kabut pada emas dibatasi agar emasnya tetap hangat.

## Batch C (sebagian) — phoenix

- **Model baru:** `CelestialPhoenix` (aset v3 83519983207661). Isinya:
  - Tubuh dengan dada penuh dan kepala bulat
  - Paruh dan cakar emas
  - Jambul 5 bulu
  - Sayap dari 3 baris bulu penutup, 11 sekunder dan 10 primer
  - Ekor: 7 bulu pendek dan 5 bulu panjang
  - Tekstur bulu bergradasi merah → jingga → emas: bulu 71895004872726/120106864305204, tubuh 128308321851598/103761656035199
- **Kompatibilitas:** nama part tetap `Body` dan `Wing` agar animasi kepakan dan hitbox tetap bekerja. `Plumage`, `Talons` dan `Eye` diberi atribut Decoration. Template lama ada di `ServerStorage.ObstacleMeshes_Legacy`.
- **Outline musuh:** OutlineTransparency 0,25 → 0,55 karena sebelumnya terlihat seperti stiker.
- **Belum dikerjakan:** 8 musuh lain (Bird, Bat, Hail, Drone, Bee, Wyvern, Phantom, Satellite).

## Verifikasi

- **Kompilasi dan Play:** 0 error kompilasi. Play Solo 500→9.990 km dan pembuatan sembilan musuh di Server berjalan dengan konsol bersih. Fixture 0 sisa.
- **File lokal:** `Fly High.rbxl` disimpan **LocalFile**, 2.639.402 B, SHA-256 2E1309D1C404541155B6B2B75A47CFD4680504AD1F0D4AF23BF7E248747B98F2.
- **Paritas ekstraksi binary = Studio:**

  | Script | Panjang | FNV-1a |
  |---|---|---|
  | BiomeScenery | 132.462 | 34a3ba55 |
  | BiomeLightingController | 12.394 | 30dd5376 |
  | ObstacleArt | 28.284 | f33652b6 |
  | ObstacleVisuals | 21.143 | 5d64a559 |

## Sisa

- Batch C: 8 musuh lain
- Batch D: efek rintangan alami
- Batch E: Cosmic, air terjun pulau, pita kabut Gateway, awan depan istana
- Uji ponsel dan grafik rendah
- Commit
