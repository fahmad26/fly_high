# QA Efek Balon Udara — Emergency Kit & Turbo Gas (15 November 2026)

> **Status historis — peninjauan dokumentasi 15 November:** laporan ini mempertahankan tanggal/build/hasil run semula. Sebutan belum commit/push di bawah berlaku saat run, bukan HEAD kini; lihat [acuan Git](../../HANDOVER.md) dan [status fitur/OPEN-07](../../PROGRESS.md). Folder ini belum menyertakan log/manifest mentah terpisah; klaim QA naratif belum diverifikasi ulang. Screenshot tetap bukti visual sesuai cakupannya. Penandaan ini bukan Playtest baru.


Dokumen bukti implementasi & QA untuk efek visual/audio balon udara pada pemakaian **Emergency Kit** (*Golden Clutch Save & Shield*) dan **Turbo Gas** (*Sky-Cyan Jet & Slipstream*).

## Ringkasan Perubahan Kode (`50/50` Parity Studio ↔ Mirror, `compileErrorCount = 0`)

1. **[`BalloonVFX.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/BalloonVFX.luau)** (ModuleScript baru di `ReplicatedStorage.FlyHigh.Modules.BalloonVFX`, `28.868` B, hash `f30c43ee_1aab98d4`):
   - Memasang rig VFX non-fisik milik klien di `workspace._FlyHighBalloonVFX` (`Massless = true`, `CanCollide = false`, `CanTouch = false`, `CanQuery = false`, `CastShadow = false`, `CollisionGroup = "FlyHighBalloons"`) yang terikat ke tiap model balon.
   - **Emergency Kit**: burst partikel emas-zamrud (`KitPatchBurst`, `sparkles_main.dds`) keluar dari slot lubang yang diperbaiki (`KitRepairedSlots`), cincin kejut tersegmentasi (`KitShockRing`, `0.65` dtk), `Highlight` sesaat pada badan balon (`KitSaveHighlight`, `0.85` dtk, nonaktif saat `ReduceHUDMotion = true`), kubah pelindung `ForceField` (`ShieldShell` + `ShieldAuraLight` + sabuk `ShieldIdleMotes`) beserta kedipan peringatan `1,5` detik sebelum habis, dan SFX spasial `electronicpingshort.wav` + `button.wav` pada grup `SFX`.
   - **Turbo Gas**: denyut inisiatif (`TurboIgnitionBurst` + `TurboShockRing` cyan `0.48` dtk + SFX spasial `volume_slider.ogg` & `electronicpingshort.wav`), 2-lapis pembakar (`TurboCoreJet`, `TurboEmberSparks`, `TurboBurnerLight`, `TurboNozzleHalo`) yang membedakan pembakaran aktif (`BurnerActive = true`) dengan standby (`BurnerActive = false`), serta `4` trail ekuator (`EnvSlipTrail1..4`), `2` trail tiang sisi (`PoleSlipTrailL/R`), dan hembusan angin kanopi (`TurboWindStream`) dengan peredaan halus `5,0` detik terakhir (`TURBO_COOLDOWN_WINDOW`).
   - Mematuhi `ReduceHUDMotion` (pengurangan laju partikel, tanpa `Highlight` sesaat).
2. **[`BalloonManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/BalloonManager.luau)** (`31.206` B, hash `e066bdf2_1bbd493c`):
   - Inisialisasi dan replikasi atribut balon (`ShieldActive`, `ShieldUntil`, `ShieldDuration`, `KitBurstSeq`, `KitRepairedSlots`, `TurboActive`, `TurboUntil`, `TurboDuration`, `TurboBurstSeq`, `BurnerActive`) saat peluncuran, `UseEmergencyKit`, `UseBuff("turbo_gas")`, sinkronisasi `Heartbeat`, dan reset di `EndFlight`.
