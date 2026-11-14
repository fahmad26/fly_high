# Audit Pemeriksaan & Penanaman Aset Pulau Awal (14 November 2026)

## Identitas Build & Lingkup

- **Tanggal:** 14 November 2026, `18:41:26+07:00` (`Asia/Jakarta`)
- **Git HEAD:** `f5aa15dc846f5ca842d1f5e22af0b7645fc4beca` (`f5aa15d`; working tree kotor, perubahan belum di-commit atau di-push)
- **Berkas tersimpan:** `Fly High.rbxl` (`1.860.721` byte, `2026-11-14 18:41:26`, SHA-256 `B48823481DF6B31FAF003E363372A52674878A73B0DF92E816BDB250954C0DD8`; `save_place` status `Saved`, binary belum dibuka ulang di sesi Studio terpisah)
- **Perubahan script & paritas source:** `0` perubahan script (`TOTAL=45`, `COMPILE_FAIL=0`, `ExactNormalizedMatch=45/45`, `DiffCount=0` antara Studio `ScriptEditorService`/`Source` dan mirror `audit/sources/`)
- **Lingkup objek Studio (`Workspace.FlyHighLobby`):**
  - `IslandNature.Flowers` (`56` model)
  - `IslandNature.Butterflies` (`14` model + atribut `FlightCenter`)
  - `IslandNature.Plants` (`60` model `Fern_*`)
  - `IslandNature.Trees` (`20` model: `PalmTree_1..8`, `BroadleafTree_9..20`)
  - `IslandNature.Rocks` (`12` model `Boulder_1..12`)
  - `IslandNature.Details` (`121` objek: `Pebble_*` + `SteppingStone_*`)
  - `PromenadeGarden` (`12` `FlowerStem` + `DaisyPetal` + `DaisyHeart` = `84` part di 4 `GardenBed`)

## Akar Masalah Sebelumnya

1. **`IslandNature.Flowers` (`Flower_7_1..Flower_7_7`):** tujuh bunga di sekitar `Pod_A.Console` melayang `+0.90` s.d. `+5.11` stud di atas Terrain `Y = 10.00` (sementara `49` bunga lain tertanam `-0.17..-0.13` stud di bawah permukaan).
2. **`IslandNature.Butterflies` (`Butterfly_7`):** memiliki `FlightCenter = (-84.48, 17.61, 23.48)` (`+7.33` stud di atas Terrain), terlalu tinggi dibanding 13 kupu-kupu lain (`FlightCenter.Y = 13.00`, clearance `+2.72..+3.00` stud).
3. **`IslandNature.Plants` (`Fern_*`):** `Fern_50`, `Fern_33`, dan sejumlah pakis pada lereng tepi pulau memiliki pangkal batang yang terbuka/mengambang terhadap kontur Terrain di sekitarnya.
4. **`IslandNature.Trees` (`PalmTree_*` & `BroadleafTree_*`):**
   - `PalmTree_3..6` di lereng menggantung `+0.08..+0.58` stud di sisi turun.
   - `BroadleafTree_14, 16, 17, 20` terlalu dekat tepi tebing/lereng curam (`gapOverLowTer = +1.34..+4.29` stud).
   - Mesh batang `trunk.trunk_geom` (`CanQuery = false`) pada `BroadleafTree_9..16, 18..20` memiliki ujung akar bintang yang mengambang `+0.08..+1.02` stud di atas Terrain meski bounding box model lebih rendah.
5. **`IslandNature.Rocks` (`Boulder_*`):** `Boulder_2, 3, 4, 5, 6, 9, 10` memiliki celah sisi miring/tepi lereng (`+0.50..+2.43` stud).
6. **`IslandNature.Details` & `PromenadeGarden`:** kerikil lereng `Pebble_*` terangkat di atas Terrain sekitar, serta `84` part bunga (`FlowerStem`, `DaisyPetal`, `DaisyHeart`) di `PromenadeGarden` duduk di `10.10` di atas permukaan `GardenBed` (`10.08`).
7. **Bukan temuan melayang (terverifikasi normal):** `PromenadeGarden.FlutedPost` bertumpu di `LanternFoot`, `Pod_A..E.Console` bertumpu pada dua `SignPost`, pot `ArrivalFern` masuk ke `10.00`, `CloudPalace` memang istana langit di `Y = 2560.9`, dan `InvisibleBoundaryCorridor` adalah batas tak terlihat.

