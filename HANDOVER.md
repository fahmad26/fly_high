# Handover Fly High

Snapshot aktif per 12 November 2026, Asia/Jakarta. Dokumen ini menggabungkan ringkasan AI_CONTEXT dan handover teknis. Progres fitur dipelihara di [PROGRESS](PROGRESS.md), aturan produk di [PRD](PRD_Fly_High.md).

Checkpoint Git 12 November: paket commit yang memuat catatan ini mencakup patch audit DataManager/WeaponManager, place lokal dengan polesan gondola/jalan dermaga, bukti audit, katalog skill/knowledge, tooling MCP dan draft motion HUD. Sebutan "belum commit/push" pada catatan run 11 November di bawah adalah status historis sebelum checkpoint ini; gunakan riwayat Git dan hasil verifikasi remote untuk status pengiriman. Tidak ada QA gameplay baru pada tugas commit. Binary place tetap belum dibuka ulang untuk dibandingkan dengan Studio. Backup lama `audit/Fly High.before-arcade-refine.rbxl` dipertahankan lokal dan tidak disertakan dalam paket.

> **Checkpoint setelah tabel baseline di bawah:** perbaikan penerbangan dan kemenangan tim menambahkan ModuleScript **PalaceArrival** (server kini 19 source, total 41). BalloonManager dan FlightSpace berubah; dermaga direnggangkan sebagai objek place, termasuk PreviewBase miniatur. Ketiga source perubahan cocok dengan Studio setelah normalisasi newline, dan seluruh 41 source lolos kompilasi. Run lima klien lulus 47 pemeriksaan terkontrol; lihat [hasil](audit/flight-fixes-2026-11-11-results.json), [bukti/build](audit/flight-fixes-2026-11-11-build.json) dan [desain](design/features/flight-arrival/design.md). Angka 40/40 dan SHA pada baseline dokumentasi adalah snapshot sebelum perubahan ini. File lokal telah disimpan; binary belum dibuka ulang untuk dibandingkan. Checkpoint ini disertakan dalam paket commit perbaikan penerbangan; hasil commit/push harus diperiksa melalui riwayat Git. Tabel berikut tetap merupakan snapshot awal, bukan HEAD terbaru.

## Keadaan workspace

Checkpoint pengiriman motion HUD: commit yang memuat catatan ini mencakup HUDMotion, revisi hover/silhouette, place tersimpan dan bukti QA kedua iterasi. Penyebutan belum commit/push pada laporan run di bawah adalah status sebelum checkpoint pengiriman; verifikasi commit remote dilakukan setelah push. Binary place belum dibuka ulang. Backup place lama tetap lokal.

Revisi hover setelah penolakan pengguna: [hasil dan batas](audit/hud-motion-refine-2026-11-12/README.md). Tombol kini memakai satu child UIScale, render layout/motion diurutkan, outline kotak cyan dihapus dan sheen mengikuti alpha sprite. Regresi 9/9, sampel hover monotonic/root stabil dan cek silhouette lulus; 42 compile, lima source sama persis. Ini menggantikan klaim kualitas motion awal yang belum memuaskan pengguna. Place tersimpan, Edit/default, belum commit/push; review manusia/mobile tetap terbuka.

Motion HUD sudah mendapat persetujuan dan implementasi awal: [desain](design/features/hud-motion/design.md), [QA/batas](audit/hud-motion-2026-11-12/README.md). Module HUDMotion baru membuat total 42 source; lima source berubah/baru sama persis dengan mirror dan 42 compile. Tombol/popup, bar, pulse state, milestone dan pilihan animasi ringan tersedia. Runtime/presentation 14/14; simulator phone/iPad dan gamepad diperiksa, input sentuh fisik belum. Place disimpan, binary belum dibuka ulang; belum commit/push tugas motion. Fixture runtime terhapus setelah Stop; viewport default. [Analisis video awal](audit/hud-motion-reference-2026-11-11/README.md) tetap bukti historis sebelum implementasi, status terbaru mengikuti UI-01.

