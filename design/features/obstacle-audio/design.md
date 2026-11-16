# Efek suara rintangan Fly High

Tanggal: 16 November 2026, Asia/Jakarta. **Status: konsep disetujui pengguna (23:29 WIB), belum diimplementasikan.** Status implementasi dan QA mengikuti baris AUDIO-01 di [PROGRESS](../../../PROGRESS.md).

## Keputusan pengguna

- Cakupan langsung seluruh rintangan, tidak bertahap.
- Cakupan **termasuk hazard** (dipastikan 23:35 WIB): sembilan musuh dan sembilan hazard, satu pasang per band (`ObstacleManager.bands`), ditambah Dinding Badai (`LargeChallengeManager`). Beberapa hazard, misalnya Angin Topan, Awan Petir dan Gelombang Panas, tidak punya template model.
- **Hanya menambah yang belum ada** (23:35 WIB). Saat rintangan mengenai balon, suara lubang dan tambal dari `BalloonVFX` sudah dipakai, jadi tidak dibuat suara "kena" per rintangan.
- Suara dipilih dari kandidat yang diperdengarkan dulu kepada pengguna sebelum dipasang.

## Kondisi saat dokumen ditulis

Hasil inspeksi source Studio, read-only:

- Rintangan belum punya suara sendiri.
- Suara yang sudah ada:
  - lubang dan tambal balon di `BalloonVFX` (GAME-02: `PunctureThud`, `PunctureHiss`, `PunctureCrewSnap`, `PunctureCrewCrit`, `PatchSnap` dan chime tambal);
  - kanal peringatan `WarningAudioController` dengan profil Freefall, RopeCritical, Storm, Critical, Hazard dan RopeLow;
  - suara senjata `PistolShot` dan `WeaponReload`;
  - suara UI di `HUDMotion`;
  - musik di `MusicController`.
- Volume efek suara diatur `AudioMixer.GetSFXScale` dan dapat di-mute dari menu SUARA (`AudioSettingsModal`).
- Event yang sudah tersedia ke klien:
  - `HazardAlertEvent` (contoh: Kabut Hampa);
  - `LargeChallengeEvent` (Dinding Badai);
  - atribut balon `PunctureSeq` / `LastPunctureHole`.

## Lapis suara baru

| Lapis | Kapan | Bentuk |
| --- | --- | --- |
| Datang (musuh) | Musuh muncul dan mendekat | 3D, menempel pada model; pemain bisa menoleh ke sumber suara sebelum melihatnya |
| Hancur (musuh) | Musuh ditembak hingga hancur | 3D pada posisi musuh |
| Telegraf (hazard) | Hazard mengumpulkan energi atau memberi tanda | 3D pada titik efek |
| Aktif (hazard) | Hazard bekerja: sambaran, ledakan, sapuan, dorongan; dibunyikan **apa pun hasilnya**, kena balon atau tidak | 3D pada titik efek |

Tidak ada lapis "kena". Kalau balon berlubang, suara `BalloonVFX` yang sudah ada tetap menjadi satu-satunya suara benturan.

## A. Musuh

| Band | Musuh (template) | Datang | Hancur |
| --- | --- | --- | --- |
| 300–2.000 km | Burung Liar (`Seagull`, `Eagle`) | kepak sayap + teriakan burung camar/elang | bulu berhamburan |
| 2.000–3.000 km | Kelelawar Badai (`StormBat`) | cicit + kepak cepat | pekik + kepak menjauh |
| 3.000–4.000 km | Bongkahan Es (`Hailstone`, 3 varian) | desir angin dingin, makin cepat saat jatuh | es pecah berderai |
| 4.000–5.000 km | Drone Penjaga (`GuardianDrone`) + paku (`MagicSpike`) | dengung mesin; bip naik saat membidik; desing saat paku ditembakkan | korsleting + ledakan kecil |
| 5.000–6.000 km | Lebah Api (`FireBee`) | dengung bergetar terus-menerus | letupan + desis padam |
| 6.000–7.000 km | Wyvern Kristal (`CrystalWyvern`) | kepak berat + geraman | raungan + kristal runtuh |
| 7.000–8.000 km | Phantom Bayangan (`ShadowPhantom`) | bisikan dan dengung hantu yang naik-turun | lenyap seperti asap |
| 8.000–9.000 km | Serpihan Satelit (`SatelliteDebris`) | derit logam berputar | logam terpental |
| 9.000–10.000 km | Phoenix Surgawi (`CelestialPhoenix`) | pekik phoenix + gemuruh bara saat menukik | pekik + percikan bara |

