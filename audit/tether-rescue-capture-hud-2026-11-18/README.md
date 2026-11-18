# QA Perbaikan Rescue Tali & Sembunyikan HUD saat Native Capture (`2026-11-18`)

- **Run ID:** `tether-rescue-capture-hud-2026-11-18`
- **Waktu:** `2026-11-18 21:32 WIB` (`Asia/Jakarta`, `UTC+7`)
- **Build dasar:** `HEAD = 9950b85` (`main`), `origin/main = 9950b85` (file kerja lokal belum dicommit)
- **Lingkungan:** Roblox Studio `1fc749f2-5a8f-4d20-8f58-c9a3897f2f64`, `Play Solo` Windows 1 klien (`Fikki2621`, `userId=8635452105`, `dataReady=true`, `placeId=97043730132219`)

## Ringkasan Perubahan & Root Cause

### 1. Rescue Tali Stabil Saat Balon Turun Loncat / Bergerak (`GAME-04`)
- **Akar masalah yang ditemukan:**
  1. Target pendaratan winch di `TetherManager` sebelumnya di `Z = 8` (`6` stud dari pagar belakang `±14`) dengan hover ekstra `+math.max(.1, hrp.Size.Y/2)`, menggunakan `Enum.HumanoidStateType.GettingUp`, dan membiarkan orientasi miring saat fase `WINCH_SETTLE`.
  2. Ketika balon turun cepat (`jumpDropRemaining`, `-22` stud/dtk) atau bergerak horizontal X/Z (`~30-37` stud/dtk), latensi replikasi antara balon milik server dan karakter milik klien menggeser posisi relatif server ~7–9 stud. Pada uji v1 awal, menulis `t.hrp.CFrame` dari server setelah `independentOwner(t, false)` malah mengirim koreksi posisi terlambat yang menembuskan klien `-2.49` stud di bawah `BasketFloor`.
- **Perbaikan v2 final:**
  - [`TetherManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/TetherManager.luau): pendaratan diarahkan ke tengah keranjang (`localX = ±2.5`, `Z = 0`, tinggi `basketStandHeight` flush `+0.12`), meratakan postur tegak (`uprightCFrameAt`) selama fase settle, reset `hum.Jump = false`, transisi ke `Enum.HumanoidStateType.Running`, menghapus penulisan `hrp.CFrame` server sesudah ownership diserahkan ke klien, mempertahankan `t.rescueGraceUntil = os.clock() + 1.15` pada evaluasi `fell`, serta mengirim event `rescueLanded` (`balloon`, `localOffset`) ke klien. Evaluasi `fell` dek memakai `floorRel.Y < -1.5` atau keluar `floor.Size/2 + 1.5`.
  - [`WeaponClientController.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/WeaponClientController.luau): saat `data.rescueLanded`, klien langsung menyinkronkan `HumanoidRootPart` tegak ke `BasketFloor`, menyamakan `AssemblyLinearVelocity = floor.AssemblyLinearVelocity`, memaksa `Running`, dan menjalankan loop `RunService.Stepped` (`0.85` detik) pada koordinat klien sendiri jika `FloorMaterial == Air`, keluar area aman, atau mulai tenggelam (`rel.Y < localOffset.Y - 0.45`).