Integrasi Figma dan Blender telah disiapkan: [MCP_SETUP](docs/roblox-development/MCP_SETUP.md). Figma terhubung; Blender stdio dan add-on aktif lolos tes status/baca scene. Restart Codex diperlukan untuk memuat tool Blender native. Folder .local-tools diabaikan Git tetapi dipakai command MCP; jangan dipindah sembarangan. Tidak ada perubahan game pada tugas setup ini.

Sambungan ujung A/E diperbaiki setelah review sebelumnya hanya memotret B/C: [fillet A/E, foto dekat seluruh A–E dan QA lima rute](audit/path-endpoints-fix-2026-11-11/README.md). Generator ini menggantikan path-seams-fix lama. Lampu/taman, lebar/collider dan posisi dermaga tetap; source gameplay tidak berubah. WORLD-01 menyimpan progres. Place tersimpan, belum commit/push perbaikan ini.

Polesan gondola tersedia pada kelima BalloonVariants dan HotAirBalloon: [desain, generator dan QA](audit/basket-polish-2026-11-11/README.md). Ini perubahan objek place; source gameplay tidak diubah. WORLD-04 mencatat cakupan uji dan sisa review. Place tersimpan, belum commit/push polesan.

[Audit game](audit/game-audit-2026-11-11/README.md) tetap menyimpan temuan historis. [Patch audit berikutnya](audit/audit-fixes-2026-11-11/README.md) memperbaiki LOS/validasi obstacle, coalescing preferensi, fencing session-lost serta occlusion papan. Source 41/41 cocok/compile; place tersimpan, binary belum dibuka ulang, belum commit/push patch ini. Performa AUD-04 diabaikan sesuai instruksi pengguna. Status dan QA tersisa ada pada OPEN-06; OPEN-05/full journey tetap belum hijau.

Referensi development kini tersedia di [docs/roblox-development](docs/roblox-development/README.md): katalog skill, knowledge Roblox/Lua/Luau, checklist dan audit keamanan bertanggal. Lihat DOC-02 di PROGRESS untuk bukti instalasi serta batas review. Ini pekerjaan dokumentasi/tooling; tidak mengubah gameplay atau hasil QA perjalanan.

Perbaikan akses dermaga: tanah yang menutupi area A telah diratakan dan jalan nyata selebar 9 stud dibangun dari plaza spawn melalui promenade ke kelima dermaga. Perubahan objek/Terrain; source gameplay tidak berubah. [QA akses](audit/dock-access-2026-11-11/README.md) menyimpan sampel tinggi, pengujian jalan native, screenshot akhir dan percobaan CSG yang ditolak. Status commit/push perubahan akses terpisah dari commit 4409385.

Regresi lanjutan: [run perjalanan enam klien](audit/journey-regression-2026-11-11/README.md) belum lulus penuh (solo fixture, trio lima lubang, duo timeout 8.283 km). Jangan menyebut suite hijau. Regresi lima klien terkontrol lulus 47/47, input driver solo terkoreksi lulus 11/11. Seluruh 41 source Studio cocok dengan mirror dan lolos kompilasi. Sebanyak 17 Beam air terjun diperbaiki dari texture gagal muat ke texture bawaan valid; run solo berikutnya bersih dari warning/error klien. Source fixture, hasil gagal, build dan batas tersedia dalam folder audit. Paket mencakup perbaikan lokal di bawah; status commit/push harus diperiksa melalui Git. Binary tersimpan belum dibuka ulang untuk pembandingan.

Checkpoint dermaga/health 1 pada commit 4409385: layout zigzag diganti busur radius 90; akses tanah/jalan direvisi lagi pada checkpoint terbaru di atas. ObstacleManager serta ObstacleMotion memprediksi kecepatan vertikal aktual saat menarget, termasuk balon turun dengan empat lubang. [QA](audit/docks-critical-health-2026-11-11/README.md) dan [build](audit/docks-critical-health-2026-11-11/build.json) mencatat 18/18 kombinasi musuh/gas serta cek okupansi.

Checkpoint reparasi/role pada commit 4409385: TetherManager, BalloonFleetAnimator dan FlightJumpController berubah setelah commit 8e02af0. Hold native diteruskan lewat remote tervalidasi, completion dihitung server, dan pembatalan membedakan pelepasan input dari hilangnya prompt. Recovery katrol serta buffer tap loncat telah ditambahkan. [QA](audit/repair-motion-2026-11-11/README.md) mencatat trio 40/40 dan solo 11/11 lulus; source akhir tetap memvalidasi jarak 10 stud. Source/place dan keterbatasan QA dicatat di [build](audit/repair-motion-2026-11-11/build.json).

