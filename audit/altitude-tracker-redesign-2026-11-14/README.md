# Audit Implementasi & QA: Tracker Ketinggian Vertikal Kanan, Top HUD Option B, & Multi-Device Layout (`UI-01`)

## Identitas

- **Fitur / Task:** Pemindahan tracker ketinggian ke sisi kanan vertikal (`ServerAltitudeTracker`), sinkronisasi seluruh kru di server (`ServerFlightsSyncEvent`), dukungan Solo & Party `2–3` pemain tanpa latar kapsul di belakang foto profil maupun pil teks di kiri avatar (sesuai revisi Figma V2), mahkota Party Master & avatar abu-abu untuk pemain mati, redesain Top HUD Option B, serta penyesuaian layout multi-device (`HUDLayout`).
- **Tanggal QA:** 14 November 2026 (`Asia/Jakarta`, sesi pasca-edit final s.d. `21:40:20 +07:00`)
- **Kode / Target:**
  - `ReplicatedStorage/FlyHigh/Remotes/ServerFlightsSyncEvent` (`RemoteEvent`, `remoteExists = true`)
  - [`HUDAltitudeTracker.luau`](../../sources/ReplicatedStorage/FlyHigh/Modules/HUDAltitudeTracker.luau) (`30,054` B stripped LF, Adler-32 `2377015608`, `MATCH=True strip`)
  - [`FlightHUDController.luau`](../../sources/StarterPlayer/StarterPlayerScripts/FlightHUDController.luau) (`26,543` B LF, Adler-32 `2856922865`, `MATCH=True nl`)
  - [`HUDLayout.luau`](../../sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau) (`28,901` B LF, Adler-32 `768019915`, `MATCH=True nl`)
  - [`HUDTheme.luau`](../../sources/ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau) (`78,084` B LF, Adler-32 `2799358645`, `MATCH=True nl`)
  - [`HUDMotion.luau`](../../sources/ReplicatedStorage/FlyHigh/Modules/HUDMotion.luau) (`53,769` B LF, Adler-32 `2437916041`, `MATCH=True nl`)
  - [`BalloonManager.luau`](../../sources/ServerScriptService/FlyHighServer/BalloonManager.luau) (`24,015` B LF, Adler-32 `3818491015`, `MATCH=True nl`)
  - [`WeaponClientController.luau`](../../sources/StarterPlayer/StarterPlayerScripts/WeaponClientController.luau) (`43,738` B LF, Adler-32 `2726659153`, `MATCH=True nl`)
- **Commit Git dasar saat inspeksi:** Branch `main`, `HEAD f5aa15d` (belum `git commit` / belum `git push`).

## Build & Sinkronisasi

- **Sinkronisasi Studio ↔ Mirror (`audit/sources/`):** `46/46` script di inventaris Studio sama persis dengan mirror (`edSameCount = 46`) dan kompilasi Luau bersih (`compileOkCount = 46`, `compileErrors = []`).
- **Penyimpanan Place Lokal (`Fly High.rbxl`):** Disimpan via `save_place` pasca-edit final (`status = "Saved"`, `filePath = "E:/Antigravity/Fly High/Fly High.rbxl"`), ukuran `1,873,905` B, `LastWrite = 2026-11-14 21:40:20 +07:00`, `SHA256 = F8381D2BCFB12EAF71549ED98ACBC6C3531813EB52B1B6F1F518DFA18DD514D3`.
- **Status Round-Trip Binary:** Belum dibuka ulang di sesi Roblox Studio baru setelah penyimpanan final.

## Lingkungan

- **Live Playtest:** Windows Roblox Studio (`2aa6cbef-a4c5-43f8-a312-6b3f42eedd2d`), mode **Play Solo** (1 klien lokal `Fikki2621`, `AutoGas` dikontrol saat pengujian turun).
- **Simulasi Geometri Multi-Device:** Skrip Python yang mengevaluasi formula [`HUDLayout.luau`](../../sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau) pasca-edit final di `8` ukuran viewport (`Desktop 1920x1080`, `Studio 2090x694`, `Laptop 1280x720`, `Tablet 1024x768`, `PhoneLand 844x390`, `PhoneSmLand 667x375`, `PhonePort 390x844`, `PhoneSmPort 360x640`) × peran (`Pilot`, `Gunner`, `Passenger`) × `textBoost` (`0` serta maksimum `3`/`6`) + `AlertBanner` (+ `CrewPingBanner` di `PhonePort 390x844`).

