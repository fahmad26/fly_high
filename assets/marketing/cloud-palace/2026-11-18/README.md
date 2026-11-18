# Fly High: Cloud Palace — Marketing Artwork v2 (Fresh Redesign)

Tanggal: 18 November 2026 (Asia/Jakarta).  
Status: **redesign v2 dibuat ulang dari nol** (bukan edit pixel gambar lama; belum diunggah atau dipublikasikan ke Roblox; tidak mengubah kode/place `.rbxl`).

## Arah Desain Ulang

1. **Dibuat Ulang dari Nol dengan Identitas Asli (`assets/icon.jpg` & `assets/thumbnail.jpg`)**:
   - **Icon (`1:1`)**: komposisi baru balon merah-emas berornamen dengan pembakar api, 2 kru Roblox ceria, kepulauan tropis di bawah, serta Istana Awan berair terjun di kanan.
   - **Thumbnail (`16:9`)**: komposisi sinematik baru balon merah-emas kembar api di atas kepulauan tropis, 3 peran kru Roblox beraksi (pilot kemudi, penembak membidik burung kristal, teknisi berhelm kuning di tali pengaman dengan kunci pas), armada balon bertema (Saturnus, Lentera Istana, Teratai ungu), serta Istana Awan di kanan.
2. **Keranjang Balon Udara Kotak (`kotak`)**: Kedua aset memakai keranjang kayu **kotak persegi** berdinding papan datar, sudut tajam 90°, siku kuningan, pagar kayu atas, lentera sudut, dan karung pemberat.
3. **Tipografi Judul Konsisten di Icon & Thumbnail**:
   - Baris utama besar: **`FLY HIGH`** (oranye–biru langit ber-outline gelap).
   - Subjudul kecil di bawahnya: **`Cloud Palace`** (putih bersih ber-outline gelap).

## Berkas Siap Pakai

| Aset | Berkas | Ukuran | Bytes |
| --- | --- | --- | --- |
| Icon utama | [icon-1024-v2.png](icon-1024-v2.png) | 1024 × 1024 PNG | 1.425.135 |
| Icon alternatif | [icon-512-v2.png](icon-512-v2.png) | 512 × 512 PNG | 407.918 |
| Thumbnail | [thumbnail-1920x1080-v2.png](thumbnail-1920x1080-v2.png) | 1920 × 1080 PNG (16:9) | 2.517.892 |
| Master icon | [icon-master-v2.png](icon-master-v2.png) | 1024 × 1024 PNG | 1.425.135 |
| Master thumbnail | [thumbnail-master-v2.png](thumbnail-master-v2.png) | 1376 × 768 PNG | 1.475.586 |
| QA preview kecil | [qa-icon-150.png](qa-icon-150.png), [qa-thumbnail-384x216.png](qa-thumbnail-384x216.png) | 150 × 150 & 384 × 216 PNG | 46.330 & 144.274 |

## Pemeriksaan

- Metode: `image-generator` subagent (generasi baru dari nol) + ekspor PNG Lanczos via Pillow 13.0.0 ([manifest.json](manifest.json)).
- Pemeriksaan visual pada master penuh serta ukuran storefront kecil (`150×150` & `384×216`) menunjukkan keranjang kotak bersudut 90°, karakter blok Roblox, Istana Awan, armada balon, dan judul `FLY HIGH` + `Cloud Palace` kecil terbaca jelas tanpa watermark atau HUD palsu.
