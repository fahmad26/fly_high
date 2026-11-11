# Knowledge praktis Roblox dan Luau

Diverifikasi terhadap sumber primer pada 11 November 2026. Ini panduan engineering, bukan pernyataan bahwa seluruh rekomendasinya sudah diimplementasikan di Fly High. Aturan fitur mengikuti [PRD](../../PRD_Fly_High.md); status aktual mengikuti [PROGRESS](../../PROGRESS.md).

## 1. Lua dan Luau

Roblox memakai Luau yang berakar pada Lua 5.1 dengan perubahan untuk sandbox, fitur bahasa dan tipe. Jangan menganggap Lua 5.4/5.5, LuaJIT, Lua luar Roblox, dan Luau memiliki library yang identik. Akses filesystem/sistem operasi umum dari tutorial Lua tidak dapat langsung dipindahkan ke Script Roblox. Dasar yang perlu dikuasai: scope local, closure, function, table, metatable, iterator, error handling dan coroutine. [Kompatibilitas resmi](https://luau.org/compatibility/).

Tipe gradual membantu menemukan kesalahan sebelum runtime. Gunakan --!strict pada modul baru yang sesuai, tipe pada kontrak publik, optional types dan refinement sebelum mengakses Instance. Hindari menutup error dengan any atau cast tanpa validasi. Lakukan migrasi legacy bertahap, bukan refactor seluruh proyek bersamaan dengan bugfix. [Tipe Luau](https://luau.org/types/).

Table dapat menjadi array atau map; key array dimulai dari 1. Jangan menghitung roster berlubang dengan #table. Nil menghapus key; hanya nil dan false bersifat falsy, sedangkan 0 dan string kosong tetap truthy. Table bersifat referensi; clone dangkal tidak memisahkan tabel anak. Pahami kapan memakai pairs/ipairs, table.clone, table.clear dan table.freeze. [Standard library](https://luau.org/library/).

## 2. Server, client dan pemilik state

Server menentukan hasil bernilai: damage, role, inventory, pembelian, rekor dan kemenangan. Client menangani input, HUD, kamera serta feedback lokal. Kode/shared config yang direplikasi bukan tempat menyimpan rahasia. ModuleScript pada server dan client tidak berbagi satu state memori. Tetapkan satu pemilik state per sistem, antarmuka jelas dan lifecycle cleanup; hindari circular dependency. [Runtime client-server](https://create.roblox.com/docs/projects/client-server).

Untuk Fly High, daftar pemilik state tetap mengikuti HANDOVER. Jangan menambah penulis inventory atau SummitCount baru hanya untuk memudahkan HUD. Event UI menampilkan state otoritatif; UI bukan bukti grant data berhasil.

## 3. Komunikasi dan validasi

RemoteEvent cocok untuk permintaan/asinkron dan sync; RemoteFunction menunggu respons. Data visual kontinu yang boleh hilang dapat menggunakan mekanisme unreliable bila kebutuhan ordering memang mengizinkan. Jangan mengubah transport hanya karena terlihat lebih cepat. [Remote events](https://create.roblox.com/docs/scripting/events/remote).

Pada server, periksa tipe, struktur/ukuran payload, angka finite, rentang, instance dari akar tepercaya, pemain hidup, tim, role, jarak, cooldown dan urutan state. Validasi ProximityPrompt juga; prompt yang tampak tersembunyi bukan pembatas keamanan. Client meminta aksi, bukan menentukan damage/harga/pemenang. [Batas keamanan client-server](https://create.roblox.com/docs/scripting/security/client-server-boundary).

Contoh konsep validator angka, bukan handler lengkap:

```luau
--!strict
local function isFiniteNumber(value: unknown): boolean
	return typeof(value) == "number" and math.isfinite(value)
end
```

math.isfinite tercantum dalam standard library yang diperiksa. Tetap periksa dukungan runtime target sebelum modernisasi API. Validator angka saja belum memvalidasi otorisasi, rate limit atau konteks aksi.

## 4. Lifecycle, concurrency dan cleanup

Task/event dapat yield atau selesai setelah pemain berganti karakter, meninggalkan tim atau objek dihancurkan. Setelah yield, periksa ulang identitas karakter, keanggotaan dan keberadaan objek sebelum memberi efek. Gunakan generation/token untuk membatalkan operasi lama. Transisi terminal harus idempotent: Victory/Game Over, pembelian dan grant tidak boleh dijalankan dua kali.

Simpan connection/timer yang perlu dibersihkan. Hapus tabel ber-key pemain, reservasi role, Tool sementara dan efek saat flight/character berakhir. Pembatalan hold, respawn dan disconnect harus punya jalur cleanup. Ini pola engineering proyek; terapkan dengan tes perilaku, bukan klaim bahwa satu helper otomatis menghilangkan semua leak.

## 5. Fisika kendaraan dan network ownership

Pahami assembly/weld, anchored/unanchored, pusat massa, collision groups dan frame lokal. Network ownership menentukan siapa mensimulasikan fisika. Server ownership memperkuat otoritas, tetapi dapat mengurangi responsivitas; pilihan ini perlu diukur, bukan diterapkan membabi buta. Meng-anchor lalu unanchor dapat mengubah ownership. [Network ownership](https://create.roblox.com/docs/physics/network-ownership).

Untuk balon: hindari beberapa mekanisme saling melawan, misalnya mover fisika, koreksi PivotTo tiap frame dan collision solver yang semuanya mengejar target berbeda. Uji pilot/penumpang, avatar berbeda, melepas role, reparasi sambil bergerak, jaringan dan FPS rendah. Kecocokan posisi di server belum membuktikan tampilan client bebas jitter.

Saat menarget balon, gunakan kecepatan bertanda dan waktu tempuh; gas aktif tidak selalu berarti naik. Tentukan apakah ancaman berupa prediksi sekali saat spawn atau homing. Uji seluruh health, kecepatan turun, gerak lateral, warning, cooldown dan invulnerability.

## 6. Terrain, collision dan penataan dunia

Terrain memiliki grid/material/occupancy. ReadVoxels dan WriteVoxels harus memakai region serta resolusi yang benar, dengan area perubahan dibatasi dan backup. Air/Water bukan tanah padat hanya karena nilai occupancy-nya. Jangan menurunkan tinggi permukaan visual dari satu rumus occupancy tanpa mengukur hasil di engine. [Terrain API](https://create.roblox.com/docs/reference/engine/classes/Terrain).

Gunakan raycast untuk mengukur permukaan hasil akhir dan periksa lantai Part di atas Terrain. Jalan berbasis material dapat tertutup part pulau. Periksa tinggi, kemiringan, ujung jalan, base dekorasi dan akses dari karakter; ambil screenshot dekat dan dari atas.

Collision group API yang diperiksa kini tersedia pada WorldRoot; PhysicsService menandai API pengelolaan grup lamanya deprecated. Jangan mengganti API tanpa memeriksa Studio target serta melakukan regresi. [WorldRoot](https://create.roblox.com/docs/reference/engine/classes/WorldRoot), [PhysicsService](https://create.roblox.com/docs/reference/engine/classes/PhysicsService).

Untuk CSG/mesh, render dan collider harus diuji secara terpisah. Collider yang bisa diinjak tidak membuktikan permukaan terlihat utuh. Pertahankan geometri lebih sederhana bila union coplanar menimbulkan celah render. Jangan menyatakan kualitas final berdasarkan generator script saja.

## 7. Art direction dan gameplay readability

Tentukan silhouette, palet, material, skala terhadap avatar dan tingkat detail sebelum menambah banyak objek. Pisahkan landmark dekat, tengah dan jauh; beri ruang kosong yang disengaja agar rintangan/interactable terbaca. Polesan tidak sama dengan menambah kepadatan.

Untuk Fly High, pertahankan lima tema bioma dan Istana Awan dari PRD. Buat daftar aset, posisi/rentang ketinggian, skala, collision dan anggaran performanya. Periksa dari balon, karakter berjalan dan perangkat kecil. Ini rekomendasi desain proyek, bukan batas engine.

## 8. UI responsif dan input lintas perangkat

Scale dan Offset memiliki peran berbeda; gunakan AnchorPoint, layout dan constraint sesuai kebutuhan. Tetapkan area teks yang terukur dan kebijakan wrap/truncate. Angka dinamis sebaiknya tetap berupa teks, sedangkan frame/dekorasi dapat berupa image. Memakai PNG tidak otomatis menyelesaikan layout responsif. [Posisi/ukuran UI](https://create.roblox.com/docs/ui/position-and-size).

Perhatikan ScreenInsets, safe area, layering dan clipping. Jangan menggandakan native jump/prompt dengan custom control untuk aksi yang sama. Untuk hold tambal/perbaiki tali, ikuti keputusan HUD native Fly High. Untuk aksi lain, gunakan custom HUD yang sudah disepakati. [ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui).

Keyboard, analog touch dan gamepad harus menuju kontrak input yang sama. Gerak balon mengikuti sumbu kamera yang diratakan ke XZ; cek saat kamera berputar 180 derajat. Input wajib kembali nol setelah lepas helm, fokus hilang atau modal terbuka. Driver virtual-key juga harus melepas tombol saat keluar role.

## 9. FPS weapon, aiming dan feedback

Pisahkan target bidikan dari origin visual muzzle. Crosshair memberi arah tujuan; tracer/muzzle flash lokal harus bermula dari muzzle viewmodel yang terlihat. Server menghitung hit dari senjata dan konteks yang sah, bukan mempercayai origin dari client.

Viewmodel mengikuti kamera pada offset kanan bawah; atur ukuran berdasarkan layar, bukan hanya world studs. Unequip harus memulihkan kamera, zoom dan visibilitas karakter. Uji audio reload, tracer, occlusion oleh senjata sendiri, auto-aim touch, dan ammo 8/∞ atau 30/∞ dengan kapasitas magazine tetap. Ini kontrak Fly High, bukan jaminan bahwa seluruh jalur sudah lulus QA.

## 10. Data dan inventory

DataStore dipakai server untuk data lintas sesi. Panggilan jaringan dapat gagal dan perlu penanganan error; UpdateAsync membantu perubahan konkuren dan callback-nya tidak boleh yield. Studio dapat mengakses data live bila API access diaktifkan, sehingga gunakan test universe/data terisolasi. [Data stores](https://create.roblox.com/docs/cloud-services/data-stores).

Tangani kegagalan load tanpa menimpa profil live dengan default. Rancang migrasi schema, retry terbatas, session ownership dan save saat shutdown. Untuk Fly High, bedakan jumlah AK-47 dimiliki, yang dialokasikan ke dua rak, dan sisa inventory; jangan menjadikan status equip sebagai bukti pembelian baru.

## 11. Monetisasi dan receipt

Developer product bisa dibeli berulang. Benefit yang persisten tetap membutuhkan ledger pembelian, grant idempotent dan penyimpanan. Jangan memberi barang hanya berdasarkan penutupan popup pembelian. [Developer products](https://create.roblox.com/docs/production/monetization/developer-products).

Ikuti kontrak ProcessReceipt yang berlaku: callback dapat dikirim ulang atau diproses pada server berbeda. Catat PurchaseId, simpan grant secara aman, baru akui pemenuhan. Verifikasi nama method pada API reference; contoh guide lama bisa memakai GetProductInfo yang kini deprecated dibanding GetProductInfoAsync. [MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService).

Publikasi, transaksi Robux nyata dan persistensi cloud tetap ditunda sesuai PROGRESS. Menambahkan knowledge atau skill tidak mengubah keputusan itu.

## 12. Aset pihak ketiga dan lisensi

Model yang kelihatan dekoratif dapat membawa backdoor. Rating/popularitas bukan jaminan keamanan. Inspeksi semua script/descendant, kemampuan sandbox dan perilaku yang mengakses jaringan, data atau require aset luar. Jangan mengaktifkan perilakunya sebelum dipahami. [Kerentanan pihak ketiga](https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities).

Catat pemilik, ID, lisensi dan tempat impor. Uji muat texture/audio, izin lintas pemilik, collision dan tampilan runtime; asset ID bukan bukti kontennya tersedia. Skill yang mengarahkan impor tidak otomatis mengotorisasi instalasi plugin atau publikasi.

## 13. Performa dan streaming

Pilih perangkat baseline lalu ukur frame time, memori, draw/triangle cost, physics, partikel, transparansi dan replikasi. Jangan menjadikan contoh angka dalam tutorial sebagai anggaran universal. Device emulator berguna untuk rasio/kontrol, tetapi bukan bukti konsumsi memori/performa perangkat fisik. [Design for performance](https://create.roblox.com/docs/performance-optimization/design).

Streaming memuat/melepas isi Workspace berdasarkan relevansi. Client harus aman ketika objek belum tersedia atau hilang. Menaruh model di ReplicatedStorage tidak memberikan semua manfaat streaming Workspace. Pastikan landmark jauh tetap terbaca melalui strategi LOD yang sesuai. [Instance streaming](https://create.roblox.com/docs/workspace/streaming).

## 14. QA yang dapat dipercaya

Test, Run dan multiplayer memiliki lingkungan berbeda; client/server harus diperiksa pada konteks yang benar. Menghentikan playtest membuang perubahan runtime, sehingga perbaikan produksi harus diterapkan di Edit. [Testing modes](https://create.roblox.com/docs/studio/testing-modes).

Pisahkan type check, compile, pengujian unit/fixture, integrasi, perjalanan natural, review visual dan perangkat fisik. Bot yang teleport, memakai shield, pause hazard atau memanggil manager langsung bukan bukti pengalaman normal manusia. Sebaliknya kegagalan driver bukan otomatis bug game.

Untuk setiap klaim, simpan build, sumber/objek yang diuji, fixture, target dan altitude aktual, hasil, log, screenshot dan cleanup. Pertahankan hasil gagal. Uji ulang sesudah perubahan yang relevan; perubahan collider/render membatalkan bukti geometri sebelumnya. Ikuti WORKFLOW untuk source Studio, mirror, file tersimpan, commit dan push sebagai lima fakta terpisah.

## 15. Pelajaran Fly High yang jangan digeneralisasi

| Kasus | Pelajaran kerja | Bukti proyek |
| --- | --- | --- |
| Dermaga tertutup gundukan | Raycast pusat/clearance horizontal dan screenshot udara saja tidak cukup; cek area akses dan jalan kaki | [QA akses](../../audit/dock-access-2026-11-11/README.md) |
| Union jalan tidak utuh | Physics pass dan visual pass adalah dua gerbang terpisah | [Percobaan akses](../../audit/dock-access-2026-11-11/README.md) |
| Health 1/5 sulit terkena | Prediksi vertical harus mengikuti arah gerak aktual | [QA critical health](../../audit/docks-critical-health-2026-11-11/README.md) |
| Driver menahan WASD | Otomasi harus melepaskan input saat pindah role | [Regresi perjalanan](../../audit/journey-regression-2026-11-11/README.md) |
| Full journey gagal | Arrival fixture yang lulus tidak boleh menjadikan suite end-to-end hijau | [PROGRESS](../../PROGRESS.md) |

Offset occupancy 8 yang pernah dipakai pada fixture terrain tertentu adalah hasil kalibrasi build itu, bukan rumus umum “tinggi Roblox selalu +2”. Uji raycast ulang pada grid/material/region dan engine yang sedang digunakan.
