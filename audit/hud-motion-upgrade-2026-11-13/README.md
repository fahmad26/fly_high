# Pembaruan Animasi HUD (`HUDMotion`) — 13 November 2026

## Build & Sinkronisasi
- **Target module**: `ReplicatedStorage.FlyHigh.Modules.HUDMotion` (`audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDMotion.luau`), satu-satunya source script yang diubah (`51.135` byte setelah normalisasi newline, Adler-32 `0x4df175cc`).
- **Lingkungan Studio**: `Fly High.rbxl` (`Edit` mode setelah Playtest selesai), `42` `LuaSourceContainer` terdeteksi, `loadstring` compile `HUDMotion` lulus tanpa error.
- **Penyimpanan & Git**: `save_place` sukses menyimpan ke `E:/Antigravity/Fly High/Fly High.rbxl` (`status: Saved`). Binary `.rbxl` tidak dibuka ulang untuk pembandingan setelah save. Perubahan belum di-commit atau di-push ke remote Git pada sesi ini.

## Ringkasan Perubahan Animasi
1. **Modal, Scrim & Blur**: `ShopModal`, `WeaponSettingsModal`, dan `TacticalPingWheel` masuk dengan `0.80 -> 1.0` (`Back Out`, `0.34s`), fade opacity, geser `offY = 22px -> 0`, fade-in/out tersinkronisasi pada `HUDModalScrim` (`0.20s` masuk / `0.14s` tutup), serta `BlurEffect` latar (`0 -> 8`, dinonaktifkan saat modal tutup).
2. **Stagger Kartu & Opsi Modal**: `Card1`/`Card2` (`ShopModal`), `HandgunSlot1..ReduceMotionToggle` (`WeaponSettingsModal`), dan `Ping1..5` (`TacticalPingWheel`) muncul bertahap. `Motion.SetVisible` kini pemicu mandiri lewat `EnsureBase` & `TriggerEnter` tanpa harus menunggu pemanggilan eksternal `state.Capture()`.
3. **Interaksi Tombol & Kilau Tiga Segmen**: Tombol memakai squash tekan `0.89`, rebound `Back Out` (`0.30s`), micro-tilt rotasi sesaat pada tap/klik, kilau diagonal tunggal (`HUDMotionSheen`), `CanvasGroup` kilau untuk tombol 3-segmen `"wide"` (`HUDMotionWideSheen`), serta burst 10 bintang pooled (`HUDHoverStar1..10`) yang dijepit agar tidak terpotong tepi layar.
4. **Telemetri Penerbangan & Peringatan**:
   - `StatusFrame` & `HUDHull1..5`: kerusakan memicu guncangan (`shakeAmp = 7`) + partikel merah-oranye & pop pip besar (`popAmp = 0.55`); perbaikan memicu pop + partikel hijau-cyan; kondisi kritis (`HoleCount >= 4`) berdenyut ritmis.
   - `AltimeterFrame`: `BarFill` dengan shimmer mengalir (`HUDProgressSheen`, aktif mulai lebar `>= 4px`), denyut `HUDGoalMarkerSlot`, serta pop `HUDSpeedPill` saat arah vertikal berubah.
   - `WeaponFrame` & `WeaponReticle`: recoil posisi saat peluru berkurang, bounce & kilau biru muda selesai reload, serta snap skala/rotasi `WeaponReticle` saat `AimLocked = true`.
   - `AlertBanner` & `HUDMotionToast`: banner peringatan masuk dengan slam + getar + ikon berdenyut; toast milestone memakai shimmer pill penuh (`CornerRadius 0.5`), fade-out halus sebelum kedaluwarsa `1.5s`, dan `8` anak `Spark1..8`.
5. **Audio UI Lembut & Aksesibilitas**: Enam suara UI bawaan Roblox ter-preload di `SoundService` (`clickfast.wav`, `switch.wav`, `button.wav`, `electronicpingshort.wav`) dengan throttle. Mode `ReduceHUDMotion` menonaktifkan overshoot, blur, shimmer, guncangan, dan burst partikel.

## Hasil QA (Studio Desktop `1066.4 x 536`, 1 Pemain)
- **Playtest interaksi & modal (build akhir `0x4df175cc`)**:
  - Klik `ShopToggleButton` & `CloseButton`: `ShopModal.Visible` membuka & menutup, `BlurEffect` naik `0 -> 8` dan kembali mati `Size = 0` saat ditutup.
  - Uji `HUDMotionToast`: `toastVis = true`, `visStars = 8` pada `0.25s`, serta konsol bersih hanya menampilkan `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.` setelah sesi akhir.
- **Fixture kontrak terisolasi (`FlyHighHUDMotionQA`, dihapus setelah selesai, build akhir `0x4df175cc`)**:
  - **Lulus (15/16)**: `rootStable`, `modalOpenFade1`, `instanceCountStable` (10x siklus modal pada `WeaponSettingsModal`), `selfContainedModalAndStagger`, `earlyShimmerVisibleAt7px`, `barTargetPreserved`, `toastSparks8`, `toastExpired`, `reducedMotion0Sparks`, `damageShakeAndPipPop`, `repairPopTriggered`, `weaponFireRecoil`, `weaponReloadPop`, `reticleLockSnap`, `hover108Settled`.
  - **Gagal pada fixture kedua (1/16)**: `blurOnOpen` pada `ScreenGui` uji kedua bernilai `false` ketika `FlyHighHUD` juga sedang aktif di `Lighting`; perilaku blur nyata pada `ShopModal` di `FlyHighHUD` terverifikasi aktif (`Size = 8`) dan nonaktif (`Size = 0`).
- **Screenshot terarsip**:
  - `01-lobby-baseline.jpg` .. `08-inflight-critical-hull-1of5.jpg`: direkam selama sesi Playtest Studio (sebagian fitur penerbangan & modal sebelum 8 edit polish terakhir).
  - `09-postfinal-lobby-settled.jpg`: direkam pada build akhir `0x4df175cc` setelah menutup `ShopModal` dan memastikan blur kembali mati (`Size = 0`).

## Cleanup & Batas QA Tersisa
- Fixture `FlyHighHUDMotionQA` dibersihkan lewat `Destroy()`; Studio dikembalikan ke mode `Edit`, `leftoverBlur = 0`, `leftoverAudio = 0`.
- **Belum diuji pada sesi ini**: tampilan viewport Phone/Tablet di Device Emulator maupun perangkat fisik iOS/Android, ketukan sentuh fisik langsung pada tombol dock/penerbangan, serta rekaman screenshot tepat pada bingkai aktif toast/fireworks dan akhir puncak Istana Awan.
