# Perbaikan sambungan jalan — 11 November 2026

> Temuan lanjutan pengguna: A/E masih salah dan terlewat pada foto B/C di run ini. Digantikan oleh [perbaikan ujung dan review visual A–E](../path-endpoints-fix-2026-11-11/README.md). Hasil uji berjalan di bawah tetap historis dan tidak membuktikan visual seluruh simpang benar.

Menggantikan geometri visual polesan sebelumnya. Pengguna menemukan sambungan B yang tidak rapi: slab persegi pada busur membuat gerigi, disk junction memakai pola berbeda dan menonjol dari batas jalan, sementara cap batu berwarna acak memperjelas ketidakselarasan. Uji berjalan sebelumnya memang lulus, tetapi tidak membuktikan geometri visual benar. Screenshot dekat pengguna adalah temuan sah.

## Perubahan akhir

- Busur visual kini tersusun dari trapesium annular dengan vertex yang sama antarsegmen. Batu mengikuti tiga baris radial, dengan nat tipis konsisten dan warna hangat yang lebih seragam.
- Border mengikuti lengkung dan dipotong pada mulut cabang; disk junction lama disembunyikan bersama slab/border lama. Collider lama tetap aktif, tidak dipindah atau diperlebar.
- Penanda huruf dipindahkan ke cabang lurus menuju dermaga. Lampu dan tanaman polesan sebelumnya dipertahankan.
- Lapisan bawah terpisah vertikal dari paver untuk menghindari z-fighting. Tidak menggunakan CSG. Seluruh 728 part visual anchored, non-collision/touch/query. Luas collider tetap sembilan stud.
- Source gameplay, Terrain, posisi dermaga dan summon clearance tidak berubah.

Generator Edit akhir: [build-surface.luau](build-surface.luau). Ini menggantikan paving visual dari generator path-polish lama; jangan menjalankan generator lama di atas hasil ini.

## Bukti dan QA

[Build](build.json) merekam HEAD dasar, dirty files, lingkungan dan SHA-256 place. Studio native solo, jaringan lokal, satu pemain dan viewport default.

- [Persimpangan B](junction-b.jpg) dan [persimpangan C](junction-c.jpg) diambil setelah Terrain selesai termuat. Tepi batu mengikuti busur dan sambungan tidak memakai patch lingkaran. B mencontohkan sambungan diagonal kiri, C simpang silang tengah; tidak mengklaim setiap kamera/perangkat telah diperiksa.
- [QA geometri](geometry-qa.json): 728 part, nol collider/query/touch tambahan, nol unanchored.
- [Driver berjalan](walk.client.luau), [hasil](walk-results.json): kelima rute A–E reached=true, CurrentPod benar dan pemain tetap hidup. Pose direset hanya di spawn sebelum tiap rute, tidak teleport/jump sepanjang rute; bukan input manual manusia atau perangkat fisik.
- [Console](console.json): hanya info mock offline; nol error/warning gameplay.
- [Cleanup](cleanup.json): nol fixture, Edit/Test/satu pemain; viewport/kamera pulau dipulihkan. [Save](save.json) lokal berhasil. Isi binary belum diperiksa lewat buka ulang. Belum commit/push.

Percobaan awal trapesium masih membuat lapisan dasar dan paver coplanar sehingga muncul pola segitiga/z-fighting; percobaan itu ditolak. Lapisan dasar diturunkan 0.09 stud dan material dibuat konsisten sebelum seluruh foto/QA akhir di atas. Tidak menggunakan screenshot percobaan itu sebagai bukti akhir.

## Pencegahan regresi

Untuk jalan melengkung, jangan menganggap susunan blok persegi otomatis menyatu. Periksa vertex sisi dalam/luar, batas cabang dan ketinggian lapisan. Uji locomotion dan review geometri visual adalah gerbang terpisah; lulus salah satunya tidak menutup yang lain. Foto lebar saja tidak cukup untuk menyatakan persimpangan rapi.
