# Perbaikan audit Fly High — 11 November 2026

## Hasil dan cakupan

AUD-01, AUD-02, AUD-03 dan AUD-06 sudah mendapat patch lokal. AUD-04/performa **diabaikan sesuai instruksi pengguna**, bukan diperbaiki atau dinyatakan lulus. AUD-05/full journey tetap OPEN-05; ini gerbang QA dari run lama, bukan akar bug produksi baru yang sudah terbukti. Tidak mengubah balancing agar bot lulus.

Build dasar 44093850df0044a86a9285f0f9f0412023369e63 dengan perubahan lokal sebelumnya tetap dipertahankan. [Build dan SHA source/place](build.json). Dua source berubah: [WeaponManager](../sources/ServerScriptService/FlyHighServer/WeaponManager.luau) dan [DataManager](../sources/ServerScriptService/FlyHighServer/DataManager.luau). ShopManager/client UI tidak diubah.

Studio ↔ mirror: [41/41 source cocok dan lolos kompilasi](source-comparison.json). Pemeriksaan membandingkan isi penuh setelah CRLF→LF dan whitespace akhir dibuang, memakai snapshot mirror yang sudah diperiksa saat audit serta dua patch terbaru. SHA-256 file mirror ada di build. Ini bukan pemeriksaan type checker penuh. [Place tersimpan lokal](save.json); binary **belum dibuka ulang** untuk membuktikan kesamaan objek/source dengan Studio. Belum commit/push pada tugas ini.

## Perubahan

