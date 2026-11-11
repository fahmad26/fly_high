# Reparasi bergerak dan loncat setelah pergantian role — 11 November 2026

## Hasil akhir

| Run | Hasil | Cakupan |
| --- | --- | --- |
| [Trio akhir](repair-motion-trio-final-pass-2026-11-11.json) | 40/40 lulus | Tiga reparasi saat manuver, early finish ditolak, payload tidak valid ditolak, hold dibatalkan, remote client tervalidasi, turun dan enam kondisi loncat setelah/per role |
| [Solo native akhir](repair-motion-solo-final-pass-2026-11-11.json) | 11/11 lulus | Virtual keyboard E pada prompt native, manuver, tambalan selesai berdasarkan timer server, turun dan lepas tali |
| [Pelepasan awal](repair-motion-native-early-cancel-2026-11-11.json) | Skenario early release lulus; keseluruhan run gagal pada percobaan hold berikutnya | Bukti pembatalan fisik sebelum durasi. Bukan hasil suite hijau. |
| [Identitas source/place](build.json) | Inspeksi akhir | Hash source/place, scope dan cleanup |

Kedua run akhir tidak mencatat runtime error game. Uji memakai warp ketinggian, anchor balon **hanya selama setup/katrol awal**, shield, pengisian ulang durabilitas antarpercobaan independen dan penempatan karakter oleh fixture. Balon tidak di-anchor selama manuver/reparasi/jump yang diukur. Ini bukan penerbangan penuh, uji jaringan buruk, performa atau pengujian sentuh perangkat fisik. Varian utama yang diuji adalah Koi.

## Temuan dan perbaikan

- [Reproduksi input masih ditekan](repair-motion-key-held-reproduction-2026-11-11.json) mencatat native hold berakhir sekitar 0,66 detik, sedangkan E masih down dan durasi yang diwajibkan 1,5 detik. Jangan menyimpulkan bahwa key sudah dilepas hanya dari hilangnya prompt dunia.
- Client melacak pelepasan input fisik (keyboard, mouse, touch, gamepad); server tetap memeriksa pemain hidup, Catwalk, jarak **10 stud**, nomor lubang, durasi dan pembatalan. Timer server menangani completion tanpa bergantung pada satu event Triggered.
- RepairHoleEvent lama belum memiliki handler; kini dihubungkan ke validasi server. Pengiriman Begin berulang tidak mereset waktu hold. Cancel tidak diblokir oleh rate limit Begin.
- Controller mendaftarkan ulang balon ketika atribut tema datang setelah model, serta hanya menulis Enabled prompt jika nilainya berubah.
- Katrol memulihkan Humanoid dari state jatuh/Physics pada server dan client. Tap loncat diberi buffer maksimal 0,2 detik sampai ada lantai valid, tanpa menambah air jump atau mengubah izin role.

## Eksperimen yang dibatalkan dan batas bukti

Semua hasil gagal tetap disimpan. Penguncian karakter selama tambal menimbulkan regresi dan **dibatalkan**. Percobaan memperluas radius ke 12 stud juga dibatalkan; source akhir tetap 10. Beberapa run gagal karena setup warp, durabilitas tali habis saat terlalu banyak percobaan, atau input mouse pada FPS. Jangan memakai kegagalan tersebut sebagai bukti bahwa source akhir lulus; lihat dua run akhir di atas.

Field nativePromptInput pada sebagian laporan diagnosis lama masih menyebut InputHoldBegin/End meskipun revisi driver sudah memakai SendKey. Laporan tersebut dipertahankan apa adanya. Run solo akhir memperbaiki identitas input; gunakan source driver dan laporan akhir untuk reproduksi.

Driver akhir: [server trio](repair-motion-final-multiplayer.server.luau), [client trio](repair-motion-final-multiplayer.client.luau), [server solo](repair-motion-final-solo.server.luau), [client solo](repair-motion-final-solo.client.luau). Driver bersyarat GetTestArgs == RepairMotionQA membutuhkan RemoteEvent sementara RepairMotionQA di FlyHigh.Remotes. Jangan menyimpan driver/remote ini dalam place produksi. Setelah test, pulihkan Edit / Test / satu pemain dan hapus fixture.

Touch/gamepad sudah memiliki jalur input dalam kode tetapi belum diverifikasi pada perangkat fisik. Latency publik dan uji perjalanan penuh tetap terbuka. Source binary tersimpan belum dibuka ulang untuk pemeriksaan kesamaan isinya.
