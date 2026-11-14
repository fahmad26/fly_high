# Rancangan Fitur: Daily Login 7-Hari Non-Hangus, Sky Coins, Buff Perbekalan, & Toko 3-Tab

Status: `draft` — Proposal telah disetujui pengguna; sedang memasuki tahap mockup UI di Figma sebelum implementasi Luau di Roblox Studio.

Dokumen acuan implementasi aktif tetap mengacu pada [PRD_Fly_High.md](../../../PRD_Fly_High.md), [PROGRESS.md](../../../PROGRESS.md), dan [HANDOVER.md](../../../HANDOVER.md). Perubahan Roblox Studio **tidak dilakukan** sebelum mockup Figma disetujui pengguna.

---

## 1. Tujuan & Prinsip Keseimbangan

1. **Meningkatkan Retensi Harian tanpa FOMO Berlebihan:** Memberi alasan kuat pemain kembali ke Lobby setiap hari lewat kalender hadiah 7 hari yang **tidak hangus** ketika absen.
2. **Menjaga Nilai Monetisasi Robux:**
   - **AK-47 Permanen (`79 Robux`)** tetap **100% eksklusif Robux**; tidak ada kartu sewa/pinjam AK-47 pada Daily Login ataupun Toko Koin.
   - **EmergencyKit (`29 Robux`)** tetap produk Robux utama; versi gratis hanya diberikan terbatas `1×` sebagai Grand Reward Hari ke-7 Daily Login.
3. **Hadiah Terintegrasi Alur Co-op & Ruang Udara Bersama:**
   - Buff (*Turbo Gas* & *Tali Awet*) membantu tim mencapai ketinggian `10.000 km`, sedangkan kosmetik (*Bingkai Tracker*, *Tracer Warna*, *Gelar Overhead*) memberi kebanggaan sosial yang terlihat oleh kru dan tim lain di server.

---

## 2. Mata Uang `Sky Coins` (Koin Awan)

### Sumber Koin Awan
| Aktivitas | Jumlah | Aturan Anti-Exploit |
| --- | :---: | --- |
| **Klaim Daily Login (Hari 1–7)** | `+50` s.d. `+350` Koin | 1× per hari kalender berbasis waktu server (`UTC+7` / WIB). |
| **Duplikat Kosmetik Hari ke-7** | `+250` Koin | Diberikan otomatis jika hadiah kosmetik permanen siklus ke-2+ sudah dimiliki. |
| **Menembus Bioma Baru (`2k / 4k / 6k / 8k km`)** | `+20 / +30 / +40 / +50` | Maksimal 1× per milestone per penerbangan (*anti-yo-yo* naik-turun batas). |
| **Tiba di Istana Awan (`10.000 km`)** | `+150` Koin | Mengikuti aturan roster sah `PalaceArrival`. |
| **Tambal Lubang / Rescue Rekan** | `+10` Koin / aksi | Ada batas maksimum per penerbangan, dan **lubang akibat tembakan tim sendiri tidak memberi koin**. |

---

## 3. Siklus Daily Login 7-Hari Non-Hangus

- **Mekanik Check-In Kumulatif:** `DailyProgress` bergerak berurutan `1 → 2 → 3 → 4 → 5 → 6 → 7`. Absen 1 hari atau beberapa minggu **tidak me-reset** progres ke Hari 1; pemain melanjutkan tepat di hari berikutnya. Setelah Hari ke-7 diklaim, siklus kembali ke Hari 1 pada hari kalender berikutnya.
- **Kapan Muncul:**
  - Ikon dock **`HARIAN`** (kalender emas bersayap + titik merah notifikasi) tampil hanya di **Lobby** (`InFlight == false`), sejajar dengan `SUARA`, `TOKO`, dan `SETELAN`.
  - Popup **`DailyLoginModal`** muncul otomatis `~1.5 detik` setelah masuk Lobby **hanya jika hadiah hari ini belum diklaim**. Otomatis disembunyikan & dikunci saat penerbangan berlangsung.

### Rincian Hadiah 7 Hari

| Hari | Hadiah Utama | Bonus Koin | Tujuan |
| :---: | :--- | :---: | :--- |
| **1** | **1× Turbo Gas (`+25% Speed`, 60 dtk)** | `+50 Koin` | Hadiah instan langsung bisa dicoba pada penerbangan pertama |
| **2** | **1× Tali Awet (`-30% Aus`, 1 Flight)** | `+75 Koin` | Mendorong pemain mencoba peran Engineer menambal di kubah |
| **3** | **Tracer Peluru "Cyan Langit" (3 Hari)** | `+100 Koin` | Efek visual tempur terlihat oleh seluruh kru & sekitar |
| **4** | **1× Turbo Gas + 1× Tali Awet** | `+125 Koin` | Bekal lengkap mengejar rekor ketinggian baru |
| **5** | **Bingkai Tracker "Awan Emas" (7 Hari)** | `+150 Koin` | Tampil menonjol di rail vertikal kanan seluruh server |
| **6** | **2× Turbo Gas (`+25% Speed`, 60 dtk)** | `+200 Koin` | Bekal mabar akhir pekan bersama party 1–3 pemain |
| **7** | **1× `EmergencyKit` + Kosmetik Permanen** | `+350 Koin` | Grand reward puncak mingguan |

