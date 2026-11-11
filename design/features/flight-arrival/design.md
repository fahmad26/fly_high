# Stabilitas penerbangan dan kemenangan tim

Disetujui pengguna 11 November 2026. Status verifikasi mengikuti [PROGRESS](../../../PROGRESS.md).

## Aturan produk

- Kelima dermaga dapat meluncurkan balon secara bersamaan selama volume spawn masing-masing kosong. Balon dari tim mana pun tetap memblokir dermaga yang ditempatinya.
- Revisi layout 11 November: FloorPad A–E mengikuti busur radius 90 stud berpusat XZ (0,15), pada sudut -90/-45/0/45/90 derajat. Posisi XZ berturut-turut (-90,15), (-63,64;-48,64), (0,-75), (63,64;-48,64), (90,15). Titik spawn balon tetap offset Z -18. Jarak terdekat 68,883 stud, melebihi clearance 60. Tata letak zigzag sebelumnya telah diganti; perubahan disimpan sebagai objek place. Lihat [QA layout](../../../audit/docks-critical-health-2026-11-11/README.md).
- Keberhasilan satu penerbangan memberi satu puncak kepada seluruh anggota roster yang masih terhubung, termasuk yang telah mati. Roster dikunci saat launch; bukan semua pemain di server.
- Pemain mati dihidupkan kembali di Istana Awan saat tim mendarat. Anggota yang sudah keluar dari server tidak ditransportasikan.
- Jika tim gagal, rekor tiap pemain dihitung dari ketinggian tertinggi selama masih hidup, bukan ketinggian tim setelah pemain mati. Rekor terbaik dari penerbangan sebelumnya tidak diturunkan.
- Overhead menampilkan jumlah puncak jika lebih dari nol; jika belum pernah menang, tampilkan rekor ketinggian.

## Pemilik state

- BalloonManager menetapkan hasil tepat sekali dan menyimpan personalBest per pemain. Death handler mengambil sampel akhir sebelum menandai pemain mati. Setiap Heartbeat memperbarui peak hanya untuk anggota hidup.
- DataManager tetap menjadi pemilik MaxAltitude dan SummitCount. Tidak ada reset data maupun perubahan skema pembelian.
- PalaceArrival mengantrekan pemenang secara FIFO. Satu worker mengurus docking, penurunan pemain dan keberangkatan sebelum mengambil balon berikutnya.
- Balon pemenang langsung dilindungi dari damage. Collision/touch fisiknya dimatikan selama antrean/animasi, lalu dihapus dari pemeriksaan penghalang penerbangan biasa.
- Penumpang hidup mengikuti balon dengan offset yang ditangkap server. Respawn tiap pemain ditangani terpisah dengan batas tunggu worker agar satu pemain tidak menahan antrean selamanya. Referensi karakter diperiksa lagi sebelum dipindahkan.
- Setelah penumpang turun, balon naik 180 stud dalam 1,4 detik dan di-destroy. Tidak ada timer destroy tetap yang memotong antrean.

## Stabilitas gerak

- Posisi memakai AlignPosition non-rigid dengan gaya diterapkan di pusat massa.
- Target tilt dihaluskan berdasarkan waktu frame.
- Kontak fisik antardua assembly balon dimatikan; FlightSpace tetap menegakkan pemisahan dan BalloonManager memberi lubang pada tabrakan. Ini menghindari solver kontak melawan mover dengan dua koreksi berbeda.
- Kualitas visual di jaringan/perangkat fisik tetap memerlukan pengujian tersendiri. Perubahan ini tidak menjanjikan hilangnya seluruh jitter replikasi.

## Verifikasi

Driver terkontrol: [flight-fixes-2026-11-11.server.luau](../../../audit/flight-fixes-2026-11-11.server.luau). Driver hanya boleh dipasang sementara, tidak disimpan ke place produksi. Hasil run, kegagalan dan batasnya ditautkan dari PROGRESS setelah pengujian.
