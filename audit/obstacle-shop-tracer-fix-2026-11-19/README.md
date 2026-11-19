# QA Perbaikan Damage Rintangan, Rebalance Harga Toko Koin, dan Upgrade Visual Tracer Peluru (`2026-11-19`)

- **Identitas:** Run ID `obstacle-shop-tracer-fix-2026-11-19`, `2026-11-19 20:25–20:38 WIB` (`Asia/Jakarta`, UTC+7).
- **Build:**
  - Base Git commit: `03a5c5c` (*"Polish Cloud Palace arrival card across screen sizes"*), dirty files lokal: `Fly High.rbxl`, 5 skrip di `audit/sources/`, serta folder audit ini (belum di-commit, belum di-push, belum di-publish ke Cloud).
  - Parity & compile Studio (`3d4a4955-a9d0-4129-b534-cee6f160ea6a`) ↔ mirror `audit/sources/`: **`66/66` compile bersih (`0` error)**, **`0` mismatch manifes seluruh skrip** (normalisasi UTF-8, `CRLF->LF`, strip trailing LF), serta kecocokan **SHA-256 `exact = true`** pada seluruh 5 skrip yang diubah:
    - [`ObstacleMotion.luau`](../../audit/sources/ServerScriptService/FlyHighServer/ObstacleMotion.luau): `5.378` B, SHA-256 `f86bc265df2edc1e0cc3482f448878b7270968a02df1d431ea1df4aa48e782fd`
    - [`ObstacleManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/ObstacleManager.luau): `25.061` B, SHA-256 `567b34d39e1194983c97b7c7a00b97ea2a7d506f1e9b1405f2b37b6816956695`
    - [`LargeChallengeManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/LargeChallengeManager.luau): `6.071` B, SHA-256 `d6e37e0eedb78c53b1ba5cfcf3b027677bb47970453d9d334cbddd205c90c3d4`
    - [`DailyAndShopCatalog.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/DailyAndShopCatalog.luau): `9.967` B, SHA-256 `7c0e1c7c97f0ef4cee98560cbda6b630caea83d4ec1fc2cf8a0974df3d9a8970`
    - [`WeaponPresentation.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/WeaponPresentation.luau): `48.055` B, SHA-256 `4dde8367e53ba041afe12e2ae22f557b23100ffe9f6feee0438a2c4943a89abc`
  - Simpan lokal: `E:/Antigravity/Fly High/Fly High.rbxl` (**`3.536.681` B**, mtime `2026-11-19T20:38:30+07:00`, SHA-256 `51dd5545c0f25cb10c30af191a329ebdec508927a35b8b8eb9fb60187496c2c0`); **belum dibuka ulang** dari disk.
- **Lingkungan:** Roblox Studio Windows (`3d4a4955-a9d0-4129-b534-cee6f160ea6a`), `Play Solo` (`1` klien `Fikki2621`, `userId = 8635452105`, `gameId = 10776821830`, `placeId = 97043730132219`).

## Ringkasan Akar Masalah & Perbaikan

1. **Damage Rintangan & Hitbox Balon (`ObstacleMotion`, `ObstacleManager`, `LargeChallengeManager`):**
   - `ObstacleManager.applyHazard` sebelumnya tidak memanggil `ApplyPuncture` sama sekali untuk `Tornado` (*Angin Topan* / puting beliung), `Wind`, `Magnetic`, dan `Fog`, sedangkan dorongan `Tornado` juga terlalu singkat (`0.6s`, melemah hingga `0` di radius `33`).
   - `ObstacleManager.touches` sebelumnya hanya menguji titik tunggal `Envelope.Position` sehingga rintangan yang menyambar area keranjang/gondola maupun bagian bawah kubah luput tanpa damage (`0` lubang).
   - `item.hit[flight] = true` ditulis sebelum hasil `applyHazard` / `ApplyPuncture` diterima (baik di `ObstacleManager` maupun `LargeChallengeManager`), sehingga balon yang terserempet saat detik terakhir `invulnTime` langsung kebal permanen meski masih bersentuhan sesudah `invulnTime` habis.
   - `Meteor` mengalami pergeseran model induk (`model:PivotTo(nextPose)`) sepanjang fase aktif meski `updateMeteor` memposisikan `MeteorLane1..3` relatif terhadap `item.origin`.
   - Perbaikan menyatukan pengecekan benturan berbasis sumbu tinggi penuh balon (`PointToSpineDistance` / `DistanceToSpine` / `DistanceToPath2D`), memastikan seluruh hazard band 1–9 + 9 musuh + `Spike` + `StormCurtain` memberi damage lubang yang tepat saat tidak dilindungi grace/shield/safe takeoff, memperbaiki dorongan `Tornado` (`28` stud/dtk selama `2,0` dtk), memperbaiki `Meteor`, dan mengunci `item.hit` hanya saat efek benar-benar diterapkan.
2. **Harga Koin Toko (`DailyAndShopCatalog`):**
   - `turbo_gas`: `120` → **`150` Koin**; `tali_awet`: tetap **`100` Koin**.
   - Tracer peluru (`×1,5`): `cyan_sky` `350` → **`525` Koin**, `dawn_gold` `400` → **`600` Koin**, `aurora_violet` `450` → **`675` Koin**.
   - Gelar (`×2`, royal eksklusif tetap `0`): `faithful_explorer` `500` → **`1000` Koin**, `cloud_conqueror` `650` → **`1300` Koin**, `prince_of_sky`/`princess_of_sky` tetap **`0` Koin**.
