# Audit Fly High — 11 November 2026

> Tindak lanjut: [patch dan regresi audit](../audit-fixes-2026-11-11/README.md) menangani AUD-01/02/03/06. Pengguna meminta AUD-04/performa diabaikan. Laporan di bawah mempertahankan keadaan serta bukti sebelum patch; status terkini dipelihara di PROGRESS.

## Kesimpulan

Fondasi gameplay dan pembagian otoritas server sudah cukup baik, tetapi **belum layak dinyatakan lulus QA rilis**. Dua masalah direproduksi: fallback senjata memberi damage melewati dinding, dan perubahan preferensi dapat menjadwalkan save berulang tanpa penggabungan. Risiko kehilangan session ownership, performa Studio, serta perjalanan natural yang belum lulus membutuhkan tindak lanjut.

Audit ini mengumpulkan temuan dan rekomendasi; **tidak menerapkan patch gameplay**. Tidak melakukan publikasi, transaksi Robux, pengujian DataStore live, atau commit/push.

## Build dan cakupan

- Dasar Git: 44093850df0044a86a9285f0f9f0412023369e63, dengan perubahan lokal akses dermaga serta dokumentasi skill/knowledge yang sudah ada sebelum audit.
- [Perbandingan source](source-comparison.json): 41/41 source Studio cocok dengan mirror setelah normalisasi newline. [Pemeriksaan statis](static-results.json): 41 source lolos kompilasi.
- Review semantik berfokus pada DataManager, ShopManager, WeaponManager, BalloonManager, TetherManager, ServerUtils, FlightSpace, PodManager, CrewAccessGuard, JumpManager, PalaceArrival/PalaceManager, ObstacleManager dan jalur client terkait input/HUD/senjata/scenery. Ini bukan klaim bahwa setiap baris generator aset besar telah diaudit manual.
- Playtest satu klien native Studio, PlaceId/GameId 0, data mock terisolasi. Simulator iPad Pro M5 13in dan iPhone 17 Pro landscape. Bukan perangkat fisik atau benchmark multiplayer.
- Fixture: manager launch/boarding, root balon di-anchor untuk menstabilkan tembakan, target dummy beratribut obstacle, dinding penghalang, grace AFK sementara; perubahan label dihitung dengan wrapper Save yang meneruskan implementasi mock asli. Tidak mengukur AFK, laju terbang atau balancing pada fixture ini.
- Sekitar dunia Edit: 2.896 BasePart, 22 ParticleEmitter, 23 Light. Terdapat 304 part unanchored, tetapi [pemeriksaan assembly](cleanup.json) menunjukkan hanya dua assembly fisika unanchored, yaitu ayunan. Jangan menyamakan jumlah part itu dengan 304 objek fisika bebas.
- Metadata, SHA source/place dan batas terdapat di build.json. Isi binary tidak dibuka ulang untuk perbandingan.

## Temuan prioritas

### AUD-01 — P1 / Tinggi: damage senjata dapat menembus penghalang

**Lokasi:** [WeaponManager](../sources/ServerScriptService/FlyHighServer/WeaponManager.luau), baris 109–112 dan 144–150.

Server mengarahkan targetPos ke clientTargetModel, kemudian fallback menerima model jika jarak <=500 dan arah cukup dekat. Fallback tidak menolak obstruction dunia yang telah ditemukan raycast, kecuali envelope balon sendiri. Memvalidasi target model sebagai obstacle saja belum menyelesaikan line of sight.

**Reproduksi aktual:** muzzle → dinding pada jarak 30 stud → target pada jarak 70 stud. [Sebelum](shot-before.json): firstHit __AuditWall, health 10000, ammo 8. Satu tembakan via RemoteEvent dengan target model itu menghasilkan [health 9975 dan ammo 7](shot-through-wall.json), meskipun firstHit tetap dinding. Ini bug yang terkonfirmasi, bukan hanya risiko pola kode. Dummy berada di folder obstacle, sehingga validasi descendant saja tidak memperbaikinya.

