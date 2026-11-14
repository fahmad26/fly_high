# QA Perbaikan Sudut Keranjang PalaceLantern & Jarak Display Balon Dermaga (14 November 2026)

## Identitas & Build
- **Tanggal**: 14 November 2026 (Asia/Jakarta)
- **Commit dasar**: `f5aa15d` (belum commit / belum push; working tree berisi perubahan sesi ini dan perubahan sebelumnya yang belum di-commit)
- **File place lokal**: `Fly High.rbxl` (`1.738.390` B, SHA-256 `5EFBEC28CA397D32B2B8EC5B69A9E154037E5D8888A1EC8C0A1BEED65ED150A8` via `save_place`); binary `.rbxl` belum dibuka ulang dari disk
- **Perubahan script Luau pada tugas ini**: `0` file (0 perubahan kode; `StarterPlayer.StarterPlayerScripts.BalloonFleetAnimator` otomatis membaca atribut `CFrame` `PreviewBase` pada setiap `PreviewBalloon`)

## Lingkungan & Fixture
- **Lingkungan**: Roblox Studio lokal (`Fly High.rbxl`, Studio ID `2aa6cbef-a4c5-43f8-a312-6b3f42eedd2d`), mode `Edit` dan dua sesi `Play Solo`
- **Fixture**: 1 pemain (`Fikki2621`), viewport desktop Studio standar; inspeksi `Edit` dilakukan pada ke-6 template armada di `ReplicatedStorage.FlyHigh.Templates.BalloonVariants` dan ke-5 `PreviewBalloon` di `Workspace.FlyHighLobby.MatchmakingPods.Pod_A..Pod_E`

## Masalah & Perubahan yang Diterapkan

### 1. Empat Objek Aneh di Sambungan Keranjang–Balon (`UpturnedEave`)
- **Temuan**: Audit atas 6 template dan 5 `PreviewBalloon` menemukan bahwa `CornerWedgePart` bernama `UpturnedEave` (4 buah per model) hanya terdapat di:
  - `ReplicatedStorage.FlyHigh.Templates.BalloonVariants.PalaceLantern.GondolaDecor` (`4` bagian, ukuran `4.80 × 1.30 × 4.80`, posisi relatif `(±12.00, 9.00, ±12.00)`)
  - `Workspace.FlyHighLobby.MatchmakingPods.Pod_E.DockDecor.PreviewBalloon.GondolaDecor` (`4` bagian, ukuran `0.50 × 0.14 × 0.50`, posisi relatif `(±1.26, 0.94, ±1.26)`)
  - Keempat `CornerWedgePart` tersebut mencuat secara horizontal ke dalam dan keluar melintasi 4 sudut atas keranjang di sambungan tiang/kornis/tali (`WORLD-04`).
- **Perbaikan**: Menghapus seluruh `UpturnedEave` (`4` pada template `PalaceLantern`, `4` pada `Pod_E.PreviewBalloon`) sambil mempertahankan `PavilionCornice`, `SupportPole1..4`, `MastFerrule`, `PavilionPost`, `LanternTassel`, dan `Motor6D` `Visual_Tassel`.
- **Verifikasi sisa objek**: `TemplateEaves=0` dan `PreviewEaves=0` di seluruh 6 template & 5 `PreviewBalloon`.

### 2. Pemindahan Display Balon Dermaga Lebih Dekat (`GAME-01`)
- **Kondisi awal**: Seluruh `PreviewPedestal` + `PreviewPedestalCap` + `PreviewBalloon` di `Pod_A..Pod_E` terletak di koordinat lokal dermaga `(+22.50, y, +7.20)` (`dist = 23.62` stud dari pusat dermaga, `gapFromDockRim = 8.92` stud).
- **Perbaikan posisi (rumput datar sisi kanan-depan dermaga, `gY=10.00`, `PreviewPedestal` `y=10.25`, `PreviewPedestalCap` `y=10.65`, plus pembaruan atribut `CFrame` `PreviewBase`)**:
  - `Pod_A` (`DawnExplorer`, yaw `77.5°`): lokal `(19.0, 4.0)`, `dist = 19.42`, `rimClr = 4.72`, `capClr14.2 = 0.98`, `pbDiff = 0.0000`, `obs = 0`
  - `Pod_B` (`FloatingGarden`, yaw `37.3°`): lokal `(16.0, 8.5)`, `dist = 18.12`, `rimClr = 3.42`, `capClr14.2 = 1.18`, `pbDiff = 0.0000`, `obs = 0`
  - `Pod_C` (`SkyKoi`, yaw `0.0°`): lokal `(17.7, 6.5)`, `dist = 18.86`, `rimClr = 4.16`, `capClr14.2 = 1.00`, `pbDiff = 0.0000`, `obs = 0`
  - `Pod_D` (`SaturnVoyager`, yaw `-37.3°`): lokal `(15.5, 10.5)`, `dist = 18.72`, `rimClr = 4.02`, `capClr14.2 = 1.04`, `pbDiff = 0.0000`, `obs = 0`
  - `Pod_E` (`PalaceLantern`, yaw `-77.5°`): lokal `(17.0, 6.0)`, `dist = 18.03`, `rimClr = 3.33`, `capClr14.2 = 1.20`, `pbDiff = 0.0000`, `obs = 0`
