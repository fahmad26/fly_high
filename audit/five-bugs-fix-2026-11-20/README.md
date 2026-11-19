# Audit Perbaikan 5 Bug Gameplay — 20 November 2026

- **Lingkungan:** Roblox Studio `62413064-d35d-4c65-ba51-2f7fda1c2e38`, `placeId = 97043730132219`, `universeId = 10776821830`, base Git `bda5b15` (masuk commit & push Git `main` 20 Nov; belum Publish ke Roblox Cloud).
- **Mode Uji:** `Play Solo` Windows 1 pemain (`Fikki2621`, `TestService.NumberOfPlayers = 1`), penulisan `DataManager` di-stub ke memori, `ObstacleManager.Paused = true`, `LargeChallengeManager.Paused = true`.

## Ringkasan 11 File Diubah (`Studio Edit = 66/66` cocok ternormalisasi, `compileFail = 0`)

1. **Bug 1 — Balon bertumpuk/berdekatan bikin karakter ngeglitch / ter-unseat:**
   - [`CrewAccessGuard.luau`](../../audit/sources/ServerScriptService/FlyHighServer/CrewAccessGuard.luau): menambahkan `inOwnBalloon()` agar pemilik balon tidak diganggu saat berada di keranjang/kursi/tali sendiri, serta memperketat deteksi balon tim lain berdasarkan `fd.profile` (`basketHit` & `upperHit`).
   - [`BalloonFleetAnimator.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/BalloonFleetAnimator.luau): menonaktifkan kolisi hull balon tim lain saat pemain sedang terbang (`disableHullCollide`).
2. **Bug 2 — Duduk di sofa/ayunan tidak bisa dilepas dengan Lompat (Space / JumpButton):**
   - [`JumpManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/JumpManager.luau): menambahkan aksi server `"DismountSeat"` (`U.Unseat(p)`, angkat `+1.2` stud, kembalikan `SetNetworkOwner(p)` ke klien) yang menolak melepas `HelmSeat`.
   - [`FlightJumpController.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/FlightJumpController.luau): mengeksekusi `tryDismountNonHelmSeat` pada `JumpRequest` maupun `JumpButton.Activated` sebelum cek `FloorMaterial`, serta menjaga `panel.Visible` saat `hum.Parent ~= nil`.
   - [`PalaceCinematics.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/PalaceCinematics.luau): `holdMovement(true)` memakai fallback default `StarterPlayer` bila `JumpPower`/`WalkSpeed` terbaca `0`.
3. **Bug 3 — Panjat/turun katrol terjatuh saat balon bergerak atau terkena knockback:**
   - [`TetherManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/TetherManager.luau): `basketStandHeight` `+0.12 -> +0.03`, menghentikan injeksi `AssemblyLinearVelocity = fd.root:GetVelocityAtPosition(...)` saat settle (`Vector3.zero` karena Humanoid berdiri di `WoodPlanks`).
   - [`WeaponClientController.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/WeaponClientController.luau): memperpanjang tunggu `waitAnchorUntil` ke `1.0` dtk, memakai `Vector3.zero` pada koreksi stabilisasi landing, serta memperketat cincin `Catwalk` ke `r` `[14.9, 17.1]`.
   - [`BalloonFleetAnimator.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/BalloonFleetAnimator.luau): membawa karakter di udara/transisi memakai perpindahan frame akurat `deltaXZ` posisi `root`.
4. **Bug 4 — Kru mati mode spectate masih memunculkan tubuh & overhead di `LobbySpawn`:**
   - [`BalloonManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/BalloonManager.luau): menyembunyikan sinkron lalu menghapus karakter respawn saat `fd.dead[p]`, melacak `fd.ghostDespawned`, `releaseGhostFocus(fd, p, true)` (`LoadCharacterAsync()` di GameOver/destroying), serta `fd.landingGraceUntil`.
   - [`PalaceArrival.luau`](../../audit/sources/ServerScriptService/FlyHighServer/PalaceArrival.luau): membersihkan `fd.ghostDespawned[p] = nil` saat kru gugur bangkit di `CloudHavenDock`.
   - [`OverheadManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/OverheadManager.luau): melewati `setupOverheadGui` saat `FlightGhost == true and InFlight == true`.
5. **Bug 5 — Orang luar tim yang mendekati/memasuki balon tim lain ter-respawn ke `LobbySpawn`:**
   - [`BalloonFleetAnimator.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/BalloonFleetAnimator.luau): menambahkan barrier tak terlihat `Barrier_<ModelName>` di sekitar balon tim lain bagi bukan kru (`CanCollide = true` bila tidak terjebak di dalam).
   - [`CrewAccessGuard.luau`](../../audit/sources/ServerScriptService/FlyHighServer/CrewAccessGuard.luau): `pushOutsideBalloon()` mendorong orang luar mulus ke tepi rim `17.5` stud di tanah aman (bukan warp ke `LobbySpawn`).
   - [`BalloonManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/BalloonManager.luau) & [`PodManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/PodManager.luau): dorongan tepi `17.5` stud saat `LaunchBalloon` & overflow dermaga `pad.Size/2 + (8.5, 0, 8.5)`.