| Item | Hasil pemeriksaan |
| --- | --- |
| Workspace | E:/Antigravity/Fly High |
| Repo | [fahmad26/fly_high](https://github.com/fahmad26/fly_high) |
| Branch dan HEAD | main, 4765f4594e8cdf793a25ebb58c4b6c1e40d98a12 |
| origin/main lokal | Sama dengan HEAD. Remote tidak di-fetch ulang dalam tugas dokumentasi. |
| Studio | Fly High.rbxl, Edit, PlaceId 0 |
| Studio terhadap mirror | 40/40 source cocok berdasarkan panjang byte dan hash rolling setelah normalisasi |
| Mirror terhadap HEAD | 38/40 cocok. FlightHUDController dan HUDLayout memuat perubahan analog lokal yang belum di-commit. |
| File place terhadap HEAD | Berubah. Source binary belum diperiksa dengan membuka ulang file tersimpan pada tugas dokumentasi ini. |
| Gameplay QA baru | Tidak dijalankan pada tugas perapian dokumentasi |

Manifest per source, metode pembandingan dan SHA-256 place ada di [baseline dokumentasi](audit/documentation-baseline-2026-11-11.json). Ulangi pemeriksaan setelah source atau place berubah.

## Menentukan sumber acuan

- Instruksi pengguna terbaru menentukan perubahan yang diinginkan. Catat persetujuan baru di PRD dan PROGRESS.
- PRD menyimpan aturan produk. PROGRESS menyimpan status implementasi serta bukti.
- Pengguna pernah memilih Studio sebagai implementasi lokal yang benar saat terjadi perbedaan. Untuk melanjutkan sesi ini, periksa Studio aktif dan bandingkan dulu dengan mirror serta HEAD.
- audit/sources/ merupakan mirror DataModel untuk review Git. Tidak ada sinkronisasi otomatis Rojo.
- Source yang cocok belum membuktikan kesamaan Terrain, model, constraint, atribut dan pengaturan StarterPlayer.
- Ikuti [WORKFLOW](docs/WORKFLOW.md) ketika ada diff atau saat menutup pekerjaan.

## Peta DataModel

Pemeriksaan 40 source mencakup tiga akar berikut. Jumlah ini merupakan inventaris, bukan hasil kompilasi/Playtest baru.

| Lokasi | Source |
| --- | --- |
| ReplicatedStorage.FlyHigh.Modules — 11 | BalloonThemes, BiomeScenery, FlightControlMath, FlyHighConfig, HUDAdventureArt, HUDAdventureCatalog, HUDGlyphs, HUDImageAssets, HUDLayout, HUDTheme, WeaponPresentation |
| ServerScriptService.FlyHighServer — 18 | BalloonManager, CrewAccessGuard, DataManager, FlightSpace, IslandWildlifeController, JumpManager, LargeChallengeManager, ObstacleArt, ObstacleManager, ObstacleMotion, OverheadManager, PalaceManager, PodManager, ServerUtils, ShopManager, TetherManager, WeaponManager, WeaponRackPresentation |
| StarterPlayer.StarterPlayerScripts — 11 | BalloonFleetAnimator, BiomeLightingController, FlightHUDController, FlightJumpController, IslandNatureAnimator, PalacePresentation, ShopClientController, StormCurtainPresentation, WarningAudioController, WeaponClientController, WorldUISkins |

Objek penting lain berada di ReplicatedStorage.FlyHigh.Remotes, Templates, EnvironmentAssets, Workspace.FlyHighLobby.MatchmakingPods dan Workspace.CloudPalace.

## Titik masuk perubahan

| Sistem | Source utama |
| --- | --- |
| Launch, kemudi, kerusakan, gas, ending | BalloonManager, FlightSpace, ServerUtils |
| Dermaga dan akses tim | PodManager, CrewAccessGuard |
| Tali, katrol, tambal dan rescue | TetherManager |
| Senjata, auto-aim, tracer dan FPS | WeaponManager, WeaponRackPresentation, WeaponClientController, WeaponPresentation |
| Musuh dan hazard reguler | ObstacleManager, ObstacleMotion, ObstacleArt |
| Dinding Badai dan loncatan | LargeChallengeManager, JumpManager, StormCurtainPresentation, FlightJumpController |
| Penyimpanan, produk dan loadout | DataManager, ShopManager, ShopClientController |
| HUD dan papan dunia | FlightHUDController, HUDLayout, HUDTheme, HUDAdventureArt, HUDAdventureCatalog, WorldUISkins |
| Bioma dan Istana Awan | BiomeScenery, BiomeLightingController, PalacePresentation, PalaceManager |
| Fauna, tanaman dan armada | IslandWildlifeController, IslandNatureAnimator, BalloonFleetAnimator |

## Perilaku penting untuk regresi

- Tim 1–3 pemain dan lima dermaga. Okupansi dermaga memeriksa balon tim mana pun.
- Rintangan lingkungan mulai 300 km. Tabrakan antarbalon dan tembakan ke balon sendiri dapat memberi lubang sejak lepas landas.
- Lima lubang memicu jatuh tetap 2.000/3 km per detik. Clutch Save masih mungkin sebelum terminal.
- Kemudi mengikuti kamera. Pengali horizontal dihitung ulang dari kru hidup setiap Heartbeat, dengan acuan 30 / 22,5 / 18 stud per detik untuk 1 / 2 / 3 kru.
- Role aktif eksklusif. Hanya pilot yang memegang kemudi boleh mengubah gas otomatis. Gas aktif tetap berjalan setelah lepas kemudi.
- Tali mengikuti alur pasang, naik, tambal tiap lubang, turun dan otomatis lepas, lalu perbaiki saat dilepas. Pemain menggantung memerlukan rescue oleh rekan bebas role.
- Tali putus melempar avatar lalu menewaskannya. Timer kejadian lama tidak boleh mengenai karakter baru.
- Senjata memakai first person saat equip dan kembali third person saat dilepas. Magazen Pistol 8 dan AK-47 30, cadangan tak terbatas.
- AK-47 permanen berbentuk unit. Dua rak membutuhkan dua unit. Loadout Party Master berlaku saat summon dan terkunci selama penerbangan.
- Kondisi HUD menghitung sisa kesehatan, 5/5 saat utuh dan 0/5 saat lima lubang.
- Hold action reparasi memakai prompt native. Tombol tap memakai HUD custom.
- Dynamic Thumbstick menjadi default sentuh lokal. MoveAction dipakai pada PlayerModule baru, GetControls pada versi lama. Native jump disembunyikan secara terpisah.
- Scenery udara bersifat lokal, tanpa collision/touch/query. Rintangan ditangani sistem server terpisah.

## Batas bukti dan lanjutan

QA reparasi/role terbaru memverifikasi loncat pada jalur produksi normal serta tambal saat bermanuver. COOP-LATERAL-POSITION tetap memerlukan pengujian latency publik dan perangkat fisik; jangan menganggap satu regresi lokal menutup semua kasus desync. Lihat PROGRESS.

Perjalanan penuh historis merekam solo/duo/trio mencapai puncak dengan verifikasi terminal co-op terpisah. singleAllGreenEndToEndSuite masih false pada [ringkasan historis](audit/full-journey-summary.json). Penerbangan scenery yang dipercepat dan memakai shield tidak memperbarui hasil suite tersebut.

Katalog Sky Adventure memuat QA HUD historis. Hasil pemuatan 7/27 gambar prototipe Oktober berbeda paket dari atlas aktif. Screenshot scenery 10 November merekam pass awal sebelum polesan lanjutan.

Publikasi, Robux nyata dan cloud ditunda. Product ID yang dikonfigurasi adalah EmergencyKit 3723339056 dan AK47Upgrade 3723339246. Harga UI dibaca dari Roblox.

Sesudah pekerjaan, perbarui PROGRESS, bersihkan fixture, simpan place dan pulihkan Edit / Test / satu pemain / viewport default. Commit/push mengikuti permintaan pengguna.
