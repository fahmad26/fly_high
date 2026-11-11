# Fly High — HUD untuk lepas landas dan kondisi darurat

Status: approved

> Rekaman keputusan/audit 7 November. Status penerapan dan QA terbaru dipelihara di [PROGRESS](../../../PROGRESS.md); jangan mengulang seluruh rencana ini sebagai backlog baru.

## Audit 7 November 2026

Saya membaca HUD versi 8 pada sesi Studio yang sedang berjalan dan meninjau tangkapan layar penerbangan dari uji sebelumnya. Viewport Studio saat inspeksi berukuran sekitar 773 × 380 unit UI. Bukti pembanding: [iPhone landscape](../../../audit/image-ui-lettering-mobile.jpg), [HUD penembak](../../../audit/image-ui-gunner.jpg), dan [toko](../../../audit/image-ui-shop.jpg).

| Prioritas | Temuan | Keputusan desain |
|---|---|---|
| P1 | Panel Dinding Badai menyembunyikan kartu kerusakan. Padahal kru perlu membaca ancaman dan jumlah lubang pada saat yang sama. | Pertahankan ringkasan kondisi selama peringatan. Tampilkan satu instruksi berdasarkan peran. |
| P1 | Dari perhitungan layout, tombol Tembak bisa menutupi kartu amunisi sekitar 30 × 22 unit pada viewport 390 × 700. Pada 320 × 600, tombol Lompat bisa bersinggungan dengan satu aksi tali di tengah sekitar 18 × 46 unit. Kedua kondisi memerlukan verifikasi visual di simulator portrait. | Susun kontrol peran dan kartu amunisi dalam kelompok dengan ruang yang sudah dialokasikan. Taruh aksi tali di atas kelompok lompat saat layar sempit. |
| P2 | Dari spawn, lima dermaga terlihat berjarak hampir sama. Jarak lurus ke pusat pad terdekat sekitar 72 stud, atau 4,5 detik pada kecepatan jalan 16 stud/detik. Itu estimasi gerak saja. Waktu pemain baru mengenali tujuan, berjalan, dan memulai penerbangan belum diukur. | Tampilkan satu petunjuk sampai pemain bergabung di dermaga. Beri status berbeda untuk Party Master dan anggota kru. |
| P2 | Kartu lobi menampilkan progres dan kecepatan nol, sementara langkah berikutnya hanya tertulis di papan fisik. Saat terbang, tujuan 10.000 km dan progres sudah terlihat, tetapi pesan peringatan kadang lebih panjang daripada aksi yang perlu dilakukan. | Utamakan langkah berikutnya di lobi. Pertahankan target, ketinggian dan progres saat terbang. Ringkas peringatan menjadi aksi dan alasan pendek. |
| P3 | Toko dan kit sudah bersifat opsional, tetapi keduanya tampak sama penting dengan aksi pertama di lobi. Label yang digambar menjadi PNG juga dapat mengecil berlebihan dan tidak ikut diterjemahkan. | Turunkan prioritas toko di lobi. Gunakan PNG untuk rupa visual dan label tetap yang lolos uji keterbacaan, dengan teks Roblox sebagai alternatif untuk bahasa lain. |

## Alur pemain

1. **Di spawn.** Tampilkan judul Fly High dan instruksi pendek **Pilih dermaga**. Tombol Toko masih dapat dibuka dari area utilitas. Kit dan Ping kru tampil ketika relevan.
2. **Sudah bergabung.** Tampilkan nama dermaga, jumlah kru seperti **2/3 kru**, dan langkah berikutnya. Party Master melihat **Mulai penerbangan**. Anggota melihat **Menunggu Master**. Prompt interaksi tetap menjadi cara memulai.
3. **Di gondola.** Saat penghitung mundur aktif, pilot melihat **Tahan gas untuk lepas landas** dengan sisa waktu. Anggota melihat **Pilot belum lepas landas**. Setelah balon naik, ruang ini kembali tersedia untuk peringatan.
4. **Saat rusak.** Jumlah lubang dan siluet kondisi terlihat bersama. Satu peringatan utama menunjukkan aksi yang tersedia untuk peran pemain. Contoh **Tahan tambal** hanya muncul ketika perbaikan bisa dilakukan.

## Susunan layar

| Perangkat | Area atas | Area bawah dan samping |
|---|---|---|
| HP landscape | Ketinggian di tengah atas. Kondisi balon di sudut kiri dalam safe area. Peringatan pendek di bawah ketinggian. | Kiri bawah untuk joystick. Kanan bawah untuk Lompat dan aksi utama peran. Amunisi berada di atas kelompok penembak. Aksi tali naik satu baris bila mulai mendekati Lompat. |
| HP portrait | Ketinggian, kondisi, dan satu peringatan ditumpuk tanpa saling menutupi. Prioritaskan satu baris per informasi utama. | Tembak dan Lompat berdampingan atau bertumpuk di sisi kanan. Amunisi mendapat baris sendiri. Kontrol tali berada di tengah di atas zona jempol bawah. |
| Tablet | Pertahankan susunan landscape atau portrait sesuai orientasi. Tampilkan konteks tambahan bila muat. | Lebarkan jarak antartombol. Tetap kelompokkan Gas, Gas Otomatis, dan Lepas Kemudi pada zona pilot. |
| Desktop | Tampilkan ketinggian, kondisi, dan peringatan secara terpisah. | Tambahkan petunjuk tombol keyboard di posisi yang konsisten. Perilaku modal tetap sama untuk mouse dan sentuh. |

