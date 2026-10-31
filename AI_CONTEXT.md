# Konteks aktif untuk AI berikutnya — Fly High

Snapshot dokumentasi: **31 Oktober 2026**. Dokumen ini menyatukan keadaan terbaru; bagian bertanggal lebih lama pada PRD, HANDOVER, dan laporan audit tetap disimpan sebagai riwayat.

## Mulai dari sini

1. Baca `PRD_Fly_High.md` lengkap untuk aturan produk, kemudian dokumen ini dan `HANDOVER.md` lengkap.
2. Untuk HUD aktif, baca `audit/HUD_ARCADE_REDESIGN.md`, `audit/hud-arcade-results.json`, dan lihat **`audit/hud-arcade-phone.jpg`**. Preview ini capture Playtest asli, bukan mockup AI.
3. Untuk status perjalanan penuh dan masalah co-op, baca `audit/FULL_JOURNEY_QA.md` dan `audit/full-journey-summary.json`.
4. `AUDIT_REPORT.md` menyimpan temuan serta hasil pengujian dari banyak iterasi. Jangan menganggap semua angka/hashes di laporan lama mewakili build terbaru.

## Workspace, versi dan sumber

- Workspace Windows: `E:\Antigravity\Fly High`.
- Repo: https://github.com/fahmad26/fly_high ; branch kerja terakhir `main`.
- Implementasi HUD terakhir: commit **`edbd49d`** (`feat: redesign HUD with bright arcade styling and responsive controls`). Perubahan dokumentasi setelah commit itu tidak mengubah gameplay/place.
- Place produksi lokal: **`Fly High.rbxl`**. SHA-256 snapshot tersimpan: **`B94CEC7E3591A0B2E2480C8F4B67CECBF909F5843389A94BCCB8457F48AC95FF`**.
- Source mirror: `audit/sources/`, dengan struktur path DataModel. Ini **bukan sinkronisasi Rojo otomatis**. Mengedit mirror saja tidak memperbarui `.rbxl`; memasang Source ke Studio saja tidak memperbarui Git. Verifikasi keduanya sebelum menyelesaikan perubahan.
- Dalam pemeriksaan terakhir, **32 LuaSourceContainer terkompilasi**; tiga modul HUD yang diubah cocok dengan mirror. Ini bukan pernyataan bahwa semua source lain sudah dibandingkan ulang setelah setiap perubahan pengguna.
- Studio ditinggalkan dalam **Edit**, toolbar **Test**, **Current device desktop**; sesi QA memakai satu pemain. Fixture `TabletUIQA` sudah dihapus. Temukan ulang Studio yang aktif; jangan mengandalkan ID koneksi sesi sebelumnya.
- Ada 27 PNG mentah pengguna di `assets/ui/final/*.png` yang masih **untracked** pada snapshot ini. Jangan hapus, ubah, atau ikutkan ke commit secara tidak sengaja. Versi compressed yang dipilih sudah tercatat di Git.

## Arsitektur source saat ini

| DataModel | Source |
|---|---|
| `ReplicatedStorage.FlyHigh.Modules` (8) | `FlyHighConfig`, `FlightControlMath`, `BalloonThemes`, `WeaponPresentation`, `HUDImageAssets`, `HUDGlyphs`, `HUDTheme`, `HUDLayout` |
| `ServerScriptService.FlyHighServer` (16) | `DataManager`, `OverheadManager`, `PodManager`, `BalloonManager`, `WeaponManager`, `WeaponRackPresentation`, `TetherManager`, `ObstacleManager`, `ShopManager`, `ServerUtils`, `PalaceManager`, `FlightSpace`, `CrewAccessGuard`, `JumpManager`, `LargeChallengeManager`, `IslandWildlifeController` |
| `StarterPlayer.StarterPlayerScripts` (8) | `FlightHUDController`, `WeaponClientController`, `ShopClientController`, `BiomeLightingController`, `FlightJumpController`, `WarningAudioController`, `BalloonFleetAnimator`, `IslandNatureAnimator` |

Daftar ini berasal dari source mirror dan jumlah kompilasi snapshot. Bandingkan lagi dengan DataModel aktif sebelum membuat perubahan.

## Aturan gameplay yang harus dipertahankan