## B. Hazard

| Band | Hazard | Telegraf | Aktif |
| --- | --- | --- | --- |
| 300–2.000 km | Angin Topan | deru pusaran pelan dari kejauhan | deru menguat dekat pusat, mengikuti kekuatan dorongan |
| 2.000–3.000 km | Awan Petir | dengung listrik saat mengisi; retakan saat laser terkunci | sambaran petir |
| 3.000–4.000 km | Jetstream Crosswind | desis angin saat pita mulai mengalir | lolongan angin yang naik-turun mengikuti dorongan |
| 4.000–5.000 km | Puing Kuno (`Ruin1–3`) | gesekan batu pelan | derak batu saat puing bergeser |
| 5.000–6.000 km | Gelombang Panas | gemuruh panas mendekat | desis tepi gelombang yang menyapu |
| 6.000–7.000 km | Anomali Magnetik (`ChargedCrystal`) | dengung kristal | pulsa bernada saat kemudi terbalik |
| 7.000–8.000 km | Kabut Hampa | tiupan sunyi | nada rendah saat jarak pandang turun, mereda saat pulih |
| 8.000–9.000 km | Meteorit Mikro (`Meteor`) | gemuruh mendekat per jalur | desing lewat + ledakan jauh |
| 9.000–10.000 km | Badai Gerbang Surgawi | gemuruh pusaran; nada naik pada kolom yang akan menyambar | sambaran besar |
| 1.800/3.600/5.400/7.200/9.000 km | Dinding Badai | tirai badai menderu selama `LARGE_WARNING_SEC` | deru menyapu saat tirai lewat |

Peringatan Storm/Hazard dari kanal peringatan tetap bertugas sebagai alarm. Suara hazard di atas adalah suara dunianya, bukan sirene kedua.

## Aturan pemutaran

- Diputar di klien (lokal) dan dipasang pada model atau titik efek yang sudah direplikasi, sehingga arah dan jarak terasa otomatis. Server tidak memutar suara.
- Paling banyak 6 suara rintangan bersamaan. Prioritasnya: aktif > hancur > telegraf > datang. Untuk lapis yang sama, sumber terdekat didahulukan.
- Jeda minimum per jenis untuk lapis datang (usulan 1,5 detik) agar kawanan burung tidak menumpuk suara yang sama.
- Saat kanal peringatan memutar suara berprioritas ≥ 40 (Storm, Freefall, RopeCritical), suara rintangan diturunkan kira-kira 40%.
- Seluruh suara masuk grup SFX sehingga mengikuti slider dan mute `AudioMixer`.
- Jangkauan suara (rolloff) disetel per ukuran rintangan: burung/lebah pendek, meteor/phoenix/Dinding Badai panjang.
- Preload saat masuk band berikutnya. Kalau aset gagal dimuat, suara dilewati tanpa error atau fallback yang berisik.
- Di ponsel atau grafis rendah: batas suara turun ke 4 dan loop ambient dimatikan lebih dulu.

## Sumber aset

- Audio dari Creator Store (berlisensi Roblox) atau unggahan sendiri yang sudah lolos moderasi.
- Untuk setiap baris tabel disiapkan 2–3 kandidat beserta asset ID. Pengguna memilih setelah mendengar.
- Pilihan akhir dicatat dalam manifest (asset ID, nama, volume, pitch, rolloff) di folder bukti implementasi.

## Garis besar implementasi

1. Modul klien `ObstacleAudio` memantau `workspace.FlyHighObstacles` (musuh dan hazard bermodel), `HazardAlertEvent` dan `LargeChallengeEvent`.
2. Untuk lapis hancur dan lapis aktif, perlu dicek saat implementasi apakah klien sudah menerima peristiwanya (musuh hancur, sambaran, ledakan). Kalau belum, tambahkan event atau atribut kecil dari `WeaponManager` / `ObstacleManager`. Suara lubang balon tidak diubah.
3. Data suara disimpan per jenis di tabel konfigurasi, tidak di-hardcode di beberapa script.

## QA yang dibutuhkan

- Fixture per band di Play Solo: setiap musuh memutar suara datang dan hancur, setiap hazard memutar telegraf dan aktif, dari arah yang benar. Suara lubang balon tetap sama seperti sebelumnya.
- Batas 6 suara, jeda per jenis, ducking saat sirene, dan mute SFX berfungsi.
- Console bersih; aset `IsLoaded`.
- Uji dengar di speaker/headphone dan perangkat mobile. Batas ini tidak bisa dibuktikan dari Studio saja.