3. **[`BalloonFleetAnimator.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/BalloonFleetAnimator.luau)** (`9.688` B, hash `f3d7f2d1_33896223`):
   - Memanggil `BalloonVFX.Attach(model)`, `BalloonVFX.Detach(model)`, serta `BalloonVFX.Step(t, eye)` di loop `PreSimulation` (60 Hz saat efek aktif, 30 Hz saat siaga).

## Bukti QA (`Play Solo` Windows 1 Klien, `Fikki2621`)

| Uji | Lingkungan & Fixture | Hasil Aktual | Screenshot |
| --- | --- | --- | --- |
| Parity & Kompilasi | `Edit` Studio vs `audit/sources/` (`check_parity.py`) | `50/50` identik, `0` mismatch, `0` error `loadstring` | — |
| Turbo Gas (jalur server live) | `DailyLoginFunction:InvokeServer("Claim")` -> `Pod_A` -> `HelmSeat` -> `AutoGas = true` -> `UseBuffEvent:FireServer("turbo_gas")` | `TurboActive = true`, `TurboBurstSeq = 1`, `BurnerActive = true`, `TurboCoreJet (Rate = 95)`, `TurboEmberSparks (Rate = 28)`, `TurboWindStream (Rate = 44)`, `TurboBurnerLight (Brightness = 3.6, Range = 44)`, `TurboNozzleHalo_Seg1..16 = true`, 6/6 `Trail = true`, 4/4 `Sound.IsLoaded = true` di grup `SFX`, `physicsViolations = []` | [`01_turbo_gas_active.jpg`](01_turbo_gas_active.jpg) |
| Emergency Kit Burst & Shield Dome (fixture atribut server) | Play Solo yang sama dengan `Balloon_Fikki2621`; atribut `KitRepairedSlots = "1,2,3"`, `ShieldDuration = 60`, `ShieldUntil = serverNow + 60`, `ShieldActive = true`, `KitBurstSeq = 1` (menggantikan pemicuan checkout/Day-7 DataManager lokal) | Kubah `ShieldShell` (`ForceField`, `[44, 59.1, 44]`, `Transparency = 0.414`) mengelilingi envelope dengan jelas, `ShieldAuraLight (Brightness = 2.01, Range = 48)`, `ShieldIdleMotes (Rate = 18)` | [`02_emergency_kit_shield.jpg`](02_emergency_kit_shield.jpg) |
| Pandangan Pemain di Keranjang | `CameraType = Custom` (`CameraSubject = Humanoid`) saat kedua efek aktif | Pandangan dek, tiang lentera, holster, horizon, dan HUD tidak terhalang | [`03_kit_shield_basket_view.jpg`](03_kit_shield_basket_view.jpg) |
| `ReduceHUDMotion`, Blink Kedaluwarsa, & Cleanup | Relaunch `Pod_A` -> uji `ReduceHUDMotion = true -> false`, uji `ShieldUntil = +6.5s` hingga lewat `0s`, lalu `Balloon_Fikki2621:Destroy()` & akhiri penerbangan | `ShieldIdleMotes` turun `18 -> 6 -> 18`; kedipan `ShieldShell.Transparency` terbaca `0.89 -> 0.637 -> 0.49 -> 0.893 -> 1.0` (`ShieldAuraLight/TurboCoreJet/Trails = false`); `workspace._FlyHighBalloonVFX` kembali `0` child baik saat mendarat alami maupun saat `:Destroy()`; `0` error script runtime pada `get_console_output` | — |

## Batas QA & Pemulihan Place

- Jalur pemanggilan `BalloonManager.UseEmergencyKit()` tidak dipicu langsung via pembelian kit karena `[DataManager]` menonaktifkan checkout di place yang belum dipublikasikan; sebagai gantinya atribut replikasi yang identik disuntikkan ke `Balloon_Fikki2621` di Play Solo untuk memverifikasi perilaku visual & audio klien.
- Uji multi-klien (`2–3` pemain bersamaan), perangkat fisik mobile/tablet, serta perjalanan penuh sampai Istana Awan belum dijalankan.
- Mode Studio dipulihkan ke `Edit` (`playersCount = 0`, `vfxFolderPresent = false`, `cameraType = Fixed`, kamera `(0,48,25) -> (0,12,-55)`).
- Place disimpan lokal ke `E:/Antigravity/Fly High/Fly High.rbxl` (`1.900.420` B, `2026-11-15 01:04:40 +07:00`, SHA-256 `CB66C64223D0226984674E169E03355F2D760DCD2B0A8C78338341615C450657`; isi binary `.rbxl` belum dibuka ulang). Belum commit/push.
