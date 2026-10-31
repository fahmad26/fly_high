# 📋 Dokumen Handover & Panduan Audit Teknis — "Fly High"

## 0. Cara membaca status terbaru

Mulai dari **[AI_CONTEXT.md](./AI_CONTEXT.md)** untuk snapshot aktif 31 Oktober 2026, peta 32 source, batas QA, preferensi pengguna dan temuan terbuka. Desain HUD aktif adalah **Sky Arcade** (`edbd49d`); preview `audit/hud-arcade-phone.jpg`, QA `audit/hud-arcade-results.json`. Bagian arsitektur awal dan laporan bertanggal lebih lama di bawah merupakan riwayat. Prioritaskan snapshot ini untuk status implementasi, dan PRD lengkap untuk aturan produk. Dokumentasi handover tidak mengubah place atau menambahkan pengujian baru.

> **HUD aktif terbaru — Sky Arcade Pro Designer (Pass 3, 31 Oktober 2026):** audit komprehensif dari kacamata UI Designer diterapkan untuk menyelesaikan feedback visual:
> 1. Background hitam/gelap pada seluruh PNG transparan dihapus tuntas (`BackgroundTransparency = 1` dan `BorderSizePixel = 0` pada semua kontainer ilustrasi `HUDArtFrame` dan `HUDEmblem`).
> 2. Bug kelengkungan UICorner diperbaiki dari `UDim.new(scale, 0)` ke `UDim.new(0, offset)`, mengembalikan `ShopModal` menjadi rectangular window modern dengan corner 16px (bukan oval/elips) dan item card menjadi rounded card 12px yang presisi.
> 3. Koreksi `face.BackgroundColor3 = Color3.new(1, 1, 1)` untuk rendering gradasi arcade 3D penuh tanpa reduksi abu-abu default Studio.
> 4. Restrukturisasi hierarki: Altimeter capsule 58px dengan angka 0 KM bold, progress bar track neon, speed chip; Grounded danger ribbon 340px dengan stroke hazard emas; Left dock 50x56 px dengan zona ikon lapang dan pita caption tebal di bawah; Item cards dengan ilustrasi produk transparan, judul emas, deskripsi informatif, dan tombol arcade 3D (`BELI 1 KIT • 29 R$` hijau emerald, `BELI AK-47 • 79 R$` kuning emas); Circular red close button.
> 5. Hasil playtest terekam pada `audit/hud-arcade-pass3-flight.jpg` dan `audit/hud-arcade-pass3-shop.jpg`. Seluruh 32 LuaSourceContainer terkompilasi dan sinkron antara Studio dan mirror.

> **HUD aktif sebelumnya — Sky Arcade, 31 Oktober 2026:** keluhan kualitas visual ditangani dengan komposisi baru, gradasi cerah, outline tegas, navigasi tile, angka ketinggian/amunisi besar dan glyph UI yang tidak memerlukan unduhan gambar. `HUDGlyphs` ditambahkan; `HUDTheme` dan `HUDLayout` diperbarui. Semua 27 sumber/ID unggahan dipertahankan; hanya empat ilustrasi sekunder yang dipakai, sehingga kegagalan gambar tidak mengembalikan kontrol ke kotak prototipe. Target sentuh >=44, role dan input tetap ditangani controller sebelumnya. Dua belas profil kondisi/perangkat direkam, dengan overlap tombol/keluar layar/teks terlihat terpotong = 0. 32 skrip terkompilasi, log bersih, fixture QA sudah dihapus. Preview asli Studio: `audit/hud-arcade-phone.jpg`; batas QA termasuk anomali jump pada fixture setelah pergantian role ada di `audit/hud-arcade-results.json`. Catatan integrasi lama di bawah adalah riwayat.

> **Riwayat prototipe integrasi HUD — sebelum Sky Arcade, 31 Oktober 2026:** `HUDImageAssets` memetakan 27 ID final, `HUDTheme` memasang gambar pada kontrol yang sudah ada, dan `HUDLayout` menjalankan pembaruan presentasi setelah layout. Teks/angka dan handler input tetap milik controller semula. Pemuatan serial memakai ImageLabel, tiga pass dengan jeda, serta fallback native per aset. Playtest satu pemain memeriksa desktop, iPhone 17 Pro, iPad 10 landscape/portrait dan peran gunner/pilot/engineer; log bersih, 31 skrip terkompilasi, fixture QA sudah dihapus. **Baru 7/27 gambar berhasil dimuat; 20 masih Failure, sehingga tampilan seluruh aset belum dapat dinyatakan selesai diverifikasi.** Sumber cocok dengan place yang disimpan. Lihat `audit/hud-images-results.json`. Catatan unggahan di bawah merupakan riwayat sebelum integrasi.

> **Riwayat unggahan aset UI — sebelum integrasi, 31 Oktober 2026:** 27 PNG final pengguna dari `assets/ui/final/compressed_img/` sudah diunggah ke Roblox melalui Studio. ID aktual dan hash sumber ada di `assets/ui/asset-manifest.json`. Pemeriksaan pemuatan: 7 Success, 20 Failure setelah respons awal HTTP 429; pengulangan dengan jeda belum mengubah hasil. Lihat `assets/ui/final/compressed_img/upload-report.json`. Integrasi gambar ke HUD belum dilakukan; tidak ada perubahan DataModel/place untuk unggahan ini.

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

## 13. Gas Otomatis di HUD Utama

Sesuai koreksi pengguna, AutoGasButton dikeluarkan dari daftar AKSI di HUDLayout. Pada mode ringkas tombol 140×48 berada di antara LOMPAT dan AKSI; ketiganya diposisikan ulang agar tidak overlap. Tampilan desktop dan validasi otorisasi server tetap mengikuti aturan pilot/kru sebelumnya. Playtest Galaxy A06: satu klik menyalakan, gas bertahan setelah lepas kemudi, lalu satu klik pada HUD utama mematikan; tombol tidak ada di tray, konsol tanpa error/warning. Viewport dikembalikan default dan driver runtime QA tidak disimpan.

