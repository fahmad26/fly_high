# Arah dorongan angin dan Dinding Badai — 17 November 2026

Checkpoint Git yang memuat pembaruan ini mengarsipkan patch iPad, dorongan angin, katalog 493, binary dan bukti QA. Catatan belum commit/push pada run di bawah bersifat historis. File lokal terakhir disimpan kembali melalui Download a Copy dan diverifikasi tetap 3.526.811 B / SHA-256 `c96f7e20c2a3a62f3977135157985b8e93758874fdcd2f215adfded92880bc14`. Belum Publish; binary belum dibuka ulang. Tidak ada gameplay QA baru pada langkah commit ini.

## Perubahan

- `ObstacleManager`: Tornado/Jetstream memakai arah horizontal `item.velocity.Unit`, bukan selalu +X. Besar/durasi dorongan reguler tetap seperti sebelumnya; arah spawn/visual tidak diacak ulang.
- `LargeChallengeManager`: kecepatan sapuan disimpan pada item dan dipakai untuk gerak dinding serta gust. Benturan yang diterima `ApplyPuncture` memberi gust horizontal sebesar setengah kecepatan sapuan (30 stud/detik dengan sapuan 60), selama 3 detik. Ramp 0,45 dtk/fade 0,5 dtk dan clamp koridor memakai controller yang sudah ada. Pilot tetap dapat melawan dengan kemudi.
- Satu gelombang tetap maksimal satu benturan per balon. Shield, grace, ArrivalProtected dan menghindar di bawah dinding mencegah damage sekaligus gust dinding. Aturan proteksi angin reguler tidak diubah.
- Hanya dua source produksi di atas diedit pada pekerjaan ini. Perubahan AI lain pada sembilan source iPad dipertahankan; `BalloonManager.before.luau` merekam baseline yang sudah memuat patch tabrakan AI tersebut.

## Build dan bukti

Dasar HEAD `e41cdcde9e680140ee5c215324fbaaff8feaae81` dengan 14 file dirty + audit iPad dari AI lain saat mulai. Studio privat universe 10776821830/place 97043730132219, sesi `6adda177-a720-40b7-a9ae-95cace503005`. [Baseline](before-parity.json) memastikan tiga source terkait cocok isi mirror sebelum edit. [Manifest akhir](final-studio-manifest.json) dan [parity](source-parity.json): 64 source cocok hash SHA-256 normalized mirror, 64 compile. CRLF→LF/trimEnd; probe SHA sama dengan audit lokalisasi, rolling checksum hanya pendamping.

## QA terarah, Play Solo Windows / satu klien

[Driver akhir](runtime-driver.server.luau) dipasang hanya pada Server DataModel sebagai Script runtime `_QAWindDirection`, agar memakai tabel `_G` produksi. Bukan script produksi tersimpan. Manager LaunchBalloon/SpawnBand/Spawn dan heartbeat produksi dijalankan. Fixture memindahkan balon ke sekitar 1.800 km, mempercepat warning, mengubah beberapa lintasan untuk memeriksa arah, menjeda spawn otomatis, serta meng-anchor karakter mengikuti balon agar tidak mati. GrantCoins/UpdateAltitude/AddSummit dicegat sementara dan dipulihkan; tidak memberi hadiah, mengubah inventory, atau mencatat rekor QA pada profil.

- [Run 2](run2.json): **21/21 lulus**. Tornado ±X dan fixture ±Z berpindah sekitar 12,8 stud mengikuti arah. Jetstream +X/fixture −X berpindah sekitar 33,9/−34,3 stud. Tidak menambah lubang.
- Dinding bersapuan +Z memberi wind `(0,0,30)`, satu lubang dan perpindahan Z sekitar 75,7 stud tanpa kemudi selama keseluruhan gust. Sesudah gust berakhir, target Z tidak terus bergeser; tidak retrigger.
- Menghindar di bawah, shield, grace dan ArrivalProtected: masing-masing tanpa gust dan tanpa lubang.
- [Run 1 gagal](run1.json), [driver lama](runtime-driver-run1.server.luau) dipertahankan. Empat pemeriksaan salah mengambil sampel wind sesudah tornado berlalu (delta balon sudah sesuai arah); spawn dinding diblokir karena settling fixture membuat altitude turun di bawah tepat 1.800 km. Driver diulang dengan sampling puncak selama kontak dan altitude fixture ditetapkan tepat sebelum spawn. Tidak ada perubahan produksi untuk melonggarkan validator.
- [Console](console.txt) memuat satu error probe MCP yang mencoba membaca `_G` terisolasi; manager tersedia di Script runtime biasa. Ini error fixture, bukan error heartbeat game. Tidak mengklaim console keseluruhan kosong.

