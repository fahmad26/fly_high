# Rencana gerak rintangan Fly High

**Status: diimplementasikan di place lokal.** Sembilan segmen rintangan mendapat pola gerak tersendiri. Penanda petir dan meteorit memakai ukuran yang sama dengan pemeriksaan server. Lihat aturan rintangan global di [PRD](../../../PRD_Fly_High.md).

## Kondisi sebelum perubahan

Musuh reguler membidik sekali saat muncul dan kemudian meluncur lurus dengan kecepatan tetap. Bongkahan Es mulai dari posisi yang lebih tinggi, tetapi juga bergerak dengan kecepatan tetap. Dinding Badai menyapu koridor dengan kecepatan tetap dan memberi pemain garis batas bawah untuk membaca jalur aman.

Dua penanda bahaya perlu diselaraskan dengan pemeriksaan server:

- **Meteorit Mikro** menampilkan tiga jalur, sementara server memeriksa satu lintasan tengah dengan radius 26 stud. Pemain dapat mengira celah di antara garis aman dilewati.
- **Awan Petir** menampilkan garis di pusat sambaran. Server memeriksa pusat kubah balon hingga jarak horizontal 17 stud dari titik itu. Penanda perlu menunjukkan lebar area yang harus dihindari, dengan memperhitungkan ukuran balon.

Di build lokal, `ObstacleManager` mengatur gerak dan benturan reguler, `ObstacleArt` membangun model dan penanda visual, dan `LargeChallengeManager` mengatur sapuan Dinding Badai.

## Pola gerak per segmen

| Ketinggian | Gerak musuh | Gerak hazard |
| --- | --- | --- |
| 300–2.000 km | **Burung Liar:** kepakan tidak serempak, fase meluncur, dan formasi sedikit melebar saat belok. | **Angin Topan:** lapisan awan berputar dengan kecepatan berbeda. Dorongan terasa lebih kuat dekat pusaran dan melemah saat balon menjauh. |
| 2.000–3.000 km | **Kelelawar Badai:** kepakan cepat dan satu belokan pendek sebelum menukik. | **Awan Petir:** awan bergeser saat mengumpulkan energi. Titik sambaran terkunci saat laser muncul, dan penanda menunjukkan lebar area bahaya. |
| 3.000–4.000 km | **Bongkahan Es:** berputar tidak beraturan dan bertambah cepat saat jatuh. | **Jetstream Crosswind:** pita angin mengalir searah dorongan. Kekuatan dorongan naik dan turun secara bertahap. |
| 4.000–5.000 km | **Drone Penjaga:** melambat, menghadap sasaran, lalu memberi kilatan singkat sebelum menembakkan paku. | **Puing Kuno:** melayang perlahan dengan celah yang tetap terlihat. Area benturan mengikuti puing yang bergerak. |
| 5.000–6.000 km | **Lebah Api:** sayap bergetar cepat, badan naik-turun sedikit, lalu melesat pendek. | **Gelombang Panas:** tepi gelombang yang berpijar menyapu ruang dan mengikuti area benturan. |
| 6.000–7.000 km | **Wyvern Kristal:** kepakan berat, fase meluncur, dan tubuh miring saat belok. | **Anomali Magnetik:** kristal berputar perlahan. Pulsa yang terlihat mendahului pembalikan kemudi. |
| 7.000–8.000 km | **Phantom Bayangan:** perubahan tinggi yang halus dengan siluet yang tetap terbaca saat bisa ditembak. | **Kabut Hampa:** kabut merayap. Jarak pandang berkurang dan pulih secara bertahap. |
| 8.000–9.000 km | **Serpihan Satelit:** mempertahankan lintasan lurus sambil berputar pelan pada sumbu miring. | **Meteorit Mikro:** pecahan berputar dan melintas dengan jeda kecil. Area benturan mengikuti masing-masing jalur. |
| 9.000–10.000 km | **Phoenix Surgawi:** mendekat dengan lintasan melengkung lalu menukik, dengan jejak bara yang menunjukkan arah. | **Badai Gerbang Surgawi:** kolom yang akan menyambar berikutnya diberi tanda singkat. Batas bahaya pusaran terlihat terpisah dari kolom sambaran. |

Untuk **Dinding Badai**, pertahankan sapuan yang stabil dan garis bawah yang bisa diandalkan pemain. Variasikan gerak kabut dan pusaran di dalam dinding.

## Verifikasi di Studio

- Server memverifikasi gerak kesembilan musuh. Pada Awan Petir, pusat kubah di 18 stud dari pusat sambaran lolos, sedangkan di 16 stud terkena satu lubang setelah peringatan. Balon di celah meteorit lolos, sedangkan balon di tengah jalur terkena satu lubang. Tiga jalur mulai bergerak bergantian.
- Burung Liar, Kelelawar Badai, dan Drone Penjaga masing-masing terkunci oleh auto-aim dan menerima damage pistol di desktop serta emulator iPhone landscape. Uji mengarahkan kamera dan mengaktifkan Tool lewat skrip Studio.
- Drone melambat saat mengisi daya dan melepaskan paku sekitar 0,67 detik setelah kilatan mulai. Kepadatan kabut naik bertahap dan pulih setelah efek selesai. Kabut Dinding Badai bergerak, sementara balon yang ditempatkan di bawah batas lolos tanpa kerusakan.
- Uji ini memakai posisi terkontrol. Kenyamanan menghindar secara manual, performa ramai, dan keseimbangan dalam perjalanan penuh masih perlu diuji.
