# QA Perbaikan Bug Touch-Drag Kamera Masuk ke Tombol HUD (`2026-11-19`)

- **Run ID:** `touch-input-guard-2026-11-19`
- **Waktu:** `2026-11-19 01:36–01:51 WIB` (`Asia/Jakarta`)
- **Lingkungan:** Roblox Studio `6e240f19-beea-4042-9663-5e7d94ab1350` (`Fikki2621's Place: 11152026_1`, `placeId=97043730132219`, `universeId=10776821830`), `Play Solo` Windows (`Fikki2621`, viewport `2090.0 x 752.0`)

## Akar Masalah Terkonfirmasi (`Repro Studio`)

1. Repro langsung via `user_mouse_input` (tekan di luar tombol lalu geser masuk ke tombol) mengonfirmasi bahwa Roblox memicu `GuiObject.InputBegan` saat pointer aktif masuk ke batas tombol dengan `input.UserInputState == Enum.UserInputState.Change`:
   - `ActionTarget.InputBegan type=MouseMovement state=Change pos=(978,415)`
   - `Shop.InputBegan type=MouseMovement state=Change pos=(43,179)`
2. Di desktop, gerak pointer memakai `MouseMovement` sehingga filter `MouseButton1` mengabaikannya. **Di iPad/layar sentuh**, gerak jari memakai `Enum.UserInputType.Touch` dengan `UserInputState.Change`, sehingga seluruh tombol HUD yang mendengarkan `GuiObject.InputBegan` ikut terpencet saat jari pemain sedang men-drag kamera dari luar HUD melewati tombol.
3. Sebaliknya, klik/tap langsung tepat di dalam tombol memicu `GuiButton.InputBegan` (`UserInputState.Begin`) lebih dulu, disusul `UserInputService.InputBegan(i, true)` (`gpe = true`) dan `GuiButton.Activated`.

## Implementasi Perbaikan

