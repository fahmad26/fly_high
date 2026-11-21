# Bentuk "es" di Istana Awan dan percobaan air terjun — 20 November 2026, ±21:15–22:00 WIB

**Hasil akhir:** perbaikan es dipertahankan. Air terjun istana **dikembalikan ke kondisi semula** atas permintaan pengguna (21:53). Ketiga percobaan di bawah sudah dihapus dari Studio dan hanya disimpan sebagai riwayat.

Laporan pengguna: [00-user-report.png](00-user-report.png). Gundukan putih dengan pinggiran bawah ungu muda bergerigi berdiri di atas lantai marmer plaza, sehingga terlihat seperti bongkahan es.

## Penyebab

Bongkahan itu adalah dua mesh awan pengapit jalur dermaga, `Workspace.CloudPalace.PalaceApproach`:

- `ApproachMist`: Fabric putih, dapat diinjak. Alasnya rata tepat di ketinggian lantai plaza (dasar 2588,68; lantai `GoldenRim` 2588,5).
- `ApproachShadow`: Fabric ungu muda di bawahnya. Puncaknya yang bergerigi naik sampai 2590,0, yaitu 1,5 stud di atas lantai plaza.

Di bagian dalam plaza, gundukan putih tampak "diletakkan" di atas marmer dengan alas datar. Pinggiran bergerigi ungu dari mesh bayangan juga mencuat di sekelilingnya. Kombinasi ini terbaca sebagai es, bukan awan ([01](01-before-right.jpg)). Tidak ada script yang mereferensikan kedua mesh ini.

## Perbaikan (Studio Edit, satu langkah undo "LowerPalaceApproachClouds")

| Mesh | Y sebelum | Y sesudah |
|---|---|---|
| ApproachMist | 2593,1201 | 2590,6201 |
| ApproachShadow | 2573,8875 | 2571,3875 |

Keduanya diturunkan 2,5 stud dengan posisi relatif tetap. Puncak gerigi ungu kini maksimal 2587,5, di bawah lantai. Alas datar putih juga tenggelam di bawah lantai, sehingga awan tampak naik dari plaza ([02](02-after-right-edit.jpg), [03](03-after-left-edit.jpg), [05](05-after-player-view.jpg)). Tampilan dari luar tetap sama, hanya sedikit lebih rendah ([04](04-after-outer.jpg)). Titik `CliffLip1–5` air terjun tepi pulau berada di `CloudIvory`/di bawah permukaan, jadi tidak terpengaruh.

## QA (Play Solo Windows, 1 pemain)

Jalan dengan `MoveTo`: dermaga → plaza → tepi gundukan kanan → naik awan kanan (Y 2596,5) → plaza → tepi kiri → naik awan kiri (Y 2597,9) → plaza. Semua tercapai dalam 1,7–4,9 dtk, tanpa tersangkut atau jatuh. Console bersih. Edit / 0 pemain / 0 sisa `_QA`.

## Review air terjun istana (kondisi sebelum perbaikan)

[06](06-waterfall-front.jpg), [07](07-waterfall-close.jpg): air keluar dari balkon menara kanan, jatuh ±36 stud ke kolam bulat kecil.

- Jatuhan berupa satu lembar transparan lurus selebar tetap (`MainWaterSheet` + filamen). Dari dekat terbaca sebagai panel kaca atau sinar.
- Lembar air menutupi pilaster gerbang dan cornice, sehingga tidak tampak mengalir dari bukaan arsitektur.
- Tidak ada lengkung di bibir spillway, tidak ada percikan atau busa yang jelas di dasar, dan kolam tangkapan dangkal serta kecil untuk jatuhan setinggi itu.

## Percobaan 1: air terjun tinggi `PalaceFall` (ditolak, sudah dihapus)

Versi ini sudah diganti dengan Percobaan 2. Pengguna menilai hasilnya "malah jadi aneh": jatuhan setinggi ±36 stud dari atap ke mangkuk kecil terbaca seperti pilar/tabung kaca di depan jendela ([10](10-plaza-front.jpg)). Dokumentasi di bawah disimpan sebagai riwayat.

Lokasi: `Workspace.CloudPalace.SummitScenery.PalaceWaterfall`.

**Dihapus:** `MarbleSpillway`, `SpillwayLip`, `Feedwater`, kedua `SpillwayWall`, `CatchBasin`, `BasinWater`, `BasinImpact` (beserta emitter), serta semua anak `WaterfallAnchors` kecuali yang namanya diawali `Cliff`. Termasuk `MainWaterSheet`, `AnimatedWaterCurrent`, `WaterSheetEdge`, `WaterEdgeFoam1–4`, `FlowFilament1–6` dan `FallingWaterSpray`.