## 14. Perbaikan Gerak dan Alur Tali

- LEPAS KEMUDI keluar dari AKSI dan tersedia langsung di HUD; GAS OTOMATIS tetap langsung tersedia. Panel lompat disembunyikan saat pilot duduk.
- TetherManager memakai Beam untuk visual tali, sehingga avatar tidak lagi menjadi satu mekanisme fisika dengan balon server-owned. Repro dua client membuktikan owner avatar lama menjadi server dan karakter bergeser relatif ke balon; sesudah perbaikan avatar tetap client-owned dan mengikuti gerak balon. Balon tetap server-owned.
- Slot tali persisten per flight: TetherStation.RopeSlots.Rope1/Rope2 (NumberValue), HolderUserId/RepairUserId, AvailableRopes dan RepairableRopes. Pasang ulang tidak memulihkan HP; tali aus dipulihkan dengan hold 4 detik saat dilepas. Server memvalidasi kru, jarak, lokasi gondola, durasi dan reservasi slot.
- Prompt baru DetachTetherPrompt (T/L2) dan RepairRopePrompt (C/R3); aksi remote BeginRopeRepair/FinishRopeRepair/CancelRopeRepair. Turun via Q otomatis membersihkan tali setelah mendarat. Stage Basket/Climbing/Catwalk/Descending mengatur validasi tambal dan visibilitas prompt/HUD.
- Prompt tambal tidak lagi membutuhkan line of sight karena ornamen/kubah menutup ray dari kamera; server tetap memerlukan stage Catwalk dan jarak 10 stud. DescendPrompt menjangkau seluruh ring (28 stud). Enam template mendapat prompt/setting yang sama.
- QA: 36 alur tali native + 50 regresi multiplayer + 51 badai/lompat = 137 lulus. Solo berjalan di ring dan menambal empat lubang tanpa teleport saat flow berlangsung, lalu turun dan otomatis lepas; HP tersisa sekitar 11%. Uji HP mengonfirmasi lepas kemudi satu tap dan hold perbaikan tali selesai/dibatalkan dengan benar.
- Kesalahan cleanup NetworkOwnership saat karakter sudah di luar Workspace diperbaiki. Log CDN 502 pada run antara disimpan; sesi akhir server dan client bersih. Semua 25 skrip terkompilasi. Bukti: audit/rigging-flow-results.json dan rigging-*-results.json. Backup: audit/Fly High.before-rigging-flow.rbxl. Driver hanya di audit, tidak disimpan di place.
- Cloud/pembelian/publikasi tetap ditunda; perangkat fisik dan latency internet belum diuji.

## 15. Audio Peringatan dan Pendaratan Katrol

- Total produksi **26 skrip**. LocalScript baru StarterPlayerScripts.WarningAudioController mendengarkan FlightStateSyncEvent, TetherEvent, HazardAlertEvent dan LargeChallengeEvent; tidak menambahkan remote produksi.
- ReplicatedStorage.FlyHigh.AudioAssets berisi Sound WarningTone (17761221095) dan WarningSiren (129496339606661), keduanya aset gratis Creator Store. Fallback memakai Roblox bundled volume_slider.ogg. Sumber/atribusi: audit/warning-audio-assets.json.
- FlyHighConfig.AUDIO_WARNINGS berisi volume, ambang 30/15%, prioritas dan pola pengulangan. Ini konfigurasi lokal proyek; tidak memakai cloud ConfigService atau mengubah damage/durabilitas.
- Pool audio milik controller (WarningAudioController.FlyHighWarningAudio): tiga Sound dan satu SoundGroup. Maksimal satu suara aktif. Objek ikut hancur bersama controller; HUDLayout membersihkan tombol milik controller yang sudah dihapus dan referensi GUI yang sudah mati.
- WarningAudioToggleButton masuk AKSI. WarningAudioMuted adalah preferensi lokal sepanjang sesi. TetherLabel menampilkan TALI MENIPIS / SEGERA TURUN dan warna amber/merah; tetap berguna saat audio mute.
- Uji berdiri di titian menemukan tabrakan selama perjalanan katrol/handoff. Group sementara FlyHighWinching menonaktifkan tabrakan selama perjalanan; pose pendaratan direplikasi 0,3 detik sebelum unanchor/ownership. Grup semula, AutoRotate dan anchor dipulihkan, termasuk cancel dan cleanup. Tinggi landing menghitung kaki R6; slot kedua naik di sisi berlawanan dan turun di X=+4 (slot pertama X=-4).
- QA final: **49 audio + 40 rigging + 50 multiplayer = 139 lulus**, log server/seluruh client bersih. Pemutaran audio diverifikasi IsLoaded, TimePosition serta PlaybackLoudness >0. Uji HP simulator memastikan mute/unmute berhasil dan kontrol gas/kemudi tetap di HUD utama.
- Semua 26 skrip terkompilasi; lima snapshot source cocok dengan Studio. Driver/remote QA sementara dihapus, viewport default, place disimpan. Backup: audit/Fly High.before-warning-audio.rbxl.
- Bukti: audit/warning-audio-results.json serta warning-audio-native/rigging/multiplayer-results.json. Run1–8 menyimpan diagnostik, termasuk fixture dan CoreGui CreatorType. Human listening review, perangkat fisik, jaringan publik, pembelian serta cloud masih belum diuji/dilanjutkan.

## 16. Tata Letak Interaksi Tali — 29 Oktober 2026