### 2. Sembunyikan HUD Saat Native Capture (`UI-01`)
- [`FlightHUDController.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/FlightHUDController.luau): mendengarkan `CaptureService.CaptureBegan` dan `CaptureEnded` (dengan `captureDepth` counter agar aman dari capture bertingkat & tidak bentrok dengan `PhotoboothSpot.PhotoPrompt`):
  - Menyembunyikan `FlyHighHUD` (`Enabled = false`, atribut `HiddenForCapture = true`) serta semua `ScreenGui` `HUDInteractionPrompt` aktif maupun yang muncul selama capture.
  - Menyembunyikan `TouchGui` **hanya** saat `Enum.CaptureType.Screenshot`, sehingga perekaman `Enum.CaptureType.Video` tetap mempertahankan kontrol sentuh di layar sembari menyembunyikan HUD & prompt.
  - Batas platform Roblox (terkonfirmasi API & Play Solo): `CaptureBegan`/`CaptureEnded` hanya dipicu oleh fitur Capture bawaan Roblox (`Esc -> Captures` atau hotkey native `Alt+1`), bukan screenshot OS eksternal (Snipping Tool / tombol fisik) ataupun pemanggilan script `CaptureService:CaptureScreenshot`.

## Hasil QA & Parity

- **Parity & Compile (`Edit`):**
  - `TetherManager.luau`: `25.659` B, SHA-256 `20f787ea031f07df7af24a713d2ce6887c121619d99fcbf9d39e9fb9b56e4bd9` — `EXACT_BYTE_MATCH`
  - `WeaponClientController.luau`: `50.498` B, SHA-256 `75530fbe270a0f323dafb9ca07653d6e4647ee8d831680a631bf54bfd895681d` — `EXACT_BYTE_MATCH`
  - `FlightHUDController.luau`: `32.987` B, SHA-256 `40e9fcaa1e0018d77bff024ac6807dd176c7a8da6b735fe31f4b11837a07612a` — `EXACT_BYTE_MATCH`
  - Seluruh **64/64** skrip: `SYM_NORM_MATCH=64`, `FAILS=0`, `compileFail=0`, `editorMatchAll=true`.
- **Tether Rescue Live Play Solo (v2 final):**
  - Balon dilepas di udara (`Pod_A`, `balloonY: 78.9 -> 42.77`), diuji dengan stres serentak sepanjang winch dan pasca-mendarat (`fd.jumpDropRemaining = 24`, `fd.wind = (28, 0, -24)`, `engineerTilt = (0.11, 0, -0.11)`, kecepatan balon aktual `(27.6..28.2, -17.1..-17.9, -23.0..-24.1)` stud/dtk) + mock rekan di dalam keranjang untuk memicu `PullCrew` produksi.
  - Hasil server: `stageAfterPull = "Rescuing"`, `droppedDuringPost = false`, `airCountAfterGrace = 0`, `postGraceStage = "Basket"`, `postGraceInBasket = true`, `t = 0.42..2.02` bertahan di `WoodPlanks` (`rel.Y = 2.54..2.56`), dan setelah `rescueGraceUntil` (`1.133` dtk) berakhir langkah keluar paksa ke `(22, -2, 22)` tetap tertangkap `postGraceFallCaught = true` (`stage = "Hanging"`).
  - Hasil klien (`_QAClientEvents`): event `rescueLanded` diterima di `-2.5, 2.693, 0`; **16/16** sampel `0.1–1.6` dtk menunjukkan `humState = "Running"`, `floorMat = "WoodPlanks"`, `anchored = false`, `rel.Y = 2.54..2.56`.
- **Native Capture HUD Live Play Solo:**
  - Shortcut native `LeftAlt + One` (`Enum.CaptureType.Screenshot`) memicu `CaptureBegan(Screenshot)` -> `FlyHighHUD.Enabled = false`, `HiddenForCapture = true`, `StartPrompt` (`HUDInteractionPrompt.Enabled`) `= false` -> lalu `CaptureEnded(Screenshot)` memulihkan ketiganya kembali (`true` / `false` / `true`).
  - `CaptureScreenshot` programatik terkonfirmasi `gotId = true`, `beganCountForProgrammatic = 0`.
  - Tombol `F12` / `LeftAlt + Two` di desktop Play Solo tidak memicu `CaptureBegan(Video)` (`log = []`), sehingga jalur `Enum.CaptureType.Video` + `TouchGui` diverifikasi lewat pembacaan jalur event yang sama dan tetap memerlukan uji perangkat sentuh / Roblox Client live.
- **Console:** `0` error / `0` warning skrip game.

## Penyimpanan Place & Cleanup

- `save_place` sukses menyimpan ke file lokal: `E:/Antigravity/Fly High/Fly High.rbxl` (`3.528.111` B, SHA-256 `b6d4bbd85ec32e7bc9d90639f17fb16a497ba944b8aece7fb067eea8d941c09e`, `2026-11-18T21:29:49+07:00`). Binary `.rbxl` belum dibuka ulang pada sesi pemeriksaan terpisah.
- Studio dikembalikan ke `Edit`, `players = 0`, `leftovers = []`, kamera default `(0, 48, 25)` (`Fixed`) diverifikasi di [edit-restored.jpg](edit-restored.jpg).
- Log mentah lengkap: [qa-results.json](qa-results.json).
