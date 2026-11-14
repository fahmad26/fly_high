# Laporan QA Bugfix Spawn Balon Dermaga, Modal Click & Scrim Topbar — 14 November 2026

- **Tanggal:** 14 November 2026 (Asia/Jakarta)
- **Build / Basis:** `HEAD` `f5aa15d` (lokal belum commit/push), Studio ID `eec13bfa-b2e6-4b11-83a9-d00c8edf4b4d`, `Fly High.rbxl` (`1.740.013` B, SHA-256 `A4364004F400DC2766E28C6557822A65E810A290BD8639D8FD2A024DA08BA437`, tersimpan lokal via `save_place`).
- **Lingkungan Uji:** Roblox Studio Desktop Play Solo (`View=(2090, 752)`, safe area `GuiAbs=(2090, 694)`, `GetGuiInset()=(0, 58 | 0, 0)`), 1 pemain (`Fikki2621`), tanpa fixture test eksternal tersisa sesudah Stop.

## 1. Ringkasan Akar Masalah & Perubahan

1. **Bug 1 — Balon udara spawn di atas papan dermaga (`Console`) dan miring (`TiltDeg=6.04°`)**
   - **Akar masalah:** `PodManager` hanya meneruskan `data.pad.Position` (`Vector3`), sehingga orientasi `FloorPad.CFrame` hilang; `FlightSpace.SpawnPosition` lalu selalu mengurangi sumbu dunia `-Z` (`pad.Z - 18`). Pada dermaga samping seperti `Pod_E`, `Console` berada tepat di sisi `-Z`, menyebabkan `BasketFloor` (`28×1.2×28`) tumpang-tindih dengan `Console` (`TopY=16.17`) dan terangkat miring; `Boulder_7` (`Pod_E`) dan `Boulder_1` (`Pod_A`) juga berada terlalu tinggi di jalur depan dermaga.
   - **Perbaikan:**
     - `ServerScriptService/FlyHighServer/FlightSpace.luau`: mengganti offset `-Z` tetap dengan proyeksi `SPAWN_FORWARD_DISTANCE = 28` stud searah vektor datar `FloorPad.CFrame.LookVector` lewat `resolvePadCFrame(origin, podName)` (mendukung `BasePart`, `CFrame`, serta `Vector3` + lookup `MatchmakingPods`), ter-clamp `Config.CORRIDOR_CENTER_LIMIT` (`120`).
     - `ServerScriptService/FlyHighServer/PodManager.luau` & `BalloonManager.luau`: meneruskan `data.pad` (`FloorPad`) dan `podName` ke `Space.SpawnPosition` pada pengecekan `blocked` maupun `LaunchBalloon`.
     - Workspace (`Fly High.rbxl`): menurunkan `IslandNature.Rocks.Boulder_1` (`center=(-106.00, 9.94, 5.00)`, `topY=11.25`) dan `Boulder_7` (`center=(107.00, 9.74, 2.00)`, `topY=11.20`) agar memberi ruang aman di bawah dasar `BasketFloor` (`11.90`).

2. **Bug 2 — Popup tertutup saat klik area mana pun selain tombol**
   - **Akar masalah:** `HUDLayout.luau` memasang `scrim.Activated` untuk menutup `ShopModal`, `TacticalPingWheel`, dan `WeaponSettingsModal`, sementara container modal (`ShopModal`, `Card1`, `Card2`, `WeaponSettingsModal`) memiliki `Active = false` sehingga klik pada teks/area non-tombol di dalam popup tembus ke `HUDModalScrim` dan menutup popup.
   - **Perbaikan:**
     - `ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau`: menghapus handler penutup pada `scrim.Activated`, mematikan `scrim.AutoButtonColor = false` & `scrim.Selectable = false`, serta memastikan `SettingsCloseButton.ZIndex = 25`.
     - `StarterPlayer/StarterPlayerScripts/ShopClientController.luau`: menetapkan `Active = true` pada `shopModal`, `card1`, `card2`, dan `settings` agar klik non-tombol di dalam popup terserap (`gameProcessedEvent = true`) dan tidak menutup popup maupun memicu aksi dunia/senjata.

