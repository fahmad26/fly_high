# QA Papan Peringkat Puncak Spawn & Efek Dampak Tembakan — 15 November 2026

Implementasi dan verifikasi dua fitur baru pada **Fly High**:
1. **Dua Papan Peringkat Top 10 Puncak Berdampingan di Dekat Spawn** (`ALL TIME` & `1 BULAN` reset otomatis tanggal 1 pukul `00:00 WIB`).
2. **Efek Dampak Tembakan Senjata** untuk objek dapat ditembak (`Hit` & `Kill`) versus efek kebal/pantul **khusus** untuk obstacle/hazard non-shootable (`Immune`).

## Ringkasan Perubahan

### 1. Papan Peringkat Top 10 Puncak (`All Time` & `1 Bulan`)
- **Geometri Dunia (`Workspace.FlyHighLobby.SpawnLeaderboards`):**
  - Dua papan berdampingan di sisi kanan dek spawn `LobbySpawn` tanpa menutupi jalan setapak atau pemandangan dermaga: `PlinthDeck`, `PlinthBrassTrim`, `LeaderboardAllTime` di `(18.70, 15.85, 18.80)`, dan `LeaderboardMonthly` di `(23.86, 15.85, 28.44)`.
- **[`DailyAndShopCatalog.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/DailyAndShopCatalog.luau)** (`7.703` B, `0d40d152_e0e8aca2`):
  - Menambah `GetUTC7YearMonth(unixTime?)` dan `FormatMonthLabelWIB(year, month)` dengan acuan zona waktu UTC+7 (WIB).
- **[`LeaderboardBoardRenderer.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/LeaderboardBoardRenderer.luau)** (`15.433` B, `dd88bbe9_279bf9fb`, `ModuleScript` baru):
  - Enkoding/dekoding skor komposit (`SUMMIT_WEIGHT = 100000`, `EncodeScore`, `DecodeScore`, `SortEntries`, `FormatKm`) sehingga setiap pemain dengan `>= 1` puncak selalu berada di atas pemain `0` puncak sekalipun rekor ketinggiannya `9.999 km`.
  - `BuildBoardGui` (`680×740` Sky Adventure `SurfaceGui`) dan `RenderBoard`: memfilter entri `0` skor (menampilkan pesan kosong saat belum ada catatan pendakian), menampilkan pil `* Nx Puncak` atau `^ X km`, serta memasang `rbxthumb://` hanya bila `userId > 0`.
- **[`DataManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/DataManager.luau)** (`22.333` B, `12d2b6da_ace87aa2`):
  - Menambah field `MonthlyKey`, `MonthlySummitCount`, dan `MonthlyMaxAltitude` pada `clean`, `attributes`, `ensureMonthlyBucket`, `UpdateAltitude`, `AddSummit`, `GetLeaderboardData`, serta `RolloverMonthly`, lalu mengirim pembaruan ke `_G.FlyHighLeaderboardManager.RecordPlayer`.
- **[`LeaderboardManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/LeaderboardManager.luau)** (`13.036` B, `98204513_f4684dc1`, `Script` baru):
  - Mengelola `OrderedDataStore` `FlyHigh_TopSummits_AllTime_v1` dan bucket bulanan `FlyHigh_TopSummits_Month_<YYYYMM>` saat pengalaman terbit (`GameId ~= 0`), serta mock in-memory terisolasi saat `GameId == 0` di Studio, sinkron sesi via `DataReady`/`RecordPlayer`, pengecekan otomatis pergantian bulan tanggal 1 `00:00 WIB`, serta `Control` `BindableFunction` berpagar `Studio` (`SetFixtures`/`SetSimulatedTime`) untuk QA.

### 2. Efek Dampak Tembakan (`Hit` / `Kill` vs `Immune` Non-Shootable)
- **[`ObstacleManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/ObstacleManager.luau)** (`20.807` B, `f8c5c01c_db80fcea`) & **[`LargeChallengeManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/LargeChallengeManager.luau)** (`5.618` B, `ea8fe6de_faf09008`):
  - Memberi atribut `HitColor` dan `MaxHealth`; memasang `VortexQueryCore` (`CanQuery = true`) pada `Tornado`/`Storm`; mengaktifkan `CanQuery = true` pada part padat non-dekorasi (`Debris` `9` part, `Magnetic` `5` part, `Lightning` `5` part, `Spike`), menyelaraskan `part.CanQuery = visible` di `updateMeteor`, serta `HitColor = (147, 197, 253)` + `CanQuery = (p ~= model.PrimaryPart)` pada `StormCurtain`.
  - Hazard atmosferik (`Wind`, `Heat`, `Fog`) dipertahankan `0` part solid queryable agar tidak menghalangi tembakan di ruang udara.