- Empat prompt TetherStation dibagi menjadi dua baris native (UIOffset Y=-48/+48; jarak 96 piksel). Berlaku pada template dasar, lima varian fleet, dan SetupBalloonTethers. Saat terpasang hanya Lepas/Naik; saat dilepas hanya Pasang/Perbaiki bila tersedia.
- BalloonFleetAnimator menyembunyikan prompt yang baru direplikasi sebelum pemeriksaan visibilitas pertama, mencegah semua aksi sempat tampil bersama. Validasi server dan durasi hold tetap berlaku.
- HUDLayout menyusun aksi tali desktop/tablet berdasarkan tombol yang terlihat, sehingga Pasang/Perbaiki serta Tambal/Turun/Lepas memiliki slot terpisah. Mode ringkas tetap memakai daftar AKSI dengan target 44 piksel; gas otomatis dan lepas kemudi tetap langsung di HUD utama.
- Pemeriksaan simulator: iPad Pro M5 (13in), LandscapeSensor, GUI 1373×971; Pasang dan Perbaiki masing-masing 150×44 dengan gap 8 piksel. Galaxy A06 GUI 705×279; Lepas/Naik masing-masing 224×44 pada baris AKSI terpisah. Pemeriksaan visual jendela Studio mengonfirmasi prompt stasiun pada dua baris; capture viewport MCP tidak menyertakan BillboardGui native.
- Regresi native tiga client: **40/40 lulus**, log server dan semua client bersih. Semua **26 skrip produksi** terkompilasi; driver/remote QA dihapus, simulator dihentikan dan Studio kembali Edit/default viewport. Bukti: audit/prompt-layout-results.json. Backup: audit/Fly High.before-prompt-layout.rbxl.

## 17. Kontrol Gas, Kecepatan Vertikal, dan Papan Spawn — 30 Oktober 2026

**Aturan cleanup QA dari pengguna:** setelah tes multiplayer, kembalikan jumlah client Server & Clients ke **1** dan mode toolbar ke **Test** (Play biasa), selain menghentikan tes, membersihkan driver, dan memulihkan viewport. ExecuteMultiplayerTestAsync dapat meninggalkan pilihan tiga client di toolbar; jangan meninggalkan pengaturan ini untuk playtest pengguna. Pengaturan sudah dipulihkan dan tombol Play biasa diverifikasi membuka tepat satu pemain.

- Button factory WeaponClientController memakai UICorner 10 piksel dan BorderSizePixel=0, sehingga PING konsisten dengan SUARA PERINGATAN dan tombol aksi lain.
- Menggantikan izin lama pada bagian 8/13: hanya penghuni HelmSeat yang hidup dan tercatat sebagai pilot boleh menyalakan maupun mematikan gas otomatis. BalloonManager memvalidasi fd.pilot, SeatPart, dan Occupant pada kedua arah toggle. FlightHUDController menyembunyikan tombol saat kemudi dilepas dan memblokir input Z/L1 dari penumpang. Gas yang sudah aktif tetap berjalan ketika kemudi kosong; pengganti pilot dapat mengambil alih. Petunjuk badai disesuaikan agar kru meminta pilot mematikan gas.
- Semua enam template VehicleSeat menonaktifkan HeadsUpDisplay; LaunchBalloon juga menegakkan properti ini. Speedometer kendaraan bawaan diganti VerticalSpeedLabel di samping progress altimeter. FlightStateSyncEvent menyertakan verticalSpeedKmPerSec, disampel dari delta ketinggian aktual per waktu server dan skala STUDS_PER_KM, termasuk PivotTo saat lima lubang. Tampilan NAIK/TURUN/DIAM; EndFlight dan Clutch Save mereset sampel. Tidak ada RemoteEvent produksi tambahan.
- WelcomeSign kini memakai sisi Front dengan normal mengarah tepat ke LobbySpawn. Dua WelcomePost dan dua WelcomeBrassFrame ikut transformasi yang sama. Script build_arrival_garden.luau diperbarui agar rebuild mempertahankan orientasi tersebut.
- Backup: audit/Fly High.before-flight-hud-fixes.rbxl. Driver QA khusus: audit/flight_hud_server_playtest.luau dan flight_hud_client_playtest.luau.
- Verifikasi: **71/71 native tiga client lulus**, log server dan semua client bersih. Mencakup penolakan toggle RemoteEvent dari dua penumpang/mantan pilot, keyboard Z mantan pilot, pilot pengganti, angka +16,8 / -6,7 / 0 / sekitar -666,5 km/detik serta reset saat Game Over. Semua 26 skrip terkompilasi.
- Galaxy A06 (LandscapeSensor, GUI 705×279): satu klik GAS OTOMATIS 140×48 menyalakan; satu klik LEPAS KEMUDI menyembunyikan kedua kontrol, gas tetap ON dan balon tetap naik. Label kecepatan muat di 122×16 piksel. iPad Pro M5: PING dan SUARA PERINGATAN sama-sama 150×44, radius 10. Konsol smoke bersih; simulator dihentikan.
- Bukti: audit/flight-hud-fixes-results.json, flight-hud-speed-phone.jpg dan spawn-sign-facing-player.jpg. Perangkat fisik, cloud, pembelian dan publikasi tetap belum dilanjutkan.

## 18. Boarding dan Akses Kru, Visual, Kamera Senjata

- Dermaga maksimal tiga pemain: anggota yang sudah masuk mempertahankan tempat, pemain berikutnya ditolak dan dipindahkan ke sisi luar pad.
- Boarding menggunakan konfirmasi kesiapan model client dengan token per anggota; karakter ditahan sebelum teleport, kemudian dilepas setelah pose gondola stabil. Model balon Persistent; timeout 20 detik mengakhiri flight dan memulihkan anchor.
- Kru tidak boleh berdiri/menumpang pada gondola maupun kubah balon tim lain. Server memindahkan penyusup ke balon sendiri atau spawn jika belum memiliki flight.
- Kamera otomatis LockFirstPerson saat handgun/AK47 dipakai, kembali ke mode sebelumnya ketika senjata dilepas atau karakter mati. Tembakan tetap dipicu tombol/manual; penargetan memakai auto aim di sekitar pusat kamera pada PC, HP dan gamepad. Tap lokasi dunia tidak menentukan arah peluru. Jika tidak ada target auto aim, tembakan mengikuti pusat kamera, sehingga menembak balon sendiri tetap dimungkinkan.
- Titian servis lebih ringkas: radius 16 stud (sebelumnya 20), lebar 3 stud, lantai 0,55 stud; titik katrol disesuaikan. Lima titik kerusakan mengikuti hasil proyeksi permukaan visual, dengan pusat gelap dan serabut kain yang hanya tampak saat rusak. Ini efek visual sobekan, bukan lubang tembus hasil potong mesh.
- Ayam memakai proporsi dada/leher/kepala terpisah, sayap berlapis, ekor kipas, jengger, pial dan kaki berjari; tetap berjalan/mematuk. Handgun dan AK47 memakai model dekoratif yang lebih rinci (slide/receiver, laras, sight, trigger guard, stock kayu dan magazen melengkung).

