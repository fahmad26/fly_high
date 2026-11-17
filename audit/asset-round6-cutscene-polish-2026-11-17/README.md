# Aset round 6 dan polesan cutscene — 17 November 2026

Permintaan pengguna (09:07 WIB): "Oke, silakan lakukan semuanya ya". Ini mencakup delapan temuan aset dan tujuh poin cutscene dari review pagi ini. Lanjutan dari [AUDIO-01/CINE-01](../palace-cutscenes-audio-2026-11-17/README.md). Di-commit dan di-push 17 November (lihat `git log`).

## Aset

| # | Temuan | Perubahan | Bukti |
|---|---|---|---|
| 1 | Tepi laut bergerigi 0–1.500 km | `BiomeLightingController` membuat `ClientSeaSkirt` hanya di klien: 66 part tepat di bawah permukaan air (y −1,1), sampai ±8.192, dengan lubang ±640 di atas pulau awal. Ikut memudar dan berganti warna bersama `updateWaterHorizon`. | [sebelum, kualitas rendah](01-sea-before-lowquality.jpg), [Level06 tanpa skirt](02-sea-level06-without-skirt.jpg), [Level06 dengan skirt](03-sea-level06-with-skirt.jpg) |
| 2 | StormBat kasar | Model v6 dari Blender (aset 113741592165135): badan berbulu, telinga runcing, taring, sayap membran berlekuk dengan tulang jari (`Wing` + `WingTip`). | [sebelum](04-stormbat-before.jpg), [sesudah](05-stormbat-v6-live.jpg), [pratinjau](08-bat-bee-v6-preview.jpg) |
| 3 | FireBee kasar | Model v6 (aset 115566779938714): toraks bulu jingga, perut bergaris neon menyala, sengat, mata majemuk, antena melengkung, enam kaki, dua pasang sayap kaca. | [sebelum](06-firebee-before.jpg), [sesudah](07-firebee-v6-live.jpg) |
| 4 | Reruntuhan senja | Kit kolom patah beralur (aset 115927584511158, `EnvironmentAssets.SunsetColumns`) menggantikan:<br>• silinder `BrokenPillar`<br>• busur kuil yang terbaca seperti tanda tanya (kini kolonade)<br>• pier + busur seperempat di BridgeAnchorIsle<br>• `SmallRuinArch`<br>Tiap pulau juga mendapat 5 bunga + 5 pakis tambahan. | [sebelum](09-sunset-before.jpg), [busur lama](11-temple-arch-before.jpg), [sesudah](10-sunset-colonnade-after.jpg) |
| 5 | Awan badai berdasar piring gelap | `CloudBaseMist` dibuat lebih terang (126,122,156), lebih tipis (α 0,74) dan lebih kecil. | [sebelum](12-storm-cloud-plates-before.jpg) |
| 6 | Bawah horizon Gerbang Surgawi kosong | Lantai lautan awan jauh lebih terang (`cloudSea` darken 0,12), ditambah 14 gumpalan `GatewayDeckBank`. Air terjun siluet istana kini bertekstur mengalir, melebar di kaki, dan berkabut. | [sebelum](13-gateway-before.jpg), [sesudah (Edit)](14-gateway-deck-after-edit.jpg) |
| 7 | Dermaga Pod polos | `DockMooring` di kelima Pod: 9 bollard kayu bercincin kuningan, tali `RopeConstraint` di antaranya (sisi naik tetap terbuka), dan 2 tiang lentera di mulut dermaga. Semua tanpa collision/query/touch. | [sebelum](15-dock-before.jpg), [sesudah](16-dock-mooring-after.jpg) |
| 8 | Rumput rata, batu melayang abu-abu (petak rumput **dikembalikan** 17 Nov siang karena rumput tinggi menembus dek/jalan, lihat [perbaikan playtest](../playtest-fixes-2026-11-17/README.md)) | 16 petak Terrain LeafyGrass → Grass (483 voxel, seed 1711, rumput tinggi dekoratif). Batu pulau melayang fajar lebih hangat, ditambah 3 akar gantung per pulau. | [rumput](17-lobby-grass-patches.jpg), [batu](18-dawn-islet-warm-stone.jpg) |

## Cutscene

