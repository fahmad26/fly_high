# Layout popup kedatangan Istana Awan — 19 November 2026 WIB

Versi akhir menaikkan ketiga baris teks di dalam kartu. [Tangkapan layar dan pengukuran akhir](#revisi-posisi-teks-di-dalam-kartu) mencakup desktop serta emulator iPhone, Galaxy A06, dan iPad Pro. Dua bagian pertama merekam tampilan awal dan revisi posisi kartu sebelum teks dinaikkan.

## Tampilan awal

Play Solo di Studio Windows, satu pemain, viewport desktop 2090×752, English. Build dibuka dari Fly High.rbxl di sesi Studio `393f0be6-f0f9-4def-aa6f-3ce28f265eaa`; SHA-256 file lokal `B2EE9143C0276DF7180D4BE5CBBEF63A742273CE01CFD90B95A8742F11CE66D9`. Preview memakai cutscene aktif dan fixture lokal klien yang menyimulasikan Docking → Departing serta posisi karakter di dermaga. Tidak menjalankan penyelesaian penerbangan atau pemberian hadiah server.

[Screenshot](arrival-popup-en.jpg) menunjukkan kartu biru tua dengan bingkai sian dan emas di tengah bawah. Kartu berukuran 434,5×158 px saat diukur. Teks terlihat `CLOUD PALACE REACHED`, `10,000 km · Summit #15 · 0:00`, dan `+150 coins`. Judul lokasi masih terlihat di atas saat tangkapan. Durasi 0:00 berasal dari fixture. Pratinjau ini hanya mencakup tampilan cutscene English di desktop.

Play dihentikan. Studio kembali ke Edit dengan 0 pemain, TestService disetel satu pemain, dan fixture sudah tidak ada.

## Revisi posisi kartu dan framing kamera

Play Solo Windows di Studio `e55b4fd4-8743-40e2-ab9b-349e7a61b36b`, place lokal `97043730132219`. Data normal siap. Fixture klien mensimulasikan Docking → Departing agar pemain melihat kartu dari `PalaceCinematics` dengan kamera, terjemahan, dan animasi produksi. iPad memakai kondisi kru gugur. Durasi `0:00` berasal dari simulasi. Koin dan rekor server tidak diberikan oleh fixture ini.

| Viewport landscape | Ukuran kartu | Jarak dari bar hitam | Screenshot |
| --- | ---: | ---: | --- |
| Desktop 2090×752 | 420×147,4 px | 26,8 px | [Desktop](after-desktop.jpg) |
| iPhone 17 Pro 749×381 | 347,5×121,9 px | 17,5 px | [iPhone](after-iphone.jpg) |
| Galaxy A06 705×338 | 308,3×108,2 px | 16,5 px | [Android](after-android.jpg) |
| iPad Pro M5 13 inci 1375×1031 | 420×147,4 px | 33,8 px | [iPad](after-ipad.jpg) |

Kartu berada di tengah area aman dan ketiga baris teks English muat di semua ukuran. Judul pengantar tersembunyi ketika kartu muncul. Uji awal di Galaxy A06 menunjukkan ikon kartu menutupi wajah avatar. Framing pendaratan di layar pendek kini mengangkat avatar dalam komposisi, dan tangkapan akhir menunjukkan jarak antara avatar dan kartu. Jarak di tabel diukur dari frame kartu ke bar saat animasi kartu selesai. [Pengukuran, hash build dan cleanup](layout-results.json) [Console](console.txt).

Satu source yang diubah lolos compile dan SHA-256 Studio cocok dengan mirror. Studio menyimpan `Fly High.rbxl` lokal (3.534.690 byte, SHA-256 `4c67978a775a82d64c63a6106521b4c98d606de3bd53ba34e4b53e5aba43c7a2`). File tersimpan belum dibuka ulang. Preview memakai emulator landscape dan desktop. Perangkat fisik, penerbangan penuh, serta jalur dengan cutscene dimatikan berada di luar run ini. Studio kembali ke Edit, 0 pemain, TestService satu pemain dan viewport 2090×752. Fixture dibuang sebelum menghentikan Play.

## Revisi posisi teks di dalam kartu

Ketiga baris dinaikkan di dalam kartu. Judul bergeser 3,5% dari tinggi kartu. Rincian penerbangan dan baris hadiah atau kebangkitan bergeser 5,5%, sehingga baris terakhir mendapat tambahan ruang sekitar 6–8 px pada layar yang diuji.

Play Solo pada Studio Windows dan place yang sama, satu pemain, English, dengan fixture Docking → Departing dari pemeriksaan sebelumnya. Semua baris muat dan area teks antarbaris terpisah. Jarak dari teks terakhir ke tepi frame terukur 18,0 px di [Galaxy A06](text-android.jpg), 20,5 px di [iPhone 17 Pro](text-iphone.jpg), dan 24,3 px di [desktop](text-desktop.jpg) dan [iPad Pro](text-ipad.jpg). Screenshot iPad memakai pesan kru bangkit. [Pengukuran](text-results.json) [Console](text-console.txt).

Source yang direvisi lolos compile dan hash Studio cocok dengan mirror. Studio menyimpan file lokal 3.534.689 byte dengan SHA-256 `1782d9689cc2ac3b10c8eee95daa28bc752f56c257d9d8b8bcb623e05dada05c`. File tersimpan belum dibuka ulang. Fixture klien dihapus, Play dihentikan, dan Studio kembali ke Edit dengan viewport default serta jumlah Test satu pemain. Cakupan perangkat sama dengan pemeriksaan di atas.
