# QA & Audit Perbaikan Notifikasi Ping Taktis (13 November 2026)

## 1. Identitas Build & Repository

- **Tanggal Verifikasi**: 13 November 2026 (`23:57:36 +07:00` simpan `.rbxl`, `23:58:38 +07:00` audit hash & status repo)
- **Git `HEAD`**: `f5aa15d`
- **Status Working Tree**: Belum commit dan belum push.
  - Modified (`M`): `Fly High.rbxl`, `HANDOVER.md`, `PROGRESS.md`, `design/features/hud-motion/design.md`, `audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau`, `audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDMotion.luau`, `audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau`, `audit/sources/ServerScriptService/FlyHighServer/TetherManager.luau`, `audit/sources/StarterPlayer/StarterPlayerScripts/FlightHUDController.luau`, `audit/sources/StarterPlayer/StarterPlayerScripts/ShopClientController.luau`, `audit/sources/StarterPlayer/StarterPlayerScripts/WeaponClientController.luau`, `audit/sources/StarterPlayer/StarterPlayerScripts/WorldUISkins.luau`
  - Untracked (`??`): `audit/Fly High.before-arcade-refine.rbxl`, `audit/hud-motion-upgrade-2026-11-13/`, `audit/hud-text-tidy-2026-11-13/`, `audit/tactical-ping-fix-2026-11-13/`
- **Simpan Place (`save_place`)**: `E:/Antigravity/Fly High/Fly High.rbxl` (`1.739.663` B, `LastWriteTime=2026-11-13T23:57:36.7261143+07:00`, SHA-256 `24ACB3F35089D83E57B32D5D0E77BDE21D5E6BE2AF079F40F1FDF1BC8F501419`).
  - *Batas verifikasi*: File binary `.rbxl` tersimpan di disk, namun belum dibuka ulang di sesi baru untuk memverifikasi isi binary secara terpisah.

## 2. Ringkasan Perubahan Teknis

1. **Pemisahan `QuickPing` (kru hidup via `TacticalPingWheel`)**:
   - Menampilkan banner HUD 2D Sky Adventure (`CrewPingBanner`) di bawah `AltimeterFrame` (`FlightHUDController`, `HUDTheme`, `HUDLayout`, `HUDMotion`) serta memutar SFX `ping` yang halus.
   - Menghapus bola kuning neon 3D dan `BillboardGui` 3D di atas karakter agar tidak merusak visibilitas dek maupun `OverheadGui`.
   - Menambahkan guard tata letak di `HUDLayout.luau` (`if portrait and pingY + pingH > warningY + 64`) agar `CrewPingBanner` tidak bertabrakan dengan tombol dock kiri.
2. **Pemolesan `GhostSpot` (bahaya dari `Ghost Spotter`) + Indikator Panah Arah**:
   - Server menolak forged `GhostSpot` dari pemain hidup dan hanya mengizinkannya saat `FlightGhost=true` (`TetherManager.luau`).
   - Mempertahankan penanda 3D sementara (`3.5` dtk) berupa bola coral-amber tembus pandang + `SelectionSphere` dan `GhostSpotBillboard` yang diperkeras (`AlwaysOnTop=true`, `LightInfluence=0`, `ZIndexBehavior=Enum.ZIndexBehavior.Global`, `ResetOnSpawn=false`, `ClipsDescendants=false`, `StudsOffset=0, 2.5, 0`, `MaxDistance=420`, `CardZ=1`, `BadgeZ=2`, `IconZ=3`), disertai banner peringatan merah (`3.8` dtk) + SFX `pingGhost`.
   - Menambahkan `GhostSpotArrows` & `arrowPool` di `WeaponClientController.luau` beserta solver penghindar HUD/tumpukan (`HUD_BLOCKER_NAMES`, `MODAL_BLOCKER_NAMES`, `collectArrowBlockers`, `arrowIntersectsBox`, `resolveArrowPosition`) agar panah indikator target di luar layar menyusuri tepi aman tanpa menutupi `GasButton`, `AutoGasButton`, dock kiri, banner HUD, maupun sesama panah (`62px+`), dan otomatis bersembunyi saat modal terpusat (`TacticalPingWheel`, `ShopModal`, `WeaponSettingsModal`, `HUDModalScrim`) aktif.

## 3. Parity Source Studio <-> Mirror & Kompilasi (`loadstring`)