| # | Poin | Perubahan |
|---|---|---|
| 1 | Montase abstrak/cepat | Kamera kini jatuh di kolom terbang asli. `BiomeLightingController` mode `CinematicAltitudeKm` menyiapkan kelima scenery bioma asli (dibangun satu per frame di balik whiteout) dan mengikuti pencahayaan serta air dari ketinggian kamera. Hanya lantai awan zona aktif yang tampil. Tiap zona mendapat porsi sama: cepat di batas zona, melambat di tengahnya. Lama jatuh 3,8 dtk. Montase buatan lama (`CinematicMontage`) dihapus. |
| 2 | Nama zona | "ZONA n · NAMA" muncul saat menembus tiap zona (nama dari HUD: LANGIT CERAH … GERBANG SURGAWI), disertai whoosh. [Zona 4](19-portal-zone4-real-scenery.jpg), [Zona 3](20-portal-zone3-real-scenery.jpg) |
| 3 | Karakter diam / teleport | Server: kru hidup melompat melengkung 0,75 dtk dari geladak ke dermaga (`PalaceArrival`, root tetap anchored). Klien: emote `cheer` saat mendarat (kru bangkit menyusul sesudah fade-in). [Lompat](23-arrival-hop-blend.jpg) |
| 4 | Potong keras | Tiap pergantian shot kini berupa gerak kamera 0,9 dtk dari framing sebelumnya. |
| 5 | Kartu belum bergaya HUD | Bingkai 9-slice `modal_frame_9slice` + crest `crest_victory`, sama dengan popup lain. [Kartu](21-arrival-card-hud-style.jpg) |
| 6 | Musik kemenangan | **Koreksi:** `MusicController` sudah memutar Jubilation → Happy Ending saat menang. Klaim saya pagi ini bahwa musiknya belum ada keliru, jadi tidak ada perubahan. |
| 7 | Efek bangkit | Tabung neon diganti pilar cahaya dua lapis tanpa tekstur (halo + inti), cincin gelombang di lantai, motes naik, bulu turun dan PointLight hangat, bertahan ±4 dtk. Shot pendaratan kru bangkit dimulai lebih lebar/tinggi agar pilar terbaca. [Uji pilar](22-revival-pillar-beams.jpg) |

## QA dan batas

- **Pengujian.** Play Solo Windows, 1 klien, driver sementara `_QA_Driver`/`_QA_TourDriver` (sudah dihapus).
- **Musuh baru.** Terlihat dan mengepak di band 2 dan 5.
- **Alur cutscene.** Tiba (hidup), bangkit (mati + menang satu langkah), dan portal turun selesai.
- **Log cutscene.** Scene 5/5 terbangun. Waktu jatuh ±4 dtk. Kamera kembali Custom.
- **Console.** Pada sesi akhir (band 2/5 + tiba), LogService server dan klien bersih (0 error/warning). Satu sesi sebelumnya ditendang DataManager ("Data belum dapat dimuat dengan aman") karena Play beruntun. Ini terkait DataStore Studio, bukan perubahan ini; sesi berikutnya normal.
- **Laut, catatan jujur.** Pada kualitas grafik terendah (otomatis Studio di mesin ini saat beban MCP), part dan terrain di kejauhan sama-sama tidak digambar. Jadi tepi laut masih terlihat di kualitas sangat rendah. Skirt membantu di kualitas menengah (bandingkan 02 dan 03). Di Level21 laut sudah menerus ke horizon. Tidak ada perubahan pada StreamingTargetRadius.
- **Capture kamera.** Pilar bangkit, kartu dan zona diambil dengan fixture kamera atau menunggu atribut. Capture live terlambat 1–3 dtk.
- **Edit.** 57 script lolos `loadstring`. 0 instance `_QA_*`/`_Import_*`. QualityLevel kembali Automatic. Edit / 0 pemain.
- **Simpan.** save_place LocalFile `E:/Antigravity/Fly High/Fly High.rbxl` 3.490.832 B, SHA-256 `f19c846ee8cf56c196bd88a43cf7d97229d050dc1a59ed07a9119b0d33b2c8e3`. Binary belum dibuka ulang.
- **Parity.** Diekstrak dari `.rbxl` dan cocok dengan Studio (LF/trimEnd, panjang + FNV-1a):
  - BiomeScenery 153348 `3b900da8`
  - SceneryHabitatArt 6640 `029e5398` (pose sayap kini juga `WingTip`)
  - PalaceArrival 5336 `6b7a17d5`
  - BiomeLightingController 16395 `5c3c4874`
  - PalaceCinematics 31657 `ccf58a43`
- **Cadangan.**
  - Template lama ada di `ServerStorage.ObstacleMeshes_Legacy.StormBat_v5` / `FireBee_v5`.
  - Busur/pilar lama tetap sebagai fallback di kode bila kit kolom hilang.
  - Rumput: daftar petak (pusat/radius) di atas bisa dibalik dengan Grass → LeafyGrass di dalam petak tersebut.
- **Sumber 3D.**
  - Generator: [`tools/build_creatures_v6.py`](../../tools/build_creatures_v6.py) dan [`tools/build_sunset_columns.py`](../../tools/build_sunset_columns.py).
  - Blender: `assets/models/scenery/FlyHigh_SceneryKits_round6.blend` (scene FlyHigh_Bat6, FlyHigh_Bee6, FlyHigh_Columns).
  - GLB ada di `assets/models/scenery/storm/generated/creatures/`. Ekspor pertama kolom di `assets/models/scenery/generated/` adalah duplikat yang tidak dipakai, karena folder itu tidak diizinkan untuk upload.
- **Belum diuji:** multi-pemain (lompatan/efek dilihat kru lain), ponsel fisik dan angka performa (5 scene sekaligus ±3.600 part selama ±4 dtk montase).