- **[`WeaponManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/WeaponManager.luau)** (`13.641` B, `c6092a79_fc119ed5`):
  - Menambah `immuneObstacle(model)` untuk obstacle/hazard ber-tag `FlyHighObstacles` & `FlyHighLargeChallenges` dengan `IsObstacle == true and Shootable == false`, serta menyiarkan argumen ke-4 `impact` (`"Hit"`, `"Kill"`, atau `"Immune"`) via `WeaponFireEvent:FireAllClients`.
- **[`WeaponPresentation.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/WeaponPresentation.luau)** (`40.446` B, `908c9364_fd48553a`):
  - Mengecualikan `FlyHighObstacles` & `FlyHighLargeChallenges` dari raycast CQB `wallPush`; menambah pool SFX impact preloaded (`clickfast.wav`, `switch.wav`, `electronicpingshort.wav`, `button.wav`, `PistolShot`); mempercepat tracer menjadi `360` stud/detik (`0.035..0.65` dtk); serta mengimplementasikan `spawnImpactEffect` dan callback `onLocalImpact`:
    - **`Hit`:** kilatan `Highlight`, partikel `WeaponImpactParticles`, burst `WeaponHitBurst` & percikan `WeaponHitSpark`.
    - **`Kill`:** inti `WeaponKillCore`, ledakan `WeaponKillExplosion`, cincin kejut `WeaponKillShockRing`, dan pecahan `WeaponKillDebris`.
    - **`Immune`:** cakram perisai energi `WeaponImmuneShieldDisc` & `WeaponImmuneShieldHalo` sejajar permukaan, kilatan `Highlight` cyan dingin, `WeaponRicochetBolt` memantul beserta `WeaponImmuneSpark`.