Produksi bertambah menjadi 27 skrip; CrewAccessGuard baru memeriksa penyusup tiap 0,1 detik. FlightActionEvent dipakai dua arah untuk PrepareBoarding/BoardReady; validasi token, karakter, anggota dan timeout tetap di server. Backup audit/Fly High.before-crew-and-art-refresh.rbxl. Generator art: audit/refresh_crew_art.luau dan refresh_repair_deck.luau.

QA: 25/25 pemeriksaan empat client native lulus, log server/seluruh client bersih. Termasuk pemain keempat, boarding tiga kru, penolakan token palsu, kru asing dikembalikan ke balonnya, first person handgun/AK47, auto aim desktop (HP obstacle 1000→975), restore kamera, naik/tambal/turun pada radius 16 dan fray visibility. Pemeriksaan geometri 25 titik pada lima varian: jangkauan maksimum 9,20 stud. Run awal mencatat error CoreGui CreatorType; raw laporan disimpan, dua run berikutnya bersih. Driver/remote QA dihapus. Perangkat fisik/latency publik belum diuji.

Studio dikembalikan ke jumlah client 1 dan mode Test/Play biasa setelah QA; tidak ada driver tes atau preview sementara di place produksi.

## 19. Koreksi Role, Equip, dan Visual — 31 Oktober 2026

- Satu pemain hanya boleh memiliki satu role aktif: Pilot, Gunner, atau Engineer. Tali yang terpasang maupun perbaikan tali yang dilepas sama-sama mengambil role Engineer. Lepas role sebelumnya sebelum beralih. ServerUtils.Role membaca state manager server; atribut CrewRole hanya untuk tampilan client.
- Semua pintu masuk kemudi, rak senjata, pasang tali, dan perbaikan tali memeriksa role/boarding. Prompt serta tombol role lain disembunyikan. Input E global tidak lagi mengirim Attach bersamaan dengan prompt native helm/pistol. Kemudi tidak diambil otomatis hanya dengan menyentuh kursinya.
- Equip memakai Humanoid:EquipTool. Unequipped lewat backpack/angka mengembalikan senjata ke rak, menyimpan ammo/reload, membersihkan role dan memulihkan kamera. Drop/death/akhir flight tetap cleanup. Pistol/AK masih first person dan auto aim terpusat.
- Penolakan duduk paksa ditunda 0,1 detik agar joint/state kursi selesai dibentuk; pembongkaran langsung di callback Occupant terbukti meninggalkan SeatPart yang macet dan menghalangi pergantian role. Server tidak memberikan pilot selama penolakan, dan client menerima perintah keluar untuk menyelaraskan state fisika.
- Ayam kini memakai mesh bersegmen (body/head/wings/legs), bukan susunan primitive; enam ayam tetap memakai controller berjalan/mematuk dengan pivot animasi disesuaikan.
- Pistol memakai geometri/tekstur inert dari aset gratis Creator Store 3554395880 oleh enzogobbo. Hanya Body/Mag dan mesh/tekstur yang disalin; seluruh skrip/effect bawaan dibuang. Dua generasi mesh pistol gagal unduh; mesh CAD alternatif ditolak pada review visual. Ayam dibuat dengan generate_mesh, publishedAssetId 137084515560002.
- WeaponRackPresentation (ModuleScript baru) membuat panel kayu, bingkai, dudukan dan tiga amunisi kecil; senjata display hilang ketika diambil dan kembali saat dilepas. Berlaku enam template dan refresh upgrade. Tracer kini jejak pendek 1,8 stud yang bergerak, bukan garis neon sepanjang lintasan.
- QA final **28/28 native satu client lulus**, log server/client bersih. Mencakup equip berulang, RightGrip, kamera, larangan role silang/remote/forced seat, kembali ke kemudi, drop, AK dan kematian. Seluruh **28 skrip produksi** terkompilasi. Pemeriksaan visual rak disimpan di audit/role-rack-preview.jpg; bukti audit/role-hotfix-results.json menyertakan rangkuman diagnostik kegagalan dan hasil lengkap run final.
- Driver/remote/preview sementara dibuang sebelum save. Studio dikembalikan ke satu client dan mode Test. Backup: audit/Fly High.before-role-hotfix.rbxl. Publikasi, pembelian/cloud, perangkat fisik dan jaringan publik tetap belum diuji.

## Penyelamatan Rekan dengan Tali — 31 Oktober 2026

