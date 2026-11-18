# QA Implementasi Gelar Royal Eksklusif & 5 Roblox Badges (`2026-11-18`)

- **Run ID:** `exclusive-titles-badges-2026-11-18`
- **Waktu:** `2026-11-18 22:45 WIB` (`Asia/Jakarta`, `UTC+7`)
- **Build dasar:** `HEAD = 9950b85` (`main`, lokal belum dicommit/push)
- **Lingkungan:** Roblox Studio `1fc749f2-5a8f-4d20-8f58-c9a3897f2f64`, `Play Solo` Windows 1 klien (`Fikki2621`, `UserId = 8635452105`, `placeId = 97043730132219`, `universeId = 10776821830`, `DataReady = true`)

## 1. Gelar Royal Eksklusif (`0` Koin + Whitelist UserId + UI Mewah ID/EN)
- **Katalog & Whitelist ([DailyAndShopCatalog.luau](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/DailyAndShopCatalog.luau)):**
  - `title:prince_of_sky`: `Pangeran Langit` (`id`) / `Prince of the Sky` (`en`), `price = 0`, `exclusiveUserIds = { 8635452105 }`.
  - `title:princess_of_sky`: `Putri Langit` (`id`) / `Princess of the Sky` (`en`), `price = 0`, `exclusiveUserIds = { 9294134678, 8635452105 }`.
  - Penegakan akses bersama `Catalog.CanAccessCosmetic(item, userId)` pada UI ([ShopTabsController.luau](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/ShopTabsController.luau)) maupun sisi server ([DataManager.luau](../../audit/sources/ServerScriptService/FlyHighServer/DataManager.luau) `cleanOwned`/`cleanTemp`/`cleanEquipped`/`CosmeticAction`, plus filter pada [OverheadManager.luau](../../audit/sources/ServerScriptService/FlyHighServer/OverheadManager.luau)).
- **Aset Ikon Diunggah & Terverifikasi:**
  - `art_cosmetic_title_prince`: `rbxassetid://107428339594877` (`ContentProvider:GetAssetFetchStatus == Success`)
  - `art_cosmetic_title_princess`: `rbxassetid://95518013683213` (`ContentProvider:GetAssetFetchStatus == Success`)
- **Tampilan Mewah & Lokalisasi ([LocalizationCatalog.luau](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/LocalizationCatalog.luau)):**
  - Kartu toko bergradien 3-lapis safir-indigo / ungu-mawar velvet + border gradien emas/champagne (`2.4 px`).
  - Overhead `CosmeticTitlePill` (`241×24 px`) menampilkan `RoyalCrest` kiri, teks ID/EN (`Pangeran Langit`/`Prince of the Sky`, `Putri Langit`/`Princess of the Sky`), gradasi latar & rim metalik, serta ornamen bintang kanan `✦`.

## 2. Integrasi 5 Roblox Experience Badges (`BadgeService`)
- **Konfigurasi & Modul Server:** [`FlyHighConfig.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/FlyHighConfig.luau) & modul baru [`BadgeManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/BadgeManager.luau) (`UserHasBadgeAsync` + `AwardBadge` non-blocking via `task.spawn`, cache per sesi & `inFlight`/`cooldown` anti-spam, grace log Studio bila `AwardBadge` mengembalikan `false` di Studio).
- **Keterhubungan Kondisi:**
  - `FirstFlight` (`1985513006821695`): masuk experience / sesi siap (`DataManager.added`).
  - `PalacePioneer` (`2228896968502208`): `SummitCount >= 1` (`DataManager.AddSummit` & backfill login `CheckDataMilestones`).
  - `StratosphereVoyager` (`612666145539186`): ketinggian `>= 5.000 km` (`DataManager.UpdateAltitude` real-time tiap 0,1 dtk + `AddSummit` + backfill login).
  - `SkyDefender` (`1171146342737589`): menghancurkan `>= 10` rintangan secara persisten lintas sesi (`ObstaclesDestroyed` di DataStore, dicatat di [`WeaponManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/WeaponManager.luau) dengan penjaga anti-ganda `_CountedKill` & autosave coalesced `DataManager.RecordObstacleDestroyed`).
  - `SkySovereign` (`133927492139337`): `SummitCount >= 10` (`DataManager.AddSummit` & backfill login).

## 3. Hasil Verifikasi & Batas
- **Parity & Compile (`Edit`):** **65/65** skrip `SYM_NORM_MATCH=65`, `FAILS=0`, `COMPILE_FAILS=[]`, `ALL_EDITOR_MATCH=True`.
- **Verifikasi API Badge Live (`GetBadgeInfoAsync` & `UserHasBadgeAsync`):** semua **5/5** badge terkonfirmasi `okInfo = true`, `isEnabled = true`, nama persis (`First Flight`, `Palace Pioneer`, `Stratosphere Voyager`, `Sky Defender`, `Sky Sovereign`).
- **Uji Gelar Live `Play Solo` (`Fikki2621`, `8635452105`):**
  - Kedua baris eksklusif tampil di `ShopModal -> KOSMETIK` (`coinsBefore = 2590 -> coinsAfter = 2590`), pembelian & pemakaian lewat `ShopCoinFunction` berhasil, semua teks muat di ukuran desktop maupun lebar sempit `360 px` (`tagFits=titleFits=descFits=true`), serta Overhead Billboard menampilkan `Pangeran Langit` / `Prince of the Sky` (`crestLoaded = true`) dan `Putri Langit` / `Princess of the Sky` (`crestLoaded = true`).
  - Matriks akses: `8635452105` mengakses keduanya (`true, true`), `9294134678` hanya `Putri Langit` (`false, true`), ID publik `99999999` ditolak keduanya (`false, false`).
- **Uji Kill Nyata & Threshold 5 Badge:**
  - Tembakan `WeaponFireEvent` nyata dari klien menghancurkan `_QATargetBird` di `550 km` -> `obsBefore = 0 -> obsAfterShot = 1`.
  - Dengan spy executor pada `BadgeManager`, terverifikasi: `ObstaclesDestroyed = 9 -> false, 10 -> true` (`SkyDefender`, tetap 1 call pada kill ke-11), `Altitude = 4999 -> false, 5000 -> true` (`StratosphereVoyager`, tetap 1 call pada 5001), dan matriks tier `Summit 0/1/9/10` memicu `FirstFlight`, `PalacePioneer`, `SkySovereign` tepat pada ambangnya.
- **Batas QA:**
  - `BadgeService:AwardBadge` secara bawaan Roblox Studio mengembalikan `false` pada sesi Studio; pemberian badge sungguhan ke akun pemain tetap perlu diverifikasi di **server game Roblox yang dipublikasikan**.
  - Akun spesifik `9294134678` & klien publik selain `8635452105` tidak login langsung ke Studio (diverifikasi melalui fungsi akses katalog/server, bukan dua klien Roblox terpisah).
  - Binary [Fly High.rbxl](../../Fly High.rbxl) tersimpan lokal (**3.532.605 B**, SHA-256 `1381cfd2b5f5d40653c0f8452cd8491693610e6bfa024f1543a548670a582819`, mtime `2026-11-18T22:44:23+07:00`) dan belum dibuka ulang; DataStore `User_8635452105` diverifikasi kembali persis baseline (`SummitCount=15`, `ObstaclesDestroyed=0`, `OwnedCosmetics={"title:faithful_explorer":true}`).
  - Studio pulih (`Edit`, `players=0`, `leftovers=[]`, kamera `(0,48,25)` di [edit-restored.jpg](edit-restored.jpg)); log mentah di [qa-results.json](qa-results.json).
