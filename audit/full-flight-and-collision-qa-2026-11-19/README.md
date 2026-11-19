# QA Penerbangan Penuh & Tabrakan Dua Balon (19 November 2026)

Pengujian murni (`QA-only`, tanpa mengubah skrip produksi, tanpa `save_place`, tanpa commit/push/publish) di Roblox Studio `Play Solo` (`studio_id = 3d4a4955-a9d0-4129-b534-cee6f160ea6a`, `TestService.NumberOfPlayers = 1`, tulis `DataManager` di-stub ke memori agar data live aman).

## 1. Hasil Uji Tabrakan Dua Balon (`Suite 1`)

### Apakah kontak fisik harus terjadi untuk menyebabkan damage?
- **Tidak.** Kolisi fisika Roblox antar-balon dinonaktifkan secara eksplisit di [`BalloonManager.luau`](../sources/ServerScriptService/FlyHighServer/BalloonManager.luau) (`PhysicsService:CollisionGroupSetCollidable("FlyHighBalloons", "FlyHighBalloons", false)`).
- Damage (`ApplyPuncture(fd, "Collision")` -> +1 lubang ke kedua balon, diikuti kebal 5 detik & flag `contacts` hingga berpisah `> touch + 6` stud) murni dipicu secara matematis oleh `FlightSpace.ContactDistance` + `BalloonManager.ResolveCollisions` saat:
  1. Band tinggi 4-stud kedua balon bertampalan (`ContactDistance ~= nil`),
  2. Gerak datar terkunci oleh `FlightSpace.ClampMovement` (`(proposed - clamped).Magnitude > 0.01`), dan
  3. Jarak horizontal memenuhi `flatDist < touch + 1` stud.

### Ringkasan Kasus Uji (`DawnExplorer` & `SaturnVoyager`, data detail di [`qa-results.json`](qa-results.json))
| Skenario | Jarak Datar & `dy` | Celah Visual Part Terdekat | Hasil Aktual | Foto |
| --- | --- | --- | --- | --- |
| **1A Samping — Near Miss** (`Dawn` vs `Dawn`) | `flatDist = 38.10` (`touch = 37.30`), `dy = 0` | `2.34 stud` (`SafetyHandrope`) | `0` lubang di kedua balon | — |
| **1A Samping — Kontak & Tahan >5,8 dtk** | `flatDist = 37.88` (`< 38.30`), `dy = 0` | **`2.253 stud`** (`SafetyHandrope`) | **+1 lubang masing-masing** meski masih ada celah udara `~2,25` stud; tetap `1` lubang selama menempel >5,8 dtk; `contacts` bersih saat ditarik ke `49.70` stud | [`collision-side-contact.jpg`](collision-side-contact.jpg) |
| **1B Samping Asimetris** (`Dawn` vs `SaturnVoyager`) | `flatDist = 39.93` (`touch = 39.09`), `dy = 0` | `0.078 stud` (`envelope_geom <-> Ring`) | +1 lubang masing-masing hampir tepat saat ring menyentuh kanopi | [`collision-side-saturn.jpg`](collision-side-saturn.jpg) |
| **1C Turun dari Atas** (`flatDist = 0` & `6`) | `dy = 56.31` (geser) -> `52.32` (damage) | `3.90 stud` saat mulai terlempar samping; `0` saat damage sisi | **Snap ke samping `X = 26.6–27.6`** (`maxXZJump = 4.11–5.25` stud/tick) sebelum kulit bersentuhan, lalu +1 lubang di tepi | [`collision-top-down.jpg`](collision-top-down.jpg) |
| **1D Naik dari Bawah (`flatDist = 6`)** | `dy = -56.82` (geser) -> `-52.81` (damage) | `4.412` -> `0.399 stud` | Snap ke samping `X = 26.6`, lalu +1 lubang di tepi (`0.399 stud`) | [`collision-bottom-up.jpg`](collision-bottom-up.jpg) |
| **1D Naik Lurus Tepat di Bawah (`flatDist = 0`, retest terisolasi)** | `dy = -56.77` -> `endPos = [27.6, 66.05, 0]` | — | **BUG:** `ClampMovement` memakai `proposed.Y` dan melempar balon bawah ke `X = 27.6` sebelum `root.Position.Y` menyentuh `-56`, sehingga `ResolveCollisions` mengecek `ContactDistance(root.Y)` yang masih `nil` → **lewat ke samping dengan `0` kerusakan (`fdA=0, fdB=0`)** | — |
| **1E Diagonal (`flatDist = 14`, turun)** | `dy = 56.33` (geser) -> `52.34` (damage) | `3.915` -> `0 stud` | Snap ke samping `X = 26.6` (`maxXZJump = 2.4`), lalu +1 lubang saat keranjang melewati tepi kubah | — |

---

## 2. Hasil Uji Penerbangan Penuh Alami (`Suite 2`, `0 km → 10.000 km`)

- Pengaturan murni produksi: `BASE_FLIGHT_DURATION_SEC = 600`, `ObstacleManager.Paused = false`, `LargeChallengeManager.Paused = false`, tanpa warp altitude, tanpa shield cheat, tanpa Turbo/Tali Awet berbayar.
- **Status kelulusan:** **Belum mencapai `10.000 km` / Istana Awan / Portal Turun** pada kedua percobaan bot solo otonom (`0` error skrip game di `get_console_output`):
  - **Run 1:** Lepas landas dari `Pod_A` (`IsMaster = true`) mencapai **`1.037,79 km`** dalam **`82,4 dtk`** — berhasil menghancurkan `4` musuh dan menambal `5` lubang (`+50` mock koin), lalu `GameOver` akibat kehabisan daya tahan tali saat memanjat lubang baru pada sisa tali `18,7%`.
  - **Run 2:** Lepas landas dari `Pod_A` mencapai **`841,60 km`** dalam **`79,7 dtk`** — berhasil menambal `4` lubang (`+40` mock koin), menembak `2` kali (`1` musuh hancur), menerima `7` kebocoran dari `Angin Topan` & `WildBird` dalam rentang `49 dtk` (`418,88 km` s.d. `841,60 km`), hingga tertahan pada **`3` lubang** (tidak bisa naik per `HOLE_EFFECTS[3]`) dan tali menyentuh `0,6% -> 0%` (`BreakRope` / `FatalRopeFall`) saat perbaikan & turun.
- **Catatan batas & temuan:** Kegagalan di `841–1.038 km` merupakan kombinasi keterbatasan bot QA (batas aman tali `24%` untuk mulai tambal masih berisiko putus saat `Descend` `1,6 dtk` yang ikut menguras `~8%` tali, serta penghentian kemudi saat memegang pistol) **sekaligus** indikator beratnya tekanan Solo di Zona 1–2 awal (`enemyInterval = 7 dtk` + `Angin Topan`, tanpa `AK-47` / `Tali Awet`, dengan siklus solo naik–tambal–turun memakan `~5–6 dtk` & `~16–20%` tali per lubang). Fase `1.800–10.000 km`, `StormCurtain` 1–5, `PalaceArrival`, dan `ReturnPortal` belum terlalui secara alami dalam run ini.

## Pemulihan Studio
- Studio pulih ke `Edit`, `playerCount = 0`, `TestService.NumberOfPlayers = 1`, `leftovers = 0`, kamera default `[0, 48, 25] -> [0, 12, -28]` ([`edit-restored.jpg`](edit-restored.jpg)).
- Tidak ada berkas skrip produksi atau `.rbxl` yang diubah/disimpan dalam QA ini; Git & Roblox Cloud tetap tidak tersentuh.