- Rekan satu flight yang hidup, berada di keranjang, tidak memegang Tool dan tidak memiliki role aktif dapat menarik pemakai tali dari titian reparasi atau posisi menggantung ke keranjang. Aksi TARIK REKAN: tombol HUD/AKSI, B, R1, atau prompt stasiun. Server memilih rekan yang memenuhi syarat menurut urutan kru; satu tarikan untuk satu korban.
- Jatuh dari batas keranjang atau titian menghasilkan stage Hanging yang menunggu pertolongan. Tali menahan avatar di bawah balon dan mengikuti geraknya; durabilitas tetap turun 5 HP/detik. Korban tidak dapat memakai Climb/Descend/Patch untuk kembali sendiri. Perjalanan katrol dan loncatan normal di dalam keranjang tidak diklasifikasikan sebagai jatuh. Pemain solo juga memerlukan rekan untuk penyelamatan; tidak ada self-rescue.
- Penyelamat memperoleh role Rescuer selama tarikan (durasi katrol 1,3 + stabilisasi 0,3 detik), menghalangi pengambilan role lain. Korban mendarat di keranjang, fisika/ownership/collision dipulihkan dan tali tetap terpasang. Turun biasa dari titian tetap otomatis melepas tali.
- Penyelamat keluar keranjang/mati/disconnect atau mengambil Tool membuat tarikan dibatalkan; korban kembali menggantung. Detach/kematian korban/akhir flight membersihkan role penyelamat, anchor serta collision. Tali habis tetap membunuh pemakainya. Anggota tim lain, penumpang bersenjata/pilot/engineer, korban sendiri dan remote palsu tidak dapat menarik.
- ServerUtils mengenali role Rescuer. TetherManager menangani Hanging/Rescuing, virtual rope catch, pembatalan dan validasi; tidak ada RemoteEvent produksi baru. PullCrewPrompt tersedia pada enam template; HUDLayout memasukkan PullCrewButton ke layout responsif. Peringatan korban meminta rekan menarik.
- QA native tiga client: **29/29 lulus**, log server dan ketiga client bersih. Mencakup self-return diblokir, akses tim/role, native prompt/remote, rescue pada balon bergerak, cancellation, korban detach, pull dari titian, descent normal, keausan dan kematian. Seluruh 28 skrip produksi terkompilasi. Bukti: audit/rope-rescue-results.json; harness rope_rescue_server_playtest.luau memakai role_hotfix_client_playtest.luau. Run awal gagal pada timing fixture Climb di dalam cooldown remote; fixture diperbaiki.
- Backup: audit/Fly High.before-rope-rescue.rbxl. Driver/remote QA dibuang sebelum save. Studio dipulihkan ke 1 client dan Test. Perangkat fisik, jaringan publik, publikasi dan pembelian/cloud belum diuji.

## Kenyamanan Rescue dan Balancing Awal — 31 Oktober 2026

- PullCrewButton kini langsung di HUD utama pada semua ukuran layar. Mode ringkas memakai ukuran 140×48, posisi di antara LOMPAT dan AKSI; tombol hanya muncul bagi rekan bebas yang bisa menolong. Tombol tidak berada di tray AKSI. Layout desktop tetap menyusun aksi tali tanpa overlap.
- Pacing rintangan reguler memakai OBSTACLE_PACING per band. Band 1–2: 50 HP (2 tembakan pistol), band 3–5: 70 HP (3), band 6–7: 85 HP (4), band 8–9: 100 HP (4). Speed 22/24/26/28/29/30/32/34/36 stud/detik. Minimum jeda enemy 8/7,5/7/6,5/6/5,5/5/4,5/4 detik; hazard 26/25/24/23/22/21/20/19/18 detik. Scheduler memeriksa setiap 2,5 detik, sehingga jeda aktual dibulatkan ke tick berikutnya.
- Hazard pertama pada band yang baru aktif di server dijadwalkan setelah satu interval, sehingga tidak bersamaan dengan enemy pertama. Penjadwalan tetap global per band, bukan per tim. Zona aman 0–1.200 km, batas 10.000 km, peringatan hazard 3 detik dan pacing dinding badai tetap berlaku.
- Native dua client: **29/29 lulus**, log server/kedua client bersih. Klik mouse melalui VirtualInput pada tombol nyata (dengan koreksi GuiInset), B keyboard, fall dari keranjang/titian pada 2.000 km, rescue saat naik, stabilitas satu detik sesudah handoff, visibilitas/ukuran/layout HUD, sembilan profil actual spawn, zona aman, warning 3 detik, dan stagger scheduler diuji.
- Viewport native 1094,4×558,4 memakai mode ringkas: tombol 140×48, parent FlyHighHUD, di dalam layar dan tidak overlap. Avatar turun dari posisi landing lokal (-4,3,43,8) ke posisi berdiri sekitar (-3,98,2,57,8,01), tetap di gondola. Ini pengujian otomatis/input simulasi, bukan penilaian rasa kontrol oleh dua manusia atau HP/controller fisik.
- Seluruh 28 skrip produksi terkompilasi. Bukti audit/rescue-comfort-results.json; harness rescue_comfort_server/client_playtest.luau. Backup audit/Fly High.before-rescue-comfort.rbxl. Driver/remote QA dihapus, Studio dikembalikan 1 client/Test. Publikasi dan pembelian/cloud tetap ditunda.

## Kamera Senjata, Efek Tembakan, dan Titian Bambu — 31 Oktober 2026