## Hasil QA (`Play Solo`, build final bersih)

Detail lengkap di [`qa-results.json`](qa-results.json).

- **Test 1 (Bug 1 — Balon bertumpuk/bersebelahan):** `belowTeleports = 0`, `satInitially = true`, `helmUnseated = 0` (`20` tick), `aboveTeleports = 0`, `sideTeleports = 0`, `dummyAlive = true`, `health = 100`; klien `otherBalloonCollidableParts = 0`, `Barrier_Balloon_OtherTeam.canCollide = true`. Screenshot: [`bug1-stacked-balloons-free-move.jpg`](bug1-stacked-balloons-free-move.jpg).
- **Test 2 (Bug 2 — Dismount sofa & ayunan vs proteksi `HelmSeat`):**
  - `RoyalSofa.LeftSeat`: klik HUD `JumpButton` -> `sit = false, seatName = "nil", Running`; keyboard `Space` -> `sit = false, seatName = "nil", Running`.
  - `RoyalSwingLeft.Carriage.SitSeat` saat berayun: klik `JumpButton` -> `sit = false, seatName = "nil", hingeTarget = 3.44`; keyboard `Space` -> `sit = false, seatName = "nil", hingeTarget = 13.79`.
  - `HelmSeat`: keyboard `Space` -> tetap duduk (`sit = true, seatName = "HelmSeat", Seated`). Screenshot: [`bug2-seat-swing-dismount.jpg`](bug2-seat-swing-dismount.jpg).
- **Test 3 (Bug 3 — Naik & turun katrol di bawah angin/guncangan tinggi):**
  - `prep|4`: `attached = true, stage = "Basket"`.
  - `climb|3`: `reachedCatwalk = true, stage = "Catwalk", fellOrHung = false, needsRescue = false, health = 100, maxBalloonSpeedXZ = 130.79`, `lastSample = {velXZ: 19.24, floor: "WoodPlanks", r: 16.26, relY: 24.57, stage: "Catwalk", needsRescue: false}` (`climb|1` saat pengambilan foto mencatat `maxBalloonSpeedXZ = 132.34`, screenshot [`bug3-climb-descend-under-knockback.jpg`](bug3-climb-descend-under-knockback.jpg)).
  - `descend|3`: `detached = true, stage = "Detached", descFell = false, outsideCount = 0, health = 100, maxBalloonSpeedXZ = 115.81`, `lastSample = {velXZ: 20.33, floor: "WoodPlanks", r: 2.61, relY: 2.57, stage: "Detached", needsRescue: false}` (selama 2 dtk gerak pasca-landing & auto-detach).