## Implementasi yang Diterapkan

1. **Bunga & Kupu-kupu di area `Pod_A`:**
   - Menurunkan `Flower_7_1..Flower_7_7` via `PivotTo` ke `minY = 9.84` di Terrain `10.00` (jarak XZ minimum ke pusat `Pod_A.Console` tetap lega `4.83` stud; `Flowers` tersisa `0/56` bermasalah).
   - Memindahkan dan menurunkan `Butterfly_7` (`FlightCenter` & pivot) ke `(-80.00, 13.00, 29.80)` sehingga seluruh `14/14` kupu-kupu berada pada rentang clearance `2.5..3.5` stud.
2. **Pakis, Kerikil & `PromenadeGarden`:**
   - Menurunkan `Fern_50`, `Fern_33`, dan pakis lereng lain hingga pangkal `stems_geom` terbenam di Terrain (`Plants stem r=0.35 flagged = 0/60`).
   - Menurunkan kerikil `Pebble_*` di lereng (`Details flagged minY > minT = 0/121`).
   - Menurunkan `84` part `FlowerStem` + `DaisyPetal` + `DaisyHeart` di `PromenadeGarden` sebesar `-0.05` stud (`FlowerStem max worldMinY = 10.050 <= GardenBed top = 10.080`, `above = 0/12`).
3. **Pohon & Batu Besar di Lereng:**
   - Menurunkan `PalmTree_3..6` (`dy = -0.45, -0.96, -0.53, -0.40`).
   - Memindahkan `BroadleafTree_14 -> (45.0, 72.5)`, `BroadleafTree_16 -> (-44.0, 84.0)`, `BroadleafTree_17 -> (49.0, 86.0)`, dan `BroadleafTree_20 -> (0.0, 100.0)` ke kontur lebih landai, serta menurunkan `BroadleafTree_9..16, 18..20` (`dy = -0.22..-1.16`) dengan menjaga `trunk_geom.CanQuery = false` dan `leavesCanCollide = 0`.
   - Menurunkan `Boulder_2 (-0.60)`, `Boulder_3 (-1.10)`, `Boulder_6 (-0.28)`, `Boulder_9 (-0.97)`, `Boulder_10 (-0.30)`, serta memindahkan `Boulder_5 -> (43.5, 87.5)` (`Y=[12.16..15.63]`) dan `Boulder_4 -> (-8.0, 99.8)` (`Y=[8.21..10.52]`).
   - Menjaga keutuhan animasi `IslandNatureAnimator` / `IslandWildlifeController` (`RestCFrameMaxDrift = 0.000022` stud).

## Hasil Verifikasi

### 1. Perbandingan Visual Sebelum & Sesudah (`Edit` & `Play Solo`)

| Area | Sebelum | Sesudah | Ringkasan |
| --- | --- | --- | --- |
| Bunga & kupu-kupu dekat `Pod_A` | [before_flowers_pod_a.jpg](before_flowers_pod_a.jpg) | [after_flowers_pod_a.jpg](after_flowers_pod_a.jpg) | `Flower_7_1..7` tertanam rapi (`9.84` vs `10.00`), jarak ke `Pod_A.Console` = `4.83` stud |
| Perspektif pemain `Play Solo` `Pod_A` | — | [qa_playsolo_poda_flowers_butterfly.jpg](qa_playsolo_poda_flowers_butterfly.jpg) | Tampilan setinggi pemain pasca-perbaikan bunga & kupu-kupu `Butterfly_7` |
| Lereng, pakis & batu besar | [before_hillsides_and_rocks.jpg](before_hillsides_and_rocks.jpg) | [after_rocks_ferns_batch1.jpg](after_rocks_ferns_batch1.jpg), [after_rocks_slopes.jpg](after_rocks_slopes.jpg) | Pakis & batu lereng tertanam di Terrain tanpa celah gantung |
| Akar `BroadleafTree` & relokasi tebing | [before_broadleaf_roots.jpg](before_broadleaf_roots.jpg) | [after_broadleaf_north.jpg](after_broadleaf_north.jpg), [after_broadleaf_west_east.jpg](after_broadleaf_west_east.jpg), [after_broadleaf_overview.jpg](after_broadleaf_overview.jpg) | Ujung akar tertanam & pohon tebing berada di lereng yang wajar |
| Bunga di `PromenadeGarden` | [before_promenade_garden.jpg](before_promenade_garden.jpg) | [after_promenade_garden.jpg](after_promenade_garden.jpg) | Batang bunga masuk ke `GardenBed` (`10.050 <= 10.080`) |
| Kamera default `Edit` terpulihkan | — | [after_edit_default_camera.jpg](after_edit_default_camera.jpg) | Kamera `(0, 48, 25) -> (0, 12, -55)`, kondisi pulau bersih |

