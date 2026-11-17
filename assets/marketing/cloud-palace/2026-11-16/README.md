# Fly High: Cloud Palace — marketing artwork v1

Tanggal: 16 November 2026. Status: **draft ditolak pengguna secara visual** karena terasa generik/slop. Pemeriksaan ukuran di bawah hanya teknis dan bukan persetujuan desain. Belum diunggah atau dipublikasikan ke Roblox. Lihat revisi di folder saudara `2026-11-17-drafts`.

## Berkas siap pakai

| Aset | Berkas | Ukuran |
| --- | --- | --- |
| Icon utama | [icon-1024-v1.png](icon-1024-v1.png) | 1024 × 1024 PNG |
| Icon alternatif | [icon-512-v1.png](icon-512-v1.png) | 512 × 512 PNG |
| Thumbnail | [thumbnail-1920x1080-v1.png](thumbnail-1920x1080-v1.png) | 1920 × 1080 PNG, 16:9 |
| Master icon | [icon-master-v1.png](icon-master-v1.png) | 1254 × 1254 PNG |
| Master thumbnail | [thumbnail-master-v1.png](thumbnail-master-v1.png) | 1672 × 941 PNG |

Ukuran mengacu pada dokumentasi resmi [experience icons](https://create.roblox.com/docs/production/publishing/experience-icons) dan [thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails). Thumbnail diekspor dari master ke 1920 × 1080 dengan pembesaran sekitar 15% dan penyesuaian rasio yang sangat kecil. Master asli disimpan tanpa perubahan.

## Arah visual

Balon koi kain gading–merah menjadi identitas utama; istana marmer berkubah emas dan air terjun turquoise menunjukkan tujuan permainan. Keranjang kayu, tali, burner, dan kostum aviator memiliki material yang sejalan antara kedua gambar.

Icon memakai satu kru dan tanpa teks agar siluet mudah dibaca ketika kecil. Thumbnail menampilkan tiga kru yang bekerja sama, dengan judul di langit bagian kanan atas dan tujuan penerbangan di kanan. Kedua gambar merupakan ilustrasi promosi, bukan tangkapan layar gameplay atau bukti kualitas model di dalam game.

## Pembuatan dan pemeriksaan

- Metode: built-in `image_gen`, satu generasi untuk icon dan satu untuk thumbnail. [Prompt lengkap](prompts.md) disimpan untuk iterasi berikutnya.
- Sharp hanya digunakan untuk ekspor ukuran dan konversi sRGB; tidak menggambar atau mengubah objek. [Script ekspor](export.cjs) menolak menimpa berkas berbeda.
- Build yang diperiksa: artwork v1 di folder ini, pada lingkungan lokal Windows. Tidak ada Playtest atau perubahan Studio untuk tugas ini.
- Fixture visual: icon [150 × 150](qa-icon-150.png) dan thumbnail [384 × 216](qa-thumbnail-384x216.png), serta gambar ukuran penuh.
- Hasil aktual: balon koi dan siluet istana terbaca pada icon kecil. Judul, tiga kru, dan istana tetap terpisah pada thumbnail kecil. Tidak terlihat teks tambahan, watermark, HUD, atau elemen promosi palsu.
- Dimensi, ukuran berkas, dan SHA-256 tercatat dalam [manifest.json](manifest.json). Salinan master sama secara byte dengan hasil generasi asli.
- Aset lama `assets/icon.jpg` dan `assets/thumbnail.jpg` dipertahankan. Source game, place, dan dokumentasi handover bersama tidak diubah agar tidak berbenturan dengan pekerjaan AI lain.

Langkah berikutnya: tinjau pilihan visual bersama pengguna; bila disetujui, unggah icon dan thumbnail ke experience tujuan. Tidak ada unggah, publish, commit, atau push dalam tugas pembuatan gambar ini.
