# Perbaikan Tabrakan Dua Balon & Pacing Solo (+ Uji Terbang Alami hingga 5.407 km) — 19 November 2026

- **ID Run:** `collision-and-full-flight-fix-2026-11-19`
- **Waktu:** 19 November 2026, `21:57–22:42 WIB` (`Asia/Jakarta`, UTC+7)
- **Build dasar:** `03a5c5c` + seluruh perbaikan lokal 19 November sebelumnya (`obstacle-shop-tracer-fix-2026-11-19`, `title-width-and-tracer-fx-2026-11-19`)
- **Lingkungan:** Windows Roblox Studio `Play Solo` (`studio_id = 3d4a4955-a9d0-4129-b534-cee6f160ea6a`, `placeId = 97043730132219`, `universeId = 10776821830`, `NumberOfPlayers = 1`, tulis `DataManager` di-stub ke memori), diikuti pemeriksaan langsung file biner tersimpan `Fly High.rbxl` menggunakan parser Zstandard (`Python 3.15 compression.zstd`).

## Perubahan Produksi

1. **[`FlightSpace.luau`](../sources/ServerScriptService/FlyHighServer/FlightSpace.luau)** (SHA-256 norm `d24aca1193590dbbd4bd0d942c3741f625f3ffa6e8fbc12bb45e3c3c9b61acc0`):
   - Memadatkan profil siluet balon ke `PROFILE_STEP = 2`, melacak `minY`/`maxY` kontinu, mengganti estimasi sudut `math.max(...)/math.cos(pi/16)` di `reach()` menjadi interpolasi linier antar sudut.
   - Menambahkan `Space.Separated(a, b, margin)` serta menulis ulang `Space.ClampMovement(fd, position, flights)` agar menyelesaikan sumbu penetrasi minimum (`penFromAbove`/`penFromBelow` vs `penH`, epsilon `±0.02`) dan mengembalikan `position, hitFlights` tanpa mendorong balon ke samping saat bertumbukan vertikal.
2. **[`BalloonManager.luau`](../sources/ServerScriptService/FlyHighServer/BalloonManager.luau)** (SHA-256 norm `89a4a84bcc2337bcb374eec896f1755e6873cfb843981ccd03bc2a92e51c4c68`):
   - Memperbarui `Manager.ResolveCollisions(fd, proposed)` untuk memakai `clamped, hitFlights = Space.ClampMovement(...)`, memicu kebocoran `Collision` langsung pada `hitFlights` begitu `(fd.root.Position - clamped).Magnitude <= 1.25` (menghapus buffer celah udara `+1`), dan membersihkan `fd.contacts` via `Space.Separated(fd, otherFlight, 6)`.
3. **[`ObstacleManager.luau`](../sources/ServerScriptService/FlyHighServer/ObstacleManager.luau)** (SHA-256 exact `d7387d123c449c6de4c5cb1f5f40550fa6b584d7674f342635238ccb9575a8d0`, norm `9a33679d1f1b6b7d2656ee0834f4c784afc783c83d84288c307f8ccbf41db252`):
   - Menambahkan `bandIsSoloOnly(list)` untuk menskalakan ukuran gelombang musuh Solo (`math.max(1, count - 1)`), `enemyInterval * 1.45`, dan `hazardInterval * 1.25` tanpa mengubah pacing Duo/Trio.

## Hasil QA Pasca-Perbaikan

### Suite 1 — Tabrakan Dua Balon (`Play Solo`, `PASS`)
- **`Case 1A` Samping (`DawnExplorer` vs `DawnExplorer`):** near-miss `flatDist = 35.75` (`visualGap = 0.077`, `0/0` lubang); kontak memicu damage pada `flatDist = 35.48` (`visualGap = 0.001` pada `HandropeLashing <-> HandropeLashing`, `1/1` lubang); menahan tempelan `5,6` dtk tetap `1` lubang (`recontact5_6sHoles = 1`); `contacts` bersih setelah mundur ([`collision-side-fixed.jpg`](collision-side-fixed.jpg)).
- **`Case 1B` Samping (`DawnExplorer` vs `SaturnVoyager`):** damage pada `flatDist = 38.98` (`visualGap = 0`, `envelope_geom <-> Ring`, `1/1` lubang).
- **`Case 1C` Atas → Bawah:**
  - `flat0`: `maxSingleTickXZJump = 0`, damage pertama di `dy = 52.71, flatDist = 0, visualGap = 0.3` (`1/1` lubang), bertahan `11,5` dtk di `[0, 102.43, 0]` (`endVisualGap = 0.033`, tetap `1/1` lubang), `contactsClearedAfterClimb = true` ([`collision-top-down-fixed.jpg`](collision-top-down-fixed.jpg)).
  - `flat6`: `maxSingleTickXZJump = 0`, damage di `dy = 52.7, flatDist = 6, visualGap = 0.288` (`1/1` lubang), posisi akhir `[6, 102.61, 0]` (`endVisualGap = 0.196`).