3. **Visual Tracer Peluru (`WeaponPresentation`):**
   - Mengganti part tunggal kecil + trail 0,12 detik dengan sistem berlapis terkelola dalam satu kontainer `FlyingBulletTracer`: kilatan laras ganda (`WeaponMuzzleFlash` + `WeaponMuzzleHalo`), `BulletCoreBeam` (`LightEmission=1`), `BulletAuraBeam` berwarna pekat (`LightEmission=0.42` agar tetap tajam di langit siang terang Zona 1/5), `BulletTraceBeam` di sepanjang lintasan tembakan, proyektil `FlyingBullet` + `BulletGlow` inti ganda, partikel `TracerSparks` khusus tracer kosmetik (menghormati `ReduceHUDMotion`), serta fase catch-up/fade halus pascabenturan.

## Skenario, Fixture & Hasil Aktual

- **Suite A — Matriks Damage Rintangan (`_QA_SuiteA`, sementara di Play Solo):** **`20/20 PASS`** ([log mentah](qa-results.json)).
  - Fixture: `ObstacleManager.Paused = true`, `LargeChallengeManager.Paused = true`, pemanggilan tulis `DataManager` (`GrantCoins`, `UpdateAltitude`, `AddSummit`, `RecordObstacleDestroyed`) di-stub di memori agar DataStore live tidak berubah, balon diposisikan bersih ke `500 km`, `1805 km` (`StormCurtain`), dan `150 km` (safe zone).
  - Terbukti lulus: `Tornado` kena kubah (`holes=1`, `windMag=28`, `invuln>0`), `Tornado` kena keranjang `root.Y+4` (`holes=1`), `Tornado` `invuln` habis di tengah tumpang tindih (`0 -> 1`), anti-ganda pada `Tornado` sama (`holes=1`), perisai `Shield` memblokir lubang & angin, `Lightning`, `Wind` keranjang, `Debris` keranjang, `Heat` keranjang, `Magnetic` (lubang + `reverseUntil`), `Fog` (lubang), `Meteor` (lubang + `parentDrift=0`), `Storm` inti & cell sambaran, musuh `WildBird` keranjang, `GuardianDrone` menembak `Spike` ke keranjang, `CelestialPhoenix`, `StormCurtain` langsung & `invuln` habis, serta zona aman `<300 km` memblokir kerusakan.
- **Suite B — Harga Koin Toko (`ShopModal` Live Play Solo):**
  - Karena `gameId = 10776821830` memakai DataStore live, verifikasi dilakukan read-only via `DailyAndShopCatalog` runtime + UI nyata `ShopModal` (tidak mengirim mutasi `BuySupply`/`CosmeticAction` ke DataStore).
  - Hasil UI (`TextFits = true`): `turbo_gas` tampil **`150 Koin` (`150 Coins`)**, `tali_awet` **`100 Koin` (`100 Coins`)**, `dawn_gold` **`600 Coins`**, `aurora_violet` **`675 Coins`**, `prince/princess_of_sky` **`0 Coins`**, `cloud_conqueror` **`1300 Coins`**. Item `cyan_sky` (`525` di katalog) dan `faithful_explorer` (`1000` di katalog) terverifikasi nilai katalognya dan tampil `✓ EQUIPPED` pada akun uji yang sudah memiliki trial/kepemilikan di DataStore.
  - Screenshot: [Tab Supplies](shop-perbekalan-prices.jpg), [Tab Cosmetics (Tracers)](shop-kosmetik-tracers.jpg), [Tab Cosmetics (Titles)](shop-kosmetik-titles.jpg).
- **Suite C — Visual Tracer Peluru (`_QA_SuiteC` + `_QA_CamAim`, Play Solo `500 km`):**
  - Balon `Pod_A` hover di `500 km`, senjata `Pistol` diambil dari `WeaponRack1`, dan `EquippedTracer` disetel sementara di memori (`"none"`, `"cyan_sky"`, `"dawn_gold"`, `"aurora_violet"`).
  - Terbukti seluruh variasi terlihat jelas di 1P dan 3P samping tanpa menutup bidikan, **`leftoverTracerCount = 0`** 1,5 detik setelah berhenti menembak, dan **`0` error skrip game** di Console Studio.
  - Screenshot: [Default 1P](tracer-default-1p.jpg), [Cyan Sky 1P](tracer-cyan-1p.jpg), [Dawn Gold 1P](tracer-dawn-gold-1p.jpg), [Aurora Violet 1P](tracer-aurora-violet-1p.jpg), [Dawn Gold 3P Samping](tracer-dawn-gold-3p-side.jpg).

## Batas Pengujian & Cleanup

- **Batas terbuka:** Tidak menjalankan uji multiplayer `2–3` klien, perangkat sentuh fisik (iPad/ponsel), perjalanan alami `300–10.000 km`, atau transaksi DataStore mutasi beli koin nyata (menjaga akun live); `Fly High.rbxl` tersimpan lokal namun belum dibuka ulang untuk verifikasi binary post-save.
- **Cleanup:** Play Solo dihentikan bersih; Studio diverifikasi berada pada mode **`Edit`**, `playerCount = 0`, `TestService.NumberOfPlayers = 1`, `leftovers = []` (zero `_QA_*`, `FlyingBulletTracer`, `WeaponMuzzleFlash`, atau `Balloon_*`), kamera dikembalikan ke `[0, 48, 25]` ([foto Edit](edit-restored.jpg)), dan place tersimpan lokal via `save_place`.
