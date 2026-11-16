# Galeri bentuk musuh dan rintangan — 16 November 2026, 18:30–18:45 WIB

Pengguna meminta: "kumpulkan semua rintangan ke satu tempat, screen capture dari beberapa sudut, cek bentuk yang aneh". Pengguna juga melaporkan bahwa phoenix masih terlihat sangat aneh.

## Fixture

- **Studio:** place 97043730132219, dibuka dari Roblox (private experience), mode Edit.
- **Penempatan:**
  - `workspace._GalleryQA` di Y=3200.
  - 9 musuh dibuat lewat salinan `ObstacleArt` (`_QA_Obstacle`), x=0…240, yaw 200°.
  - 9 rintangan di z=250, berjarak 100 stud.
- **Pencahayaan:** ClockTime 10, Brightness 2.5, FogEnd 100000. Kamera Scriptable.
- **Pembersihan:** semua dibersihkan sesudahnya, 0 sisa `_QA*`/`_Review*`/`_Gallery*`/`*_Import`. Lighting dan kamera dikembalikan ke atribut yang disimpan.

## Temuan dan perbaikan

| Temuan | Penyebab | Perbaikan | Bukti |
|---|---|---|---|
| Phoenix "sangat aneh": jambul melayang di belakang, ekor di kepala, sayap terbalik | Impor glTF Roblox memutar setiap mesh 180° di sumbu Y, sedangkan posisi part memakai pusat dari Blender. Akibatnya geometri tiap part terbalik di tempatnya. | Setiap MeshPart di template semi-realistis diputar 180° pada pusatnya sendiri, lalu diberi atribut `ImportYawFixed`. | 02, 04 (sebelum); 05–09 (sesudah) |
| Meteor berupa bola biru gelap polos | Template v4 hanya dipoles materialnya | Meteor v5 dibuat ulang. Detail ada di bawah tabel. | 12 (sebelum); 13, 14 (sesudah) |
| Drone masih kapsul kamera kuningan versi lama | Belum diremodel | GuardianDrone v5 dibuat ulang. Detail ada di bawah tabel. | 15 (sebelum); 16, 17 (sesudah) |
| Satelit | Bentuk sudah terbaca (bus emas, panel biru, parabola) | Tidak diubah. Draf generator ada di `build_creatures.py`, tetapi tidak dipasang. | 07, 09 |
| Rintangan lain | Tornado, petir, angin, puing, panas, magnet, kabut dan badai sudah terbaca | Tidak diubah | 10, 11 |

Template yang diputar oleh perbaikan yaw: Seagull, Eagle, CelestialPhoenix, ShadowPhantom, CrystalWyvern, StormBat, FireBee.

**Meteor v5** (aset 104097092302147, generator `tools/build_meteor.py`):

- Batu basalt bulat tak beraturan dengan kawah dan alur retakan.
- Pita lava Neon (`Lava`) di dalam alur.
- `Body` diberi SurfaceAppearance batu IslandKit dengan tint 170,138,120.
- Tinggi 9,29 stud, sama dengan v4.

**GuardianDrone v5** (aset 122179757209881, `build_creatures.py` `drone()`):

- Bola penjaga dengan sabuk armor, nacelle pendorong di kiri dan kanan, dan antena bawah.
- Lensa `Aperture` (Neon; ObstacleArt mewarnainya cyan).
- Cincin halo `Halo` (Neon cyan, `Decoration`).
- Dipasang dengan flip yaw.
- Nama `Body`/`Aperture` tetap.

Template lama disimpan di `ServerStorage.ObstacleMeshes_Legacy` (Meteor, GuardianDrone).

## Kepakan sayap

Kepakan diuji dengan simulasi di Edit, belum dengan Play. Rumus `ObstacleManager` disalin apa adanya: joint `(side*0.68, 0.35, 0)`, `CFrame.Angles(0,0,side*Motion.WingAngle(...))`. Rumus ini diterapkan pada phoenix, kelelawar, wyvern dan lebah, pada sudut maksimum dan minimum.

Sayap tetap menempel di bahu dan simetris (screenshot 18, 19). Rumus memakai posisi part, bukan orientasinya, sehingga flip yaw tidak mengubah engsel.

Belum dicek di Play Solo atau di perangkat.

## Status penyimpanan

- **Source:** 5 script tidak berubah pada putaran ini. FNV Studio sama dengan mirror commit `1008f48`:
  - BiomeScenery 133957/7c7f85de
  - SceneryHabitatArt 6611/c0fc1787
  - BiomeLightingController 12394/30dd5376
  - ObstacleArt 28284/f33652b6
  - ObstacleVisuals 21767/e2f044a5
- **Place:** `save_place` tersimpan ke Roblox **Cloud versi 9**, karena place dibuka dari Roblox.
  - `Fly High.rbxl` lokal di repo **belum** memuat perubahan template ini.
  - Untuk menyamakan file lokal: File → Save to File (timpa `Fly High.rbxl`).
- **Belum diuji:** performa dan grafik rendah di ponsel.
  - Meteor ±9,9 ribu segitiga untuk batu dan ±1,3 ribu untuk lava, ×3 per rintangan meteor.
  - Drone ±4,7 ribu segitiga.
  - Semua MeshPart memakai RenderFidelity Automatic (LOD aktif).

## Screenshot

Semua di folder ini:

- **Sebelum:**
  - `01`–`03`: galeri depan dan atas.
  - `04`: phoenix dari samping.
- **Sesudah:**
  - `05`: phoenix dari samping.
  - `06`–`09`: depan, atas dan belakang.
  - `20`: semua musuh.
- **Rintangan:** `10`, `11`.
- **Meteor:** `12`–`14`.
- **Drone:** `15`–`17`.
- **Kepakan:** `18`, `19`.
