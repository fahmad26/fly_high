# Perbaikan hasil review visual 0–10.000 km — 16 November 2026

Mengerjakan tujuh temuan dari [review visual](../visual-review-0-10000km-2026-11-15/README.md), dalam urutan yang disetujui pengguna: 3 → 1 → 2 → 4 → 5 → 6 → 7.

**Status:** semua kode dan aset terpasang, dikompilasi, dan diuji tanpa error. **Cek visual belum dilakukan.** Sejak sekitar 01:40 WIB viewport 3D Studio tidak merender dunia: Edit maupun Play hanya menampilkan latar abu-abu gelap, sementara UI tetap muncul. Semua perubahan wajib dilihat dan disetel ulang setelah viewport normal kembali.

## Perubahan

| # | Temuan | Perubahan | Lokasi |
|---|---|---|---|
| 3 | ShelfBank seperti cerutu; anvil veil dari atas seperti piring | ShelfBank tidak lagi melayang bebas di 2.050–3.900 km. **Gust shelf** ditempel di bawah setiap cumulonimbus cincin, di sisi hilir angin. Sumbu panjangnya melintang angin, kedalamannya ×2 (sekitar 2:1, bukan 5:1). Ditambah **dek bawah** 6 shelf di 1.975–2.035 km yang memudar bila gondola turun di bawahnya. Anvil veil tanpa soft shell. Transparansinya 0,55 dari samping dan 0,86 bila kamera di atasnya. | `BiomeScenery`: `gustShelf`, `stormKitThundercloud`, `VEIL_SIDE_T/VEIL_TOP_T` |
| 1 | Rintangan terbaca sebagai satu garis laser | `ObstacleVisuals.Telegraph` (lihat rincian di bawah). Gameplay, hitbox dan pacing tidak berubah. | `ObstacleVisuals`, `ObstacleArt.Hazard` |
| 2 | Zona Cosmic hampir hitam | `BIOME_SETTINGS[4]` diubah (lihat rincian di bawah). Ditambah 7 bank **nebula** emisif jauh. | `BiomeLightingController`, `BiomeScenery.exosphere` |
| 4 | Awan bola kartun di Dawn/Gateway | `band()` profil default/foundation kini memakai mesh cumulus kit (Congestus) dengan LUT terang. Ada dua LUT: Day `77383340574029` dan Gold `97439095888170`, dipilih otomatis dari warna palet. Ditambah soft shell dan veil. Foundation dibalik sehingga bangunan duduk di dasar awan yang datar. | `BiomeScenery.brightCloud` |
| 5 | Musuh terlalu kecil | Skala ×1,25. Highlight outline yang kontras dengan langit zona. PointLight kecil untuk Bat/Hail/Wyvern/Phantom. Radius tabrakan balon tetap 18; target tembak ikut membesar 25%. | `ObstacleArt`: `READABILITY_SCALE`, `addReadability` |
| 6 | Pulau kerucut terbalik + akar tongkat; air terjun strip lurus | Lihat rincian di bawah. | `BiomeScenery`, `CloudPalace` |
| 7 | Horizon keras, matahari sunset besar, awan depan istana | Lihat rincian di bawah. | `BiomeScenery.gateway`, `BiomeLightingController` |

**Rincian #1 — telegraph rintangan.** Garis PathBeam tipis dimatikan dan diganti visual yang mengikuti hitbox:

- **Volume bahaya** (ForceField, Decoration, tidak bisa di-query) yang cocok dengan hitbox:
  - Wind/Heat: kotak 82×46×46
  - Fog/Magnetic: bola 66
  - Lightning: kolom r17, −37…+49
  - Storm: bola 50
  - Debris: halo 46 + debu per reruntuhan
- **Lajur chevron** bergerak di sepanjang lintasan. Teksturnya `FH_HazardChevron` `124478271519029`.
- **Aliran angin dan panas** dengan tekstur `FH_HazardFlow` `85832877682740`.
- **Lajur meteor**: ribbon chevron selebar 36 dengan atribut `MeteorLane`.
- **Thunderhead Lightning**: bola plastik diganti mesh cumulus kit.

**Rincian #2 — pencahayaan zona Cosmic** (`BIOME_SETTINGS[4]`):

- Brightness 1,05 → 2,4
- OutdoorAmbient (132,146,204), Ambient (124,132,178)
- ColorShift_Top kebiruan
- Atmosphere: biru, Density 0,24, Haze 0,9
- Tint dan Contrast 0,07

**Rincian #6 — pulau dan air terjun:**

- **Pulau:** mesh baru `IslandUnderside`, berupa batu berlapis yang meruncing dengan stalaktit (aset `119786612713966`, template `EnvironmentAssets.IslandKit`). Mesh ini menggantikan kerucut `Basalt` di `buildSculptedIslandTerrain`, sehingga berlaku untuk pulau Dawn, Sunset, Cosmic dan observatorium.
- **Akar tongkat** diganti tanaman rambat Beam yang meruncing dan melengkung.
- **Air terjun** (`attachSculptedWaterfall`):
  - 5 aliran yang melengkung dari bibir tebing dan melebar ke bawah
  - Tekstur garis air yang bergerak
  - Busa di bibir, dua emitter kabut, dan veil kabut yang lebih besar