**Dipertahankan:** air terjun tepi pulau (`CliffCascade`/`CliffCurrent`, `CliffLip1–5`/`CliffFallEnd1–5`) dan 5 part `CascadeSpray`.

**Ditambah:** model `PalaceFall` (38 BasePart, semuanya Anchored, CanTouch false):

- **Bukaan di dinding istana** (Y ±2628,6): lengkung gelap dengan bingkai dan cincin emas, jamb, keystone dan crest kaca. Air kini tampak keluar dari bukaan arsitektur, bukan dari balkon.
- **Talang:** lantai, dinding dan cap, dua corbel, bibir silinder dan pita emas.
- **Jatuhan berlapis:** beam `FallBackSheet`, `FallBody` dan `FallCoreSheet` melengkung dari bibir (arah keluar −0,26/0,97) lalu melebar ke bawah (±10 → 11,4 stud). Ditambah 5 garis `FallStreak` dan 2 `FallEdgeFoam`. Jatuhan berada di kanan gerbang, tidak menutupi pilaster ([10](10-plaza-front.jpg)).
- **Air mancur bertingkat** di dasar (pusat 24,2 / 15,0): plinth Ø16,2, dinding kolam Ø15 dengan rim emas, pedestal dan mangkuk atas Ø7,2 dengan rim emas. Ada 10 tirai luapan `OverflowCurtain0–9` dari mangkuk atas ke kolam bawah. Batu memakai Limestone gading agar serasi dengan istana; Marble awal terlihat abu-abu berurat.
- **Partikel:** busa bibir, kabut jatuhan, percikan + kabut di titik jatuh (dengan PointLight lembut), dan 6 emitter busa kolam.

Satu usulan belum dibuat: saluran luapan ke tepi plaza. Air mancur sudah terbaca jelas tanpa itu, jadi saluran bisa ditambah nanti bila diinginkan.

### QA (Play Solo, 1 pemain)

- **Visual:** [08](08-fountain-close.jpg) dekat, [09](09-fall-from-below.jpg) dari bawah ke arah bukaan, [10](10-plaza-front.jpg) depan plaza, [11](11-approach-far.jpg) dari jalur kedatangan. Jatuhan bertekstur jelas dan kolam terbaca sebagai air mancur.
- **Partikel:** partikel percikan berwarna putih-aqua, sehingga di atas air/kaca cerah tidak terlalu menonjol dalam screenshot. Semua emitter aktif di klien. Render partikel dibuktikan dengan emitter uji merah sementara, yang sudah dihapus.
- **Collision:** `BasinPlinth`, `BasinWall`, `BowlPedestal` dan `BowlBody` kini CanCollide/CanQuery true, sedangkan bagian lain non-collide. `MoveTo` lurus ke pusat kolam berhenti di tepi plinth (±8,3 stud dari pusat). Jalan memutar penuh berhasil, termasuk celah belakang antara kolam dan dinding (z ±5). Begitu juga jalan ke sisi ReturnPortal (41,5 / 22,1). Tidak tersangkut, HP 100.
- **Console:** bersih (hanya info DataManager dan reset kamera dari alat QA).
- **Belum diverifikasi:** salinan siluet jauh `BiomeScenery` (dibuat saat runtime di ketinggian lain; tidak ditemukan salinan pada Play di puncak), dan sinematik kedatangan.
- **Pemulihan:** Edit / 0 pemain / 0 instance atau atribut `_QA`.

## Percobaan 2: air mancur dinding kecil `PalaceWallFountain` (ditolak, sudah dihapus)

Pengguna (21:44): "Air yang keluar sangat sedikit dan aliran sungainya cukup besar." Corong kecil dan kolam bulat tidak sebanding dengan kanal ber-curb selebar ±12 stud di depannya. Kolam bulat juga menutupi kepala kanal itu. Riwayat:

Pengguna memilih air mancur dinding. Model `PalaceFall` dihapus seluruhnya: bukaan atas, talang, beam jatuhan, mangkuk bertingkat, tirai luapan dan partikel. Penggantinya adalah `PalaceWaterfall.PalaceWallFountain` (22 BasePart) di pilar fasad antara gerbang dan `GalleryCore`, X 20,5:

