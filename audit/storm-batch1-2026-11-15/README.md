# Batch 1 revisi seni lingkungan — Zona 2 badai (graybox, menunggu persetujuan)

15 November 2026, 21:30–21:47 WIB. Claude. Rencana: [plan.md](../../design/features/environment-art-revision/plan.md) Batch 1; persetujuan pengguna untuk unggah graybox, redam fragmen bercincin emas, commit checkpoint dan sudut kamera TP+FPS.

**Status: preview graybox untuk review. `BiomeScenery` dan place belum diubah.** Semua uji memakai fixture Edit sementara yang sudah dihapus.

## Build dan lingkungan

- Git dasar `242adf2` (commit checkpoint lokal, belum push). Studio `Fly High.rbxl` terhubung ke place 97043730132219 / universe 10776821830; 54 source cocok mirror (checksum) sebelum mulai — [parity](../cloud-publish-parity-2026-11-15/comparison.json).
- Studio **Edit** (bukan Play Solo): tidak ada login/DataStore, tidak ada warp ketinggian, rekor pemain tidak tersentuh. Viewport 1576×549, FOV 70, kualitas render Studio default.
- Fixture `workspace._Batch1StormQA`: `BiomeScenery.Build(2)` + balon `SkyKoi` dipindah ke Y altitude; lighting disalin dari `BiomeLightingController` zona 2 (ClockTime 19,55, Brightness 1,3, Fog 800, ambient/atmosphere/tint) dan horizon air dipudarkan seperti klien pada >2.210 km. Nilai lama disimpan sebagai atribut lalu dipulihkan.
- Altitude target = aktual (balon di-pivot langsung): 2.200 km Y 562,5; 2.421 km Y 617,75; 3.000 km Y 762,5. Kamera TP (+60, +32, +53) dari dasar keranjang menatap pusat balon; FPS dari dek (6, +5,75, 5). Bukan penerbangan, bukan perangkat fisik; tanpa animasi/partikel waktu-jalan dan tanpa HUD.

## Sebelum → sesudah

[Lembar perbandingan](batch1-before-after.jpg). Capture asli: `before-*.jpg`, `after-*.jpg`. Iterasi 1 yang ditolak sendiri: [awan seperti jamur](iter1-tp-2421-mushroom-clouds.jpg).

| Elemen | Sebelum | Graybox |
| --- | --- | --- |
| Tornado latar | 29 elipsoid bertumpuk, kaki Y 634 tepat di atas kamera 2.421 km, radius ±360 | Satu mesh corong kontinu (`StormFunnel`) + kepala awan menyatu (`StormVortexHead`) + rok debu transparan; skala 0,8, arah sama tetapi radius 480, kaki 2.540 km. Terbaca latar jauh, tidak mengisi pusat frame |
| Awan Thunderhead/Anvil (12) | Bola SpecialMesh terpisah | `StormThunderhead` (anvil searah angin) dan `StormCongestus` bergantian, satu arah angin, diturunkan 45–60 stud |
| Lapisan bawah | Kosong antara 1.380 km dan koridor | 10 `StormShelfBank` berselang 205 km di radius 360–500 |
| Hujan | 6 tirai, arah angin acak per tirai | Satu arah angin, panjang miring berlapis, lebar dikecilkan (Beam yang sama) |
| Fragmen batu | Cincin neon emas + kristal neon terang | Cincin SmoothPlastic ungu redup T 0,45; kristal digelapkan T 0,25 |

## Aset dan geometri

[manifest.json](manifest.json): dua unggahan Model Approved (94026780390187, 81199287960960), 6 mesh, 400–6.240 tris per mesh. Thunderhead pada unggahan pertama digantikan iterasi 2. Pemeriksaan bmesh lolos untuk semua mesh; `qa_check.py` skill tidak bisa dijalankan karena safe mode MCP Blender. Ukuran impor sama dengan sumber (1 BU = 1 stud), tanpa script. Paket impor dihapus dari ServerStorage setelah review. Sumber: [generator](../../tools/build_storm_batch1.py); `.blend` terpisah tidak dapat ditulis di safe mode — scene `FlyHigh_StormBatch1` hanya ada di sesi Blender yang terbuka dan tidak disimpan ke file Atelier pengguna.

## Belum / temuan