Target sentuh minimal **44 × 44 unit UI**, jarak antarkontrol minimal **8 unit**, dan label aksi utama ditargetkan setara **14 px** pada ukuran uji. Pilih posisi berdasarkan safe area dan ruang aktual yang tersedia. Sisakan pusat layar untuk melihat rintangan dan reticle.

## Status dan teks

| Status | Tampilan |
|---|---|
| Normal | **Balon aman · 0/5** dengan indikator utuh. Saat ada lubang, tampilkan angka dan indikator pecah yang berbeda bentuk. |
| Kritis | **Kritis · 4/5** dengan ikon peringatan. **Terjun bebas · 5/5** dengan ikon turun. Aksi Kit muncul sebagai pilihan penyelamatan hanya jika server mengizinkan. |
| Kosong | Di luar penerbangan, sembunyikan meter yang belum relevan. Saat stok habis, tampilkan **Kit habis** pada konteks kit. Amunisi kosong menonjolkan **Isi ulang** bila aksi tersedia. |
| Memuat | Saat data penerbangan belum diterima, tampilkan placeholder **—** untuk angka. Hindari menampilkan nol sebagai data awal. |
| Gagal | Jika tekstur gagal dimuat, tampilkan latar sederhana, ikon atau label teks, dan hitbox yang sama. Bila aksi ditolak, tampilkan pesan singkat dari respons yang tersedia. |
| Terkunci | Tampilkan ikon gembok dan alasan pendek pada aksi yang penting diketahui, misalnya **Hanya pilot**. Sembunyikan aksi peran lain yang tidak relevan. |

Gunakan aset Sky Arcade PNG yang sudah tersedia untuk tombol, ikon, panel, dan label yang tetap. Timer, harga, amunisi, nama, status yang berubah, dan teks terjemahan memakai teks yang dapat menyesuaikan ruang. Hindari indikator yang hanya berubah warna. Gunakan satu pesan prioritas pada satu waktu dan jangan buka toko saat pemain menekan aksi darurat.

## Verifikasi setelah rancangan disetujui

- Uji lobi → dermaga → kemudi → lepas landas dengan input asli. Ukur waktu dari HUD siap hingga interaksi Mulai Penerbangan. Pisahkan waktu dari uji dengan pemain yang sudah tahu rutenya dan waktu dari pemain baru.
- Uji portrait 320 × 600 dan 390 × 700, landscape 749 × 322, tablet, serta desktop. Periksa hitbox aksi, batas layar, dan keterbacaan. Di perangkat fisik, cek zona jempol serta overlay bawaan Roblox.
- Uji pilot, penembak, dan teknisi. Cek 0/4/5 lubang, peringatan badai, mode terkunci, kit kosong, data lambat, tekstur gagal, serta teks alternatif yang lebih panjang.
- Pastikan hitung mundur, tinggi, kecepatan, dan amunisi tetap mengikuti data permainan. Catat hasil tanpa menganggap uji satu pemain membuktikan alur kru.

## Hasil implementasi HUD versi 9

- Pada Playtest satu pemain, navigasi otomatis dari spawn ke Dermaga C memerlukan sekitar 5,2 detik. Pemain masuk sebagai Master, memulai penerbangan lewat prompt, mengambil kemudi, dan menyalakan gas otomatis. Kecepatan menjadi positif dan hitung mundur berhenti. Durasi itu hanya untuk berjalan, bukan waktu orientasi pemain baru.
- Fixture menguji posisi kontrol penembak dan tali pada 320 × 600, 390 × 700, 749 × 322, 1024 × 768, dan 1277 × 662. Saat Playtest iPhone landscape 749 × 323, pistol diambil melalui prompt. Pemeriksaan visual menemukan overlay bawaan Roblox, sehingga utilitas dan amunisi dipindah. Pada iPhone portrait 401 × 718, fixture kontrol terakhir menegaskan amunisi, Tembak, dan Lompat berada pada baris terpisah.
- Snapshot 4 dan 5 lubang mempertahankan kartu kondisi saat Dinding Badai aktif. Kit kosong menunjukkan **Kit habis** dan menonaktifkan tombol. Penambahan kit pada fixture mengaktifkan **SAVE!**. Placeholder dan latar cadangan saat gambar kosong juga terverifikasi.
- Verifikasi belum mencakup perangkat fisik, permainan kru nyata, alur lengkap teknisi, atau penerjemahan dengan katalog terjemahan produksi. Skrip fixture hanya untuk sesi uji dan sudah dihapus.