## Skenario

1. **Lobby `Pod_A` (Top HUD Option B & visibilitas tracker):** Memverifikasi judul `DERMAGA A` / `1/3 kru · Mulai penerbangan`, hilangnya altimeter lama di bar atas (`HUDGoalMarkerSlot.Visible = false`), serta `ServerAltitudeTracker` tersembunyi saat belum terbang (`InFlight == false`).
2. **Solo Flight Climb (`LANGIT CERAH`):** Naik di balon solo dan memeriksa munculnya `ServerAltitudeTracker` di sisi kanan, foto profil headshot solo + `MasterCrown` emas di atasnya, pil kecepatan hijau (`▲ +km/s`), serta pengukur `trackerPos` / `trackerSize` pada `385 km` & `413 km`.
3. **Multi-Team, Party 3 Pemain, Stagger Overlap, & Status Mati:** Injeksi payload `ServerFlightsSyncEvent` 4 kru saat terbang live (`FlightRow_10` kru lokal 3 anggota `236..263 km` termasuk 1 mati; `FlightRow_20` dekat puncak `9750 km` memeriksa clearance `PalaceCrest`; `FlightRow_30` `5620 km` vs `FlightRow_40` `5500 km` untuk stagger vertikal & Party Master mati).
4. **Live Descent & Alert Top HUD:** Mematikan `AutoGas` saat terbang live (`137 km`) untuk memeriksa perubahan warna `HUDSpeedPill` ke merah crimson (`▼ -km/s`) dan subjudul peringatan `Zona 1 · Balon Menurun!`.
5. **Validasi Geometri Multi-Device (`HUDLayout`):** Memastikan tidak ada overlap (`hits=[]`) antara `AltimeterFrame`, `ServerAltitudeTracker`, HUD senjata/pilot/penumpang, `AlertBanner`, dan `CrewPingBanner` di `32` konfigurasi viewport/peran setelah perbaikan `pillHalfW`, guard `botBlockers`, `minTrackerH = 72`, dan compact scaling `h = 60..140`.

## Fixture

- **Skenario 3 (Play Solo 1 klien):** Payload injeksi `ServerFlightsSyncEvent` 4 kru (`FlightRow_10`–`FlightRow_40`) dijalankan langsung pada sesi Play Solo untuk mensimulasikan beberapa tim, party `2–3` anggota, dan pemain/Party Master berstatus mati.
- **Skenario 5:** Simulasi matematis Python di luar engine render Roblox atas formula [`HUDLayout.luau`](../../sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau) pasca-edit final.

## Bukti

- [`screenshots/01_lobby_podA_optionB.jpg`](screenshots/01_lobby_podA_optionB.jpg) (`353,383` B) — Lobby `Pod_A` (`DERMAGA A` / `1/3 kru · Mulai penerbangan`), Top HUD Option B, `ServerAltitudeTracker` tersembunyi.
- [`screenshots/02_solo_flight_413km.jpg`](screenshots/02_solo_flight_413km.jpg) (`231,995` B) — Penerbangan Solo live (`413 km`, `LANGIT CERAH`, `KONDISI LAMBUNG 2/5`), headshot solo + `MasterCrown` emas di rail kanan.
- [`screenshots/03_multiteam_party3_dead_stagger_climb.jpg`](screenshots/03_multiteam_party3_dead_stagger_climb.jpg) (`259,299` B) — Pendakian live emerald (`▲ +16.5 km/s`, `Zona 1 · Target Istana Awan`) + fixture `ServerFlightsSyncEvent` 4 kru, tanpa latar kapsul di belakang avatar, avatar mati abu-abu + `"X"`, stagger elbow bersih (`overlaps=[]`).
- [`screenshots/04_live_descent_crimson_alert.jpg`](screenshots/04_live_descent_crimson_alert.jpg) (`278,019` B) — Penurunan live (`AutoGas OFF`, `137 km`), pil merah crimson `▼ -9.9 km/s` (`-10.0 km/s` telemetri) dan subjudul merah `Zona 1 · Balon Menurun!`.
- **Console Studio (Play Solo pasca-edit final):** Bersih dari error/warning gameplay; hanya log standar `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.`.