- **Istana:** ribbon air istana memakai tekstur aliran, ditambah kabut di ujungnya.

**Rincian #7 — kerapian langit:**

- **Lautan awan** 3×3 tile cumulus Gold (2.040 stud per tile) di sekitar 7.340 km. Ini mengisi bagian bawah horizon yang sebelumnya datar dan bergaris keras.
- **Sunshaft gateway** dibuat lebar, lembut dan bertekstur. Strip sempit lama terbaca sebagai air terjun.
- **Matahari zona Sunset:** SunAngularSize 11 → 6 lewat tween per zona, dipulihkan saat skrip dihancurkan.
- **Awan depan istana** (`CloudPalace.PalaceApproach`, dek yang bisa diinjak, tidak dipindah): material Fabric, warna lembut, ditambah soft shell non-collide. SummitCloudBanks/DockCornerCloud juga diubah ke Fabric.

## Aset baru (semua Approved)

| Nama | Tipe | Aset | Image/Mesh | File |
|---|---|---|---|---|
| FH_HazardChevron | Decal | 92852486345537 | rbxassetid://124478271519029 | `assets/models/scenery/storm/generated/FH_HazardChevron.png` |
| FH_HazardFlow | Decal | 128396373801839 | rbxassetid://85832877682740 | `…/FH_HazardFlow.png` |
| FH_CloudLUT_Day | Decal | 86078801617606 | rbxassetid://77383340574029 | `…/FH_CloudLUT_Day.png` |
| FH_CloudLUT_Gold | Decal | 100619531545856 | rbxassetid://97439095888170 | `…/FH_CloudLUT_Gold.png` |
| FlyHigh_IslandUnderside_v1 | Model | 119786612713966 | mesh rbxassetid://107595772192204 (~4k tris) | `…/FlyHigh_IslandUnderside_v1.glb` |

Mesh pulau dibuat di Blender (scene `FlyHigh_StormBatch1`, objek `IslandUnderside`, hanya di sesi live). Generatornya ada di `tools/build_island_underside.py`. Folder unggah yang disetujui hanya `storm/generated`, jadi aset non-badai ikut disimpan di sana. Tekstur dibuat dengan PIL di sesi ini; parameternya tercatat di tabel aset.

## Verifikasi

- **Kompilasi dan build:**
  - Lima zona `BiomeScenery.Build` berhasil tanpa error, termasuk pemanggilan update pada beberapa km dan opacity 0,5.
  - Jumlah elemen baru terhitung: CloudLobe mesh Dawn 5 / Gateway 31, CloudSeaTile 9, Basalt mesh 9/18/4/2, HangingVine 21, NebulaBank 7.
  - Sembilan hazard dan sembilan musuh dibuat di Edit dan di Server Play tanpa error.
- **Play Solo:** satu klien. Server mengirim `FlightStateSyncEvent` 500 → 9.990 km (16 langkah). Klien membangun CelestialGateway, dan Output konsol kosong (tanpa error/warning).
- **Paritas source:** source diekstrak dari `Fly High.rbxl` yang tersimpan dengan `tools/rbxl_sources.py` (LZ4/zstd), lalu ditulis ke mirror. Panjang dan FNV-1a (LF/trimEnd) cocok dengan Studio:

  | Script | Panjang | FNV-1a |
  |---|---|---|
  | BiomeScenery | 126.959 | 8b107484 |
  | BiomeLightingController | 12.153 | c6421e3a |
  | ObstacleArt | 28.228 | b010c391 |
  | ObstacleVisuals | 19.310 | 79248321 |

- **File:** `Fly High.rbxl` disimpan LocalFile, 2.451.893 B, SHA-256 09924BD45C8CDCCDAC47D733EBE95967EB1E78FFA4546D793C0796FA2FCFEE01. Backup sebelum simpan ada di `audit/storm-batch1-2026-11-15/Fly High.before-review-fixes-save.rbxl` (6C5CFAE1…).
- **Fixture:** `_ReviewQA`/`_QA*` dibersihkan (0 sisa); Lighting/Atmosphere/air/kamera dipulihkan.

## Belum dilakukan / risiko

- **Belum ada cek visual apa pun.** Butuh viewport yang merender. Yang perlu dicek dan mungkin disetel:
  - Arah chevron dan arah gulir tekstur
  - Kepekatan ForceField
  - Kecerahan Cosmic
  - Orientasi awan foundation yang dibalik
  - Kecocokan sambungan mesh pulau dengan permukaan atas
  - Lautan awan di horizon
  - Air terjun
  - Outline musuh