### 2. Pengukuran Geometrik Pasca-Edit Final (`execute_luau` Mode `Edit`)

- `Flowers = 0/56` flagged (`56/56` tertanam di Terrain).
- `Butterflies = 0/14` flagged (`14/14` pada clearance `2.5..3.5` stud).
- `Plants = 0/60` flagged pada radius batang `r = 0.35` (`Fern_1..60`).
- `Details = 0/121` flagged (`minY <= minT`).
- `PromenadeGarden = 0/12` `FlowerStem` di atas `GardenBed` (`max worldMinY = 10.050 <= bedTop = 10.080`).
- `RestCFrameMaxDrift = 0.000022` stud.
- `Trees`: seluruh `20/20` batang tertanam di Terrain pusatnya, `leavesCanCollide = 0`, clearance kanopi `BroadleafTree_14` `7.65` stud di atas tanah pangkal (`17.72 - 10.06`; `3.15` stud di atas sisi bukit tertinggi tepi kanopi `14.56`). Cross-section raycast `trunk_geom` pada sampel `BroadleafTree_9, 11, 13, 17` mencatat `235–274` titik tertanam (`-0.69..-2.21` stud) dengan hanya `1–5` titik lengkung transisi antar-akar (`+0.10..+0.18` stud).
- `Rocks`: seluruh `12/12` `Boulder` tertanam `-0.59` s.d. `-1.97` stud di bawah `terC` pusatnya (sisi miring bagian luar melengkung mengikuti kontur lereng).

### 3. Uji Navigasi & Collision `Play Solo` + Console

- **Lingkungan:** `Play Solo` 1 pemain (`Fikki2621`, `speed_multiplier = 3`) pada Windows Studio.
- **Rute berurutan (`8/8` `Success`, `stuck = 0`):** `(-0.9, 12.9, 31.0)` -> `(-74, 12.5, 29)` -> `(-81, 13, 43)` -> `(-47, 16, 78)` (lereng NW `BroadleafTree_16`/`Boulder_3`) -> `(-36, 16, 86)` -> `(-4, 14, 92)` (utara `BroadleafTree_20`/`Boulder_4`) -> `(43, 17, 79)` (bukit NE `Boulder_5`/`BroadleafTree_17`) -> `(41, 13, 68)` (dekat `BroadleafTree_14`) -> `Workspace.FlyHighLobby.MatchmakingPods.Pod_A.FloorPad`.
- **Status akhir klien:** `Health = 100.0/100.0`, `State = Enum.HumanoidStateType.Running`, `Pos = (-89.25, 12.25, 15.16)`, `XZDistToPad = 0.77` stud, `Butterfly_7` aktif terbang di `(-81.89, 13.60, 28.25)`.
- **Console (`get_console_output`):** hanya `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.` (`0` error & `0` warning gameplay).

## Cleanup, Simpanan & Batas Verifikasi

- `start_stop_play(is_start=false)` dijalankan: `Edit` mode, `PlayersInEdit = 0`, `Leftover = 0`, `CurrentCamera` dipulihkan ke `(0, 48, 25)` menghadap `(0, 12, -55)`.
- `save_place` sukses menulis `Fly High.rbxl` (`1.860.721` B, `2026-11-14 18:41:26`, SHA-256 `B48823481DF6B31FAF003E363372A52674878A73B0DF92E816BDB250954C0DD8`).
- **Batas:** pengujian live dilakukan dengan `1` klien desktop Windows; review visual di perangkat mobile/tablet serta membuka ulang binary `.rbxl` di sesi Studio terpisah belum dilakukan, dan perubahan belum di-commit/di-push.
