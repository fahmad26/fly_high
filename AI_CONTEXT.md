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

## HUD aktif: Sky Arcade Pro Max (Pass 6 — Layout Collision Fix & Avionics Isolation)

Iterasi Pass 6 menuntaskan umpan balik kritis pengguna terkait cacat visual pada Altimeter atas dan banner peringatan lepas landas (`GroundedCountdown`):
1. **Pemisahan Vertikal Bersih (Zero Clipping/Overlap)**: Banner peringatan `GroundedCountdown` sebelumnya menabrak dan menimpa border bawah kapsul `AltimeterFrame` karena kalkulasi koordinat `topH + 10` pada `altY = 8`. Diperbaiki pada `HUDLayout.luau` dengan formula dinamis `noticeY = altY + topH + 12`, menjamin celah bernapas (gap) konsisten 12px tanpa overlap border di seluruh resolusi layar.
2. **Isolasi Progress Bar (Anti-Bleed)**: Pada implementasi sebelumnya, track progress bar hitam `BarBg` memanjang melebihi batas dan menembus ke bawah kotak telemetri kecepatan vertikal (`VerticalSpeedLabel`). Pada `HUDTheme.luau`, lebar bar dihitung ulang secara ketat dengan batas akhir `barEndX = speedX - 12` dan `barW = math.max(60, barEndX - barX)`, menjamin track progress bar berhenti rapi 12px sebelum chip kecepatan dan tidak pernah menabraknya.
3. **Penyelesaian Bug Flapping/Flicker Telemetri Kecepatan**: Ditemukan akar masalah mengapa teks kecepatan vertikal berganti-ganti ("valuenya kadang berubah-ubah") antara `NAIK +16.0 km/dtk` dan `▲ +16.3 km/s`. `FlightHUDController` lama menulis format legacy langsung ke instance `VerticalSpeedLabel` setiap kali packet `flightSyncEvent` tiba (10 Hz), sementara `HUDTheme` menimpa teks yang sama pada `RenderStepped` (60 FPS). Diselesaikan tuntas di kedua sisi:
   - `HUDTheme` kini membuat dedicated component `HUDSpeedPill` dengan label khusus `HUDSpeedText` (`GothamBlack 11px`, `TextWrapped = false`), dan menyembunyikan total instance raw `VerticalSpeedLabel` (`TextTransparency = 1, BackgroundTransparency = 1`).
   - `FlightHUDController` kini menulis atribut numerik bersih `altFrame:SetAttribute("VerticalSpeed", speed)` dan menyelaraskan format fallback menjadi `▲ +%.1f km/s` (atau `▼ -%.1f km/s`, `● 0.0 km/s`), mengeliminasi race condition dan mencegah teks flapping seutuhnya.
4. **Toolbar Kiri Vertikal Rapi**: Tombol navigasi dock samping (`TOKO`, `KIT`, `PING`, `SUARA`) disusun vertikal rapi di tepi kiri layar dengan `gap = 8px`, `tileW = 50px`, `tileH = 56px`, dan label transparan elegan terintegrasi.
5. **Tombol Jump Arcade Bulat Penuh (Pass 5)**: Mempertahankan tombol lompat bulat murni 84–90px di kanan bawah, ikon panah 58% terpusat, tanpa stiker teks yang memotong lengkungan bawah, serta keycap badge `[SPACE]` khusus PC (`not Input.TouchEnabled`).

## Pembaruan Senjata & Auto-Aim Sentuh iPad — 1 November 2026

Mengatasi laporan pengguna terkait auto-aim pistol yang tidak bekerja saat diuji coba pada perangkat iPad:
1. **Threshold Bidikan Adaptive & Resolusi Dinamis**:
   - Mengganti radius piksel statis `best = 100` (yang pada layar iPad hanya mencakup sudut sempit < 10 derajat) dengan kalkulasi adaptif berbasis FOV kamera dan proporsi viewport.
   - Pada perangkat iPad/layar sentuh (`TouchEnabled`), sudut penguncian diperluas hingga **28 derajat** dengan radius layar hingga **38% dimensi layar terkecil** (minimal 220 piksel), mencakup secara nyaman pergerakan target pada layar sentuh.
   - Pada PC/mouse, sudut toleransi disetel pada 18 derajat (minimal 120 piksel).
2. **Dynamic Reticle Visual Feedback**:
   - Reticle bidik kini bereaksi secara dinamis di `RenderStepped`: saat target rintangan terbang terdeteksi dalam jangkauan auto-aim, reticle berubah dari `+` putih menjadi tanda kurung `[ + ]` berwarna merah arcade tajam (`Color3.fromRGB(255, 70, 70)`).
3. **Kamera Soft-Lock Assist saat Menembak**:
   - Pada perangkat layar sentuh, saat tombol tembak ditekan, kamera secara halus melakukan penyesuaian sudut (lerp 35%) ke arah rintangan yang terkunci, memberikan rasa penguncian sasaran (*soft-lock*) yang nyata tanpa mengganggu navigasi drag jempol.
4. **Dukungan Tap-to-Fire via `tool.Activated`**:
   - Menghubungkan event `tool.Activated` dan `tool.Deactivated`, memungkinkan pemain iPad menembak baik dengan menekan tombol HUD `[ 🎯 TEMBAK ]` maupun mengetuk area layar secara langsung.
5. **Server Spherecast & Mitigasi Latensi Jaringan**:
   - Remote `WeaponFireEvent` mengirimkan referensi `targetModel` dari client ke server sehingga server membidik posisi rintangan aktual di server, mengeliminasi tembakan meleset akibat desinkronisasi latensi (ping).
   - Di server, selain raycast garis lurus, digunakan `workspace:Spherecast` dengan radius 2.5 stud untuk target bergerak cepat, sekaligus tetap memprioritaskan kerusakan balon sendiri jika pemain membidik Envelope balon timnya.

Visual playtest terverifikasi Pass 6 tersimpan di `audit/hud-arcade-pass6-telemetry-fix.jpg` dan `audit/hud-arcade-pass6-fix.jpg`. Visual Pass 5 tersimpan di `audit/hud-arcade-pass5-jump.jpg`.
- Tipografi seluruh elemen teks menggunakan vector `UIStroke` (`ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual`, ketebalan 1.5–2.5px).
- Hierarki font Gotham Arcade: `Enum.Font.GothamBlack` untuk hero metric (altitude, ammo, modal headers) dan action verbs (`GAS NAIK`, `OTOMATIS: ON`, `LEPAS`); `Enum.Font.GothamBold` untuk subtitel bioma dan rincian peluru cadangan.
- Shop Modal menampilkan kartu belanja slate dengan ilustrasi produk transparan tanpa kotak hitam, judul emas `GothamBlack 15px`, bullet point deskripsi `GothamBold 11px`, dan tombol 3D arcade bergradasi.

Preview Playtest Aktual:
- Pass 6 (Top HUD & Layout Fix): `audit/hud-arcade-pass6-fix.jpg`
- Pass 5 (Jump Button & Dock Clean): `audit/hud-arcade-pass5-jump.jpg`
- Pass 4 (In-Flight Flight & Shop): `audit/hud-arcade-pass4-flight.jpg` & `audit/hud-arcade-pass4-shop.jpg`
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
