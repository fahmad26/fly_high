# QA Perbaikan HUD Atas, Pil `10.000 km`, dan Border Card Toko (iPad & Multi-Viewport) — 15 November 2026

## Ringkasan Masalah & Perbaikan

Menindaklanjuti temuan uji coba di iPad:

1. **Spasi vertikal teks HUD atas (`AltimeterFrame` — `"LANGIT CERAH"` & `"Zona 1 · Target Istana Awan"`):**
   - Pada [`HUDTheme.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau), posisi dua baris teks diperapat ke titik tengah vertikal kapsul `58 px`: `titleY = centerY - 6 - textBoost / 2`, `detailY = centerY + 8 + textBoost / 2`, `titleH = 18 + textBoost`, `detailH = 12 + textBoost`, `TextYAlignment = Enum.TextYAlignment.Center`, serta `TextSize` judul `narrow and 15 or 18`.
2. **Overflow pil kanan atas (`ServerAltitudeTracker` — `"10.000 km"`):**
   - Pada [`HUDAltitudeTracker.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDAltitudeTracker.luau) dan [`HUDLayout.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau), lebar `TopGoalPill` diperbesar menjadi `(compact and 84 or 94) + textBoost * 2` (`BottomLocalPill` menjadi `(compact and 80 or 90) + textBoost * 2`, `pillHalfW = (compact or portrait) and (43 + textBoost) or (48 + textBoost)`), serta label pil diberi inset horizontal (`Size = UDim2.new(1, -12, 1, -2)` untuk `TopGoalPill`, `UDim2.new(1, -10, 1, -2)` untuk `BottomLocalPill`), `AnchorPoint(0.5, 0.5)`, `TextScaled = true`, `TextWrapped = false`, dan `UITextSizeConstraint`.
3. **Border card terpotong di `ShopModal` (Tab `ROBUX`, `PERBEKALAN`, `KOSMETIK`):**
   - Menambahkan inset kontainer `4 px` pada `RobuxScroll` ([`HUDLayout.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau): `strokeInset = 4`, `availW = innerW - 8`, `availH = cardAreaH - 8`, `CanvasSize` `+8`, `ScrollBarThickness = needScroll and 5 or 0`), `SuppliesContainer` (`inset = 4` di `layoutSupplies()`) & `CosmeticsScroll` ([`ShopTabsController.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/ShopTabsController.luau): `cosPad` `Left=4, Right=10, Top=4, Bottom=6`), meningkatkan `UIStroke` border ke bilangan bulat `2 px` (`Transparency = 0.14`) di [`HUDTheme.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau) & [`ShopTabsController.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/ShopTabsController.luau), serta menyelaraskan `cardCorner` radius ke `15 px` di [`ShopClientController.luau`](../sources/StarterPlayer/StarterPlayerScripts/ShopClientController.luau).

## Parity & Kompilasi (`52/52` Script)

Diverifikasi via `ScriptEditorService:GetEditorSource` + `loadstring` di `Edit` mode Roblox Studio terhadap [`audit/sources/`](../sources/): **`52/52` sama persis (`mismatches = 0`, `compileErrorCount = 0`)**.

| Script | Norm `len` | Norm `djb` | File Size (Disk) | File SHA-256 (Disk Raw) |
| --- | ---: | --- | ---: | --- |
| [`HUDTheme.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau) | `84.378` | `8de898eb` | `84.379` B | `5417ac30016238a77d5e1f909b6c8e72e6fc22d010e159d2205eb5f04185d0f7` |
| [`HUDLayout.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau) | `39.276` | `5b9f8092` | `39.277` B | `0b9dd3eafb44404204f5eacf4a172898def65000c3adf8d9f57066f02a226c5a` |
| [`HUDAltitudeTracker.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDAltitudeTracker.luau) | `32.443` | `8eaa91b2` | `32.444` B | `389bdd2092ff2e459308879f7da76da2d1c066248038827f3ec90dc42eb9dd21` |
| [`ShopTabsController.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/ShopTabsController.luau) | `27.302` | `87f5aa72` | `27.303` B | `d6b5fd0aefe770a5992ff0195795b71a5a28b0571cdf4532eafa23a99d4770b3` |
| [`ShopClientController.luau`](../sources/StarterPlayer/StarterPlayerScripts/ShopClientController.luau) | `20.250` | `18cc17eb` | `20.251` B | `15d7fe893e79ecb294d23636bc3446d520ad8abe393fc1a64e04947f5671b5b4` |

## Hasil QA `Play Solo` (Windows Studio, `1` Klien `Fikki2621`, Fixture `QA_ViewportSize`/`QA_Touch`)

### 1. Flight HUD Atas & Tracker Kanan (`Pod_A` -> `InFlight=true`)

Seluruh `5` konfigurasi viewport lulus (`PASS=true`):

| Viewport Fixture | Kapsul Y (`rY`) | `HUDAltitude` (`tY`, `sz`) | `HUDGoal` (`gY`, `sz`) | Margin Atas/Bawah | `TopGoalPill` (`"10.000 km"`) | `BottomLocalPill` (`"0 km"`) |
| --- | --- | --- | --- | --- | --- | --- |
| `iPad_1024x768` (`QA_Touch=true`) | `8..66` | `22..40` (`15`, `TextFits=true`) | `39..51` (`12`, `TextFits=true`) | `14` / `15` px | `w=94`, `x=912..1006`, `lblW=82`, `bounds=55.0`, `TextFits=true` | `w=90`, `x=914..1004`, `lblW=80`, `bounds=29.0`, `TextFits=true` |
| `iPadPro_1180x820` (`QA_Touch=true`) | `8..66` | `22..40` (`18`, `TextFits=true`) | `39..51` (`12`, `TextFits=true`) | `14` / `15` px | `w=94`, `x=1068..1162`, `lblW=82`, `bounds=55.0`, `TextFits=true` | `w=90`, `x=1070..1160`, `lblW=80`, `bounds=29.0`, `TextFits=true` |
| `PhonePortrait_390x844` (`QA_Touch=true`) | `8..66` | `22..40` (`15`, `TextFits=true`) | `39..51` (`12`, `TextFits=true`) | `14` / `15` px | `w=84`, `x=294..378`, `lblW=72`, `bounds=55.0`, `TextFits=true` | `w=80`, `x=296..376`, `lblW=70`, `bounds=29.0`, `TextFits=true` |
| `PhoneLandscape_844x390` (`QA_Touch=true`) | `8..66` | `22..40` (`15`, `TextFits=true`) | `39..51` (`12`, `TextFits=true`) | `14` / `15` px | `w=84`, `x=748..832`, `lblW=72`, `bounds=46.0`, `TextFits=true` | `w=80`, `x=750..830`, `lblW=70`, `bounds=24.0`, `TextFits=true` |
| `NativeDesktop` (`2090×752`) | `8..66` | `22..40` (`18`, `TextFits=true`) | `39..51` (`12`, `TextFits=true`) | `14` / `15` px | `w=94`, `x=1978..2072`, `lblW=82`, `bounds=55.0`, `TextFits=true` | `w=90`, `x=1980..2070`, `lblW=80`, `bounds=29.0`, `TextFits=true` |

### 2. Border Card `ShopModal` (`ROBUX`, `PERBEKALAN`, `KOSMETIK`)

Seluruh `5` konfigurasi viewport lulus (`PASS=true`, `th=2`, `issues=[]`, termasuk cek scroll posisi atas & dasar pada `RobuxScroll` saat scroll dan `CosmeticsScroll` berdasar `AbsoluteCanvasSize.Y`):

- `iPad_1024x768`: `robux` (`n=4, L=4.0, T=4.0, R=2.7, B=4.0, scr=false`), `perbekalan` (`n=2, L=4.0, T=4.0, R=4.0, B=4.0`), `kosmetik` (`n=7, L=4.0, T=4.0, R=10.0, B=6.0, scr=true`).
- `iPadPro_1180x820`: `robux` (`L=4.0, T=4.0, R=4.0, B=4.0, scr=false`), `perbekalan` (`L=4.0, T=4.0, R=4.0, B=4.0`), `kosmetik` (`L=4.0, T=4.0, R=10.0, B=6.0, scr=true`).
- `PhonePortrait_390x844`: `robux` (`L=4.0, T=4.0, R=14.0, B=4.0, scr=true`), `perbekalan` (`L=4.0, T=4.0, R=4.0, B=4.0`), `kosmetik` (`L=4.0, T=4.0, R=10.0, B=6.0, scr=true`).
- `PhoneLandscape_844x390`: `robux` (`L=4.0, T=4.0, R=14.0, B=4.0, scr=true`), `perbekalan` (`L=4.0, T=4.0, R=4.0, B=4.0`), `kosmetik` (`L=4.0, T=4.0, R=10.0, B=6.0, scr=true`).
- `NativeDesktop`: `robux` (`L=4.0, T=4.0, R=4.0, B=4.0, scr=false`), `perbekalan` (`L=4.0, T=4.0, R=4.0, B=4.0`), `kosmetik` (`L=4.0, T=4.0, R=10.0, B=6.0, scr=true`).

### 3. Screenshot Verifikasi Visual

Catatan: Gambar `01..04` diambil langsung via `screen_capture` saat `QA_ViewportSize = 1024×768` & `QA_Touch = true` aktif di Play Solo Windows (UI dirender pada area iPad `1024×768` di sisi kiri kanvas Studio), dan gambar `05` pada viewport Studio native setelah `QA_ViewportSize`/`QA_Touch` dibersihkan:

- [`01_ipad_shop_robux.jpg`](01_ipad_shop_robux.jpg) (`242.213` B) — Keempat sisi border card Tab `ROBUX` utuh tanpa terpotong & scrollbar nonaktif saat muat.
- [`02_ipad_shop_perbekalan.jpg`](02_ipad_shop_perbekalan.jpg) (`227.644` B) — Kedua card `PERBEKALAN` dengan border `2 px` utuh merata.
- [`03_ipad_shop_kosmetik.jpg`](03_ipad_shop_kosmetik.jpg) (`239.850` B) — Seluruh card Tab `KOSMETIK` memiliki border atas/kiri/bawah/kanan utuh dengan celah aman sebelum scrollbar.
- [`04_ipad_flight_hud_1024x768.jpg`](04_ipad_flight_hud_1024x768.jpg) (`397.280` B) — `"LANGIT CERAH"` + `"Zona 1 · Target Istana Awan"` terpusat vertikal dan `"10.000 km"` sepenuhnya di dalam pil kanan pada tata letak `1024×768`.
- [`05_desktop_flight_hud.jpg`](05_desktop_flight_hud.jpg) (`393.155` B) — Tata letak Flight HUD Desktop (`QA_ViewportSize` & `QA_Touch` dibersihkan).

## Console, Pemulihan Studio & Penyimpanan Place

- `get_console_output`: `0` error/warning gameplay (`[DataManager] Unpublished Studio: isolated mock data; checkout disabled.` saja dari mode mock lokal; serta `1` warning diagnostik awal `AssistantCommand` `WaitForChild("FlyHighHud")` sebelum perbaikan nama `FlyHighHUD`).
- Pasca Playtest: `ShopModal.Visible = false`, atribut QA dibersihkan, `start_stop_play(is_start=false)` selesai ke mode `Edit` (`players = 0`), dan kamera default dipulihkan (`[0, 48, 25]` -> `(0, 12, -55)`).
- Place tersimpan ke [`Fly High.rbxl`](../../Fly%20High.rbxl) via `save_place`: `1.913.300` byte, mtime `2026-11-15 03:02:30` waktu lokal, SHA-256 `C554D1A84D2252C0A34572E0DE95BC761348CD65EAAF7828713C15BB1EDD888B` (isi binary `.rbxl` belum dibuka ulang).
- QA tersisa: verifikasi visual langsung di perangkat iPad fisik nyata & membuka ulang file binary `.rbxl`.