- Garis putih horizon 1.000 km (Dawn) belum diubah: penyebabnya belum bisa dipastikan tanpa render.
- Biaya render naik: lautan awan 9×~8k tris, mesh pulau, soft shell awan dan Highlight musuh. Highlight dibatasi 31 per layar oleh Roblox. Uji ponsel/tablet dan grafik rendah belum dilakukan.
- Binary belum dibuka ulang; belum commit/push.

## Iterasi QA visual — 16 November 2026, 11:25–12:45 WIB

Viewport kembali merender setelah Studio dibuka ulang. Galeri dibuat dengan fixture Edit: lighting zona, scene `Build(zone)`, serta rintangan dan musuh dengan atau tanpa balon. Gambarnya ada di `qa-16nov/` dan ringkasan `qa-16nov-contact.jpg`. Partikel di gambar Edit dipancarkan sekaligus, jadi tampak lebih tebal dibanding saat Play.

| Temuan saat cek visual | Perbaikan |
|---|---|
| Volume bahaya ForceField berbentuk kotak tampak seperti peti kaca | Wind/Heat/Lightning memakai elipsoid (SpecialMesh Sphere). Semua ForceField Transparency 0 sehingga tepinya bercahaya; halo Debris 0,3. |
| Lajur chevron selebar hitbox menjadi zig-zag raksasa yang pudar | Lebar maksimal 18, transparansi 0,15, panjang ubin 0,9× lebar. Sheet aliran tetap lebar asli. |
| Fringe awan petir membentuk cakram pucat | Emitter lebih kecil dan gelap, densitas 0,5. |
| Tornado berupa gumpalan abu-abu | Corong uap dari kit (FunnelCore + 2 FunnelShell, skala 0,2; Storm 0,24 berwarna jingga, Decoration). Volume Beam 0,7/0,8, FunnelVapor lebih kecil dengan densitas 0,55. |
| Cumulus Dawn tampak abu-abu mendung | Shell Neon putih/emas dengan transparansi 0,86. Tata letak datar diberi tinggi minimal 0,4× lebar. |
| Dek bawah badai seperti tumpukan piring dari atas | Congestus pipih menggantikan ShelfBank yang direntang. |
| Gust shelf dari atas seperti piring gelap | Memudar ke 0,92 bila gondola di atasnya. |
| Bagian bawah horizon Cosmic biru elektrik | Atmosphere (58,64,118) / Decay (34,28,74), Density 0,22, Haze 0,45. |
| "Segitiga gelap" pada review | Ternyata dasar laut Terrain (Grass y −22, sekitar ±1.000 stud) yang terlihat setelah air memudar penuh, bukan artefak. |
| Lautan awan mesh tampak seperti padang pasir (`13-rejected-mesh-cloudsea.jpg`) | Diganti tekstur dek awan tileable `FH_CloudDeck` (decal 116548342084060 → image 88219497565542, Approved). Dua layer Texture pada 5×5 plate tak terlihat (2.040 stud, StudsPerTile 1.020/680), ditambah lantai opak gelap 30 stud di bawahnya agar dasar laut tidak tembus. Dipasang di Badai 1.000 km, Sunset 2.900, Cosmic 5.000, dan Gateway 6.900, sehingga selalu 250–775 stud di bawah gondola. |
| Air terjun istana: strip lurus di 10.000 km (`CloudPalace.SummitScenery.PalaceWaterfall`, 10 Beam) | Tekstur aliran, lebar bawah ×1,6, memudar ke 1, ditambah 5 emitter `CascadeSpray`. Soft shell `PalaceApproach` dihapus lagi karena tampak seperti halo. |

**Bukti dan status:**

- **Play Solo** 500→9.990 km (15 langkah) dan sembilan hazard di Server: konsol bersih.
- **Simpan:** sebelum pengguna menyimpan ke Roblox, file lokal disimpan 2.453.011 B, SHA-256 4C71D4F9…955A. Pengguna lalu memakai **File → Save to Roblox As** ke place 97043730132219 agar izin MCP bisa diatur, dan scope asset diaktifkan.
- **Simpan akhir** lewat MCP masuk **Cloud versi 7**. `Fly High.rbxl` lokal **belum memuat** dua perubahan terakhir: ID `CLOUD_DECK` dan lantai lautan awan.
- **Paritas Studio = mirror:**

  | Script | Panjang | FNV-1a |
  |---|---|---|
  | BiomeScenery | 129.707 | a4516689 |
  | BiomeLightingController | 12.151 | 4e9ed2bf |
  | ObstacleArt | 28.228 | b010c391 |
  | ObstacleVisuals | 21.143 | 5d64a559 |

- **Fixture:** dibersihkan (0 sisa).
- **Masih terbuka:**
  - Simpan ulang ke file lokal (File → Save to File)
  - Uji grafik rendah dan ponsel
  - Uji penerbangan nyata dengan hazard bergerak
  - Buka ulang binary
  - Commit