- Lepas/drop/backpack unequip senjata memaksa Classic dan mendorong zoom minimum sementara ke 10 stud, lalu mengembalikan batas zoom semula setelah 0,25 detik. Classic saja sebelumnya meninggalkan kamera pada jarak first person. Token pergantian senjata membatalkan restore lama; zoom asli dipertahankan saat swap cepat. Mati tetap melepaskan first person; spectator mengikuti alur yang sudah ada.
- ModuleScript WeaponPresentation baru menampilkan jejak peluru neon 0,09 stud × panjang maksimal 6 stud (durasi 0,09–0,35 detik), muzzle flash dan point light singkat setelah tembakan diterima server. Penembak first person mendapat origin visual di bawah bidikan agar tidak tertutup avatar; ray damage tetap dari muzzle server. Pool delapan emitter/suara per client, batas 32 tracer aktif dan cleanup saat controller dihancurkan. Pistol dan AK memakai efek yang sama dengan pitch berbeda.
- Audio gratis Creator Store Pistol Shot oleh MrAudio6, ID 132539859090895, tersimpan sebagai AudioAssets.PistolShot. Audio di-preload, diputar spasial dalam radius 140 stud; tidak mengikuti tombol mute audio peringatan.
- Enam template mendapat BambooRigging: dua bilah bambu per segmen ring (32 batang), ruas bambu, tali pegangan dan delapan tali penyangga berujung pada raycast permukaan visual envelope. Empat tali suspensi gondola juga menempel pada skin aktual, bukan titik akhir yang sama pada semua bentuk balon.
- Papan lama menjadi collider transparan lebar 3 stud dengan top Y=18,6 yang dipertahankan; bambu dekoratif tidak menambah tabrakan. Guard transparan di sisi luar dan handrope tipis menjaga ruang pijakan. Tidak mengubah posisi katrol maupun lima lubang. Builder: audit/build_bamboo_repair_walkway.luau.
- QA final native dua client **22/22 lulus**, log server/kedua client bersih; **29 skrip produksi terkompilasi**. Jarak kamera sesudah Drop/backpack/swap cepat sekitar 10 stud, zoom minimum kembali 0,5. Sound IsLoaded/IsPlaying serta PlaybackLoudness >0 terukur pada penembak/rekan. Tracer terproyeksi ke layar penembak, muzzle flash, damage dan cleanup diuji. Berjalan satu lingkaran penuh di ring radius 16 memakai Humanoid.Move normal, menambal lalu turun otomatis lepas tali lulus. Ini pengujian otomatis, belum penilaian manusia/perangkat fisik.
- Bukti audit/weapon-bamboo-results.json dan bamboo-walkway-preview.jpg. Backup audit/Fly High.before-weapon-fx-bamboo.rbxl. Driver/remote/preview QA dihapus; Studio dikembalikan 1 client/Test sebelum save. Publikasi serta pembelian/cloud tetap ditunda.

## Keranjang SkyKoi dan Tali Putus — 31 Oktober 2026

- Empat CornerWedgePart BoatProw (13×3,2×6,5) adalah sumber kayu besar menonjol di bawah keranjang SkyKoi. Delapan instance pada template dan preview Dermaga C dihapus, dan generator build_balloon_fleets.luau tidak lagi membuatnya. Lantai, batas keranjang, wave trim dan tema balon tetap ada.
- Durabilitas tali 0 sekarang memanggil TetherManager.BreakRope. Server menandai FatalRopeFall pada karakter, melepas tali/anchor/rescue, mempertahankan pose saat ini (tidak rewind katrol), lalu memberikan kecepatan menjauh 42 stud/detik ditambah kecepatan balon dan impuls vertikal awal 8 stud/detik. Avatar masuk Physics/PlatformStand, server-owned, dengan tumbukan sementara nonaktif agar tidak tersangkut kembali pada keranjang; grup tumbukan semula dipulihkan setelah 0,3 detik.
- Karakter tetap hidup selama efek jatuh, lalu Health=0 setelah 1,25 detik. Void atau kematian lain dapat mengakhiri lebih cepat. Timer memeriksa identitas karakter dan keanggotaan Player sehingga tidak membunuh respawn baru.
- U.Alive menganggap fatal fall tidak lagi eligible untuk gameplay: role, rescue, jump, emergency kit dan crew access guard tidak dapat mengembalikan/teleport pemain tersebut. Pemain lain tetap bisa menerbangkan balon. Role penyelamat dibersihkan jika tali korban putus saat ditarik. Tali yang putus menyimpan 0 HP dan dapat diperbaiki oleh kru lain.
- Konfigurasi baru ROPE_BREAK_DEATH_DELAY_SEC=1,25 dan ROPE_BREAK_OUTWARD_SPEED=42. Aturan ini menggantikan kematian seketika saat tali habis dalam dokumentasi sebelumnya.
- QA native tiga client: **24/24 lulus**, log server/ketiga client bersih. Memeriksa SkyKoi tanpa papan, pelepasan anchor/rope, kecepatan radial ~42 stud/detik, gerak/jatuh sebelum mati, larangan role/self rescue, delay kematian, kru lain tetap aktif, snap saat rescue tanpa rewind, snap di titian serta timer tidak mengenai respawn. Seluruh **29 skrip produksi terkompilasi**. Ini pengujian otomatis, belum perangkat fisik/human playtest.
- Bukti audit/rope-break-results.json dan sky-koi-clean-basket.jpg. Backup audit/Fly High.before-rope-break-ejection.rbxl. Driver/remote/preview QA dibuang, Studio kembali 1 client/Test sebelum save. Publikasi, pembelian dan cloud tetap ditunda.

## Peluru Melayang yang Lebih Terbaca — 31 Oktober 2026

- WeaponPresentation kini membuat FlyingBullet berbentuk kapsul/ellipsoid neon 0,24×0,24×0,85 stud, diinisialisasi tepat pada origin visual sebelum dimasukkan ke Workspace. Peluru memiliki Trail sepanjang waktu 0,12 detik dan inti BillboardGui 6×6 piksel dengan world occlusion agar tetap terbaca ketika model 3D menjadi sangat kecil pada jarak jauh.
- Animasi kosmetik bergerak 160 stud/detik, durasi minimum 0,25 dan maksimum 1,8 detik. Peluru tetap terang selama perjalanan, berhenti pada titik benturan server, lalu inti disembunyikan dan trail dibiarkan habis 0,13 detik. Batas 32 peluru aktif serta cleanup controller tetap berlaku. Damage masih memakai raycast server yang sudah ada; objek visual tidak memiliki collision/touch/query.
- QA native dua client **15/15 lulus**, log server/kedua client bersih; 29 skrip produksi terkompilasi. Peluru pistol diamati 8 frame/sekitar 0,46 detik dan berpindah >74 stud; peluru jauh diamati 17 frame/sekitar 1,07 detik dan berpindah >170 stud. Rentetan AK menghasilkan tiga peluru terpisah. Peer melihat gerak, server damage bekerja dan semua objek/tail dibersihkan.
- Run diagnostik menunjukkan desain pertama masih terlalu singkat pada frame rate native rendah. Fixture jarak jauh sebelumnya mengarah ke dinding koridor Z=-148 (hit nyata sekitar 109 stud), lalu diperbaiki menghadap rentang koridor lebih panjang; tidak ada perubahan hitbox/raycast untuk menembus dinding.
- Bukti audit/flying-bullet-results.json dan harness flying_bullet_server/client_playtest.luau. Backup audit/Fly High.before-flying-bullets.rbxl. Driver/remote QA dihapus, Studio dipulihkan 1 client/Test sebelum save. Pengujian ini otomatis; kenyamanan visual oleh pemain/perangkat fisik belum dinilai.

