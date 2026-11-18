# QA Landing Istana Awan (Campuran & Semua Hidup), Portal Turun & Perbaikan Ikon Gelar (`2026-11-19`)

- **Run ID:** `palace-portal-2026-11-19`
- **Waktu:** `2026-11-19 01:17–01:26 WIB` (`baseline` selesai `2026-11-18T18:17:22Z`, `final` selesai `2026-11-18T18:24:29Z`, Play Solo visual capture `01:26 WIB`)
- **Lingkungan:** Roblox Studio `6e240f19-beea-4042-9663-5e7d94ab1350` (`Fikki2621's Place: 11152026_1`, `placeId=97043730132219`, `universeId=10776821830`), `Start Server & Players` **2 klien lokal** (`Player1` & `Player2`, Windows) serta `Play Solo` Windows

## Ringkasan Temuan & Perbaikan

### 1. Cutscene Pendaratan Istana Awan, Kartu Kedatangan & Portal Turun (`CINE-01`, `UI-01`)
Baseline ([baseline-results.json](baseline-results.json)) menghasilkan **17/20 PASS** dengan dua masalah visual/HUD pada cutscene pendaratan + portal turun serta typo atribut koin pada skrip uji baseline (`Coins` vs `SkyCoins`):
- **Overlap emblem crest & judul pada `ArrivalCard`:** Terkonfirmasi pada metrik baseline (`crestRect` bottom `336.23` bertumpuk di atas `titleLabelRect` top `331.76`) dan tampak di [arrival_card_before.jpg](arrival_card_before.jpg).
- **Popup `HUDFlightResult` tampil di belakang layar saat cutscene aktif:** `hudResultDuringCine = true` pada baseline, serta risiko popup habis di tengah dok bila `CutscenesEnabled == false`.
- **Perbaikan yang diterapkan:**
  - [`PalaceCinematics.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/PalaceCinematics.luau): Merombak layout `ArrivalCard` (`UISizeConstraint MinSize=(296, 108)` & `MaxSize=(440, 158)`, `AspectRatio=2.75`, `Position=(0.5, 0.89)`, `Size=(0.46, 0.24)`, `CardCrest` di `Y=0`, `cardTitle` di `Y=0.24`), menambah animasi `UIScale` Back-out & shrink fade-out, memperbarui `fadeCharacter` dengan `fadeTokens` + listener `DescendantAdded` untuk aksesori yang baru termuat pasca kebangkitan `LoadCharacterAsync()`, memberi pill backdrop gelap semi-transparan pada `ZoneLabel` (`BackgroundColor3=RGB(8, 22, 54)`, `UICorner`, `UIStroke`, `UIPadding`), menambah `resetOverlays()` di `enterCinematic`/`exitCinematic`, serta `skipExitBlend=true` pada `runReturn()` (`guarded`) untuk menghilangkan jeda beku `0.8` detik sesudah mendarat.
  - [`HUDTheme.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau): Menyembunyikan `HUDFlightResult` saat `ArrivalPending == true and CutscenesEnabled ~= false`, serta me-refresh `resultUntil = os.clock() + 4` saat `PalaceArrival` mendarat jika `CutscenesEnabled == false`.

### 2. Bug Kotak Kosong (`□`) pada Overhead Title `Prince of the Sky` / `Princess of the Sky` (`UI-01`, `DATA-01`)
- **Akar masalah:** [`OverheadManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/OverheadManager.luau) sebelumnya memakai `RoyalSparkle` bertipe `TextLabel` (`Font = Enum.Font.GothamBlack`, `Text = "✦"` `U+2726`), yang glifnya tidak tersedia di fallback font Gotham pada iOS/iPadOS sehingga muncul kotak tofu (`□`) di sisi kanan judul.
- **Perbaikan ([`OverheadManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/OverheadManager.luau)):** Mengganti `TextLabel` `"✦"` menjadi elemen geometris `Frame` bintang 4-sudut murni UI (`RoyalSparkle` berisi 3 `Frame` lengan bersudut bulat/rotasi) yang diwarnai mengikuti `pal.rimA`.

## Hasil QA Final 2 Klien (`20/20 PASS`)

- **Hasil akhir ([final-results.json](final-results.json)):** **`success = true`**, **`20/20` PASS**, `0` error server, `0` error/warning klien (`Player1` & `Player2`).
- **Phase A — Pendaratan Istana Awan (Campuran: `Player1` hidup, `Player2` mati/ghost):**
  - `afterAlive`: `puncak=3`, `coins=1120` (`+150` dari `970`), `inFlight=false`, `ghost=false`, `focus="nil"`, `palaceArrival=true`.
  - `afterDead`: `puncak=3` (bertambah `+1`), `coins=570` (`+0`, sesuai aturan hanya penyintas yang mendapat `+150` koin), `inFlight=false`, `ghost=false`, `focus="nil"`, `palaceArrival=true`.
  - Kedua klien menampilkan `revivalRingSeen=true` (efek kebangkitan kru gugur), kartu hidup (`+150 koin`), kartu mati (`"Kru bangkit — kamu ikut sampai!"`), `cardCrestOverlapsTitle=false` (`crestBottom=338.87` < `titleTop=347.31`), `hudResultDuringCine=false`, `hudHiddenDuringCine=true`, serta kontrol & kamera `Custom` pulih (`phaseA_controls_restored_both`).