- **[`WeaponClientController.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/WeaponClientController.luau)** (`46.153` B, `e4d26d84_d972dbfe`):
  - Menambah `HitFeedbackPill` di bawah `WeaponReticle` serta handler `onLocalWeaponImpact` (`> x <` untuk `Hit`, `[ * ]` + `"HANCUR!"` untuk `Kill`, `[ ! ]` + `"KEBAL"` untuk `Immune`) yang dijaga oleh `feedbackUntil` pada `RenderStepped`.

## Hasil QA (Studio Windows · Build Lokal Pasca-Edit Final)

- **Kompilasi & Parity (`check_parity.py` & `loadstring` Studio):**
  - `52/52` script pada Studio terkompilasi bersih (`compileErrorCount = 0`).
  - `python check_parity.py`: `studioCount = 52`, `mirrorCount = 52`, `matched = 52`, `mismatched = []`, `extra = []`.
- **QA 1 — Papan Peringkat Top 10 & Rollover Tanggal 1 (`Play Solo` `1` Klien `Ajooes`/`Fikki2621`, `GameId == 0` Mock):**
  - **UTC+7 helper:** `2026-11-30 23:59:59 WIB` menghasilkan `202611` / `"Nov 2026"`, dan `+2` detik menghasilkan `202612` / `"Des 2026"`.
  - **Empty state & filter `0` km:** entri skor `0` disembunyikan dan papan menampilkan banner ajakan pendakian (`04-playsolo-spawn-boards-empty-state.jpg`).
  - **Sorting, prioritas puncak, pemotongan Top 10 & fallback ketinggian:** dengan fixture `12` entri, `LeaderboardAllTime` hanya menampilkan Top 10 dengan urutan ketat `4x Puncak > 2x Puncak > 1x Puncak > ^ 9.999 km > ... > ^ 3.100 km`, sedangkan `LeaderboardMonthly` menampilkan `Nov 2026` dengan puncak di atas rekor ketinggian (`02-playsolo-spawn-boards-populated-distance.jpg`, `03-playsolo-spawn-boards-populated-closeup.jpg`).
  - **Simulasi rollover tengah malam tgl 1:** memajukan waktu dari `2026-11-30 23:59:59 WIB` ke `2026-12-01 00:00:01 WIB` mengosongkan `LeaderboardMonthly` sementara 10 peringkat `LeaderboardAllTime` tetap utuh.
- **QA 2 — Efek Tembakan di Udara (`Play Solo` Windows `1` Klien):**
  - Meluncur dari `Pod_A` ke `458 km` lalu mengambil `Pistol` (`[E]`):
    - Menembak **`WildBird`** (shootable): HP turun `50 -> 25` (`Hit`: `WeaponHitBurst`, `WeaponHitSpark x5`, `WeaponImpactParticles`), tembakan kedua menghancurkan target (`Kill`: `WeaponKillCore`, `WeaponKillExplosion`, `WeaponKillShockRing`, `WeaponKillDebris x9`, HUD `"HANCUR!"`).
    - Menembak **`Angin Topan`** (non-shootable): target tidak menerima kerusakan (`Immune`: `WeaponImmuneShieldDisc`, `WeaponImmuneShieldHalo`, `WeaponRicochetBolt`, `WeaponImmuneSpark x6`, HUD `"[ ! ]"` + `"KEBAL"`).
    - Menembak **langit kosong**: menghasilkan `impact = "none"` tanpa efek pantul palsu.
- **QA 3 — Boot Bersih ke-2 & Penerbangan Nyata (`Pod_A` -> `422 km`):**
  - Penerbangan nyata dari `Pod_A` (`~432 km` lalu Game Over pada `422 km`) memperbarui **kedua papan** (`LeaderboardAllTime` & `LeaderboardMonthly`) secara otomatis dengan `#1` `Ajooes` · `^ 422 km` beserta avatar thumbnail (`05-playsolo-live-flight-422km-updated.jpg`).
  - Pengecekan CQB & part queryable mengonfirmasi `StormCurtain` dikecualikan dari `wallPush` (`cqbStormIgnored = true, combatStormDetected = true`) dan `Wind`/`Heat`/`Fog` memiliki `0` part solid dibanding `Debris=9`, `Magnetic=5`, `Lightning=5`.
  - Log console akhir bersih dari error maupun warning gameplay (hanya pesan startup standar `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.`).
- **Pemulihan Edit & Penyimpanan Place:**
  - Playtest dihentikan bersih ke mode `Edit` (`playersCount = 0`, `strayCount = 0`), kamera dipulihkan ke `(0, 48, 25) -> (0, 12, -55)`.
  - Tersimpan ke [`Fly High.rbxl`](../../Fly High.rbxl) (`1.913.058` B, `2026-11-15 02:16:04 +07:00`, SHA-256 `7584CECA4E4CDA34C60623E1D46FACDA1C35CD13E8ED94A2628F6ADEC29807E7`).

## Bukti Screenshot

- [`01-edit-spawn-leaderboards.jpg`](01-edit-spawn-leaderboards.jpg) — Mode `Edit`: posisi dua papan berdampingan di samping dek `LobbySpawn`.
- [`02-playsolo-spawn-boards-populated-distance.jpg`](02-playsolo-spawn-boards-populated-distance.jpg) — `Play Solo`: tampilan jarak berdiri di dek spawn.
- [`03-playsolo-spawn-boards-populated-closeup.jpg`](03-playsolo-spawn-boards-populated-closeup.jpg) — `Play Solo`: close-up fixture Top 10 All-Time & Top 4 Bulanan `Nov 2026`.
- [`04-playsolo-spawn-boards-empty-state.jpg`](04-playsolo-spawn-boards-empty-state.jpg) — `Play Solo`: tampilan keadaan kosong saat belum ada skor `> 0`.
- [`05-playsolo-live-flight-422km-updated.jpg`](05-playsolo-live-flight-422km-updated.jpg) — `Play Solo` boot ke-2: pembaruan langsung kedua papan setelah penerbangan nyata `422 km`.

## Batas QA & Pekerjaan Tersisa

- **`OrderedDataStore` produksi (`DEFER-01`):** Karena Studio berada di `GameId == 0`, penyimpanan persisten lintas-sesi melalui `OrderedDataStore` (`FlyHigh_TopSummits_AllTime_v1` & `FlyHigh_TopSummits_Month_<YYYYMM>`) memerlukan verifikasi ulang setelah experience diterbitkan.
- **Bukti visual VFX dampak tembakan:** Spawning part & HUD pill `Hit`/`Kill`/`Immune` terkonfirmasi melalui telemetri runtime Play Solo (tangkapan `01..05` memotret papan spawn sebelum dan sesudah penerbangan `422 km`, belum mengambil frame mid-air tepat saat ledakan/pantulan terjadi).
- **Perangkat sentuh & multiplayer:** Belum dilakukan uji `2–3` klien sekaligus (replikasi VFX tembak & rebutan peringkat server) maupun perangkat Phone/Tablet fisik, serta binary [`Fly High.rbxl`](../../Fly High.rbxl) belum dibuka ulang (tercakup pada paket commit `15 November 2026`).