- 2.200 km: lapisan bawah belum tampak pada arah kamera ini (shelf terdekat di luar frame).
- Corong masih polos; aksen spiral VFX native, warna dekat/jauh dan LOD belum dibuat.
- Belum: integrasi `BiomeScenery` + template di `EnvironmentAssets`, Play Solo/grafis rendah/phone-tablet, lifecycle/fade antarbioma, profil performa, simpan place.
- Cleanup: fixture, efek grade, folder tersembunyi dan paket impor dihapus; Lighting/Terrain/kamera dipulihkan dan diverifikasi (sisa 0).

## Uji tampilan semi-realistis — 21:48–22:03 WIB

Pengguna menilai graybox masih kasar/kurang realistis dan memilih arah **semi-realistis** (awan bertekstur lembut, cahaya/bayangan meyakinkan, palet tetap indigo/ungu PRD). Uji dibatasi pada satu tornado dan satu keluarga cumulonimbus sebagai patokan mutu.

- Geometri: [generator](../../tools/build_storm_lookdev.py). Cumulonimbus v4 (371 lobus fraktal, anvil kontinu tebal di inti dan menipis searah angin, dasar rata; 10.686 tris), wall cloud bergumpal (8.000), inti corong dan selubung luar ber-UV silinder (4.880 / 3.528). Iterasi v1 (anvil pelat, palet terlalu biru) ditolak sendiri.
- Shading: occlusion raycast per vertex + arah normal bawah + tinggi di-bake ke UV yang membaca tekstur gradasi `FH_CloudLUT` (dasar gelap, puncak terang, celah gelap). Corong memakai tekstur pita spiral; selubung memakai alpha.
- Roblox: material **Fabric** (SmoothPlastic memberi kilap plastik), ParticleEmitter asap ber-LightInfluence 1 di tepi anvil, dasar, kaki tornado.
- Capture fixture Edit yang sama: [perbandingan sebelum/graybox/semi-realistis](batch1-lookdev2-compare.jpg), `lookdev2-*.jpg`.
- Temuan: awan >~450 stud tertelan Fog 800 bila terlalu gelap; partikel tepi masih tampak sebagai halo; wall cloud dari jarak menengah terlalu gelap; anvil atas masih halus. Hujan, kilat, shelf/congestus belum diberi shading ini.
- Cleanup: fixture, efek, paket impor dihapus; Lighting/Terrain/kamera pulih (sisa 0). Place/BiomeScenery belum diubah.

## Tornado "terlalu solid" — 22:17–22:25 WIB

[Screenshot playtest pengguna 3.316 km](user-playtest-3316km-live-tornado.png) memperlihatkan tornado **live lama** (29 elipsoid, undakan cincin, fragmen bercincin emas belum diredam); uji Batch 1 belum terpasang di game. Masukan pengguna: tornado terlalu solid. Masukan ini juga berlaku untuk uji solid look-dev v2.

Uji tambahan fixture Edit (tanpa unggahan baru, memakai mesh LookDev2 95444165690383), lighting zona 2, tiga tornado berdampingan: [perbandingan](tornado-solid-vs-vapor.jpg), [mentah](tornado-3way-raw.jpg), [dekat ~270 stud](tornado-vapor-close.jpg).

- Versi **uap**: inti corong diperkecil 0,5× radius dengan Transparency 0,18; tiga selubung tekstur-alpha 0,72/0,9/1,08× radius dengan Transparency 0,3/0,45/0,6 dan yaw berbeda; tujuh ParticleEmitter uap di sepanjang sumbu (ukuran mengikuti radius, T 0,5–0,55, LightInfluence 1); awan debu di kaki; kabut di rok wall cloud.
- Hasil: siluet corong tidak lagi buram dan terlihat berlapis/berkabut. Wall cloud di atasnya masih massa padat gelap — perlakuan yang sama (transparansi parsial + kabut) belum diterapkan ke awan.
- Biaya: 4 MeshPart transparan bertumpuk + ±9 emitter per tornado; overdraw belum diprofilkan. Animasi rotasi selubung belum diuji (fixture Edit statis).
- Cleanup: fixture/efek/paket dihapus, Lighting dan kamera pulih (sisa 0).

## Implementasi versi uap — 22:22–22:41 WIB

Pengguna menyetujui arah **versi uap** (tornado tembus pandang), setuju wall cloud terlalu padat, dan menyatakan biaya render tidak menjadi batasan.