**Perbaikan:** batasi target pada Model obstacle aktif yang dikelola server, lakukan raycast/shapecast dari muzzle dengan filter yang benar, dan jangan memakai aim-assist fallback bila ada penghalang sah sebelum target. Aim-assist boleh membantu toleransi sasaran, tetapi tidak melewati blocker. Tambahkan regresi dinding, envelope sendiri, jarak maksimum, target palsu dan target terhapus. [Dasar validasi Roblox](https://create.roblox.com/docs/scripting/security/client-server-boundary).

### AUD-02 — P2 / Sedang: preferensi pemain memicu save tanpa coalescing

**Lokasi:** [ShopManager](../sources/ServerScriptService/FlyHighServer/ShopManager.luau), baris 11 dan 19–21; [DataManager](../sources/ServerScriptService/FlyHighServer/DataManager.luau), baris 140–145.

Remote menerima perubahan label hingga satu per 0,25 detik; setiap perubahan langsung task.spawn Save. Save menunggu busy lalu tetap menulis snapshot, tanpa menggabungkan pekerjaan preferensi yang sudah tertinggal.

**Reproduksi aktual:** 12 toggle berjarak 0,28 detik memanggil Save **12 kali**. [Bukti](preference-save-count.json). Karena offline mode, ini bukti amplification pemanggilan Save, **bukan** 12 write cloud yang telah dilakukan atau bukti throttling live.

**Perbaikan:** tandai preference dirty, debounce/coalesce per profil, gabungkan dengan autosave, dan flush satu kali saat keluar/shutdown. Tetapkan rate limit yang sesuai jenis aksi. Pembelian/receipt tetap harus memakai jalur durable sendiri. Uji budget/retry di test universe saat pekerjaan cloud kembali diotorisasi. [DataStore](https://create.roblox.com/docs/cloud-services/data-stores).

### AUD-03 — P2 / Sedang, bersyarat cloud: tidak ada state session-lost

**Lokasi:** [DataManager](../sources/ServerScriptService/FlyHighServer/DataManager.luau), baris 35–50, 72–73, dan 93–145.

Lease kadaluarsa sesudah 180 detik; write menolak jika ID lease telah dimiliki server lain. Penolakan ini baik untuk mencegah overwrite profil baru. Namun setelah tiga kegagalan, sistem hanya warn dan return false; DataReady serta operasi progression tidak dipagari oleh state session-lost.

**Dampak bersyarat:** bila lease benar-benar berpindah saat sesi lama masih memproses aksi, sesi tersebut dapat terus menampilkan progres yang tidak lagi dapat disimpan. Ini temuan pembacaan kode, **belum direproduksi lintas server/cloud**, dan bukan klaim data sudah hilang.

**Perbaikan:** bedakan kegagalan jaringan sementara dari ownership yang pasti hilang; hentikan mutasi bernilai/grant pada ownership loss, cabut DataReady atau lakukan safe disconnect dengan pesan yang jelas. Uji retry, expiry, rejoin dan shutdown dalam lingkungan terisolasi. Pekerjaan cloud tetap ditunda sesuai DEFER-01.

### AUD-04 — P2 / Sedang: sampel frame time memerlukan profiling lanjutan

[Sampel](frame-sample.json): 69 frame selama sekitar tiga detik, median **44,03 ms**, p95 **45,27 ms**, kira-kira 23 FPS. [Snapshot runtime](performance.json): 7.732 instance client dan memori sekitar 3.239 MB.

Ini observasi Studio lokal dengan simulator, bukan benchmark iPhone/iPad nyata. Tidak membuktikan scenery menjadi penyebab tunggal, tidak membuktikan memory leak, dan tidak menetapkan anggaran memori perangkat produksi.

**Perbaikan berikutnya:** rekam MicroProfiler/Script Profiler, pisahkan biaya render/HUD/animasi/physics, ukur pada perangkat baseline nyata, lalu bandingkan satu variabel per percobaan. Prioritaskan pengurangan kerja per-frame dan biaya aset berdasarkan hasil profiling. [Batas emulator menurut Roblox](https://create.roblox.com/docs/performance-optimization/design).

### AUD-05 — P2 / Gerbang QA: perjalanan natural masih belum lulus

[Run terakhir](../journey-regression-2026-11-11/README.md) tetap menjadi bukti historis: solo terkendala driver sekitar 1.939 km; trio mencapai lima lubang dan jatuh; duo timeout sekitar 8.283 km dengan 149 reparasi. Run itu bukan hasil audit baru ini.

Regresi arrival 47/47, reparasi terarah dan native walking tidak mengubah status end-to-end menjadi hijau. Driver key-release sudah lulus terarah; perjalanan penuh setelah koreksi tersebut belum tersedia.

**Tindak lanjut:** benahi terminal guard dan input driver, ulangi perjalanan dengan seed/fixture terdokumentasi, lalu lakukan uji manusia sebelum menyimpulkan frekuensi rintangan harus diturunkan. Pertahankan OPEN-05 dan OPEN-01.

### AUD-06 — P3 / Rendah: tanaman menutup sebagian tulisan papan spawn

[Screenshot level pemain](spawn-eye.jpg) memperlihatkan daun tanaman di depan bagian bawah WelcomeSign. Jalur utama sendiri terlihat jelas. Ini masalah keterbacaan/onboarding kecil, bukan kegagalan akses dermaga.

**Perbaikan:** pindahkan tanaman keluar bidang pandang papan, cek avatar kecil/tinggi dan kamera masuk awal. Pertahankan framing papan serta jalan tanpa menambah teks tutorial.

## Yang sudah baik

- Server menentukan role, puncture, magazine/reload, pembelian dan progression; item/harga pembelian berasal dari config server.
- Receipt memiliki ledger PurchaseId dan baru diakui setelah grant/write berhasil. Load data gagal tidak langsung diteruskan sebagai profil default live. Ini temuan source; transaksi dan persistensi nyata belum diuji.
- [Uji NaN](shot-nan.json): health dan ammo tidak berubah dari tembakan sebelumnya. Validasi finite menolak request tersebut.
- Boarding memakai token dan karakter yang cocok; role mempunyai pemeriksaan pusat serta cleanup.
- Rekor/puncak, FIFO arrival, revive dan cleanup memiliki bukti terarah yang tersimpan pada run sebelumnya.
- Tidak ada LuaSourceContainer tambahan di luar tiga akar produksi pada snapshot Edit. Tidak ada fixture audit tertinggal.
- HUD menampilkan health 5/5 serta ammo 7/∞ dengan magazine 8 pada sampel. Native jump ganda tidak terlihat pada sampel.
- Jalan spawn menuju dermaga kini terlihat; lima rute sudah lulus pengujian native pada [QA akses](../dock-access-2026-11-11/README.md). Pengujian itu tidak diulang menjadi klaim baru di audit ini.

## Review HUD dan dunia

| Sampel | Bukti | Hasil dan batas |
| --- | --- | --- |
| Desktop weapon | [Screenshot](desktop-weapon.jpg) | Baseline. Nama capture awal sempat tablet, tetapi setter gagal sebelum aktivasi; file ini sengaja diberi label desktop. |
| iPhone 17 Pro landscape | [Screenshot](iphone-weapon.jpg), [rect](phone-ui.json) | Viewport 749×381; tombol utama 46–84 px, berada di dalam GUI pada sampel. Reflow compact tampak disengaja. Bukan semua state role. |
| iPad Pro M5 13in landscape | [Screenshot](ipad-weapon.jpg), [rect](tablet-ui.json) | Viewport 1375×1030; tombol utama 50–90 px, tidak tampak overlap utama pada sampel. |
| Setelan iPad | [Screenshot](ipad-settings.jpg) | Layout popup terbaca dan lock flight terlihat. Modal dibuka dengan Visible=true sebagai fixture layout; klik masuk menu tidak diklaim lulus. |
| Spawn | [Level pemain](spawn-eye.jpg) | Jalan/landmark terbaca; AUD-06 occlusion tanaman. |
| Istana Awan | [Edit view](palace-edit.jpg) | Siluet, kubah dan air terjun tersedia. Bukan inspeksi seluruh collision, cloud walking atau semua bioma perjalanan. |

UI tidak dinyatakan selesai terverifikasi untuk semua perangkat/state. Full scenery per bioma, kontrol analog nyata, gamepad, variasi avatar, latency/jitter, leak soak dan perangkat fisik belum diuji ulang pada audit ini.

## Error alat dan cleanup

[Console mentah](console-raw.json) menyimpan percobaan awal tool yang membaca _G manager dari sandbox MCP terisolasi, sehingga memunculkan nil/FlightBalloon errors. Audit kemudian memakai Script runtime + BindableFunction adapter untuk mengakses manager produksi. Error ini tidak dilabeli sebagai bug bootstrap game.

Percobaan orientation sebelum mengaktifkan perangkat juga ditolak oleh simulator. Urutan diperbaiki: pilih perangkat dahulu, lalu orientasi. Snapshot desktop yang salah diberi nama awal tidak dipakai sebagai bukti tablet.

Fixture gameplay mengubah runtime saja dan dibuang ketika Stop. Wrapper Save dipulihkan sebelum Stop. [Cleanup](cleanup.json) mencatat nol fixture dan nol script tambahan. Studio kembali Edit/Test/satu pemain, device default dan kamera pulau; save_place melaporkan tidak ada perubahan place yang perlu disimpan. Tidak ada patch source, commit atau push pada tugas audit ini.

## Urutan perbaikan yang disarankan

1. AUD-01: server line of sight dan validasi target senjata.
2. AUD-02: penggabungan save preferensi; AUD-03 sebelum mengaktifkan cloud.
3. AUD-04: profiling terarah, lalu optimasi yang terbukti.
4. AUD-05: ulangi full journey dengan driver terkoreksi dan review kesulitan manusia.
5. AUD-06: pindahkan tanaman penghalang papan.