- **Pembersihan vegetasi penghalang (`IslandNature`, `CanQuery=false`)**:
  - Menggeser 3 tanaman keluar ke rumput terbuka: `Fern_28` (`dist = 5.80`, `y = 10.04`), `Fern_29` (`dist = 6.40`, `y = 10.11`), dan `Flower_8_3` (`dist = 4.80`, `y = 9.96`), sehingga `Intruding<4.0 = 0` pada seluruh 5 pedestal.

## Skenario & Hasil Aktual

| Skenario | Hasil Aktual |
| --- | --- |
| Inspeksi Edit 6 template & 5 preview (`Pod_A..Pod_E`) | `TemplateEaves=0`, `PreviewEaves=0`, `pbDiff=0.0000` di ke-5 pod, `obs=0`, `Intruding<4.0 = 0`. Seluruh screenshot sebelum/sesudah terverifikasi bersih. |
| Playtest Run 1 — `Pod_E` (`PalaceLantern`) | Client: ke-5 `PreviewBalloon` terpusat (`xzErr=0.0000`), `Pod_E` bobbing vertikal `p1y=11.3956 -> p2y=11.2979` (`PreviewYDelta=0.0939` awal / `0.0977` lanjutan; `rotDot=1.0000`). Launch via `StartPrompt`: `Balloon_Fikki2621` muncul (`inBasket=true`), Server: `Theme=E`, `TiltDeg=0.0000`, `Eaves=0`, `BalloonWorldOv=0[]`, `CapGap=1.40`, `RootY=12.50`. Konsol: hanya `[DataManager] Unpublished Studio...` & camera reset notice (`0` error/warning gameplay). |
| Playtest Run 2 — `Pod_A` (`DawnExplorer`, clearance cap terkecil `0.98`) | Launch via `StartPrompt`: `Balloon_Fikki2621` muncul (`inBasket=true`), `PreA yDelta=0.0278`. Server: `Theme=A`, `TiltDeg=0.0000`, `BalloonWorldOv=0[]`, `CapGap=1.08`, `RootY=12.50`. Konsol bersih dari error gameplay. |

## Bukti Tersimpan
- Sebelum (`Edit`):
  - [before_podE_preview.jpg](before_podE_preview.jpg) — closeup `PreviewBalloon` `Pod_E` dengan 4 `UpturnedEave`
  - [before_podC_dock.jpg](before_podC_dock.jpg) — posisi awal display `Pod_C` di `(22.5, 7.2)`
- Sesudah (`Edit`):
  - [after_podA_dock.jpg](after_podA_dock.jpg)
  - [after_podB_dock.jpg](after_podB_dock.jpg)
  - [after_podC_dock.jpg](after_podC_dock.jpg)
  - [after_podD_dock.jpg](after_podD_dock.jpg)
  - [after_podE_dock.jpg](after_podE_dock.jpg)
  - [after_podE_preview_closeup.jpg](after_podE_preview_closeup.jpg) — `PreviewBalloon` `Pod_E` tanpa `UpturnedEave`
- Sesudah (`Playtest` Play Solo):
  - [playtest_podE_palace_ext.jpg](playtest_podE_palace_ext.jpg) — eksterior sudut atas `PalaceLantern` bersih
  - [playtest_podE_palace_front.jpg](playtest_podE_palace_front.jpg) — balon `PalaceLantern` melampaui pedestal/preview baru tanpa tabrakan
  - [playtest_podA_ext.jpg](playtest_podA_ext.jpg) — balon `Pod_A` (`DawnExplorer`) jernih melewati pedestal/preview baru

## Batas QA
1. Peluncuran live `Play Solo` pada iterasi ini hanya menguji `Pod_E` (`PalaceLantern`) dan `Pod_A` (`DawnExplorer`); clearance spawn runtime `Pod_B`, `Pod_C`, dan `Pod_D` (`capClr14.2 = 1.00–1.18`) disimpulkan dari kesesuaian geometri & pengecekan posisi preview `xzErr=0.0000`, bukan uji spawn live terpisah setelah relokasi pedestal.
2. Pada jendela pengukuran Playtest `Pod_E`, `rotDot=1.0000` sehingga perubahan sudut yaw `PreviewBalloon` tidak teramati dalam sampel tersebut (hanya gerak naik-turun `PreviewYDelta` dan `xzErr=0.0000` yang terukur berubah).
3. Fixture 1 pemain di desktop Studio; belum diuji multi-klien (2–3 pemain), viewport phone/tablet, maupun pembukaan ulang binary `Fly High.rbxl` pasca-`save_place`.
4. Belum di-commit maupun di-push ke git remote.

## Cleanup
- `start_stop_play(is_start=false)` selesai -> Studio kembali ke mode `Edit`.
- Verifikasi akhir sebelum simpan: `LingeringBalloons=0`, `TemplateEaves=0`, `PreviewEaves=0`, kelima pod terkonfirmasi pada koordinat baru (`pb=0.0000`), kamera Edit dipulihkan ke `(0,48,25)->(0,12,-55)`, lalu `save_place` menyimpan ke `Fly High.rbxl`.