## Audit Perjalanan Penuh dan Lifecycle Bioma — 31 Oktober 2026

- Solo mencapai Victory 10.000 km melalui penerbangan normal dalam 708,45 detik, dengan 34 tambalan. Lima bioma, lima milestone badai, kredit summit dan pendaratan hidup terverifikasi dalam audit/full-journey-partial-results.json. Putaran itu memiliki kegagalan duo/trio dan satu warning dari aksi kamera MCP; jangan menyebut keseluruhan laporan lulus.
- audit/full-journey-duo-trio-diagnostic.json mencatat 41/44 pemeriksaan lulus: empat persiapan dan seluruh 37 pemeriksaan skenario akhir/cleanup lulus; tiga kegagalan terkait perjalanan duo/trio. Clutch Save, penolakan kit berulang, jatuh 2.000 km sekitar tiga detik, Game Over, rescue, snap tali dengan efek jatuh sebelum mati, respawn, AFK 60 detik, disconnect native, serta kosongnya reservasi tali/senjata terverifikasi.
- **Temuan terbuka:** saat pilot bermanuver horizontal cepat, posisi repairer yang dilihat client dapat berbeda dari pembacaan server. Uji terfokus mencatat posisi client dekat titik reparasi, tetapi server membaca jarak lubang 11,07 stud dan kemudian stage Hanging. Penyebab pasti fisika/replikasi belum dipastikan. Batas jangkauan, validasi role dan deteksi jatuh produksi tidak dilonggarkan. Prioritaskan investigasi ini sebelum menyatakan co-op bebas masalah.
- Pilot yang menahan gerak horizontal selama reparasi, dengan gas otomatis tetap menyala, lulus delapan siklus reparasi trio dan tiga log client (11/11). Itu fixture terkontrol dengan altitude 2.500 km dan hazards dijeda; bukan bukti perjalanan penuh. Bukti audit/moving-trio-repair-coordinated-results.json; source moving_trio_repair_probe.luau. Label fixture generik pada raw hasil probe diperjelas dalam audit/FULL_JOURNEY_QA.md.
- Bug pencahayaan nyata direproduksi: Game Over pada 2.500 km meninggalkan Lighting di Indigo (ClockTime 0,5/FogEnd 800). BiomeLightingController kini memulihkan Dawn saat Game Over/respawn lobby, menginvalidasi timer kabut lama, mempertahankan bioma tim untuk Ghost Spotter aktif, dan mempertahankan Celestial saat Victory. Regresi Play satu pemain **12/12 lulus**, log server/client bersih. Bukti audit/biome-lifecycle-results.json dan reproduksi original terpisah.
- Hanya BiomeLightingController berubah pada kode produksi; tidak ada perubahan remote, ekonomi atau fisika untuk membuat penguji lulus. Harness memakai penempatan berkoordinat lokal balon dengan konfirmasi client, gerak Humanoid normal dan role/repair manager produksi. Rincian seluruh fixture, kegagalan dan batas pengujian berada di audit/FULL_JOURNEY_QA.md. Backup: audit/Fly High.before-full-journey-qa.rbxl.
- Duo dan trio akhirnya sama-sama tercatat mencapai **10.000 km pada kecepatan normal**, dengan 26/13 tambalan dan hazards aktif. Raw audit/full-journey-coordinated-results.json tetap gagal karena penguji mencoba berinteraksi setelah Victory menghapus state tali; jangan mengubahnya menjadi laporan all-pass. Harness diperbaiki untuk mengakhiri reparasi yang dibatalkan oleh Victory dan tetap menjalankan assertion summit/docking. Pendaratan co-op kemudian diverifikasi terpisah: **28/28 lulus**, kelima kru menerima summit, hidup di palace, role/tool/anchor dilepas, reservasi kosong dan model bersih alami. Fixture terminal memakai altitude 9.995 km lalu naik normal; bukan pengulangan rute penuh. Bukti audit/victory-handoff-results.json; error startup CoreGui pada percobaan sebelumnya disimpan terpisah. Temuan manuver cepat tetap terbuka.
- Cleanup final: tidak ada instance QA/probe tersisa, **29 skrip produksi terkompilasi**, place disimpan, toolbar **Test** dan jumlah client **1** diverifikasi melalui UI. Ringkasan mesin beserta SHA256 place: audit/full-journey-summary.json. Ini audit dengan temuan co-op terbuka, bukan persetujuan rilis.

## Perapian HUD iPad dan Tombol Lompat — 31 Oktober 2026