Diverifikasi 7/7 identik byte-per-byte antara `Edit` DataModel Studio dan `audit/sources/` (dicek ulang pasca-Playtest pada `23:57:15`, `StrayFixtures=[]`), dengan status kompilasi `compile=OK`:

| Instance Studio | Mirror Lokal | Ukuran (B) | Adler-32 | SHA-256 | Compile |
| --- | --- | ---: | --- | --- | --- |
| `ServerScriptService.FlyHighServer.TetherManager` | `audit/sources/ServerScriptService/FlyHighServer/TetherManager.luau` | 23.619 | `F69990A9` | `5999B512D12CED5797609F887A7F84AC4B585C12F090DABDE6B53FDB3196D84A` | `OK` |
| `StarterPlayer.StarterPlayerScripts.WorldUISkins` | `audit/sources/StarterPlayer/StarterPlayerScripts/WorldUISkins.luau` | 6.023 | `7FDFB0AC` | `768B8718771D2968CAF63CD8E552130AE292F8E88823DD6D6CA91B0487B03FA0` | `OK` |
| `StarterPlayer.StarterPlayerScripts.FlightHUDController` | `audit/sources/StarterPlayer/StarterPlayerScripts/FlightHUDController.luau` | 24.206 | `DFEE0142` | `E1066626AB2C0D26ADD37314092C21174B1821AB8D9A10EA8F00F2A21F94F9B9` | `OK` |
| `ReplicatedStorage.FlyHigh.Modules.HUDLayout` | `audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau` | 19.425 | `876DC997` | `6CBCF5B0FE6B972E8D0C45E06907CC8322F3A761BEA5E711C863E45BBF7A0536` | `OK` |
| `ReplicatedStorage.FlyHigh.Modules.HUDTheme` | `audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau` | 57.121 | `82BD65B1` | `F9C77B3DD4200D19BB366555A526AF1F9E8B3F8D6FA0135FAC7E643CDB3F3F3C` | `OK` |
| `ReplicatedStorage.FlyHigh.Modules.HUDMotion` | `audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDMotion.luau` | 53.325 | `990F0EE3` | `7FB79E8F8D5D7BBF7F98CCCD267E869DB4D0201B95D0A1D1523D9BABB60353D8` | `OK` |
| `StarterPlayer.StarterPlayerScripts.WeaponClientController` | `audit/sources/StarterPlayer/StarterPlayerScripts/WeaponClientController.luau` | 43.679 | `AE926F7C` | `0AB0E4E0BB59ABBA6E91C594AF787D71D0BBEB73E696992AE05D7843AE41F632` | `OK` |

## 4. Hasil Verifikasi Playtest & Bukti

Semua uji di bawah ini dijalankan **pasca-edit akhir** (`WeaponClientController` `43.679` B / `AE926F7C`) dalam lingkungan Roblox Studio Play Solo (`2090x694`), kecuali butir yang diberi keterangan khusus pra-penambahan solver panah.

- **Log Konsol (`get_console_output`)**: Bebas error dan warning dari skrip game (`[DataManager] Unpublished Studio: isolated mock data; checkout disabled.` dan log reset kamera Studio Assistant ke `Custom` berasal dari sistem Studio/harness).
- **`QuickPing` & Anti-Spam Banner (`CrewPingBanner`)**:
  - Klik `PingButton` membuka `TacticalPingWheel` (`WheelVis=true`, `Ping1='Gas Api Sekarang!'`, `fits=true`).
  - Klik `Ping1` menutup wheel (`Wheel=false`), memunculkan `CrewPingBanner` (`kind=quick`, `sender='KRU • Ajooes'` `fits=true`, `msg='Fokus Tembak Rintangan!'` `fits=true` saat re-ping, `OH=true`, `Markers3D=0`), serta memutar SFX `ping` (`sfx=true`).
  - Re-ping cepat pada `2.35` dtk mereset expiry (`seq=5 -> 6`, `dt=+5.65`, `vis=true`, `closing=false`), bertahan melewati expiry ping pertama (`PastP1(true)=true`), dan menutup otomatis sesuai durasi baru (`PastP2(false)=false`).
  - Screenshot: [qa_final_quick_ping_desktop.jpg](qa_final_quick_ping_desktop.jpg).
- **`GhostSpotArrows` — Penghindaran `GasButton` & Penumpukan Tepi Sama**:
  - Fixture dua target di sudut kanan-bawah belakang kamera menghasilkan `SameEdgeSnap=A1=(2028,518 '116m') A2=(1964,518 '120m') dY=0.0 dist=63.0 overlaps=[]`, jelas berada di atas area `GasButton` / `AutoGasButton`.
  - Screenshot: [qa_final_arrows_clear_gas_desktop.jpg](qa_final_arrows_clear_gas_desktop.jpg).