- **Test 4 (Bug 4 — Ghost tanpa tubuh spawn, GameOver respawn, & Victory revival):**
  - `test4_kill_ghost`: `flightGhost = true, inFlight = true, repFocusMatchesRoot = true, characterIsNil = true, wsModelsNamedPlayer = 0, overheadAtLobby = 0, ghostDespawnedFlag = true`; klien `cameraSubject = "Workspace.Balloon_Fikki2621.RootPart"`, `ghostFrameVisible = true`. Screenshot: [`bug4-ghost-no-lobby-body.jpg`](bug4-ghost-no-lobby-body.jpg).
  - `test4_gameover_respawn|2`: `hasCharacter = true, health = 100, distToLobby = 2.51, repFocusIsNil = true, flightGhost = false`, klien `cameraSubject = "Workspace.Fikki2621.Humanoid"`.
  - `test4_victory_revival|2`: `nilDuringGhost = true, palaceArrived = true, arrivalRevived = true, hasCharacter = true, health = 100, distToDock = 8.53, flightGhost = false, repFocusIsNil = true`.
- **Test 5 (Bug 5 — Penghalang tak terlihat & dorongan tepi halus):**
  - `5A`: `enteredBasket = false, walkMinDistXZ = 15.99, afterWalkToLobby = 76.18`, `Barrier_Balloon_OtherTeam.canCollide = true`.
  - `5B`: `afterPushDistToPod = 17.66, afterPushToLobby = 74.66, health = 100`. Screenshot: [`bug5-outsider-barrier-at-dock.jpg`](bug5-outsider-barrier-at-dock.jpg).
- **Console (`get_console_output`):** 0 error pada seluruh 11 blok kode yang diubah; tercatat log info studio `[BadgeManager]`, 2 error probe awal `AssistantCommand`, 1 error skrip QA client sebelum diperbaiki di Step 1, serta 1 error sinyal teardown bawaan di `BalloonManager:356` (`HelmPrompt is not a valid member of VehicleSeat "HelmSeat"`) ketika skrip QA menghancurkan balon saat pemain duduk di kemudi.

## Pemulihan Edit, Penyimpanan Place & Batas QA

- **Edit & Parity:** Semua skrip/fixture `_QA_*` & `FlyHighLocalBarriers` dibersihkan (`leftoverCount = 0, TestService.NumberOfPlayers = 1`), Studio kembali ke mode `Edit` dengan kamera default (`edit-restored.jpg`), dan parity Studio ↔ `audit/sources/` **`66/66`** (`compileFail = 0`).
- **Penyimpanan Place & Verifikasi Biner Lokal ([`binary-source-report.json`](binary-source-report.json)):** `save_place` menyimpan ke **Cloud Team Create versi 69** (`location = "TeamCreate", status = "Saved", published = false`), dan file lokal [`Fly High.rbxl`](../../Fly%20High.rbxl) telah disinkronkan pengguna pada `2026-11-20 02:09:38 WIB` (**`3.541.776` B**, SHA-256 `9cd2da3a6a6c8a439e18a5841efd7060876f1b8cb4ed597d7efe36e1dd0c3c03`). Pemeriksaan langsung parser zstd mengonfirmasi **`66/66` skrip cocok ternormalisasi (`0` mismatch)**, `qaNames = []`, `Workspace._has_QA_attr = false`, dan `TestService.NumberOfPlayers = [1]`. Team Create v69 maupun `.rbxl` belum dibuka ulang di sesi Studio baru.
- **Batas QA:** `5C` (dorongan orang luar saat `LaunchBalloon` antar pemain nyata), uji multi-klien `2–3` pemain nyata (balon bertumpuk antar kru, perspektif rekan hidup terhadap ghost mati, barrier orang luar nyata), uji sentuh perangkat fisik (HP/tablet), serta pembukaan ulang place setelah simpan tetap terbuka.
