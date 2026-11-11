# Polesan jalan dermaga — 11 November 2026

Jalan spawn–promenade–dermaga A–E kini memakai paving sandstone dengan variasi warna hangat dan sambungan fisik yang terbaca, border slate, sepuluh lentera, empat taman sage/daisy dan lima medali penanda A–E dengan batu pemandu berwarna tema dermaga. Tidak memakai import pihak ketiga atau script runtime baru.

80 slab jalan diberi material/warna baru; 231 cap paving non-collision membentuk pola susun tiga/empat kolom. Cap tipis berada di atas slab, hanya kosmetik. Lebar collider jalan tetap sembilan stud; posisi dermaga, summon volume dan Terrain tidak berubah. Persimpangan dibiarkan terbuka. 529 part dekorasi total, seluruhnya anchored, CanCollide/CanTouch/CanQuery=false. Lentera memakai Neon tanpa PointLight tambahan.

[Screenshot jalan utama](path-main.jpg) dan [persimpangan C](dock-junction.jpg) diambil saat Play, setelah aset termuat. Capture awal sesaat setelah Play sempat merekam Terrain belum selesai termuat; tidak dipakai sebagai bukti akhir.

## Build, generator dan QA

- [Build](build.json): Git dasar, perubahan lokal sebelumnya, SHA-256 place dan lingkungan. Perubahan hanya objek/material place; source gameplay tidak disentuh.
- Rekonstruksi Edit: jalankan [build-path](build-path.luau), kemudian [pavers](pavers.luau) sekali. build-path membersihkan model dekorasi sebelumnya. Jangan menjalankan pavers berulang tanpa membersihkan HandCutPaver atau mengulang build-path.
- [Geometri](geometry-qa.json): 529 part dekorasi, nol blocking/query/touch dan nol unanchored. [Build result](build-results.json) diambil sebelum penambahan 231 paver, sehingga mencatat 298; bukan konflik inventaris akhir.
- [Driver native](walk.client.luau), [hasil](walk-results.json): Studio solo, satu pemain, lima rute dari spawn melewati jalan utama dan waypoint busur sampai pusat tiap dermaga. Kelimanya reached=true, CurrentPod cocok A/B/C/D/E, pemain tetap hidup. Pose direset hanya di spawn sebelum masing-masing rute, tanpa teleport sepanjang rute atau jump. Tidak mengukur input manusia/perangkat fisik, beberapa avatar atau lima tim sekaligus.
- [Console](console.json): hanya informasi mock data offline, nol error/warning gameplay.
- [Cleanup](cleanup.json): nol fixture, Edit/Test/satu pemain, viewport default dan kamera pulau. [Save](save.json) lokal berhasil; binary belum dibuka ulang. Belum commit/push.

Sisa review: kenyamanan visual manusia dan tablet/ponsel sungguhan. Hasil ini tidak mengubah status QA perjalanan penuh atau cloud.