- **`WallPlaque`:** panel Limestone gading 6,4 × 8 stud dengan puncak lengkung dan bingkai emas. Di dalamnya ada ceruk biru tua dengan garis lengkung emas, keystone emas, dan ambang di bawah.
- **Corong:** medalion emas dengan permata kaca, pipa dan bibir emas pendek setinggi ±7,6 stud di atas lantai.
- **Aliran:** dua beam (`StreamCore` bertekstur air dan `StreamGlow`) melengkung pendek ±6 stud ke kolam. FaceCamera aktif agar aliran tetap terbaca dari samping.
- **`Basin`:** kolam bulat di depan dinding (pusat z 7,2) dengan plinth Ø10,2, dinding Ø9,2, cincin emas dan permukaan air Ø8,3 tepat di atas cincin. Plinth dan dinding dapat ditabrak; part lain non-collide.
- **Efek:** percikan, kabut dan PointLight lembut di titik jatuh (emitter disalin dari versi sebelumnya), ditambah 3 emitter busa kecil.

Air terjun tepi pulau (`Cliff*`, `CascadeSpray`) tidak berubah.

### QA (Play Solo, 1 pemain)

- **Visual:** [12](12-wall-fountain-close.jpg) dekat, [13](13-wall-fountain-plaza.jpg) depan plaza (fasad tidak lagi tertutup), [14](14-wall-fountain-side.jpg) samping (Edit; panel rata di pilar, tidak melayang).
- **Perbaikan selama QA:** cincin emas awalnya berupa silinder padat yang menutupi air. Permukaan air dan titik jatuh dinaikkan 0,25 stud ke atas cincin.
- **Collision:** `MoveTo` ke pusat kolam berhenti di tepi plinth. Jalan memutar (kanan, sisi ReturnPortal 35,6 / 21,7, lalu kiri ke arah gerbang) lancar, HP 100.
- **Console:** bersih. Edit / 0 pemain / 0 `_QA`.
- **Belum diverifikasi:** salinan siluet `BiomeScenery` dan sinematik kedatangan.

## Percobaan 3: kaskade dinding lebar + sungai `PalaceWallCascade` (dibatalkan, sudah dihapus)

**Temuan konteks** ([18](18-river-head-bare.jpg), Edit tanpa air mancur): `CloudPalace.CloudCascades.Porcelain` sudah memuat kanal sungai ber-curb putih.
- Hulunya ada di dasar pilar fasad. Di sana ada ambang lebar, tinggi +0,72 stud, pada z 7–11,5 dan x ±16–33.
- Interior kanal z 12–24 setinggi lantai. Permukaan sungai mesh mulai sekitar z 26 (+0,43) dan berakhir di awan sekitar (38, 48).
- Part splash lama `CascadesAndMist.PoolSplash.StreamImpact1–3` di z 10,7 menunjukkan desain awal memang mengalirkan air jatuh ke hulu kanal ini.

**Model baru** `PalaceWaterfall.PalaceWallCascade` (23 BasePart, 20 Beam). Model ini menggantikan `PalaceWallFountain`, termasuk kolam bulatnya.

- **`WallNiche`** (X 20,5): panel Limestone 8,6 stud dengan lengkung dan bingkai emas, serta ceruk biru tua 6,4 stud dengan medalion. `BaseBlock` dapat ditabrak dan menutup celah ke lantai. Di FL+6 ada `WeirShelf` lebar penuh dengan bibir emas `WeirLip`, pipi emas dan air di atas shelf.
- **Tirai air:** `SheetBack`, `SheetCore` dan 4 `SheetStreak` selebar ±6,4–7,4 stud jatuh ±5,3 stud ke ambang hulu (z 7,6).
- **Permukaan air:** satu jalur beam datar `Flow1–9` (lapisan `WaterBase`, `WaterFlow` bertekstur bergerak dan `WaterSheen`). Jalurnya dari ambang, turun satu anak tangga ke kanal, mengikuti kanal di antara curb (lebar 12–13 → 9 stud), lalu di atas sungai mesh hingga memudar ke awan.
- **Partikel:** percikan, kabut dan PointLight di garis jatuh, ditambah 4 emitter busa di anak tangga z 12,4.

### QA (Play Solo, 1 pemain)

- **Visual:** [15](15-cascade-close.jpg) dekat, [16](16-cascade-river-high.jpg) dari atas (alur dinding → ambang → kanal → awan menyambung), [17](17-cascade-plaza.jpg) depan plaza.
- **Akses:** `MoveTo` menyeberangi sungai (14,24 → 39,5/24), naik ke ambang di bawah tirai (28,4/9,5), menyusuri ambang ke kiri dan kembali. Semua tercapai, HP 100. Air hanya visual (non-collide), jadi sungai tetap dapat dilewati seperti sebelumnya.
- **Console:** bersih. Edit / 0 pemain / 0 `_QA`. `CanQuery` mesh yang sempat dinyalakan sementara untuk pengukuran sudah dikembalikan ke false.
- **Belum diverifikasi:** salinan siluet `BiomeScenery` dan sinematik kedatangan.