- **AUD-01:** hint auto-aim hanya menerima Model langsung di folder FlyHighObstacles yang tercatat dalam activeObstacles server, hidup, shootable dan berada dalam waktu aktif. Hint salah ditolak sebelum ammo terpakai. Hapus fallback damage tanpa line of sight. Raycast berhenti pada penghalang; toleransi Spherecast hanya dipakai saat ray kosong dan kandidat memiliki LOS dari laras. Jarak hint maksimal 500 stud. Self-shot tetap diizinkan, balon tim lain tetap dikecualikan.
- **AUD-02:** label berubah langsung di memori/atribut, dengan satu timer tetap lima detik per profil. Nilai akhir yang sama dengan nilai tersimpan tidak ditulis ulang. Save lain, termasuk receipt, mencatat preferensi yang ikut tersimpan sehingga timer tidak menulis ulang. Keluar/shutdown tetap flush; receipt dan pilihan loadout tetap menggunakan jalur durable langsung.
- **AUD-03:** completed UpdateAsync yang membuktikan ID sesi berbeda/hilang memagari profil: DataReady=false, DataSessionLost=true, semua mutasi progres/inventaris/preferensi/grant diblokir, Save tidak mengulang overwrite, pemain diputus dengan pesan masuk kembali. Error jaringan biasa tetap retryable dan tidak dianggap kehilangan sesi. Release berhasil menandai sesi tidak boleh dipakai lagi. [Rujukan kontrak UpdateAsync dan pembatalan transform](https://create.roblox.com/docs/cloud-services/data-stores).
- **AUD-06:** ArrivalFern kiri dipindah dari (-12.5,10,39) ke (-23,10,39), sehingga tidak menutupi tulisan WelcomeSign. [Screenshot sesudah](spawn-sign.jpg). Ini pemindahan objek place, bukan source generator.

## QA aktual

Lingkungan: Native Studio Solo Test, satu klien, PlaceId/GameId 0, jaringan lokal/default viewport. Tidak ada transaksi Robux atau akses DataStore live.

| Skenario | Hasil aktual | Bukti |
| --- | --- | --- |
| Dinding 30 stud, target 70 stud | Ammo 8→7; health tetap 10000 | [wall](wall.json) |
| Target tanpa dinding | Satu tembakan mengurangi health 10000→9975; ammo 6→5 | [open-shot](open-shot.json) |
| NaN | Health 9975 dan ammo 5 tetap | [nan](nan.json) |
| Hint jarak 550 stud | Health 10000 dan ammo 5 tetap | [range](range.json) |
| Hint sebelum activeAt | Health 10000 dan ammo 5 tetap | [inactive](inactive.json) |
| Model tak terdaftar dan Folder spoof | Health 10000 dan ammo 5 tetap, tidak crash | [fake](fake.json) |
| Self-shot | Holes 0→1, ammo 5→4 | [self-shot](self-shot.json) |
| 13 toggle melalui remote native, 0.28 detik per toggle | Satu pemanggilan Save, label akhir false | [native-preferences](native-preferences.json) |
| Regresi DataManager mock | 16/16 assertion lulus | [data-regression](data-regression.json), [fixture](data-regression.luau) |
| Boot produksi bersih sebelum fixture preferensi tambahan | DataReady true, satu pemain, nol fixture; hanya info mock offline | [boot](clean-boot.json), [console](console-clean-boot.json) |
| Papan spawn | Seluruh tulisan tidak lagi tertutup tanaman pada sudut yang dicapture | [screenshot](spawn-sign.jpg) |

Regresi data mengeksekusi badan kode DataManager terbaru dengan fake store/player/task/Instance. Bootstrap layanan dan event footer tidak dijalankan pada mock. Scheduler virtual mempercepat timer, fake store memanggil transform produksi; ini **bukan persistensi lintas server/cloud**. Mencakup 12 toggle yang kembali ke nilai semula (0 write), 13 toggle (1 write), receipt segera dan deduplikasi, receipt ikut flush preferensi, release flush dan pembatalan timer, retry jaringan sementara/berulang, pemulihan, foreign owner dan penolakan mutasi sesudah session-lost.

Fixture senjata memakai manager launch/BoardReady, root balon/avatar di-anchor dan balon digeser +200 stud agar target stabil di band aktif. Obstacle dummy didaftarkan server dengan field gerak lengkap, bukan dibuat lewat spawn alami; sumber [adapter runtime](weapon-runtime.server.luau). Auto-aim client tidak diubah; tidak mengklaim QA sentuh/perangkat fisik baru. Shield fixture dilepas sebelum self-shot.

Untuk mereplay LOS: launch/equip/Target; fire remote ke PrimaryPart dummy, baca Read. Lalu nonaktifkan **CanCollide dan CanQuery** pada __AuditFixWall sebelum tembakan tanpa dinding. Percobaan awal hanya menonaktifkan CanQuery masih diblokir karena CanCollide=true; satu peluru tambahan terpakai dan target tetap utuh. Karena itu bukti clear shot dimulai ammo 6, bukan 7. Ini kegagalan fixture, bukan regresi senjata.

Counter Save awal di run senjata mencakup autosave berkala sehingga bernilai 2/3 pada sebagian snapshot; jangan menafsirkannya sebagai jumlah save preferensi. Run native terpisah di atas mengukur satu perubahan batch dengan caller DataManager baris 170, dan mock memeriksa jumlah write secara deterministik.

## Error fixture, cleanup dan batas

[Console fixture mentah](console-fixtures.json) menyimpan penolakan loadstring di sandbox MCP, percobaan properti LoadStringEnabled yang tidak tersedia, dan assignment path fixture salah. Harness kemudian memakai badan source yang dibungkus fungsi biasa dengan dependency fake; tidak mengaktifkan loadstring pada game. Warning Save failed/session ownership lost di run itu sengaja berasal dari fake user 987654. Run boot produksi berikutnya bersih; log gagal tidak dihapus.

[Cleanup](cleanup.json): nol __Audit fixture, Edit, Test satu pemain, default viewport/kamera pulau. Seluruh Script/BindableFunction/wrapper Save hanya runtime dan dibuang saat Stop. Screenshot pertama memakai capture tool tanpa capture_id ditolak; capture akhir berhasil. Ekspor screenshot pertama melewati batas ukuran auto-review tool; diselesaikan dengan chunk kecil tanpa mengubah izin.

Sisa QA: OPEN-05 penerbangan alami solo/duo/trio dengan driver terkoreksi dan review manusia; latency/perangkat fisik; DataStore rejoin/lease expiry/shutdown sesungguhnya ketika DEFER-01 dibuka. Jangan menandai rilis penuh hijau berdasarkan regresi terarah ini.