- Co-op **1–3 pemain**, lima dermaga/armada, ruang udara bersama, tujuan Istana Awan **10.000 km**, lima bioma. Gondola **28×28 stud**.
- Zona **0–1.200 km** bebas rintangan lingkungan. **Tabrakan antarbalon dan tembakan ke balon sendiri tetap memberi lubang di zona itu**; jangan menerapkan kebal kerusakan menyeluruh. Tembakan tidak merusak balon tim lain.
- Maksimum **5 lubang**. Jatuh pada 5 lubang berkecepatan tetap sekitar **666,7 km/detik**: dari 2.000 km sekitar 3 detik; bukan selalu 3 detik dari semua ketinggian. Clutch Save tetap mungkin selama belum terminal.
- Role **Pilot/Gunner/Engineer/Rescuer eksklusif**. Semua dapat dilepas sesuai alurnya. Hanya pilot yang sedang benar-benar memegang kemudi boleh menyalakan/mematikan gas otomatis; gas yang aktif tetap menyala setelah kemudi dilepas. Kemudi mengikuti arah kamera.
- Max tiga anggota dermaga dan larangan boarding balon tim lain. Summon dermaga terhalang balon tim mana pun yang belum cukup jauh. Grounded AFK 60 detik menghancurkan balon dan menewaskan kru.
- Tali: pasang → naik kubah → tambal tiap lubang → turun (otomatis lepas tali) → perbaiki tali saat dilepas. Bisa melepas tali sebelum naik. Tali 100 HP, aus 5 HP/detik di luar keranjang. Memasang tali tidak mengisi durabilitas.
- Pemain bertali yang jatuh/menggantung tidak boleh teleport kembali sendiri; rekan satu tim yang bebas role/peralatan menariknya. Putus tali melempar pemain keluar lalu menewaskannya dengan guard identitas karakter.
- Equip senjata memaksa first person; drop kembali third person. Auto aim berdasarkan pusat kamera, tanpa tap arbitrer ke mana saja. Visual proyektil dan suara tembakan sudah diimplementasikan.
- Loncatan kru/Dinding Badai **sudah diimplementasikan pada iterasi berikutnya**, meskipun instruksi historis pernah meminta dokumentasi saja. Pilot dan pemain di katrol/kubah/repair tidak boleh melompat; gunner dan pemakai tali yang masih di keranjang mengikuti izin server. Ada cooldown efek turun.

## HUD aktif: Sky Arcade Pro Max (Pass 5 — Jump Button & Action Suite Overhaul)

Pengguna memberikan catatan kritis bahwa tombol Loncat (`JumpButton`) dan kontrol aksi bulat lainnya masih kurang memuaskan jika dilihat dari kacamata UI Designer. Ditemukan akar masalah visual: tombol loncat sebelumnya merender caption pill persegi panjang hitam (`LOMPAT`) yang memotong busur lingkaran bawah seperti stiker tempelan, membuat icon panah terdesak ke atas dan ukuran tombol terasa terlalu mepet ke tepi layar.

Iterasi Pass 5 menyelesaikan masalah ini secara menyeluruh:
1. **Pembersihan Geometri Tombol Bulat (Pure Iconography)**: Menghilangkan caption pill persegi panjang pada semua kontrol berjenis `round` (`JumpButton`, `MobileShootButton`, `CloseButton`). Tombol aksi kini mengusung pure arcade iconography tanpa stiker teks yang merusak kelengkungan lingkaran.
2. **Presisi Iconography & Centering**: Icon panah loncat kini di-center sempurna di tengah lingkaran dengan rasio 58% diameter tombol (51–53px), dilengkapi efek 3D embossed drop shadow.
3. **Ergonomi Touch Target Standar AAA (Blade Ball & Rivals)**: Ukuran tombol loncat ditingkatkan menjadi **88px** (mobile) dan **92px** (desktop/tablet), dengan margin nyaman **24px** (mobile) dan **28px** (desktop) dari tepi bawah-kanan layar.
4. **Keycap Badge Khusus PC**: Menampilkan hint `[SPACE]` mengambang rapi di sudut atas tombol hanya saat input keyboard aktif (`not Input.TouchEnabled`), dan otomatis tersembunyi pada perangkat sentuh mobile.
5. **Pembersihan Toolbar Samping Kiri**: Menghilangkan kotak stiker hitam ber-stroke ganda pada tombol dock samping (`TOKO`, `KIT`, `PING`, `SUARA`), menggantinya dengan label transparan vektor terintegrasi yang menyatu elegan di atas gradien glossy tile.
6. **Harmonisasi Palet Arcade Sapphire**: Meng-upgrade palet biru dari cyan jenuh menjadi saturasi arcade berlapis (Ice Cyan highlight, Cerulean core, Deep Cobalt bevel, dan Midnight outline).
7. **Penyempurnaan Altimeter & Progress Track**: Melebarkan progress bar menjadi 180–220px dengan chip telemetri kecepatan vertikal di sudut kanan atas.

