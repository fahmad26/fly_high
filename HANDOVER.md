# 📋 Dokumen Handover & Panduan Audit Teknis — "Fly High"

Dokumen ini disiapkan sebagai panduan komprehensif bagi AI Reviewer / Developer selanjutnya untuk memeriksa, mengaudit, dan melanjutkan pengembangan game Roblox **Fly High**.

> **Pembaruan audit 28 Oktober 2026:** Dua revisi PRD sudah diterapkan dan place lokal sudah disimpan. Bagian arsitektur/status awal di bawah adalah baseline historis; gunakan bagian 5 dan [AUDIT_REPORT.md](./AUDIT_REPORT.md) untuk keadaan terbaru dan batas verifikasi.

---

## 1. Informasi Repositori & Berkas Utama

- **Repositori GitHub**: [https://github.com/fahmad26/fly_high](https://github.com/fahmad26/fly_high)
- **Berkas Spesifikasi Produk (PRD)**: [`PRD_Fly_High.md`](./PRD_Fly_High.md) *(Sumber kebenaran utama / Single Source of Truth)*
- **Berkas Place Roblox Studio**: [`Fly High.rbxl`](./Fly%20High.rbxl)
- **Ikhtisar Proyek**: [`README.md`](./README.md)

---

## 2. Arsitektur DataModel di dalam `Fly High.rbxl`

Seluruh kode dan aset permainan berada di dalam [`Fly High.rbxl`](./Fly%20High.rbxl) dengan struktur hierarki berikut:

### A. `ReplicatedStorage.FlyHigh`
1. **`Modules.FlyHighConfig`** (`ModuleScript`):
   - Menyimpan konstanta global: `MAX_ALTITUDE_KM = 10000`, `BASE_FLIGHT_DURATION_SEC = 600`, `MAX_HOLES = 5`, `PASSIVE_INVULN_DURATION = 5`, `CLUTCH_SAVE_INVULN_DURATION = 60`, `MAX_PLAYERS_PER_POD = 3`, `COUNTDOWN_DURATION = 1`, durabilitas tali (`ROPE_MAX_DURABILITY = 100`, `ROPE_DECAY_PER_SEC = 5`), spesifikasi `Pistol` & `AK47`, serta tabel `HOLE_EFFECTS` (0 s.d. 5 lubang).
2. **`Remotes`** (`Folder` berisi `RemoteEvent`):
   - `PilotControlEvent` (Client -> Server: input kemudi WASD & status tombol Gas, di-throttle 10 Hz).
   - `FlightStateSyncEvent` (Server -> Client: sinkronisasi ketinggian, jumlah lubang, timer kebal, status terjun bebas, di-throttle 10 Hz).
   - `EmergencyKitEvent` (Client -> Server: aktivasi Emergency Repair Kit / Clutch Save).
   - `HazardAlertEvent` (Server -> Client: peringatan dini 3 detik sebelum hazard unshootable seperti Tornado).
   - `TetherEvent` (Server -> Client: status ikatan tali pengaman & durabilitas).
   - `RepairHoleEvent` (Event perbaikan lubang).
   - `TacticalPingEvent` (Client -> Server: komunikasi taktis & *Ghost Spotter* beacon 3D).
   - `WeaponFireEvent` (Client -> Server -> AllClients: validasi tembakan raycast & visual peluru).
   - `WeaponDropEvent` (Client -> Server: mengembalikan senjata ke rak terdekat dengan tombol `[G]`).
   - `ShopPurchaseEvent` (Client -> Server: pembelian Emergency Kit & upgrade AK-47).
3. **`Templates`** (`Folder`):
   - `HotAirBalloon` (`Model`): Memiliki `RootPart` (dengan `AlignPosition` & `AlignOrientation`), `BasketFloor`, pagar pembatas, `HelmSeat` (dengan `HelmPrompt`), `Burner` (`BurnerFlame` & `BurnerLight`), `EmergencySiren` (`SirenLight`), `WeaponRack1`, `WeaponRack2`, `TetherStation` (`TetherPrompt` & `ClimbPrompt`), `Envelope`, `EnvelopeWalkway` (`DescendPrompt`), dan `HoleSlots` (`Hole1` s.d. `Hole5` masing-masing dengan `PatchPrompt`).
   - `Weapons` (`Folder`): `Pistol` (8 peluru, semi-auto) dan `AK47` (30 peluru, auto).
   - `Obstacles` (`Folder`): `WildBird`, `Tornado`, `Hailstone`.

### B. `ServerScriptService.FlyHighServer`
1. **`DataManager`** (`Script`):
   - Mengelola penyimpanan `DataStoreService` (`FlyHigh_PlayerData_v1`) dengan *fallback mock mode* otomatis jika place belum dipublikasikan.
   - Menyimpan dan menyinkronkan atribut pemain (`MaxAltitude`, `SummitCount`, `EmergencyKits`) serta folder `leaderstats`.
2. **`OverheadManager`** (`Script`):
   - Memasang `BillboardGui` di atas kepala karakter pemain yang menampilkan label `👑 PARTY MASTER` (jika Master), serta `[⭐ Puncak: Xx]` (jika sudah pernah menamatkan 10.000 km) atau `[Rekor: X km]`.
3. **`PodManager`** (`Script`):
   - Mengelola 5 pod keberangkatan (`Pod_A` s.d. `Pod_E`) di dalam `Workspace.FlyHighLobby.MatchmakingPods`.
   - Mendeteksi pemain di atas pad menggunakan `Workspace:GetPartBoundsInBox` (`Enum.RaycastFilterType.Include`), menetapkan pemain pertama sebagai Master (`IsMaster = true`), dan memicu peluncuran balon tepat di koordinat pad masing-masing (`podData.pad.Position`).
4. **`BalloonManager`** (`Script`):
   - Melakukan *spawn* balon di permukaan darat (`Y = 12.5`), meneleportasi kru ke dalam keranjang, dan menginisialisasi rak senjata serta stasiun tali.
   - Menjalankan loop fisika `RunService.Heartbeat`: menghitung laju naik/turun berdasarkan jumlah lubang (`0` s.d. `5`), kemudi horizontal WASD, kemiringan dinamis (*tilt*), *Clutch Save* dengan *Anti-Waste Cooldown* (mengunci pemakaian kit ganda saat shield 60 detik aktif), deteksi 2 kondisi *Game Over* (*Ground Crash* di 0 km setelah lepas landas & *Total Crew Wipe*), serta pendaratan kemenangan di `CloudPalace` pada ketinggian 10.000 km.
5. **`WeaponManager`** (`Script`):
   - Mengatur 2 rak senjata di gondola (Pistol default atau AK-47 jika Master membeli upgrade).
   - Menangani pengembalian senjata ke rak (`WeaponDropEvent`) dan validasi tembakan raycast di sisi server (`Enum.RaycastFilterType.Exclude`) terhadap model ber-atribut `IsObstacle`.
6. **`TetherManager`** (`Script`):
   - Mengatur ketersediaan tali pengaman (1 tali untuk tim 1–2 pemain, 2 tali untuk tim 3 pemain).
   - Mengelola sistem katrol *winch* untuk naik ke `EnvelopeWalkway` dan turun kembali ke `BasketFloor`.
   - Menghitung peluruhan durabilitas tali (`-5 HP/detik` di luar keranjang), *rope snap* (putus pada 0% yang menewaskan pemain), *dynamic weight tilt* pada balon, *Repair Hold Scaling* (`1.5s` Solo / `2.0s` Duo / `3.0s` Trio), dan marker 3D *Ghost Spotter*.
7. **`ObstacleManager`** (`Script`):
   - Mengatur pemunculan rintangan global di jalur terbang berdasarkan ketinggian balon aktif, pergerakan rintangan menggunakan `BodyVelocity`, peringatan dini 3 detik untuk Tornado, serta deteksi tumbukan ke kubah balon.
8. **`ShopManager`** (`Script`):
   - Memproses pembelian *Emergency Kit* (siapa saja) dan *AK-47 Upgrade* (khusus Party Master, langsung memperbarui rak senjata balon tim).

### C. `StarterPlayer.StarterPlayerScripts`
1. **`FlightHUDController`** (`LocalScript`):
   - Menampilkan Altimeter Progress Bar, status 5 lubang, peringatan dini 3 detik, dan tombol *Emergency Kit*.
   - Menampilkan tombol **`[ 🔥 GAS / NAIK ]`** **hanya** ketika pemain duduk di `HelmSeat` (Mendukung Mouse & Touch; tidak menggunakan tombol Spacebar agar tidak memicu lompatan keluar kursi).
   - Mengirimkan input kemudi WASD secara ter-throttle ke server hanya saat menjadi Pilot.
2. **`WeaponClientController`** (`LocalScript`):
   - Menampilkan HUD amunisi, tombol tembak manual mobile, *soft-lock aim assist* ke rintangan terdekat di layar, efek *recoil/spread*, visual *bullet tracer*, bar durabilitas tali pengaman, serta tombol *Ghost Spotter* ketika karakter mati (otomatis di-reset saat respawn).
3. **`ShopClientController`** (`LocalScript`):
   - Menampilkan tombol dan modal toko untuk membeli *Emergency Kit* dan *AK-47 Upgrade*.
4. **`BiomeLightingController`** (`LocalScript`):
   - Mengubah properti `Lighting` secara mulus (`TweenService`) setiap kenaikan 2.000 km melewati 5 bioma sesuai PRD.

### D. `Workspace`
1. **`FlyHighLobby`**: Pulau awal kompak (`150x140`), `LobbySpawn`, `WelcomeSign`, `MatchmakingPods` (`Pod_A`–`Pod_E`), `OceanWater`, dan `InvisibleBoundaryCorridor` (4 dinding pembatas vertikal).
2. **`CloudPalace`**: Pulau & Istana Awan di puncak (`Y = 2500`), `CloudHavenDock`, `PhotoboothSpot` (dengan `PhotoPrompt` penyembunyi HUD 8 detik), dan `ReturnPortal`.

---

## 3. Status Implementasi vs. Perubahan PRD Terakhir (PENTING)

Seluruh fitur inti di atas telah diuji melalui *Automated Self-Review* (8 skenario pengujian end-to-end di dalam Game VM Roblox Studio) dan berjalan tanpa error.

Namun, tepat sebelum handover ini, User meminta **2 pembaruan spesifikasi yang baru ditulis ke dalam `PRD_Fly_High.md` terlebih dahulu** dan **perlu diimplementasikan/diverifikasi ke dalam `Fly High.rbxl`**:

1. **Perluasan Safe Takeoff Zone menjadi 6x Lipat (`0 – 1.200 km`)**:
   - **Di PRD (`PRD_Fly_High.md`)**: Sudah diperbarui menjadi `0 – 1.200 km` bebas rintangan agar antar balon pemain tidak bertabrakan saat lepas landas.
   - **Di `Fly High.rbxl` (`ObstacleManager.lua`)**: Saat ini kondisi aman masih memeriksa `if altKm >= 200 then`. Perlu diubah menjadi `if altKm >= 1200 then` (serta menyesuaikan ambang rintangan pertama pada `1.200 – 2.000 km`).
2. **Perluasan Keranjang Balon Udara (Gondola) menjadi 2x Lipat**:
   - **Di PRD (`PRD_Fly_High.md`)**: Sudah diperbarui bahwa ukuran lantai keranjang (`BasketFloor`) diperluas 2x lipat karena ukuran saat ini terasa sempit.
   - **Di `Fly High.rbxl` (`ReplicatedStorage.FlyHigh.Templates.HotAirBalloon`)**: Ukuran `BasketFloor`, pagar pembatas (`Railing`), posisi `HelmSeat`, `WeaponRack1`, `WeaponRack2`, `TetherStation`, serta jarak deteksi keluar keranjang di `TetherManager.lua` (`dist > 8.5`) perlu diperbesar 2x lipat mengikuti geometri keranjang baru.

---

## 4. Daftar Periksa Audit (Review Checklist)

1. **Verifikasi Kesesuaian PRD**: Bandingkan seluruh bab di [`PRD_Fly_High.md`](./PRD_Fly_High.md) dengan skrip dan objek di [`Fly High.rbxl`](./Fly%20High.rbxl).
2. **Implementasi 2 Poin Update PRD Terakhir**:
   - Update batas *Safe Takeoff Zone* ke `1.200 km` di `ObstacleManager`.
   - Perbesar geometri keranjang `HotAirBalloon` 2x lipat beserta penyesuaian offset komponennya dan radius deteksi di `TetherManager`.
3. **Audit Keamanan & Performa**:
   - Pastikan seluruh `RemoteEvent` memvalidasi input dan otorisasi di sisi server (misal: validasi jarak, cooldown, kepemilikan item, dan status Master).
   - Pastikan pembersihan objek (*memory leak prevention*) saat balon hancur atau pemain keluar dari server.
4. **Uji Coba Playtest di Roblox Studio**:
   - Jalankan *Playtest* dan pastikan konsol bersih dari error/warning.

---

## 5. Hasil Audit 28 Oktober 2026

- Safe Takeoff Zone 1.200 km diterapkan pada spawn, pergerakan obstacle dan validasi damage.
- Gondola menjadi 28×28 stud (panjang/lebar masing-masing 2×); pagar, helm, rak, stasiun, tiang dan deteksi tali ikut disesuaikan. Boarding digeser 18 stud ke belakang pad.
- Ditambahkan ServerUtils (ModuleScript) dan PalaceManager (Script), sehingga total 15 skrip. Source dapat ditinjau di `audit/sources/`.
- Amunisi/raycast/reload dikendalikan server; validasi kru, remote, repair hold, kit, lifecycle tali dan status terminal diperbaiki.
- Rintangan memakai scheduler global per segmen dan profil dasar sembilan zona. Beberapa model dan efek masih prototipe.
- Altitude menggunakan 0,25 stud/km dari groundY=12,5; batas flight root=2512,5. Istana berada di atas ceiling penerbangan (CloudIsland Y=2580, Z=0), dengan docking bertahap ke CloudHavenDock.
- Koridor diganti menjadi delapan Part yang menjangkau tanah sampai Y=2600, tepi ±150; pusat balon dibatasi ±120.
- Katrol bergerak halus; tersedia kontrol HUD pasang/isi tali, naik, turun dan tahan tambal. F naik, Q turun.
- Shop sekarang menggunakan ProcessReceipt. PRODUCT_IDS kini terisi (lihat bagian 9); pembelian pada file lokal unpublished tetap dinonaktifkan. Mock data hanya untuk Studio unpublished.
- Regresi otomatis: **43/43 lulus**, 15 skrip dapat dikompilasi; sesi terakhir **0 error / 0 warning**.
- Pengujian lokal mengonfirmasi Clutch Save, interaksi rigging, raycast/ammo server, Victory + Summit dan Ground Crash. Multiplayer nyata, cloud DataStore/receipts, mobile/controller fisik dan run natural 600 detik belum diverifikasi.
- Audio sirine, Hall of Fame persisten, dekor biome lengkap dan model/efek unik semua hazard masih terbuka.
- **Tindak lanjut laut selesai:** terrain rumput luar pulau diganti air Terrain 4096×4096 stud pada Y=0, dengan pesisir berpasir dan pusat lobby tetap Y=10. Sampling luar pulau kini Water; antrean dan peluncuran balon berhasil diuji. Backup di `audit/Fly High.before-ocean.rbxl`; detail di `audit/ocean-results.json`.
- Backup: `audit/Fly High.before-audit.rbxl`. Harness QA tidak dimasukkan ke place tersimpan. Detail temuan dan bukti ada di [AUDIT_REPORT.md](./AUDIT_REPORT.md).

## 6. Pembaruan Vegetasi dan Fauna Pulau

- Scene: `Workspace.FlyHighLobby.IslandNature`, dengan folder Trees, Plants, Flowers, Rocks, Details, Chickens dan Butterflies.
- Template mesh khusus: `ReplicatedStorage.FlyHigh.EnvironmentAssets` (PalmTree, BroadleafTree, Fern, Boulder, Chicken, Butterfly dan Flower).
- Jumlah: 20 pohon, 60 pakis/tanaman, 56 bunga, 12 batu besar, 114 kerikil + 7 batu pijakan, 6 ayam, 14 kupu-kupu.
- Pohon, pakis, batu, ayam dan kupu-kupu memakai mesh dengan siluet khusus. Bunga memakai geometri CSG berkelopak dan berdaun; bukan bola kecil sebagai kelopak.
- Terrain mendapat bukit kecil, jalur tanah dan material LeafyGrass di area lobby; tinggi fasilitas inti tetap dipertahankan. Spawn, jalur pod dan radius landasan dikecualikan dari dekorasi besar.
- `ServerScriptService.FlyHighServer.IslandWildlifeController`: ayam memilih tujuan aman di sekitar Home, berjalan, diam dan mematuk. Menghindari laut, pohon, batu, pemain dan area pod. Server hanya mereplikasi transform root pada 20 Hz.
- `StarterPlayer.StarterPlayerScripts.IslandNatureAnimator`: gerak kaki/kepala ayam, penerbangan/kepakan kupu-kupu serta goyangan daun; berjalan di client pada 30 Hz dengan pembatasan jarak.
- Total terbaru: 17 skrip. Model dekorasi tidak membawa skrip bawaan dari aset.
- QA: enam ayam berpindah posisi; 14/14 kupu-kupu bergerak; gerak kaki teramati; 17 skrip lolos kompilasi; playtest tanpa error/warning; API peluncuran balon berhasil pada root Y=12,5.
- Backup: `audit/Fly High.before-island-life.rbxl`. Manifest aset: `audit/nature-assets.json`; hasil QA: `audit/island-life-results.json`.

## 7. Lima Dermaga dan Armada Balon

- Pod_A: Penjelajah Fajar; Pod_B: Taman Mengapung; Pod_C: Koi Langit; Pod_D: Pengelana Saturnus; Pod_E: Lentera Istana.
- Pod lama menjadi dek bundar kayu/batu dengan panel SurfaceGui tunggal, indikator tiga kru, lampu status dan miniatur armada berputar. FloorPad deteksi serta StartPrompt tetap dipakai PodManager.
- ModuleScript baru: ReplicatedStorage.FlyHigh.Modules.BalloonThemes. Template mekanik dasar tetap HotAirBalloon; lima varian berada di Templates.BalloonVariants, kulit mesh di BalloonSkins, CSG di FleetGeometry.
- BalloonManager.LaunchBalloon menerima argumen opsional keempat podName; PodManager mengirim nama pod sehingga pilihan armada berasal dari server.
- Semua armada mempertahankan lantai 28×28, collider penerbangan yang sama, lima titik kerusakan, helm, dua rak dan stasiun tali. Ornamen tidak memiliki collision; seluruh bagian tersambung ke satu assembly milik server.
- LocalScript baru BalloonFleetAnimator menggerakkan miniatur, ekor/sirip koi, bintang orbit dan rumbai. Prompt dibatasi konteks kru lokal; validasi server tetap berlaku.
- Total terbaru 19 skrip; Source lengkap diekspor ke audit/sources. Lima peluncuran API produksi lulus; peluncuran Pod_C melalui prompt juga diuji. Konsol terakhir 0 error/0 warning.
- Bukti: audit/fleet-results.json, audit/fleet_playtest.luau, audit/fleet-assets.json, audit/five-fleets-preview.jpg. Backup: audit/Fly High.before-five-fleets.rbxl.
- Skrip build di audit/ adalah catatan rekonstruksi Edit, bukan script runtime. Aset hasil generasi disimpan di place; normalisasi/segmentasi/tekstur memerlukan cache aset tersebut.

## 8. Spawn dan Kontrol Penerbangan Terbaru

- ArrivalGarden menggantikan pad spawn putih secara visual; LobbySpawn tetap menjadi SpawnLocation tersembunyi.
- FlightControlMath (ReplicatedStorage.FlyHigh.Modules) memetakan input ke arah kamera horizontal. FlightSpace (ServerScriptService.FlyHighServer) menangani ruang spawn dan batas antarpusat balon. Total terbaru: 21 skrip.
- RemoteEvent baru FlightActionEvent menerima ReleaseHelm dan AutoGas. Server memvalidasi kru hidup, pilot untuk menyalakan gas, tipe boolean dan rate limit. Server mengatur AutoGas pada state serta attribute balon.
- Kontrol: H/Y lepas kemudi; Z/L1 gas otomatis; G/B kembalikan senjata; T/L2 lepas tali. Seluruhnya tersedia melalui tombol HUD juga. E pasang/isi tali, F naik, Q turun dan R reload tetap berlaku.
- TetherEvent menerima Detach dan membersihkan rope/attachment serta mengembalikan status humanoid/anchor saat katrol dibatalkan.
- Collider antarbalon diaktifkan; ResolveCollisions membatasi posisi target pada server dan menandai satu kerusakan per kontak. Clearance 60 stud horizontal, 64 vertikal. Semua jalur LaunchBalloon memeriksa okupansi lintas dermaga.
- ApplyPuncture(fd,cause) mendukung Collision/SelfShot di bawah 1.200 km. Rintangan masih tunduk SAFE_TAKEOFF_KM; Shield/grace damage tetap dihormati. WeaponManager membiarkan raycast mengenai proxy kubah sendiri dan mengecualikan balon tim lain.
- Lima lubang turun pada 2.000/3 km/detik. Server memindahkan balon dan kru yang masih berada di gondola/bertali secara konsisten agar dek tidak meninggalkan kru akibat percepatan mendadak. Clutch Save tetap aktif sebelum tanah.
- GROUNDED_TIMEOUT_SEC=60; penghitung server ditampilkan pada HUD. Ground crash/AFK memakai lifecycle EndFlight dan cleanup yang sama.
- U.Flight mengabaikan model yang sudah dilepas dari DataModel agar callback Destroying yang tertunda tidak menahan relaunch.
- Tantangan besar dan efek loncatan **hanya dokumentasi/backlog**, belum ada fitur runtime baru terkait loncatan.
- Backup sebelum revisi: audit/Fly High.before-flight-controls.rbxl. Bukti pengujian tambahan dan batasannya: audit/flight-controls-results.json serta AUDIT_REPORT.md.

## 9. Developer Products Terpasang (29 Oktober 2026)

| Key FlyHighConfig.PRODUCT_IDS | Product ID | Harga dasar terverifikasi |
| --- | --- | --- |
| EmergencyKit | 3723339056 | 29 Robux |
| AK47Upgrade | 3723339246 | 79 Robux |

ShopClientController membaca harga dari MarketplaceService:GetProductInfoAsync pada client; nominal perkiraan lama sudah dihapus. Prompt selesai/batal mengembalikan tombol tanpa memberikan item. Handler server _G.FlyHighShopManager.ProcessReceipt menjadi callback MarketplaceService.ProcessReceipt. DataManager.GrantReceipt mengembalikan (granted, isNew); hanya receipt AK baru yang boleh mencoba memasang upgrade otomatis.

Jumlah skrip tetap 21. QA receipt 14/14 lulus dengan penyimpanan mock; harga dan UI berhasil diperiksa di Play, konsol tanpa error/warning. Place masih lokal (GameId=0): transaksi Robux dan DataStore cloud belum diuji. Publikasikan/unggah file terbaru ke experience pemilik produk untuk pengujian berikutnya. Detail: audit/product-results.json dan AUDIT_REPORT.md.

## 10. Hasil QA Multiplayer Native (29 Oktober 2026)

- StudioTestService menjalankan tiga client terpisah dengan Player serta koneksi replikasi asli. Dua tim simultan (duo vs solo) diuji, selain satu flight trio.
- **50/50 pemeriksaan lulus**: antrean dan handoff Master, prompt start, pilot lepas + auto gas, gunner/engineer, replikasi perlengkapan, repair, Clutch Save, timeout daratan, okupansi lintas dermaga, collision, pembatasan akses lintas tim, tembakan dan disconnect cleanup.
- Collision selama 8 detik menghasilkan tepat satu lubang pada kedua tim dengan jarak root minimum 60,00023 stud; server tetap memegang physics ownership.
- WeaponClientController diperbaiki agar tidak mengakses TetherStation/HoleSlots/PatchPrompt sebelum child model direplikasi. Ini satu-satunya perubahan runtime pada sesi multiplayer ini; jumlah tetap 21 skrip.
- Bukti final: audit/multiplayer-results.json; log server dan tiga client kosong dari error/warning. Backup: audit/Fly High.before-multiplayer.rbxl. Harness native tersimpan di audit/ dan sudah dihapus dari DataModel produksi.
- Posisi skenario diatur server; hold patch memakai engineer stationary; timeout dipercepat. Ini simulasi lokal Studio, belum menggantikan uji manusia, perangkat nyata, latency atau server publik. Pembelian/cloud tetap ditunda. Fitur rintangan besar + loncat tetap dokumentasi.

## 11. Dinding Badai dan Loncatan Kru (29 Oktober 2026)

Fitur yang sebelumnya berupa backlog kini diimplementasikan. Total skrip produksi menjadi **24**.

- JumpManager (ServerScriptService.FlyHighServer): izin lompat menurut peran, penyimpanan/restorasi JumpPower/JumpHeight/state, observasi grounded/takeoff, cooldown, landed rearm, pembagian jatah turun dan cleanup koneksi Humanoid.
- LargeChallengeManager (server): scheduler lima milestone, gelombang global per zone, peringatan personal bagi pendatang, swept-volume hit, satu hit per flight, deduplikasi milestone serta cleanup model.
- FlightJumpController (StarterPlayerScripts): menegakkan state lompat lokal karena SetStateEnabled server tidak direplikasi, tombol lompat lintas input, cooldown dan panel instruksi badai yang responsif.
- Remote baru FlightJumpEvent hanya menerima Request; server tidak menerima jumlah penurunan dari client. LargeChallengeEvent dipakai server untuk Warning/Ended.
- FlyHighConfig memuat JUMP_* dan LARGE_* untuk balancing. BalloonManager mengonsumsi jumpDropRemaining dalam integrasi vertikal; EndFlight dan Emergency Kit mengosongkan jatah. Lima lubang tetap memakai kecepatan jatuh darurat.
- ObstacleManager menunda spawn reguler yang menarget peserta selama largeChallengeUntil dan memprediksi auto gas juga.
- Template visual: ReplicatedStorage.FlyHigh.Templates.Obstacles.StormCurtain, dengan 5 bank/wisp CSG, petir pada dua sisi dan core transparan. Collision gameplay dihitung server, bukan collider fisik awan.
- Nilai awal: 6 detik warning, volume 360×120×32, speed 60 stud/detik, milestone 1800/3600/5400/7200/9000 km. Jatah lompat 18/eligibleCrew stud, konsumsi maksimal 22 stud/detik, cap 36, cooldown 1,05 detik.
- Native QA menggunakan tiga client: solo/duo/trio, gunner/tethered jump, blokir pilot/katrol/kubah, anti-spam, global wave, damage dan avoidance serta milestone repeat prevention. Bukti: audit/storm-jump-results.json.
- Backup: audit/Fly High.before-storm-jumps.rbxl. Build visual: audit/build_storm_curtain.luau. Harness baru: audit/storm_jump_server_playtest.luau dan storm_jump_client_playtest.luau; tidak dipasang ke place produksi.
- Pembelian/cloud tetap ditunda. Perangkat sentuh/gamepad fisik, jaringan internet dan human playtest belum dijalankan.

## 12. QA Perangkat dan Perbaikan HUD — 29 Oktober 2026

- Jumlah produksi menjadi **25 skrip**, termasuk ModuleScript baru ReplicatedStorage.FlyHigh.Modules.HUDLayout. FlightHUDController memulai satu pengelola layout; FlightJumpController tidak lagi menimpa UIScale secara terpisah.
- Ditemukan skala lama mengecilkan objek tanpa mengoreksi offset posisinya: pada GUI 705×279, menu toko berada Y=-40,5 dan JumpPanel melewati bagian bawah layar. Layout baru memakai area aman GUI, posisi/dimensi yang konsisten, mode ringkas dan panel AKSI yang dapat digulir.
- ShopClientController memakai ScrollingFrame dengan tombol beli/tutup 44 piksel; harga dan alur receipt tidak diubah.
- Bug tombol lompat mode sentuh diperbaiki: Humanoid.Jump yang disetel saat Activated ditimpa TouchJump bawaan sebelum simulasi fisik. Tombol kini memasuki state Jumping biasa segera setelah validasi local grounded/role/health. Server tetap memvalidasi takeoff nyata; satu klik simulator menghasilkan JumpCount=1.
- Device Simulator: Galaxy A06, iPhone 17 Pro dan iPad Pro M5 (13in), landscape. Tidak ada panel terlihat di luar layar dan tidak ada tombol root sentuh di bawah 44 piksel pada hasil akhir.
- Regresi tiga client: **50/50 multiplayer + 51/51 badai/lompat lulus**; log server dan seluruh client pada sesi final bersih. Semua 25 skrip dapat dikompilasi. Driver QA dan remote sementara sudah dihapus; Studio kembali Edit/default viewport.
- Artefak: audit/device-qa-results.json, device-multiplayer-results.json, device-storm-results.json, device-phone-preview.jpg, device_review_server.luau, device_layout_probe.luau. Backup: audit/Fly High.before-device-qa.rbxl.
- Dua run antara meluluskan 50 skenario gameplay tetapi mencatat CoreGui CreatorType atau satu warning asset HTTP 502; raw log disimpan. Lookup harness untuk tombol AutoGas kini rekursif karena tombol dipindah ke panel AKSI pada mode ringkas.
- Ini tetap pengujian otomatis dan interaksi simulator; belum human playtest, HP/controller fisik atau latency internet. Cloud/pembelian/publikasi tetap ditunda.
