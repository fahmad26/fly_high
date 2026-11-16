# Revisi semi-realistis lanjutan (Batch C–E) — 16 November 2026, 12:35 WIB

## Perbaikan dari catatan sebelumnya
- **Phoenix v4** (aset 92054335906237): kepala dan paruh lebih besar, jambul lebih tinggi.
- **Hiasan phoenix di kapal/altar** (`SceneryHabitatArt.Clone` dengan tint): SurfaceAppearance kini dilepas dan material diganti Metal. Hasilnya patung emas, bukan bulu merah.
- **Awan bola abu-abu di sekitar istana** (`CloudPalace...SummitCloudBanks`, 6 bank): diganti cumulus mesh kit dengan LUT Gold dan shell Neon. Bola lama dibuat transparan, backup ada di `ServerStorage.SummitCloudBanks_Legacy`.
- **Varian pulau Crag:** tinggi dibatasi (×0,78) agar tidak menjadi paku.

## Batch C — musuh
| Musuh | Isi | Aset |
|---|---|---|
| Seagull / Eagle (flock WildBird) | Generator bulu yang sama dengan phoenix. Gull putih berujung gelap; elang cokelat dengan primer berjari dan kepala putih. | 90480244479718 / 75520841714834 |
| CrystalWyvern | Tubuh dan ekor bersisik, sayap selaput 4 jari, duri kristal Glass | 99254809215381 |
| StormBat | Tubuh berbulu gelap, telinga, sayap selaput ungu | 119778420451324 |
| FireBee | Tubuh bergaris emas/hitam, kaki, antena, sayap kaca | 127458610363503 |
| ShadowPhantom | Jubah berkerudung, wajah kosong gelap, mata bercahaya, lengan dan ujung jubah compang-camping | 77733310015739 |
| Hailstone ×3 / Drone / Satellite / Meteor | Polesan material: es Glass reflektif, logam Metal, batu Basalt | (mesh lama) |

- **Tekstur baru:**
  - Bulu gull 126231044795687 dan bulu elang 96184296499208
  - Tubuh netral 79249784841106 (di-tint per musuh)
  - Selaput 127958251895052 + normal 133426121673140
  - Garis lebah 76550920931851
- **Kompatibilitas:** nama part `Body`/`Wing` dipertahankan untuk animasi dan hitbox; `Arms` dipertahankan untuk Phantom. Dekorasi baru diberi atribut `Decoration`. Ukuran disamakan dengan bbox template lama, dan skala Model dikembalikan ke 1 karena `scaleModelVisuals` memakai `ScaleTo` absolut. Template lama ada di `ServerStorage.ObstacleMeshes_Legacy`.

## Batch D — rintangan
- **Gelembung bahaya:** dibatasi minimal transparansi 0,35, jadi hanya kilau tipis. Tampilan utama berasal dari partikel cuaca.
- **Wind:** ditambah partikel debu dan kelopak yang terbawa angin.

## Batch E — detail akhir
- **Cosmic:** planet bercincin di horizon (760 stud, 2 cincin, atmosfer Neon).
- **Air terjun pulau:** dibuat ±40% lebih lebar agar terbaca dari jauh.

## Verifikasi
- **Kompilasi dan Play:** 0 error kompilasi. Play Solo 500→9.990 km, ditambah pembuatan 9 musuh dan 9 rintangan di Server: konsol bersih. Fixture 0 sisa.
- **File lokal:** `Fly High.rbxl` disimpan LocalFile, 2.846.087 B, SHA-256 55DBECE015EB4F188DEF2C0F99B9B14EB22E45BD732900AB06E9A5F726C3AE55.
- **Paritas binary = Studio:**

  | Script | Panjang | FNV-1a |
  |---|---|---|
  | BiomeScenery | 133.957 | 7c7f85de |
  | SceneryHabitatArt | 6.611 | c0fc1787 |
  | BiomeLightingController | 12.394 | 30dd5376 |
  | ObstacleArt | 28.284 | f33652b6 |
  | ObstacleVisuals | 21.767 | e2f044a5 |

## Belum
- Drone dan Satellite belum dimodel ulang (hanya material).
- Pita kabut pink di horizon Gateway dibiarkan, karena memang nuansa golden hour.
- Belum diuji gerak kepakan pada model baru saat Play terbang sungguhan.
- Belum diuji di ponsel atau grafik rendah. Jumlah segitiga per musuh naik menjadi sekitar 1–3 ribu.
- Belum commit.
- Generator Blender untuk burung dan musuh hanya ada di sesi live (scene `FlyHigh_StormBatch1`) dan di riwayat percakapan; belum disalin ke `tools/`.
