# Review visual 0–10.000 km — 15 Nov 2026

Metode:
- Fixture Edit-mode `_ReviewQA`: lighting zona dari `BIOME_SETTINGS`, `BiomeScenery.Build(zone)` + `update(km)`, balon SkyKoi, musuh band via `Art.Enemy`, hazard via `Art.Hazard`.
- Kamera orang ketiga (TP) per band rintangan (1000/2500/3500/4500/5500/6500/7500/8500/9500) + palace 10.000 km.
- Fixture sudah dibersihkan: Lighting/Atmosphere/Water/kamera dipulihkan, 0 sisa `QA`.
- Batasan:
  - Ini still Edit, bukan Play. Hazard dan musuh tidak beranimasi.
  - Satu sudut TP per ketinggian; tidak ada sudut FPS, grafik rendah, atau ponsel.

## Temuan per ketinggian

| km | Zona / musuh / hazard | Temuan |
|---|---|---|
| 1000 | Dawn / Bird / Tornado | Awan bola putih gaya lama bentrok dengan storm semi-realistis; pulau crag bersegi; air terjun tipis; burung kecil; garis putih horizon; tornado hazard seperti hantu |
| 2500 | Storm / Bat / Lightning | Lightning = cakram pucat seperti bulan + garis laser pink; kelelawar kecil |
| 3500 | Storm / Hail / Wind | Wind = satu garis laser lurus; ShelfBank di atas pemain seperti cerutu melayang; anvil veil dari atas seperti piring bergaris tepi |
| 4500 | Sunset / Drone / Debris | Pulau kerucut terbalik dengan akar tongkat; air terjun lurus tipis jatuh ke kosong; drone/debris sulit terbaca |
| 5500 | Sunset / FireBee / Heat | Heat = satu garis laser kuning; cakram matahari besar dan datar; FireBee tidak terbaca |
| 6500 | Cosmic / CrystalWyvern / Magnetic | Hampir hitam total, hanya balon yang terang; wyvern kecil; cincin magnetic samar; pulau atas low-poly bersegi |
| 7500 | Cosmic / ShadowPhantom / Fog | Masih sangat gelap; phantom hampir tak terlihat; pita kabut dan observatorium cukup baik |
| 8500 | Gateway / SatelliteDebris / Meteor | Batas keras langit biru vs kabut pink-cokelat; awan kartun bulat; debris = bola navy polos; meteor = garis laser + chevron |
| 9500 | Gateway / CelestialPhoenix / Storm | Sama: awan kartun, batas horizon keras; phoenix kecil; hazard storm tidak terlihat |
| 10000 | Cloud Palace | Istana bagus; tetapi awan bola menutupi depan istana; air terjun strip lurus jatuh ke kosong |

Bidang segitiga gelap di bawah frame (5500/6500/8500) kemungkinan artefak capture Edit; perlu dicek di Play sebelum dianggap bug.

## Prioritas perbaikan (disarankan)

1. **P0 — Hazard VFX terbaca:** ganti garis laser tunggal (Lightning, Wind, Heat, Meteor, Storm) dengan telegraph volumetrik (pita/beam, partikel, zona bahaya di lantai udara) + aksen warna per hazard.
2. **P0 — Zona Cosmic terlalu gelap:** naikkan ambient/rim, starfield + nebula lebih kuat, emissive di pulau/musuh.
3. **P0 — Batch 1b fix storm:**
   - ShelfBank: hanya dekat band; dipasang di bawah base Cb; lebih lebar dan kurang lonjong; fade di atas pemain.
   - Anvil veil: dibuat bergradasi/fade dari atas.
4. **P1 — Satu gaya awan:** kit awan Zona 1 dan 5 dibangun ulang dengan pipeline LUT yang sama (palet lebih terang) supaya konsisten dengan storm.
5. **P1 — Keterbacaan musuh:** skala lebih besar, siluet, rim light / outline lembut.
6. **P1 — Pulau dan air terjun (Batch 2):**
   - Batu berlapis, bukan kerucut terbalik.
   - Air terjun meruncing, dengan kabut/busa di dasar dan fade, bukan strip lurus.
7. **P2 — Horizon:** hilangkan garis keras langit vs kabut bawah (Atmosphere/water fade per zona); kecilkan dan lembutkan cakram matahari sunset; awan di depan istana dipindah.