- **`Case 1D` Bawah → Atas:**
  - `flat0`: `maxSingleTickXZJump = 0.126`, damage di `dy = -53.17, flatDist = 0, visualGap = 0.746` (`1/1` lubang), posisi akhir `[0, 67.57, 0]` (`endVisualGap = 0.095`) ([`collision-bottom-up-fixed.jpg`](collision-bottom-up-fixed.jpg)).
  - `flat6`: `maxSingleTickXZJump = 0`, damage di `dy = -53.11, flatDist = 6, visualGap = 0.704` (`1/1` lubang), posisi akhir `[6, 67.57, 0]` (`endVisualGap = 0.106`).
- **`Case 1E` Diagonal (`start = [14, 112, 0]`):** `endPos = [14, 102.56, 0]`, `maxSingleTickXZJump = 0`, damage di `dy = 52.7, flatDist = 14` (`1/1` lubang).

### Suite 2 — Penerbangan Penuh Alami Solo (`Pod_A`, teramati s.d. `5.407,09 km`)
- Diluncurkan alami dari `Pod_A` (`isMaster = true`, tulis `DataManager` di-stub ke memori):
  - **Zona 1 Dawn (`~924–1.181 km`):** berhasil menangkis gelombang awal dan menjaga `holes = 0` ([`flight-zone1-dawn.jpg`](flight-zone1-dawn.jpg)).
  - **Zona 2 Storm (`~2.260–2.455 km`, `StormCurtain 1800` & `3600`):** menembus `2.000 km` (`201,2` dtk), menghindar `StormCurtain 1800` (`warnedAtAlt = 1816.6, safeRootY = 422.8, dodged = true, hit = false`) ([`flight-zone2-storm.jpg`](flight-zone2-storm.jpg)) dan `StormCurtain 3600` (`warnedAtAlt = 3621.5, safeRootY = 872.7, dodged = true, hit = false`).
  - **Zona 3 Sunset (`~4.167–5.407 km`, `StormCurtain 5400`):** menembus `4.000 km` (`470,8` dtk) ([`flight-zone3-sunset.jpg`](flight-zone3-sunset.jpg)), lalu menghindar `StormCurtain 5400` (`warnedAtAlt = 5406.3, safeRootY = 1322.8, dodged = true, hit = false`). Pengukuran terakhir pada `elapsedSec = 649 dtk`: `altitudeKm = 5217.61` (`maxAltitudeKm = 5407.09`), `health = 100`, `holes = 1` (`maxHoles = 2`), `repairsCompleted = 59`, `ropeRepairs = 16`, `ropeMinDurability = 21.7%`, `equipSuccess = 7/7`, `shotsFired = 29`, `enemiesDestroyed = 7`, `mockCoins = 110`, dan **`0` error skrip game** di konsol (hanya log dev `[BadgeManager] Studio skipped live badge grant ...` yang wajar).
- **Batas teramati:** Setelah checkpoint `22:15 WIB` (`5.217,61 km`), sesi Roblox Studio ditutup setelah pengguna menyimpan `Fly High.rbxl` pada `22:30:32 WIB`. Segmen **`5.407 -> 10.000 km` (Zona 4 Cosmic, Zona 5 Gateway, `StormCurtain 7200/9000`, `PalaceArrival`, `ReturnPortal`) belum tercatat lengkap dalam log sesi ini.**

## Parity, Kebersihan Binary Place & Batas

- **Studio pra-QA:** `66/66` compile `0` error dan `66/66` SHA-256 cocok dengan `audit/sources/`.
- **Binary [`Fly High.rbxl`](../../Fly%20High.rbxl) tersimpan (`2026-11-19T22:30:32+07:00`):**
  - Ukuran **`3.540.508` B**, SHA-256 **`427ea1c230fcf1aa09044064bd9ac8ae25462d0f145a96531866ef123de3cd92`**.
  - Pemeriksaan zstd langsung ([`binary-source-report.json`](binary-source-report.json)): **`66/66` skrip biner cocok ternormalisasi dengan `audit/sources/` (`0` mismatch, `0` missing/extra)**, **`qaNames = []`** (`0` objek `_QA_`/`QA_`), **`Workspace._has_QA_attr = false`**, dan **`TestService.NumberOfPlayers = 1`**.
  - **Batas:** File `.rbxl` tersimpan ini diperiksa langsung secara biner, **belum dibuka ulang di sesi Roblox Studio baru**, sehingga properti visual/Terrain non-skrip masih mengacu pada sesi Studio sebelum ditutup. Uji `5.407 -> 10.000 km`, Duo/Trio `2–3` klien nyata, serta perangkat sentuh fisik masih terbuka.