- **Helper terpusat [`TouchInputGuard.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/TouchInputGuard.luau):**
  - Menyediakan `TouchInputGuard.IsDirectBegin(guiObject, input)` untuk memastikan `input.UserInputState == Enum.UserInputState.Begin`, menolak `Touch` yang sudah terdaftar pada `UserInputService.TouchStarted`/`InputBegan` dengan `gpe == false` (drag kamera dunia), `moved == true`, `> 0.08` detik sejak mulai, atau sudah diklaim `GuiObject` lain (`claimed ~= guiObject`), sementara tetap memperbolehkan multi-listener pada `GuiObject` yang sama (aksi + animasi `HUDMotion`/`HUDTheme`) serta multi-touch terpisah per `InputObject` (key lemah `__mode = "k"` + cleanup `TouchEnded`/`InputEnded`/`WindowFocusReleased`).
- **6 Call Site `GuiObject.InputBegan` yang diperbarui:**
  1. [`HUDInteractionPrompts.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDInteractionPrompts.luau) (`ActionTarget`: `START FLIGHT` / `MULAI TERBANG`, `BOARD`, `OPEN SHOP`, `PATCH BALLOON`, `REPAIR ROPE`, `HOLD HELM`, `PULL CREW`, `CLIMB DOME`, `ENTER PORTAL`, `PHOTO`, dll.)
  2. [`FlightHUDController.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/FlightHUDController.luau) (`gasBtn` / `GAS / NAIK`)
  3. [`WeaponClientController.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/WeaponClientController.luau) (`mobileShootBtn` / `TEMBAK`)
  4. [`AudioSettingsModal.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/AudioSettingsModal.luau) (`sliderHit` volume slider; plus guard `not activeDrag`)
  5. [`HUDMotion.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDMotion.luau) (`btn.InputBegan` press squish; tetap mempertahankan Gamepad `ButtonA`)
  6. [`HUDTheme.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau) (`o.InputBegan` state `r.pressed`)

## Hasil Verifikasi (`Play Solo` & Parity)

- **Log mentah:** [qa-results.json](qa-results.json)
- **Interaksi Nyata (`user_mouse_input` di `Play Solo`, `0` error skrip game):**
  - **Drag luar → masuk `ActionTarget` (`StartPrompt` / `MULAI TERBANG`, tahan `320ms`):** `dragLogs = []`, `inFlight = false` (tidak terpencet/terpicu).
  - **Tekan langsung `ActionTarget` (`350ms`):** `PromptHoldBegan` → `PromptTriggered` → `inFlight = true`.
  - **Drag luar → masuk `ShopToggleButton`:** `shopModalVisible = false`; **klik langsung:** `shopModalVisible = true`.
  - **Klik langsung `AudioRowMaster.SliderHit`:** Master berubah `1.0 -> 0.5`, Music tetap `0.6`.
  - **Drag luar → masuk `GasButton` (saat duduk di `HelmSeat`):** `[]` (tetap `240,100,30`); **tekan langsung `150ms` → lepas:** `["direct:255,140,40", "direct:240,100,30"]`.
- **Unit & Matrix Runtime `TouchInputGuard.IsDirectBegin` pada kontrol terpasang (`ShopToggleButton`, `GasButton`, `AudioSliderHit`, `MobileShootButton`):**
  - Seluruh kasus `touchChangeRejected` (`UserInputState.Change`), `touchBeginAcceptedA`, `sameTouchSameButtonAccepted`, `sameTouchDifferentButtonRejected`, `secondFingerDirectAcceptedB`, `mouseBeginAccepted`, `mouseMovementRejected`, dan `keyboardRejected` bernilai **`true`**.
- **Parity & Compile (`Edit`):**
  - **66/66** skrip compile bersih (`compileErrors = []`) dan cocok panjang byte UTF-8 ternormalisasi dengan `audit/sources/` (`mismatches = `).
  - **7/7** file baru/terubah cocok isi **persis (`exact=True`) & SHA-256**: `TouchInputGuard` (`3.029` B, `017b1b1a2305318c`), `HUDInteractionPrompts` (`12.707` B, `0532ed02f7f5dd19`), `HUDMotion` (`53.949` B, `ccb2e3f200c8f895`), `HUDTheme` (`85.269` B, `1e9d3ecf5e4320b2`), `AudioSettingsModal` (`14.937` B, `67bd5606370d9817`), `FlightHUDController` (`33.047` B, `388cd52fadcc2755`), `WeaponClientController` (`51.112` B, `050e5782fa641a41`).
- **Batasan Terbuka:**
  - `VirtualInputManager:SendTouchEvent` memerlukan kapabilitas `RobloxScript` sehingga simulasi swipe OS sentuh asli pada perangkat **iPad fisik** tetap perlu dikonfirmasi pengguna setelah build dipublish/dijalankan di iPad.
  - Pada mode desktop FirstPerson saat `Pistol` dipakai (`MouseBehavior = LockCenter`), klik kiri di luar HUD menembak lewat `tool.Activated`; `MobileShootButton` terverifikasi lewat matriks runtime `IsDirectBegin` dengan `mobileShootVisible = true`.

## Cleanup & Penyimpanan Place

- Studio dikembalikan ke `Edit`, `playerCount = 0`, `leftovers = []`, kamera `Fixed` `(0, 48, 25)` → `(0, 14, -5)` ([edit-restored.jpg](edit-restored.jpg)).
- Tersimpan lokal ke `E:/Antigravity/Fly High/Fly High.rbxl` (`3.534.527` B, `2026-11-19 01:50:51 WIB`, SHA-256 `B2EE9143C0276DF7180D4BE5CBBEF63A742273CE01CFD90B95A8742F11CE66D9`); belum dibuka ulang dari disk, belum dicommit/dipush, dan belum dipublish ke Roblox Cloud.