3. **Bug 3 — Overlay abu-abu tidak menutupi area atas layar (topbar inset)**
   - **Akar masalah:** `HUDLayout.luau` memakai `ScreenInsets.CoreUISafeInsets` (area `0..58px` atas berada di luar `FlyHighHUD`) namun hanya menambah offset topbar saat `TacticalPingWheel` aktif dan tidak konsisten pada `ShopModal`/`WeaponSettingsModal`; selain itu perubahan `BackgroundTransparency` (`1` ↔ `0.35`) dapat bercampur dengan cache opacity awal di `HUDMotion`.
   - **Perbaikan:**
     - `ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau`: menyetel `gui.ClipToDeviceSafeArea = false`, menambah helper `syncScrimBounds(w, h)` berbasis `GuiService:GetGuiInset()` dan selisih `CurrentCamera.ViewportSize` (dijalankan saat inisialisasi maupun tiap tick layout), mempertahankan `scrim.BackgroundTransparency = 0.35` dengan `scrimImage.Visible = false` agar konsisten untuk ketiga modal (`ShopModal`, `WeaponSettingsModal`, `TacticalPingWheel`).

## 2. Paritas Source & Kompilasi

Seluruh 5 file yang berubah diverifikasi identik byte-per-byte antara Studio (`Edit`) dan mirror `audit/sources/` pasca-normalisasi trailing newline dan lolos `loadstring`:

| File | Ukuran (B) | Adler-32 | SHA-256 (`audit/sources/`) | `loadstring` |
| --- | ---: | --- | --- | --- |
| `audit/sources/ServerScriptService/FlyHighServer/FlightSpace.luau` | 3.425 | `0x8BFC8EB2` | `EDDF70E582D4C81ACC7752846CAB066071C7843EDC0D73FDEB64D6B6061340AD` | `true` |
| `audit/sources/ServerScriptService/FlyHighServer/PodManager.luau` | 5.438 | `0x6A244252` | `63DA36101619CBDF42F45D34F6A2358B49F61D1A48EB1EACC533166F55B7D1D5` | `true` |
| `audit/sources/ServerScriptService/FlyHighServer/BalloonManager.luau` | 21.007 | `0xC59E7A46` | `2C3DB131E53A91AA5973F2606335A1D6CF00D334713B1912B9A58960EC9AC326` | `true` |
| `audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau` | 19.697 | `0x6D791B16` | `6174AD19F3A0793F5ED4DB6C6F789B3CF223F29B28A482122EE7F9F1BAF9E593` | `true` |
| `audit/sources/StarterPlayer/StarterPlayerScripts/ShopClientController.luau` | 18.578 | `0xD016A316` | `00795CFC0451423A98B9E9E72367B046E5F2A512C88000F4DEB48BAAC86F72A9` | `true` |

## 3. Hasil Verifikasi & Bukti Tersimpan

### Sebelum Perbaikan (Baseline Repro)
- **Bug 1 (`Pod_E`):** `RootPos=(90.36, 15.71, -3.42)`, `TiltDeg=6.04°`, `BasketFloor` menyentuh `Pod_E.Console` → [repro_podE_balloon_tilt.jpg](repro_podE_balloon_tilt.jpg).
- **Bug 2 (`ShopModal` & `WeaponSettingsModal`):** klik `ModalTitle` menutup `ShopModal`; klik `InventoryCount` menutup `WeaponSettingsModal`.
- **Bug 3 (`ShopModal`):** `ScrimAbsPos=(0,0)`, `ScrimAbsSize=(2090,694)`, area topbar `0..58px` biru terang tak tertutup overlay → [repro_shop_top_inset_uncovered.jpg](repro_shop_top_inset_uncovered.jpg).

### Sesudah Perbaikan (Playtest Final + Cek Edit Geometri)
- **Visual Batu Bank (`Edit`):**
  - `Boulder_7` (`topY=11.20`): [edit_podE_boulder7_post_adjust.jpg](edit_podE_boulder7_post_adjust.jpg)
  - `Boulder_1` (`topY=11.25`): [edit_podA_boulder1_post_adjust.jpg](edit_podA_boulder1_post_adjust.jpg)
