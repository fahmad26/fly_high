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

## HUD aktif: Sky Arcade Pro Max (Pass 3 — UI Designer Pass)

Pengguna meminta perbaikan mendalam dari kacamata UI Designer karena HUD sebelumnya masih terasa kurang rapi, terdapat background hitam pada gambar PNG transparan, dan tata letak icon/teks belum seimbang.

Iterasi Pass 3 (UI Designer Pass) berhasil menyelesaikan seluruh masalah tersebut:
1. **Pembersihan Background Hitam pada PNG Transparan**:
   - Kontainer gambar (`HUDArtFrame`, `HUDEmblem`, dll.) kini diset `BackgroundTransparency = 1` dan `BorderSizePixel = 0`.
   - Gambar hot-air balloon, emergency medical kit, dan senjata AK-47 kini me-render transparansi PNG murni tanpa kotak hitam, lingkaran gelap, maupun artefak backing kotor.
2. **Perbaikan Proporsi Bentuk Modal (Bug UICorner)**:
   - Ditemukan bug pada fungsi `round()` yang mengisikan radius pixel ke Scale UDim (`UDim.new(16, 0)` menghasilkan kelengkungan 1600% / elips oval).
   - Telah diperbaiki menjadi `UDim.new(0, radius)` sehingga `ShopModal` kini berbentuk rounded rectangle modern yang presisi (16px corner) dan kartu item (`Card1`, `Card2`) berbentuk kotak rounded 12px yang elegan.
3. **Koreksi Saturasi & Kecerahan Gradasi Arcade**:
   - `HUDSurface.BackgroundColor3` dipastikan `Color3.new(1, 1, 1)` (putih bersih) sebelum diaplikasikan `UIGradient`, mencegah warna gradasi tereduksi oleh abu-abu default Roblox Studio.
4. **Hierarki & Layout Avionik yang Rapi**:
   - **Altimeter Kapsul (58px)**: Ketinggian `0 KM` besar & tebal di sebelah emblem balon transparan, subtitel `ISTANA AWAN • 10.000 KM`, horizontal progress bar track neon cyan-emerald dengan persentase `0.0%`, serta chip avionik kecepatan di kanan atas.
   - **Pita Peringatan Grounded**: Pita hazard 340px proporsional di bawah kapsul (bukan double-decker bar kloningan yang monoton), border hazard gold, ikon peringatan Lucide, dan teks bersih tanpa duplikasi emoji.
   - **Left Dock Toolbar**: Tombol tile arcade `50x56 px` (`TOKO`, `KIT`, `PING`, `SUARA`). Ikon berpusat di zona atas (28x28) dengan breathing room lapang, pita teks tebal di bawah dengan stroke aksen tematik per tombol. Smart badge hanya muncul jika kit > 0 (tanpa angka merah "0" yang mengganggu).
   - **Shop Modal & Kartu Belanja**: Jendela modal 450x370 px yang proporsional, tombol close bulat merah di pojok kanan atas, kartu belanja slate dengan ilustrasi produk transparan, judul emas, deskripsi informatif, dan tombol arcade 3D bertingkat (`BELI 1 KIT • 29 R$` hijau emerald dan `BELI AK-47 • 79 R$` kuning amber).
   - **Tactical Ping Wheel**: 5 baris taktis berlatar warna dan ikon spesifik (`flame`, `warning`, `rope`, `repair`, `aim`).
   - **Tombol Lompat**: Tombol arcade sirkular 80px di sudut kanan bawah dengan chevron panah ke atas.

Preview Playtest Aktual Pass 3:
- In-Flight HUD: `audit/hud-arcade-pass3-flight.jpg`
- Shop Modal: `audit/hud-arcade-pass3-shop.jpg`
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