- **`GhostSpotArrows` — Simetri Kiri/Kanan & Jarak Aman Dock Kiri**:
  - Fixture target kiri dan kanan di belakang kamera menghasilkan `Opp=[dY=0.0 A1=(89,325 rot=-90.0 '99m' icon=true) A2=(2030,325 rot=90.0 '116m' icon=true)]`; badge sisi kiri (`x=89`) bersih di kanan dock (`Setelan`) tanpa menumpuk.
  - Screenshot: [qa_final_arrows_opposite_desktop.jpg](qa_final_arrows_opposite_desktop.jpg).
- **`GhostSpot` Guard Hidup, Snap Rintangan, Pelacakan, `pingGhost` & `GhostSpotBillboard`**:
  - Pemain hidup ditolak (`gfAlive=false`, `aliveMarkers=0`).
  - Saat `FlightGhost=true` lewat `SpotHazardButton`: `gfGhost=true`, snap ke fixture `_QASpotTestObsA` (`dist=74.66`); uji arah `+X` mengembalikan `dist=152.53 <= 250`.
  - SFX `pingGhostPlayed=true`; menggeser `_QASpotTestObsA` sebesar `(12,4,0)` diikuti penanda (`shift=12.65`, `err=0.000`).
  - Atribut `GhostSpotBillboard` pasca-edit akhir: `AlwaysOnTop=true`, `LightInfluence=0`, `ZIndexBehavior=Enum.ZIndexBehavior.Global`, `ResetOnSpawn=false`, `ClipsDescendants=false`, `StudsOffset=0, 2.5, 0`, `MaxDistance=420`, `SelectionSphere=true`, `CardZ=1`, `BadgeZ=2`, `IconZ=3`.
  - *Catatan referensi pra-solver panah (`23:37..23:41`, sebelum penambahan `resolveArrowPosition` yang tidak mengubah `spotTargetPosition()` maupun isi `GhostSpotBillboard`)*: uji clamp tembok `400` stud `_QAFarWall` tercatat `distFromBalloon=238.05`; pemeriksaan `GhostSpotBillboard` in-frustum tercatat `Title='BAHAYA • 66m' (fits=true)`, `Sub='Spot: TesterArwah' (fits=true)`, `IconLoaded=true` (pada run pasca-edit akhir posisi off-screen/frame-0 mencatat `TextFits=false`/`IconLoad=false` karena frustum culling/deferral frame-0). Foto referensi visual penanda 3D + banner merah `ARWAH • TesterArwah`: [qa_pre_arrow_solver_ghost_marker.jpg](qa_pre_arrow_solver_ghost_marker.jpg).
- **Uji Responsif Multi-Viewport (`ViewportAudit`)**:
  - Harness simulasi di Client Playtest menguji salinan off-screen `CrewPingBanner` serta logika `HUDLayout` & `resolveArrowPosition` pada `Desktop_1066x536`, `Tablet_iPad_1024x711`, `Phone_Land_749x381`, dan `Phone_Port_390x700` × 2 `textBoost` (`0`, `3`/`6`) × 3 state (`Clean`, `Alert`, `Toast`) × 4 proyeksi panah (`BottomRight` + tumpukan, `LeftDock`, `TopCenter`): **`120` lulus, `0` gagal**.

## 5. Batasan QA & Status Pembersihan

- **Batasan yang belum teruji**:
  - Pengujian phone/tablet dijalankan lewat harness simulasi Client di Desktop Studio (`2090x694`), bukan pada perangkat iPad/ponsel fisik.
  - Mode Play Solo mengakhiri penerbangan saat kru habis (`alive == 0` -> `EndFlight`), sehingga alur multi-pemain `Ghost` hidup vs kru hidup belum diuji pada 2+ client bersamaan.
  - Tool `screen_capture` Studio MCP tidak men-capture elemen `BillboardGui`.
  - File binary `Fly High.rbxl` sudah disimpan, namun belum dibuka ulang secara terpisah.
- **Pembersihan pasca-Playtest**:
  - Fixture uji (`_QASpotTestObsA`, `_QAFarWall`, serta atribut sementara `_QA*`) sudah dihapus; Playtest dihentikan dan Studio kembali terverifikasi di mode **`Edit`** dengan `StrayFixtures=[]`.
