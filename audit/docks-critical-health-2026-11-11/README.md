# Dermaga dan rintangan pada health 1/5 — 11 November 2026

## Perubahan

- Kelima dermaga kini mengikuti setengah lingkaran radius 90 stud dengan pusat (0, 15) pada bidang XZ. A/E berada di sisi depan, C di tengah belakang, B/D di antaranya. Jarak terdekat 68,883 stud, di atas clearance balon 60 stud. Dermaga C tidak lagi bertumpuk dengan plaza spawn.
- Jalur tanah berbentuk promenade setengah lingkaran radius 70, dengan sambungan pendek ke setiap dermaga dan satu jalur utama dari spawn. Material jalur lama dibersihkan tanpa mengubah ketinggian/occupancy Terrain, laut atau pantai.
- Papan menghadap area spawn. PreviewBase miniatur diperbarui mengikuti transformasi dermaga. Pohon dan dekorasi penghalang dipindahkan; area diperiksa terhadap lokasi platform **dan** offset spawn balon Z -18. Jarak minimum pohon terhadap titik spawn akhir sekitar 45 stud.
- Prediksi lama menambahkan +12,5 stud saat gas aktif tanpa memeriksa arah gerak aktual. Pada empat lubang, balon justru turun sekitar -2,08 stud/detik dengan gas atau -4,15 tanpa gas. Contoh prediksi lama meleset vertikal sekitar 21,5/19,6 stud, melampaui radius hit 18.
- Musuh kini memakai kecepatan vertikal bertanda dan waktu tempuh per proyektil. Aim ditentukan sekali saat spawn; bukan homing. Hazard memperhitungkan warning + titik tengah durasi aktif. Charge drone memakai prediksi waktu tembak. Frekuensi, health, radius damage, grace period dan safe zone tidak diubah.

## Bukti

- [Screenshot akhir](top-final.jpg) dan [layout akhir](layout-final-results.json).
- [Playtest akhir](playtest-results.json): 18/18 kombinasi sembilan jenis musuh tembak × gas aktif/dilepas berhasil memberi lubang kelima pada balon dengan empat lubang. Balon sehat masih dapat terkena; di bawah 300 km tetap tidak boleh spawn musuh.
- Sepuluh pemeriksaan okupansi lulus: balon di dermaga yang sama memblokir summon; empat proxy balon di dermaga lain tidak memblokir. Proxy memakai model balon dan posisi spawn produksi, bukan lima tim manusia.
- [Identitas build](build.json), [driver test](server-playtest.luau) dan [skrip layout](layout.luau).

Playtest memakai satu pemain dan balon produksi. Ketinggian di-warp antarband, karakter di-anchor/dibawa untuk pengukuran, grace jarak boarding diperpanjang saat warp, empat lubang disiapkan melalui ApplyPuncture, invulnerability direset sesudah setup, spawning alami serta Dinding Badai dipause. Musuh manual memakai gerakan dan damage produksi, tanpa shield. Ini bukan perjalanan penuh atau uji dodge/performa/perangkat fisik. Angka 137 checks dalam JSON mencakup assert persiapan fixture; bukan 137 skenario gameplay berbeda.

[Attempt pertama](attempt1.json) gagal karena aktor tidak dipindahkan secara atomik saat warp antarcase, sehingga flight berakhir sebelum case berikutnya. Driver diperbaiki, hasil gagal tetap disimpan. Pemanggilan MCP awal juga kehilangan respons saat pergantian mode; hasil berikutnya ditahan di konteks Edit sebelum diekspor. Dua percobaan layout awal kehabisan kandidat pohon; kandidat ditambah dan material Ground jalur lama diterima sebagai tanah. Penataan akhir diverifikasi lagi secara statis.

Setelah playtest, satu pohon dan dekorasi tambahan disingkirkan dari offset spawn A/E; posisi dermaga dan source gameplay tetap sama. Screenshot akhir merekam keadaan sesudah perapian tersebut. Seluruh 41 source lolos kompilasi; dua source yang berubah cocok dengan mirror. Place tersimpan lokal, fixture dihapus, kembali Edit/Test/satu pemain. Binary belum dibuka ulang untuk perbandingan isi. Belum commit/push.