Visual playtest terverifikasi tersimpan di `audit/hud-arcade-pass5-jump.jpg`.
   - Seluruh teks kini menggunakan `UIStroke` dengan `ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual` dan ketebalan 1.5–2.5px.
   - Menonaktifkan stroke lama (`TextStrokeTransparency = 1`), melenyapkan outline miter 1px yang bergerigi dan counter-plugging pada teks ukuran kecil.
2. **Hierarki Tipografi Gotham Arcade Premium**:
   - **Hero Metric & Action Verb**: Menggunakan `Enum.Font.GothamBlack` untuk angka ketinggian, judul modal, dan teks aksi tombol (`GAS NAIK`, `OTOMATIS: ON`, `LEPAS`).
   - **Subtitel & Deskripsi**: Menggunakan `Enum.Font.GothamBold` untuk nama bioma tujuan, rincian peluru cadangan, dan poin-poin penjelasan produk pada shop.
   - Menghapus ketergantungan `TextScaled = true` pada bounding box pendek yang sebelumnya menciutkan font menjadi mikro-glif; menggantinya dengan fixed TextSize yang lapang dan proporsional.
3. **Penyempurnaan Chip Kecepatan Avionik (Vertical Speed)**:
   - Diformat rapi menyerupai instrumen dirgantara: panah dinamis `▲ +24.3 km/dtk` (neon green `#4ade80`), `▼ -2.5 km/dtk` (danger red `#f87171`), atau `● 0.0 km/s` (navy cyan `#93c5fd`).
   - Dilengkapi atribut `RawSpeed` internal pada instrumen agar parsing status naik/turun tidak ter-reset menjadi "DIAM" oleh render loop per frame.
4. **Penyempurnaan Tombol Pilot & Layout Responsif**:
   - Tombol `AutoGasButton` diformat menjadi `OTOMATIS: ON` (hijau) dan `OTOMATIS: OFF` (biru) dengan `GothamBlack 13px`, ikon kemudi/api, dan hint shortcut `[Z]`. Bebas dari glitch line-wrapping kata.
   - Posisi tombol lompat arcade (`JumpPanel` / `JumpButton`) diletakkan di sudut kanan bawah (zona jempol kanan) dengan format sirkular sempurna 82px.
   - Shop Modal menampilkan kartu belanja slate dengan ilustrasi produk transparan tanpa kotak hitam, judul emas `GothamBlack 15px`, bullet point deskripsi `GothamBold 11px`, dan tombol 3D arcade bergradasi.

Preview Playtest Aktual Pass 4:
- In-Flight HUD: `audit/hud-arcade-pass4-flight.jpg`
- Shop Modal: `audit/hud-arcade-pass4-shop.jpg`
- `HUDGlyphs`: ikon berbasis komponen UI Roblox yang dapat diskalakan. Kontrol dan panel inti tidak memerlukan gambar unduhan.
- `HUDImageAssets`: mempertahankan pemetaan **27 ID** unggahan. Sumber final: `assets/ui/final/compressed_img/`. Manifest kanonik: `assets/ui/asset-manifest.json`; ID sederhana: `assets/ui/final/compressed_img/roblox-asset-ids.json`.
- Hanya **empat ilustrasi opsional** yang sekarang diminta oleh tema: `balloon_intact`, `emergency_kit`, `weapon_pistol`, `weapon_ak47`. Tidak ada re-upload atau perubahan PNG pada redesign.
- Altimeter di atas tengah, kartu kondisi lima segmen, tile TOKO/KIT/PING/SUARA, amunisi dan aksi gunner di kanan bawah, aksi tali kontekstual langsung. **Tray AKSI lama sudah tidak dipakai.** Gas otomatis dan lepas kemudi tetap langsung tersedia khusus pilot.
- Tombol lompat custom bulat di kanan bawah, native jump disembunyikan, joystick native tetap aktif. Ada tampilan terkunci dan badge cooldown. Perbaikan tali tetap diberi label tahan.
- Controller gameplay semula tetap memiliki button instance, handler input, canonical label, role checks dan remotes. Hindari menambahkan handler aksi duplikat saat mengubah presentasi.

## Pengujian: klaim yang didukung bukti