## Pemulihan air terjun ke kondisi semula (21:53)

Permintaan pengguna: "Air terjun balikin ke semula deh, tapi pastikan es yang sudah kamu perbaiki tetap difix."

- **Sumber:** `Fly High.rbxl` di disk (disimpan 20:58:32 WIB, sebelum pekerjaan air terjun dimulai). File di-parse offline (format biner rbxl, chunk zstd, dibaca lewat `libzstd`). Subtree `Workspace.CloudPalace.SummitScenery.PalaceWaterfall` diambil darinya, berisi 89 instance: 14 Part, 37 Attachment, 23 Beam, 12 ParticleEmitter, 2 SpecialMesh, 1 Model.
- **Yang dibuat ulang:** 57 instance yang sempat dihapus dibuat ulang di Studio dengan seluruh properti non-default, termasuk referensi `Attachment0/1` Beam. Daftarnya: `MarbleSpillway`, `SpillwayLip`, `Feedwater`, 2× `SpillwayWall`, `CatchBasin` dan `BasinWater` (beserta SpecialMesh dan `BasinFoamOrigin1–3`/`SpreadingSurfaceFoam`), `BasinImpact` (`BasinMist`, `BasinSpray`), serta anak non-`Cliff` di `WaterfallAnchors` (`MainWaterSheet`, `AnimatedWaterCurrent`, `WaterSheetEdge`, `WaterEdgeFoam1–4`, `FlowFilament1–6`, 2× `FallSprayOrigin`/`FallingWaterSpray`). Tidak ada properti yang gagal di-set.
- **Yang tidak disentuh:** `Cliff*` dan `CascadeSpray` memang tidak pernah diubah, jadi tetap apa adanya. `PalaceWallCascade` dihapus.
- **Verifikasi:** jumlah per kelas di Studio sama persis dengan file (Beam 23, ParticleEmitter 12, Part 14, Attachment 37, SpecialMesh 2). `MainWaterSheet` kembali terhubung ke `StoneLipWaterline` → `BasinWaterline`. Tampilan depan plaza sama dengan sebelum pekerjaan ([19](19-restored-original-front.jpg) vs [06](06-waterfall-front.jpg)).
- **Es tetap diperbaiki:** `ApproachMist` Y 2590,62 dan `ApproachShadow` Y 2571,39 (masih turun 2,5 stud). Gundukan naik dari plaza tanpa alas datar dan gerigi ungu ([20](20-ice-fix-kept.jpg)).
- **Pembersihan:** console bersih. Edit / 0 pemain / 0 sisa `_QA` maupun model percobaan. `CanQuery` mesh kanal tetap false.

### Catatan undo

Script rebuild pertama sempat gagal di tengah (`CFrame.fromMatrix` menerima nil setelah part lama dihapus), lalu dijalankan ulang dengan sukses. Akibatnya recording ChangeHistory "RebuildPalaceWaterfall" tertinggal dalam status *in progress*, sehingga riwayat undo langkah ini mungkin tidak rapi. Jangan mengandalkan Ctrl+Z untuk membatalkan perubahan air terjun/air mancur. Jika perlu kembali, ambil dari `Fly High.rbxl` yang tersimpan sebelumnya atau dari Git.

## Status

Penurunan awan dan pemulihan air terjun **belum disimpan** ke `Fly High.rbxl`, belum commit atau Publish. Source script tidak berubah (mirror tetap 67/67).

Catatan: `Fly High.rbxl` di disk sudah berubah dari HEAD sebelum pekerjaan ini (3.547.492 B, disimpan 20:58:32 WIB, bersamaan dengan folder baru `assets/marketing/cloud-palace/2026-11-20/`). Simpanan itu bukan dari sesi ini dan belum memuat penurunan awan di atas. Air terjunnya identik dengan kondisi Studio sekarang karena air terjun dipulihkan dari file ini.

## Checkpoint Git (ditambahkan 21 Nov 16:40 WIB)
Status di atas adalah status pada waktu run. Setelahnya, `Fly High.rbxl` lokal (`3.590.804` B) disimpan pengguna 21 Nov 16:16 WIB, SHA-256 `120a7ad6…71b59432`; parser offline: 67/67 source sama persis dengan mirror setelah normalisasi (LF, spasi akhir), objek/model belum dibuka ulang. Laporan ini dikonsolidasikan ke commit & push `main` 21 Nov.