- **Phase B — Portal Turun (`PalaceReturn` -> Lobby):**
  - Seluruh 5 zona tampil lengkap secara berurutan (`zonesSeen = ["ZONA 5 · GERBANG SURGAWI", "ZONA 4 · LANGIT BINTANG", "ZONA 3 · PULAU SENJA", "ZONA 2 · AWAN MENDUNG", "ZONA 1 · LANGIT CERAH"]`), `sceneryMax = 5`, `fadedOutSeen = true`, `whiteoutSeen = true`, `endTransparency = 0`, `endWalkSpeed = 16`, `endCharY = 12.898`, `endCamType = "Custom"`, `endHudEnabled = true`.
  - Jalur `CutscenesEnabled = false` (`phaseB_fast_return_cutscene_off`) juga lulus terpisah.
- **Phase C — Pendaratan Istana Awan (Semua Hidup):**
  - `p1CoinDelta = +150`, `p2CoinDelta = +150` (`puncak=4`), `revivalRingSeen = false` pada kedua pemain, kedua kartu menampilkan `"+150 koin"`, `cardCrestOverlapsTitle = false`, `hudResultDuringCine = false`, `hudResultAfterCine = false`.

## Verifikasi Visual Play Solo, Responsif & Overhead UI

- **Before / After Visual Capture:**
  - Sebelum perbaikan: [arrival_card_before.jpg](arrival_card_before.jpg) (crest sedikit menyentuh tepi atas teks judul kartu).
  - Sesudah perbaikan: [arrival_card_and_zone_fixed.jpg](arrival_card_and_zone_fixed.jpg) (celah bersih antara emblem crest dan `"CLOUD PALACE REACHED"` serta pill gelap terbaca jelas di belakang `"ZONE 5 · CELESTIAL GATEWAY"`).
- **Uji Layout Responsif Phone / Tablet (simulasi clone UI pada Play Solo):**
  - `phone_landscape (667x375)`: `297x108`, `crestGap = +7.56`, `fitsViewport = true`
  - `phone_portrait (375x667)`: `296x107.6`, `crestGap = +7.53`, `fitsViewport = true`
  - `tablet (1024x768)`: `434.5x158`, `crestGap = +11.06`, `fitsViewport = true`
- **Verifikasi Runtime `RoyalSparkle` (`Play Solo`):** `RoyalSparkle.ClassName = "Frame"`, `arms = 3`, `spVis = true`, `spPos = (228.96, 43)`, tanpa mutasi DataStore (`0`).
- **Batasan yang tetap terbuka:**
  1. `screen_capture` di Roblox Studio tidak merender `BillboardGui` 3D di atas `LocalPlayer.Character.Head`, sehingga tampilan akhir bintang 4-sudut `RoyalSparkle` di perangkat iPad/iOS fisik masih perlu dikonfirmasi langsung setelah publish/uji client.
  2. Perubahan `CutscenesEnabled == false` pada `HUDTheme.luau` untuk popup dok saat mendarat baru terverifikasi compile & baca jalur kode (uji live Phase A/C berjalan dengan `CutscenesEnabled = true`; baru Phase B portal turun yang diuji dengan `CutscenesEnabled = false`).

## Parity, Cleanup & Penyimpanan Place

- **Parity & Compile (`Edit`):** `65/65` skrip compile bersih (`compileErrors = []`), `65/65` mirror `audit/sources/` match panjang byte UTF-8 ternormalisasi. SHA-256 prefix file scope ini:
  - `PalaceCinematics.luau`: `9aaebe72b5cd47cf` (`33.971` UTF-8 B)
  - `HUDTheme.luau`: `e6e8062468b6ad72` (`85.270` UTF-8 B)
  - `OverheadManager.luau`: `bb2f59e07893d99f` (`11.861` UTF-8 B)
- **Cleanup & Place:** `_QA_*` bersih (`0`), kembali ke `Edit` / `0` pemain / `TestService.NumberOfPlayers = 1` / kamera default ([foto](../death-ping-2026-11-19/edit-restored.jpg)), tersimpan ke `E:/Antigravity/Fly High/Fly High.rbxl` (`3.533.855` B, `2026-11-19 01:29:28 WIB`, SHA-256 `5FE2544BD90E6C3BFEA64AC64BD6DBCE092C0628FF0447494969CC4A94596FCE`, belum dibuka ulang dari disk dan belum dicommit/dipush). **Catatan belum dapat dipulihkan:** panggilan `StudioTestService:ExecuteMultiplayerTestAsync(2, ...)` meninggalkan pilihan tombol Play/Test pada Next-Gen Ribbon Studio di mode `StartServer` (`2` pemain) karena tidak tersedia API Studio/MCP resmi untuk mengubah pilihan UI Ribbon tersebut kembali ke `Test` (`Play`) secara terprogram.
