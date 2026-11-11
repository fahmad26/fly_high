# Bukti analisis referensi motion HUD

Tanggal sesi: 11–12 November 2026, Asia/Jakarta; folder mempertahankan tanggal mulai. Lingkungan: file video lokal dianalisis visual menggunakan PyAV 19.0.2 + Pillow, tanpa menjalankan game/plugin yang tampil di dalam video. PyAV disimpan pada tooling lokal `.local-tools/video-analysis` (diabaikan Git). Audio belum dianalisis.

Ini bukti analisis desain, **bukan QA gameplay atau bukti HUD Studio saat ini**. Build source lokal: main berbasis `44093850df0044a86a9285f0f9f0412023369e63`, working tree sudah dirty sebelum tugas. [Snapshot](source-snapshot.json) menyimpan SHA-256 berkas HUD yang diperiksa dan status Git setelah draft dokumentasi ditulis. Tidak ada fixture Playtest; tidak mengubah Test/player count/viewport.

- [Desain dan rencana draft](../../design/features/hud-motion/design.md).
- [Metadata dan SHA-256 video asli](metadata.json). Video asli tetap di D:/Downloads, tidak disalin ke repo.
- [Video 1, overview seluruh durasi](video-1-overview.jpg), 19 sampel berjarak sekitar 2,25 detik.
- [Video 2, overview seluruh durasi](video-2-overview.jpg), 19 sampel berjarak sekitar 4,98 detik.
- [Video 1, menu/progression/reward 5,5–19 detik](video-1-5.5-19.jpg), langkah 0,5 detik.
- [Video 2, demo tombol 0–7 detik](video-2-0-7.jpg), langkah 0,35 detik.
- [Video 2, ekspor dan demo akhir 85–94,5 detik](video-2-85-94.5.jpg), langkah 0,5 detik.

Timestamp label adalah waktu frame hasil decode. Lembar overview mempertahankan frame lengkap yang diperkecil; lembar detail memotong area monitor/UI untuk keterbacaan, bukan bukti resolusi game. `extract.py` dan `details.py` mereproduksi sampel dari path video lokal tersebut.

Hasil aktual: perubahan ukuran tombol/dekorasi dadu terlihat pada video 2; perubahan progression dan reveal reward terlihat pada video 1. Easing, trigger persis hover/klik, smoothness antarpotongan menu dan gerak highlight diagonal tidak dipastikan dari rekaman. Nama plugin/promo di video tidak diaudit/diinstal sebagai bagian tugas ini.

Tidak ada klaim pengukuran performa, suara, pengujian touch atau kesamaan Studio–mirror–binary. Belum ada implementasi motion baru.