---

## 4. Item Perbekalan & Kosmetik Baru

### A. `Turbo Gas` (`+25% Kecepatan` selama `60 Detik`)
- **Mekanika ([`BalloonManager`](../../../audit/sources/ServerScriptService/FlyHighServer/BalloonManager.luau)):** Saat aktif, laju naik ketika gas menyala (`can_ascend == true`) serta kelincahan kemudi horizontal mendapat pengali **`1.25×` selama `60 detik`**. Pada `0` lubang, laju naik meningkat dari `~16.67 km/s` menjadi `~20.83 km/s`. Tidak membatalkan status terjun bebas `5` lubang.
- **Anti-Waste Cooldown Tim (`60s`):** Sama seperti mekanisme `EmergencyKit`, selama `Turbo Gas` sedang aktif pada balon tim, tombol milik rekan setim otomatis dikunci sementara (`"Boost Tim Sedang Aktif!"`) agar durasi tidak terbuang ganda. Maksimal aktivasi per pemain per flight dibatasi di server.

### B. `Tali Awet` / *Reinforced Harness* (`1× Penerbangan`)
- **Mekanika ([`TetherManager`](../../../audit/sources/ServerScriptService/FlyHighServer/TetherManager.luau)):** Mengurangi laju pengurangan durabilitas tali di luar gondola sebesar **`30%`** (dari `ROPE_DECAY_PER_SEC = 5` HP/s menjadi **`3.5` HP/s**, menambah waktu aman di kubah dari `20 detik` menjadi **`~28.5 detik`**) selama **`1` sesi penerbangan penuh** untuk pemain yang mengaktifkannya (`non-stackable`, maksimal 1× aktif per flight).

### C. Kosmetik Sosial
1. **Bingkai Avatar Tracker (`ServerAltitudeTracker`):** Ornamen lingkaran & glow di sekeliling headshot pada tracker kanan ([`HUDAltitudeTracker`](../../../audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDAltitudeTracker.luau)) tanpa menambahkan background kapsul di belakang profil maupun pill angka di kiri avatar.
2. **Warna Jejak Peluru (*Tracer Tint*):** Kustomisasi warna jejak peluru (*Cyan Langit*, *Emas Fajar*, *Merah Senja*, *Neon Hijau*) pada render tracer 1P/3P.
3. **Gelar Overhead Tambahan (`OverheadManager`):** Tag judul bergaya khusus di bawah `[Puncak: Xx]` / `[Rekor: X km]`.

---

## 5. Ekspansi `ShopModal` (3 Tab) & Integrasi HUD

- **`ShopModal` 3 Tab (`Sky Adventure` 9-Slice):**
  1. **Tab `ROBUX`:** `Emergency Kit` (`29 Robux`) dan `AK-47 Permanen` (`79 Robux`).
  2. **Tab `PERBEKALAN` (`Sky Coins`):** `Turbo Gas` (`120 Koin`) dan `Tali Awet` (`100 Koin`), lengkap dengan informasi stok pemain saat ini.
  3. **Tab `KOSMETIK` (`Sky Coins`):** Daftar *Bingkai Tracker*, *Warna Tracer Peluru*, dan *Gelar Overhead* dengan tombol `BELI` / `PAKAI` / `✓ DIPAKAI`.
- **Saldo `Sky Coins`:** Ditampilkan di pojok header kanan pada `DailyLoginModal` dan `ShopModal` tanpa menambah clutter di HUD utama saat terbang.
- **Layout Responsif Multi-Device ([`HUDLayout`](../../../audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau)):** Menjamin target sentuh minimal `44×44 px` dan tata letak ringkas di Desktop, Tablet, Phone Landscape, serta Phone Portrait.

---

## 6. Rencana Perubahan Data & Server Authoritative (`DataManager`)

- Field tambahan di [`DataManager`](../../../audit/sources/ServerScriptService/FlyHighServer/DataManager.luau):
  - `SkyCoins` (`0..1e9`)
  - `DailyProgress` (`1..7`) & `LastDailyClaimDay` (`math.floor((os.time() + 7*3600) / 86400)`)
  - `SpeedBoostStock` & `RopeBuffStock`
  - `OwnedCosmetics` & `EquippedCosmetics` (`TrackerFrame`, `TracerColor`, `OverheadTitle`)
  - `TempCosmetics` (masa berlaku kosmetik harian berdurasi, misal 3 hari / 7 hari)
- Semua mutasi divalidasi di server menggunakan session lock (`writable(s)` / `s.busy`) dan rate limiter.

---

## 7. Urutan Pengerjaan

1. **Review Desain UI di Figma (`V1` — Tahap Sekarang):** Susun `DailyLoginModal` (Desktop + Phone), `ShopModal` 3 Tab (Desktop + Phone), ikon dock `HARIAN`, tombol buff `Turbo Gas` & `Tali Awet`, serta pratinjau kosmetik di Figma untuk disetujui pengguna.
2. **Ekspor Aset & Implementasi Luau:** Setelah visual Figma disetujui, ekspor sprite crest/ikon ke `assets/ui/sky-adventure/`, bangun server handler (`DataManager`, `ShopManager`, `BalloonManager`, `TetherManager`) & HUD UI, lalu jalankan QA kompilasi, Playtest, dan multi-device.
