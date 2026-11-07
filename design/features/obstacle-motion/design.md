# Rencana gerak rintangan Fly High

**Status: menunggu persetujuan pengguna untuk implementasi.** Rencana ini membahas gerak, keterbacaan bahaya, dan cara mengujinya. Analisis memakai build lokal dengan sembilan segmen rintangan reguler dan zona lepas landas bebas rintangan di bawah 300 km. Lihat bagian rintangan global di [PRD](../../../PRD_Fly_High.md).

## Kondisi saat ini

Musuh reguler membidik sekali saat muncul dan kemudian meluncur lurus dengan kecepatan tetap. Bongkahan Es mulai dari posisi yang lebih tinggi, tetapi juga bergerak dengan kecepatan tetap. Dinding Badai menyapu koridor dengan kecepatan tetap dan memberi pemain garis batas bawah untuk membaca jalur aman.

Dua penanda bahaya perlu diselaraskan dengan pemeriksaan server:

- **Meteorit Mikro** menampilkan tiga jalur, sementara server memeriksa satu lintasan tengah dengan radius 26 stud. Pemain dapat mengira celah di antara garis aman dilewati.
- **Awan Petir** menampilkan garis di pusat sambaran. Server memeriksa pusat kubah balon hingga jarak horizontal 17 stud dari titik itu. Penanda perlu menunjukkan lebar area yang harus dihindari, dengan memperhitungkan ukuran balon.

Di build lokal, `ObstacleManager` mengatur gerak dan benturan reguler, `ObstacleArt` membangun model dan penanda visual, dan `LargeChallengeManager` mengatur sapuan Dinding Badai.

## Usulan per segmen

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

## Urutan pengerjaan setelah disetujui

1. Selaraskan penanda dan area benturan Meteorit Mikro serta Awan Petir. Pastikan celah yang terlihat aman memang bisa dilalui oleh balon.
2. Prototipe Burung Liar, Kelelawar Badai, dan Drone Penjaga. Bandingkan gerak ketiganya dalam penerbangan untuk memastikan setiap pola mudah dikenali dan bisa direspons.
3. Terapkan pola yang sama pada musuh dan hazard lainnya. Tambahkan variasi visual di dalam Dinding Badai tanpa menggeser penanda bawah dari batas aman.

## Kriteria uji di Studio

- Coba melintas di dalam dan di luar penanda petir, serta di antara jalur meteorit. Kerusakan harus sesuai dengan area yang terlihat setelah peringatan berakhir.
- Coba menghindar, membidik, dan menembak tiga musuh prototipe di desktop dan emulator layar sentuh. Gerak harus cukup terbaca bagi pilot dan gunner, termasuk saat balon sedang bermanuver.
- Uji bahwa paku drone keluar setelah kilatan, serta celah puing dan batas bawah Dinding Badai tetap sesuai dengan area benturan selama objek bergerak.