## Hasil

- **Kompilasi & Parity:** `46/46` script Studio tersinkron dengan mirror (`edSameCount = 46`) dan lolos kompilasi (`compileErrors = []`); `ServerFlightsSyncEvent` ada (`remoteExists = true`). Bug sesi uji awal (`(row :: any)._handles` diganti weak table `rowHandles`, serta `altimeterFrame` -> `altFrame` di [`FlightHUDController.luau`](../../sources/StarterPlayer/StarterPlayerScripts/FlightHUDController.luau)) teratasi penuh pada build final.
- **Play Solo Live (Pasca-Edit Final):**
  - Lobby & Solo Climb terkonfirmasi: pada sampel `385 km`, `trackerPos=[1893,14]`, `trackerSize=[179,430]`, `speedText="▲ +7.4 km/s"`; tangkapan layar `413 km` menampilkan rail kanan & Top HUD Option B utuh.
  - Fixture 4-kru pada pendakian live terkonfirmasi: `FlightRow_10` (`236..263 km`, 3 anggota, latar transparan, 1 mati greyscale + `X`), `FlightRow_20` (`9750 km`, bebas tabrakan dengan `PalaceCrest`), stagger `FlightRow_30` (`5620 km`, `dotY=228, pY=228`) vs `FlightRow_40` (`5500 km`, `dotY=232, pY=276, elbowVis=true`) dengan Party Master mati (`DeadVeil=true, DeadBadge=true, MasterCrown.Visible=true, crownClr=[170,180,195]`), dan `overlaps=[]`.
  - Penurunan live (`137 km`) menampilkan pil crimson `▼ -9.9 km/s` + subjudul `Zona 1 · Balon Menurun!`.
- **Simulasi Geometri Multi-Device (Pasca-Edit Final):** **`32/32 PASS` (`hits=[]`)**, termasuk skenario sempit yang sebelumnya bermasalah pada `PhoneSmLand 667x375` (`bandLeft = 520` bersih dari `AltimeterFrame`/`AlertBanner`) dan peran `Gunner` pada `PhoneSmPort 360x640`.

## Batas

1. Status multi-kru (`4` tim), party `2–3` pemain, dan avatar/Party Master mati baru diuji lewat injeksi fixture `ServerFlightsSyncEvent` pada Play Solo 1 klien (`Fikki2621`), belum lewat sesi Server + 3 klien Studio/publik nyata.
2. Evaluasi `8` viewport (`32` konfigurasi) multi-device masih berbasis perhitungan geometri Python atas [`HUDLayout.luau`](../../sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau), belum tangkapan render di Device Emulator Studio maupun tablet/HP fisik.
3. Live Playtest pasca-edit final baru mencakup Lobby `Pod_A` dan Zona 1 (`LANGIT CERAH` naik/turun); Zona 2 (`AWAN MENDUNG`) sempat diamati sebelum polish final `HUDLayout`/`HUDAltitudeTracker`, sedangkan Zona 3–5 & ketibaan `10.000 km` Istana Awan pada [`HUDTheme.luau`](../../sources/ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau) baru diverifikasi via inspeksi kode + kompilasi.
4. `Fly High.rbxl` tersimpan (`1,873,905` B, `SHA256=F8381D2BCFB12EAF71549ED98ACBC6C3531813EB52B1B6F1F518DFA18DD514D3`), tetapi belum dibuka ulang di sesi Studio baru dan belum di-commit/push ke Git.

## Cleanup

- Hook injeksi server QA telah dibersihkan dan sesi Play Solo dihentikan (`get_studio_state` = `Edit`).
- Pemeriksaan pasca-playtest di mode `Edit`: `playersCount=0`, `balloonsInWs=[]`, `playerGuiChildren=0`, `cameraType="Enum.CameraType.Fixed"`.