- HUDLayout membedakan tablet sentuh dari desktop: informasi/kit/utilitas di kiri, altimeter dibatasi lebarnya, kontrol senjata di kanan, dan area sentuh terpisah. Teks kit dibungkus, angka kecepatan dibatasi dalam labelnya, indikator lubang menyesuaikan lebar. Pada HP, kartu ammo diringkas dan tombol tembak digeser ke kiri atas tombol lompat agar tidak masuk area capture native.
- JumpPanel sekarang transparan dengan tombol lingkaran di kanan bawah: 96×96 tablet, 72×72 layout ringkas, 80×80 desktop lebar. Panah dan caption menunjukkan LOMPAT / TERKUNCI atau SPACE/A. Pilot menyembunyikan tombol; engineer di titian/katrol tetap dibatasi oleh izin jump server. Gas otomatis dan lepas kemudi tetap langsung di HUD.
- FlightJumpController hanya menyembunyikan JumpButton di TouchGui, memantau perubahan Visible dan pembuatan ulang GUI. Joystick tidak dinonaktifkan. Tombol custom tersedia di lobby dan sesudah respawn; lompat lobby tidak meminta efek turun balon ke server. Binding keyboard/gamepad tetap tersedia.
- WeaponClientController menghilangkan petunjuk keyboard pada tombol sentuh; FlightHUDController menyediakan caption kit/kemudi/gas yang sesuai perangkat. Tidak ada perubahan pada damage, validasi role, fisika, atau mekanik tali. Temuan co-op pada manuver cepat dari audit sebelumnya tetap terbuka.
- QA: 11 profil layout/peran pada iPad 10th Generation (landscape/portrait), iPad Pro M5 13 inci (landscape/portrait), iPhone 17 Pro, dan desktop normal/1280×720. Tidak ada overlap tombol proyek, keluar layar atau text overflow; target sentuh minimal 44×44. Target mouse desktop dapat lebih kecil. Tap simulator HP diterima server saat memegang pistol; tombol juga bekerja di lobby. Gas otomatis/lepas kemudi dan kit menerima input UI. Respawn dan percobaan menampilkan ulang native JumpButton tetap menghasilkan custom jump + joystick tanpa tombol jump native.
- Fixture UI memakai satu pemain, balon diam pada 253 km, hazards dijeda dan HP tali dijaga agar review visual tidak membunuh repairer. Ini bukan uji fisika penerbangan, perangkat fisik, atau jaringan publik. Mouse virtual dalam LockCenter tidak menekan tombol phone; tap langsung pada simulator digunakan untuk verifikasi. Sesi final bersih dari error/warning. **29 skrip produksi terkompilasi**, driver QA dibuang, viewport Current device/desktop dan **1 client / Test** dipulihkan sebelum save.
- Bukti: audit/ipad-ui-results.json, audit/ipad-ui-pro-gunner.jpg; driver audit/tablet_ui_review_server.luau dan probe tablet_ui_probe.luau. Backup place dan empat source aktif disimpan di audit/Fly High.before-ipad-ui.rbxl serta audit/ipad-ui-before/.
- Kandidat aset gambar, ukuran sumber/tampil dan deskripsi berada di UI_IMAGE_ASSET_PLAN.md. Gambar belum dibuat/diunggah; angka, harga, ammo, cooldown dan progress tetap UI dinamis.

## Redesign HUD Sky Arcade Pro Max & Perbaikan Bug Warning — 31 Oktober 2026

- **Perbaikan Bug GroundedCountdown**: Teks `LEPAS LANDAS! Balon hancur dalam %d detik` sebelumnya tertutup surface dekoratif dan menampilkan bar kosong oranye. Diperbaiki dengan handler khusus `kind == "countdown"` pada `HUDTheme.luau` yang memproyeksikan teks langsung ke label `HUDCountdownNotice` (`ZIndex = z + 4`, `Font = FredokaOne`, outline hitam pekat, aksen hazard emas, dan tanpa duplikasi emoji).
- **Integrasi Vektor Ikon Lucide (MIT License)**: Melalui `HUDGlyphs.luau`, memanfaatkan spritesheet resolusi tinggi resmi untuk merender ikon tajam (`store`, `kit`, `ping`, `sound`, `flame`, `jump`, `aim`, `repair`, `rope`, `weapon`, `exit`, dll.) tanpa dependensi aset privat.
- **Tombol Taktil 3D Bevel & Detached Caption Pills**: Seluruh tombol utama mengusung konstruksi 3 stops visual (Ground Drop Shadow, 3D Bottom Bevel Lip, Top Interactive Face dengan Specular Gloss Sheen) yang memiliki efek fisik turun 4px saat ditekan. Label teks dipisahkan ke dalam pill badge bawah ber-stroke aksen tematik (`TOKO` emas, `KIT` hijau, `PING` biru, `SUARA` ungu).
- **Perbaikan Kanvas ShopModal**: Memperbaiki bug occlusion di mana skin panel menutupi isi kanvas ScrollingFrame. Kini `ShopModal` dirender dengan styling dialog arcade obsidian, `CloseButton` sirkular merah di pojok kanan atas, serta kartu item `Card1` (Emergency Repair & Shield) dan `Card2` (AK-47 Tactical Upgrade) yang menampilkan ikon produk, judul emas, deskripsi lengkap, dan tombol beli 3D (`BELI 1 KIT • 29 R$` dan `BELI AK-47 • 79 R$`).
- **TacticalPingWheel Interaktif**: 5 aksi ping kini memiliki diferensiasi warna & ikon unik: `Ping1` (Gas Api - oranye/flame), `Ping2` (Awas Tornado - ungu/warning), `Ping3` (Tali Habis - emas/rope), `Ping4` (Perbaiki - hijau/repair), `Ping5` (Tembak Rintangan - merah/aim).
- **Altimeter Medali Juara**: Altimeter dilengkapi emblem lingkaran bertumpuk di tepi kiri dengan border cincin emas 3D, neon cyan progress track, dan speed chip avionik.
- **Smart Notification Badge**: Badge kit pada tombol dock hanya muncul jika stok kit > 0 (warna hijau) atau saat balon dalam kondisi kritis (peringatan merah), menjaga UI tetap bersih tanpa angka "0" merah yang mengganggu.
- **Verifikasi & Preview**: Diuji langsung dalam playtest Client & Server Studio pada mode penerbangan sesungguhnya dan terdokumentasi dalam tangkapan layar `audit/hud-arcade-pass2-flight.jpg`, `audit/hud-arcade-pass2-shop.jpg`, dan `audit/hud-arcade-pass2-ping.jpg`. Seluruh **32 source container** terkompilasi bersih tanpa error/warning.