- `audit/hud-arcade-results.json`: **12 profil perangkat/kondisi**, overlap tombol proyek/keluar layar/teks terlihat terpotong/target sentuh terlalu kecil = 0. Desktop, iPad landscape/portrait, phone landscape/portrait; kondisi gunner, pilot, engineer, toko, 4 lubang dan warning diperiksa.
- Input native memverifikasi toko buka/tutup, auto gas ON, lepas kemudi dengan gas tetap ON, kit menghapus 4 lubang, dan satu jump yang diterima server pada sesi baru. Log terakhir hanya pemberitahuan mock-data Studio unpublished; tidak ada warning/error proyek pada sesi itu.
- Fixture meng-anchor balon dan menghentikan hazard. Ini **bukan** pembuktian ulang fisika penerbangan, multiplayer publik, transaksi atau kenyamanan perangkat fisik.
- Badge cooldown, label eksplisit tahan perbaikan tali, dan pengurangan preload menjadi empat ilustrasi dikompilasi/disimpan setelah scene terakhir; perubahan kecil ini belum mendapat putaran Playtest penuh berikutnya.
- Pengujian perjalanan penuh lama mencatat solo/duo/trio mencapai 10.000 km, tetapi `singleAllGreenEndToEndSuite` tetap **false**. Ada masalah bot/cleanup terminal pada raw report; gunakan ringkasan dan focused fixtures, bukan mengubahnya menjadi klaim semua lulus.

## Temuan terbuka dan pekerjaan lanjutan

1. **COOP-LATERAL-POSITION:** manuver horizontal cepat dapat menimbulkan beda jarak repair client/server lalu Hanging. Penyebab belum terkonfirmasi. Validator produksi **belum dilonggarkan**. Bukti: `audit/FULL_JOURNEY_QA.md`, `audit/full-journey-summary.json`.
2. **Jump setelah pergantian role dalam fixture:** saat auto gas aktif, tap terbukti memicu Activated client tetapi counter jump server tidak bertambah. Sesi baru dengan auto gas OFF menerima jump. Ini observasi pada fixture anchored, bukan akar masalah yang sudah diketahui. Reproduksi dengan kombinasi role/auto gas/ownership/balloon bergerak sebelum menyebut bug produksi atau mengubah validasi.
3. **Ketersediaan gambar:** unggahan mengembalikan 27 ID, tetapi pemeriksaan lama hanya 7 Success dan 20 Failure setelah HTTP 429; jangan menyebut seluruh 27 sudah load-verified atau menyimpulkan moderation rejection. Manifest menyimpan hasil historis. Jangan re-upload massal tanpa kebutuhan; core HUD terbaru sudah independen.
4. **Review visual manusia dan perangkat fisik** masih perlu. Cek pula native Roblox overlays, backpack, dan 3D proximity prompts; pemeriksaan overlap 12 profil hanya membandingkan tombol proyek, bukan seluruh CoreGui.

## Monetisasi dan pekerjaan yang ditunda

- Developer Product `EmergencyKit`: **3723339056**; `AK47Upgrade`: **3723339246**. Harga UI mengikuti data Marketplace, jangan mengganti harga regional dengan angka hard-coded.
- Pengguna **menunda publikasi experience, pembelian Robux nyata dan pengujian cloud**. Jangan meminta publikasi kembali atau melakukannya sebagai syarat perubahan HUD.

## Cara melanjutkan pekerjaan

- Pertahankan perubahan pengguna; baca git status sebelum edit. Tidak perlu mengulang pembuatan aset/cropping kolase. Kolase konsep merupakan referensi gaya lama, bukan sumber atlas produksi.
- Sebelum mengubah source, bandingkan Studio aktif dengan mirror dan snapshot Git; save pengguna dapat berisi perubahan terbaru yang belum diekspor.
- Setelah mengubah game: sinkronkan Studio dan mirror, lakukan checks yang sesuai, hapus fixture, **save `.rbxl`**, periksa log dan laporkan batas QA. Kembalikan jumlah player tes ke **1** setelah pengujian multiplayer.
- Pengguna memiliki preferensi untuk commit/push hasil yang selesai; commit terakhir implementasi adalah `edbd49d`. Perubahan dokumentasi berikutnya dapat berada di HEAD yang lebih baru. Jangan stage 27 PNG mentah untracked secara massal.
- Jika AI berikutnya belum memiliki instruksi pekerjaan baru, gunakan dokumen ini sebagai konteks dan sampaikan pemahaman singkat; jangan menganggap daftar temuan terbuka sebagai izin untuk memublikasikan atau merombak gameplay.