Cleanup run mencatat nol flight/obstacle/dinding, fungsi progres dan flag pause dipulihkan. Script runtime dihapus, Play dihentikan, Edit/default viewport pulih. Jumlah test satu pemain/mode Test tidak diubah. Tidak ada driver atau perubahan runtime masuk Edit. Tidak menguji multiplayer, perangkat fisik, penerbangan natural penuh atau kenyamanan visual/jaringan; angka di atas hasil fixture, bukan balancing final.

## Penyimpanan

Studio privat disimpan ke **Cloud v40**, tanpa Publish. File proyek lokal diambil melalui Download a Copy sesudah cleanup; hasil parse binary/hash dicatat di `binary-source-report.json`. Binary belum dibuka ulang pada pekerjaan ini; kesamaan source tidak membuktikan seluruh properti place. Belum commit/push pekerjaan ini. Status iPad sebelumnya “belum disimpan” adalah status sesi AI sebelumnya; source iPad ikut berada dalam simpan v40 ini, QA lamanya tidak diulang.

## Pengujian lanjutan atas permintaan pengguna

[Driver](followup-driver.server.luau), [hasil mentah](followup-results.json), [console](followup-console.txt), [verifikasi build](followup-verification.json). Build tetap Cloud v40 / binary `c96f7e20c2a3a62f3977135157985b8e93758874fdcd2f215adfded92880bc14`. Play Solo Windows satu klien/default viewport. Semua 64 source tetap hash yang sama dan compile sesudah QA; tidak ada perubahan kode produksi atau simpan/publish baru pada pengujian ini.

**31/31 pemeriksaan lulus**, termasuk beberapa sampel waktu warning (bukan 31 skenario independen):

- Spawn Tornado dan Jetstream melalui SpawnBand dengan lintasan asli, tanpa mengubah kecepatan/activeAt. Warning aktual ~3 detik; sampel sebelum benturan tanpa gust. Perpindahan mengikuti arah lintasan native yang terpilih pada run ini (+X).
- Dinding empat skenario memakai warning asli ~6 detik, tanpa melewati waktunya. Benturan tengah terjadi ~9,7 detik sejak spawn; dekat batas koridor ~11,7 detik. Masing-masing satu lubang.
- Tanpa kemudi: perpindahan Z ~75,7 stud. Dengan input kemudi −Z dari fixture heartbeat setelah wind tersedia, balon dapat melawan dan bergerak kembali. Input tersebut tetap ditahan setelah gust selesai; angka perpindahan akhir tidak dipakai sebagai ukuran kekuatan gust saja.
- Dekat batas koridor: target Z maksimal 120, sama dengan batas konfigurasi; tidak melewati batas target.
- Kasus terakhir: karakter dilepas dari anchor dan follower dimatikan. Sesudah sapuan dan gust, HP 100, posisi relatif `(0,141; 2,573; 0,008)` stud, tetap di keranjang. Ini satu avatar/solo, bukan bukti semua avatar/jaringan/multiplayer.
- Console run ini kosong. Cleanup runtime: nol flight/obstacle/dinding, fungsi progres/pause dipulihkan, driver dihapus, Edit/default viewport pulih. Pengaturan Test/satu pemain tidak diubah. Progres/hadiah dicegat selama fixture dan tidak dicatat pada profil.

Label `fixture` pada JSON mentah diwarisi driver run sebelumnya dan masih menyebut warning warp/karakter anchored secara umum. Label itu terlalu umum untuk run lanjutan: warning tidak di-warp; karakter hanya anchored pada kasus sebelum rider. Driver tersimpan, timestamp hasil dan `followup-verification.json` menjelaskan kondisi aktual. Screenshot yang sempat ditangkap tiba sesudah cleanup (lobby), sehingga tidak dipakai sebagai bukti visual benturan. Kenyamanan visual, perangkat fisik, perjalanan natural dan multiplayer tetap belum diverifikasi.