- **Spawn Balon Dermaga:**
  - `Pod_E` (live Playtest, tahan `E`): `RootPos=(117.33, 12.50, 8.93)`, `FloorPos=(117.33, 12.50, 8.93)`, `FloorSize=(28.00, 1.20, 28.00)`, `TiltDeg=0.0000°`, `TouchAndOverlap=[]` → [qa_final_podE_balloon_level.jpg](qa_final_podE_balloon_level.jpg).
  - `Pod_A` (live Playtest, tahan `E`): `RootPos=(-117.33, 12.50, 8.93)`, `TiltDeg=0.0000°`, `TouchAndOverlap=[]`.
  - `Pod_D` (live Playtest, tahan `E`): `RootPos=(80.59, 12.50, -70.92)`, `TiltDeg=0.0000°`, `TouchAndOverlap=[]`.
  - `Pod_B` & `Pod_C` (sapuan geometri `Edit` memakai `FlightSpace.SpawnPosition`): `(-80.59, 12.50, -70.92)` & `(0.00, 12.50, -103.00)`, jarak pusat ke `Console` `34.58` stud, titik tertinggi di bawah footprint `10.28` (`TimberDeck`) & `10.00` (`Terrain`), selisih `1.62` & `1.90` stud di bawah dasar `BasketFloor` (`11.90`).
- **Scrim & Klik Non-Tombol Pada Semua Modal:**
  - `ShopModal` → `Scrim`: `AbsPos=(0, -58)`, `AbsSize=(2090, 752)`, `BgT=0.35`; klik `ModalTitle`, `Card1.ProductDescription`, scrim `(450,350)`, `(1650,350)`, dan area topbar `(1000,30)` mempertahankan `ShopVis=true`; uji ulang sambil memegang `Pistol` mencatat `gpe=true` di semua 5 titik klik (`toolAct=0`); `CloseButton` menutup bersih (`ShopVis=false`, `ScrimVis=false`) → [qa_final_shop_scrim_full.jpg](qa_final_shop_scrim_full.jpg).
  - `WeaponSettingsModal` → `Scrim`: `AbsPos=(0, -58)`, `AbsSize=(2090, 752)`, `BgT=0.35`, `CloseZ=25`; klik `Title`, `InventoryCount`, `LaunchNote`, dan scrim `(450,350)`, `(1650,350)`, `(1000,30)` mempertahankan `SetVis=true`; klik `ReduceMotionToggle` mengubah `"Animasi: Penuh"` ↔ `"Animasi: Ringan"`; `SettingsCloseButton` menutup bersih → [qa_final_settings_scrim_full.jpg](qa_final_settings_scrim_full.jpg).
  - `TacticalPingWheel` (diuji sesudah siklus buka-tutup Toko & Setelan): `Scrim` tetap `AbsPos=(0, -58)`, `AbsSize=(2090, 752)`, `BgT=0.35`; klik `PingTitle` dan scrim luar mempertahankan `PingVis=true`; `PingCloseButton` menutup bersih → [qa_final_ping_scrim_full_after_shop.jpg](qa_final_ping_scrim_full_after_shop.jpg).
- **Konsol & Pemulihan:** `get_console_output` bebas error/warning script game (hanya pesan unpublished mock DataStore dan satu error typo `getgenv()` dari skrip uji `AssistantCommand`). Studio dipulihkan ke mode `Edit` default satu pemain dan disimpan ke `Fly High.rbxl`.

## 4. Batas QA Tersisa

- `Pod_B` dan `Pod_C` baru diverifikasi lewat sapuan geometri `Edit`, belum di-spawn satu per satu dalam Playtest.
- Uji UI dijalankan pada Studio Desktop (`2090×752`, `TopInset=(0,58)`, `BottomInset=(0,0)`); perangkat fisik ponsel/tablet ber-notch asimetris (landscape side inset) belum diuji di perangkat nyata.
- Binary `Fly High.rbxl` sudah disimpan lokal, namun belum dibuka ulang dari disk dan perubahan belum di-commit atau di-push ke remote.
