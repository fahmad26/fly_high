# Laporan QA: Poles Spawn & Skala Visual Rintangan + SFX Lubang Balon (Opsi A)

Tanggal: 15 November 2026 (Asia/Jakarta)  
Build / Tempat: Lokal Roblox Studio `Edit`/`Play Solo` (`E:/Antigravity/Fly High/Fly High.rbxl`, `1.916.916` B, `2026-11-15T11:47:49+07:00`, SHA-256 `4C8CE3A5BFD3F9F1E549FF845DBF36038C862A9976A489812DEE235C848194D3`, belum dibuka ulang pasca-save).  
Lingkungan uji: Windows `Play Solo` `1` klien (`Fikki2621`, `GameId == 0`), ditambah harness transient `ServerScriptService._PlaytestBridgeRunner` + `ServerStorage._PlaytestBridge` & spy event `Sound.Played` klien selama Playtest saja (hilang bersih saat kembali ke `Edit`).

## Parity & Kompilasi (`52/52`)

- **Studio ↔ Mirror `audit/sources/`**: `52/52` skrip ada (`DISK_COUNT=52`), `4` skrip yang disentuh pada rangkaian ini terverifikasi identik terhadap normalisasi LF / TrimEnd FNV-1a exact (`32-bit`):
  - [`ObstacleArt.luau`](../sources/ServerScriptService/FlyHighServer/ObstacleArt.luau): `27.155` B disk (`27.154` norm Studio/disk, FNV-1a `0cc86612`, SHA-256 `DCB80BB03DC264EFB074BFED60EB185AF48C2212F37B65611C3D417FEF019F00`)
  - [`ObstacleManager.luau`](../sources/ServerScriptService/FlyHighServer/ObstacleManager.luau): `23.499` B disk (`23.498` norm Studio/disk, FNV-1a `66c7ef2c`, SHA-256 `3E14256E9352CF7A33B439703A036E31D65B00D80097E3EDF19F6F6298C8F8CE`)
  - [`BalloonManager.luau`](../sources/ServerScriptService/FlyHighServer/BalloonManager.luau): `31.764` B disk (`31.763` norm Studio/disk, FNV-1a `fc0facaa`, SHA-256 `CFABA5AEBD2579BE07724FE9AE5E62C591E74D77462577E3DBA2848232E6A1EB`)
  - [`BalloonVFX.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/BalloonVFX.luau): `40.969` B disk (`40.968` norm Studio/disk, FNV-1a `d95aa1bc`, SHA-256 `AA86F6C4759CBE4AC505D3146F3ABFB9A6C13E57CE7BC84BD469B9AEF71084B8`; `WeaponReload` dihapus total)
- **Kompilasi Studio (`loadstring`)**: `COMPILE_TOTAL=52`, `FAIL=0`.

## Hasil Verifikasi Aktual (`Play Solo`, `4.000 km`, `y = 1012.5`)

1. **Skala Visual Rintangan & Keselarasan Sayap (`ObstacleArt` + `ObstacleManager`)**:
   - `WildBird` (`Band 1`): `VisualScale = 1.9` (pengawal `0.72` + `JointScale`), jarak spawn `145.3` stud, fading `1.00 -> 0.00` dalam `0.45s`, `bbox = 45.8 × 8.9 × 19.0`, sayap tetap terpasang simetris (`Wing@5.0, Wing@5.0, Wing@20.2, Wing@14.2`).
   - `GuardianDrone` (`Band 4`): `VisualScale = 2`, jarak spawn `145.3` stud, `bbox = 15.1 × 5.2 × 7.4`; saat `Charging=true`, menembakkan `Paku Sihir` (`Art.Spike`) `+4.5` stud di depan `Aperture` dengan ukuran terukur `1.80 × 1.85 × 8.80` (`Spike = 1.4 × 1.6 × 8.8`, `wakeW0 = 2.20`) pada `distEnv = 68.1` stud.
   - `CrystalWyvern` (`Band 6`): `VisualScale = 2.2`, jarak `145.3` stud, `bbox = 26.4 × 7.7 × 18.6`, sayap terpasang (`CrystalWing@7.0..10.2`).
   - `CelestialPhoenix` (`Band 9`): `VisualScale = 2.6`, jarak `158.7` stud, `bbox = 28.7 × 9.5 × 21.1`, sayap terpasang (`Wing@6.8, Wing@6.8`).
2. **Spawn Rintangan Anti Pop-In Tengah & Lintasan (`Band 1..9`)**:
   - `Tornado`: `Dist0 = 70.0`, `pathLen = 140.0`.
   - `Lightning`: `Dist0 = 14.8` (tidak di titik `0.0`), `Thunderhead` turun mulus di atas kepala (`bbox.Y` `54.4 -> 44.5` di `T=2.85s`).
   - `Wind`: `Dist0 = 68.0`, `pathLen = 136.0` (+ `PathBeam`).
   - `Debris`: `Dist0 = 84.0`, `minRuinDist0 = 55.6`, `OriginDist = 0.0` (meluncur masuk `84.0 -> 20.8 -> 0.0`, `FadeDone = false -> true` di `0.95s`, `Ruin2` di `(31, 0, -12)`).
   - `Heat`: `Dist0 = 68.0`, `pathLen = 136.0`.
   - `Magnetic`: `Dist0 = 84.0`, `minCrystalDist0 = 65.7` (`ChargedCrystal` tersebar melingkar radius `24` stud mengelilingi pusat), meluncur `84.0 -> 20.9 -> 0.0`.
   - `Fog`: `Dist0 = 60.0`, `pathLen = 120.0`.
   - `Meteor`: `Dist0 = 87.9`, `pathLen = 175.8`, `laneBbox = 11.4 × 11.6 × 10.1`.
   - `Storm`: `Dist0 = 13.6` (tidak di `0.0`).
3. **SFX Lubang & Tambal Balon (Opsi A — Penggantian Suara Reload & Penyesuaian Volume Default `65%` pada `BalloonVFX.luau`, grup `SFX`)**:
   - Seluruh `7` instance suara lubang/tambal pada `Balloon_Fikki2621` berstatus `IsLoaded=true` & `grp=SFX`: `PunctureThud` (`rbxassetid://9113263649` *Balloon Pop 3*, `len=0.430s`, `vol=0.312`, `spd=0.95`), `PunctureHiss` (`rbxasset://sounds/volume_slider.ogg`, `len=0.845s`, `vol=0.273`, `spd=1.48`), `PunctureCrewSnap` (`rbxassetid://9113825868` *Cloth Rip Halting 11*, `len=0.230s`, `vol=0.234`, `spd=1.02` — menggantikan `AudioAssets.WeaponReload`), `PunctureCrewCrit` (`rbxassetid://17761221095`, `len=0.267s`, `vol=0.182`, `spd=0.80`), `PatchSnap` (`rbxasset://sounds/switch.wav`, `len=0.235s`, `vol=0.460`, `spd=1.16`), dan `PatchCrewChimeLow`/`High` (`rbxasset://sounds/electronicpingshort.wav`, `len=0.720s`, `vol=0.280`/`0.260`, `spd=1.28`/`1.60`). Keempat layer suara lubang kini tepat `65%` dari volume default awal (`0.48 -> 0.312`, `0.42 -> 0.273`, `0.36 -> 0.234`, `0.28 -> 0.182`).
   - **Lubang ke-1..3 (`HITS=true(h=1..3)`)**: memainkan `PunctureThud` (`9113263649`, `vol=0.312`), `PunctureHiss` (`volume_slider.ogg`, `vol=0.273`), dan `PunctureCrewSnap` (`9113825868`, `vol=0.234`) tanpa `PunctureCrewCrit` maupun `WeaponReload`.
   - **Lubang ke-4 (`HITS=true(h=4)`)**: memainkan ketiga layer tersebut plus `PunctureCrewCrit` (`17761221095`, `vol=0.182`).
   - **Saat perisai aktif**: penolakan perisai (`ok=false`) terverifikasi pada run pra-penyesuaian volume (`BalloonManager` tidak berubah sesudahnya).
   - **Tambal manual (`RepairHole(4)` -> `h=3`)**: memainkan `PatchSnap` (`vol=0.460`), `PatchCrewChimeLow` (`vol=0.280`), dan `PatchCrewChimeHigh` (`vol=0.260`).
   - **Emergency Kit (`UseEmergencyKit`)**: terverifikasi pada run pra-ganti asset puncture (`KitSaveChime`/`KitSaveBody` terpisah dari `PatchCrewChime`; skrip kit tidak berubah).
   - **Status mute (`AudioSFXMuted=true`)**: pada `h=5` mencatat `SFX_LOG_COUNT=0` (`0` suara grup `SFX` diputar pada klien).
4. **Screenshot Visual**:
   - [`01-playtest-storm-horizon.jpg`](01-playtest-storm-horizon.jpg): balon di Zona 3 (`4.000 km`, `Pulau Senja`), awan badai & vortex di sisi kiri luar keranjang (diambil pada run pra-ganti asset puncture; skrip obstacle tak diubah sesudahnya).
   - [`02-playtest-scaled-enemies-phoenix.jpg`](02-playtest-scaled-enemies-phoenix.jpg): `CrystalWyvern`, `CelestialPhoenix`, meteor, dan cincin `Magnetic` (`ChargedCrystal` keliling, run pra-ganti asset puncture).
   - [`03-playtest-flock-spike-meteor-magnetic.jpg`](03-playtest-flock-spike-meteor-magnetic.jpg): perbandingan `WildBird` (pengawal `0.72`), `GuardianDrone` + `Paku Sihir`, `CrystalWyvern`, `CelestialPhoenix`, `Meteor`, dan `Magnetic` (run pra-ganti asset puncture).

## Pemulihan Studio & Batas QA

- **Mode `Edit` pulih bersih**: `PLAYERS=0`, `HAS_TEMP=false` (`_PlaytestBridge*` tidak ada di `Edit`), `TOTAL=52`, `FAIL=0`, kamera kembali ke `(0.0, 48.0, 25.0)` menghadap `(0, 12, -55)`.
- **Console output**: `0` error/warning runtime gameplay (`get_console_output` pasca-run Play Solo bersih hanya menampilkan info mock `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.`).
- **QA tersisa**: uji dengar subjektif atas suara pop + robek kain (`9113263649` + `9113825868` + `volume_slider.ogg`) & pertempuran alami penuh `300–10.000 km` bersama kru `2–3` klien nyata (Play Solo Windows mengonfirmasi event `.Played`/propertinya via API, bukan pendengaran langsung di speaker), perangkat mobile/tablet nyata (iPad), serta buka ulang binary `Fly High.rbxl`.