**Aset:** unggahan Model `96515546941911` (FlyHigh_StormZone2_v1, Approved) → dipasang sebagai `ReplicatedStorage.FlyHigh.EnvironmentAssets.StormZone2`: Cumulonimbus 10.686 tris, Congestus 8.268, ShelfBank 8.650, WallCloud 8.000 (gradasi dipetakan 0,30–1,0 agar tidak gelap), FunnelCore 4.880, FunnelShell 3.528. Atribut `SourceCenter`, material Fabric, tanpa script/tautan paket. Semua mesh lolos pemeriksaan geometri (rapat, 1 pulau, tanpa n-gon/degenerate).

**Source `BiomeScenery`:** `thundercloud()` lama menjadi `thundercloudLegacy()` (fallback bila kit tidak ada). Baru: `stormKitThundercloud()` — 9 cumulonimbus/congestus + 3 anvil satu arah angin dengan salinan tepi lembut (1,045×, T 0,8), kabut dasar/anvil, PointLight kilat internal (puncak lembut tiap 13 dtk, tanpa strobo); 10 ShelfBank lapisan bawah; tornado uap (inti 0,5× T 0,18, tiga selubung T 0,3/0,45/0,6 berputar pada sumbu corong dengan kecepatan berbeda, 7 kabut uap, awan debu, rok wall cloud) skala 0,8 di radius 480/kaki 2.540 km; hujan satu arah angin; fragmen diredam. Studio = mirror: 116.109 byte, FNV-1a `582624e6` (LF/trimEnd), loadstring lolos.

**QA (fixture Edit, kode produksi via klon modul):** Build(2) 9,0 ms; 231 part, 125 MeshPart, 40 part transparan, 40 ParticleEmitter, 22 PointLight, 78 Beam; flag collision/query/touch = 0; update() 6× tanpa error. Capture [sebelum/sesudah](batch1-final-before-after.jpg), `final-*.jpg`. Viewport Studio berubah ke 1920×690 sehingga bingkai "sesudah" sedikit lebih lebar dari "sebelum" (1576×549).

**Simpan:** backup `Fly High.before-batch1-save.rbxl` (EA632B7B…). `save_place` menyimpan ke **Roblox (Cloud) sebagai versi place 4**, bukan ke file lokal; tidak publish. File lokal `Fly High.rbxl` belum berisi perubahan ini sampai pengguna menyimpan ke file (File → Save to File).

**Belum:** Play Solo/perjalanan alami di Zona 2 (rotasi selubung dan prime partikel hanya diuji lewat update() di Edit), grafis rendah, ponsel/tablet fisik, profil performa/overdraw, fade lintas bioma 1.780–2.220 dan 3.780–4.220 km, review wall cloud dari dekat.

## Perbaikan cumulonimbus "tumpukan piring" — 22:37–22:53 WIB

[Playtest pengguna 3.316 km](user-playtest-3316km-cb-tiered.png): tornado uap kiri dinilai oke; awan kanan terbaca aneh. Diagnosis fixture ([sebelum](cb-tiered-issue-3316.jpg)): cumulonimbus sejajar mata (−325, 847, −314) — menara tersusun 11 baris lobus berjarak sama → garis bertingkat; anvil dari 3 lembar elips berbeda tebal → bawah berundak; dari samping/dekat menjadi "meja/kue lapis".

- Dua percobaan generator (menara acak + anvil kubah) ditolak sendiri: anvil menjadi "jari"/batang tipis dan ada pulau lepas.
- Solusi: cumulonimbus **dipisah** — `CbTower` (menara bunga kol gemuk, lobus acak tanpa baris; 7.430 tris) + `CbAnvil` (selubung lensa terpisah, 12.834 tris, gradasi atas) yang dirender **Transparency 0,5** dengan salinan tepi 0,88 dan kabut selubung. Unggahan 132205682977093 (Approved). Pulau terkecil dibuang; geometri lolos (boundary/non-manifold/degenerate/n-gon/winding 0).
- `stormCloud()` memakai pasangan tower+anvil bila tersedia; template `Cumulonimbus` lama tetap fallback. Studio = mirror 116.839 B, FNV-1a `9b7c9c8b`, compile lolos. [Sesudah](cb-split-fixed-3316.jpg).
- Pengguna sudah menyimpan ke file (±22:33, 2.339.338 B, B9654B8E…, backup `Fly High.before-cb-split-save.rbxl`). `save_place` kini **LocalFile**: 2.426.642 B, SHA-256 6C5CFAE159A6E29252847DA1D9E5A7BE426D90A990181827F4955787AD03B0B8, belum dibuka ulang. Fixture bersih (sisa 0), 54 source.
