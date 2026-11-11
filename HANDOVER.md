# Handover Fly High

Snapshot aktif per 11 November 2026, Asia/Jakarta. Dokumen ini menggabungkan ringkasan AI_CONTEXT dan handover teknis. Progres fitur dipelihara di [PROGRESS](PROGRESS.md), aturan produk di [PRD](PRD_Fly_High.md).

> **Checkpoint setelah tabel baseline di bawah:** perbaikan penerbangan dan kemenangan tim menambahkan ModuleScript **PalaceArrival** (server kini 19 source, total 41). BalloonManager dan FlightSpace berubah; dermaga direnggangkan sebagai objek place, termasuk PreviewBase miniatur. Ketiga source perubahan cocok dengan Studio setelah normalisasi newline, dan seluruh 41 source lolos kompilasi. Run lima klien lulus 47 pemeriksaan terkontrol; lihat [hasil](audit/flight-fixes-2026-11-11-results.json), [bukti/build](audit/flight-fixes-2026-11-11-build.json) dan [desain](design/features/flight-arrival/design.md). Angka 40/40 dan SHA pada baseline dokumentasi adalah snapshot sebelum perubahan ini. File lokal telah disimpan; binary belum dibuka ulang untuk dibandingkan. Checkpoint ini disertakan dalam paket commit perbaikan penerbangan; hasil commit/push harus diperiksa melalui riwayat Git. Tabel berikut tetap merupakan snapshot awal, bukan HEAD terbaru.

## Keadaan workspace

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

Temuan COOP-LATERAL-POSITION dan anomali jump setelah pergantian role belum ditutup oleh QA analog. Lihat PROGRESS.

Perjalanan penuh historis merekam solo/duo/trio mencapai puncak dengan verifikasi terminal co-op terpisah. singleAllGreenEndToEndSuite masih false pada [ringkasan historis](audit/full-journey-summary.json). Penerbangan scenery yang dipercepat dan memakai shield tidak memperbarui hasil suite tersebut.

Katalog Sky Adventure memuat QA HUD historis. Hasil pemuatan 7/27 gambar prototipe Oktober berbeda paket dari atlas aktif. Screenshot scenery 10 November merekam pass awal sebelum polesan lanjutan.

Publikasi, Robux nyata dan cloud ditunda. Product ID yang dikonfigurasi adalah EmergencyKit 3723339056 dan AK47Upgrade 3723339246. Harga UI dibaca dari Roblox.

Sesudah pekerjaan, perbarui PROGRESS, bersihkan fixture, simpan place dan pulihkan Edit / Test / satu pemain / viewport default. Commit/push mengikuti permintaan pengguna.
