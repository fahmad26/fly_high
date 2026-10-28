# 📋 Dokumen Handover & Panduan Audit Teknis — "Fly High"

Dokumen ini disiapkan sebagai panduan komprehensif bagi AI Reviewer / Developer selanjutnya untuk memeriksa, mengaudit, dan melanjutkan pengembangan game Roblox **Fly High**.

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
