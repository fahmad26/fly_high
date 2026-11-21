# Handgun & AK-47 v2 + tangan first-person (21 November 2026)

## Permintaan
- 11:34 WIB: "perbaiki tangan dan Handgun serta AK-47 ... posisinya masih berantakan. Boleh remodelling asset menggunakan Blender."
- 12:02 WIB, umpan balik untuk percobaan pertama (lengan stylized buatan Blender): "tangannya aneh banget, seperti kayu, dan tangan yang satu lagi posisinya aneh dan terlalu panjang."

## Keputusan akhir
- **Senjata**: memakai model baru dari Blender (sumber di `assets/models/weapons/FlyHigh_Weapons_v2.blend`, FBX `FlyHigh_PistolVM.fbx` / `FlyHigh_AK47VM.fbx`). Asset Model diunggah ke akun pengguna:
  - Pistol `139558185278029`
  - AK-47 `105907948969808`
  - Mesh dipasang ke `ReplicatedStorage.FlyHigh.Templates.Weapons.Pistol/AK47`: tool 3P, rak, dan sumber viewmodel 1P.
  - Visual lama dicadangkan di `ServerStorage.WeaponsLegacy_20261121`.
- **Tangan**:
  - Lengan stylized Blender **dibatalkan**. Folder `Templates.FirstPerson` dan jalur `createBakedView` sudah dihapus.
  - Kode `WeaponPresentation` kembali sama dengan HEAD, kecuali tabel `viewProfiles`.
  - Viewmodel memakai lengan realistis yang sudah ada (`Templates.ViewModelArms`: jaket + sarung tangan taktis, mesh bertulang). Lengan diposekan ulang terhadap grip senjata baru.

## Perubahan source
`ReplicatedStorage.FlyHigh.Modules.WeaponPresentation`: hanya blok `viewProfiles` (Pistol, AK47). Versi akhir (setelah revisi 12:51) Studio = mirror: len 71610, FNV `518516c2`. Angka pose di bawah ini dari versi pertama; versi akhir dijelaskan di bagian Revisi.

Pistol, two-hand isosceles:
- gun 0.95×, posisi (0.30, −0.51, −1.38).
- Tangan kanan: telapak di panel kanan, buku jari di depan grip, telunjuk masuk trigger guard, jempol lurus ke depan.
- Tangan kiri: membungkus panel kiri dan jari tangan kanan, jempol ke depan.

AK-47, hip hold:
- Badan diputar 25° (bladed) supaya lengan kiri mencapai handguard tanpa terlalu lurus atau panjang.
- Tangan kanan tinggi di pistol grip, telunjuk di trigger.
- Tangan kiri di bawah handguard, jari melingkar ke sisi kanan, jempol di sisi kiri.

Metode:
- Titik buku jari tengah ditentukan dari geometri grip (screenshot samping dengan penggaris).
- `wristOffset = buku jari × gunScale − arahJari × 0,425` (panjang telapak rig pada armsScale 0,042).
- Diverifikasi lewat posisi tulang hasil IK (`R_middle1`/`L_middle1` tepat di target).

## Revisi 12:16 WIB: tangan menembus senjata
Pengguna melapor: "itu tangannya nembus senjata". Laporan itu benar.
- Sebelumnya pose hanya dicek dari depan dan satu sisi.
- Dari sudut lain, grip pistol terlihat menembus telapak/jari tangan kiri (`10`, `11`).
- Pengukuran AK versi pertama: 44 titik jari/telapak berada di dalam mesh.

Perbaikan:
- **Pengukur bentuk senjata yang akurat.**
  - Segitiga mesh asli dibaca lewat `AssetService:CreateEditableMeshAsync`.
  - Mesh diubah menjadi voxel 0,012–0,016 stud, dengan isi ditentukan memakai winding ray.
  - Hasilnya diubah menjadi distance field (chamfer).
  - Collision `PreciseConvexDecomposition` tidak bisa dipakai. Hull-nya menggembung sampai sekitar 0,1 stud di depan grip dan trigger guard.
- **Fitting genggaman otomatis.**
  - Telapak didorong keluar sampai bebas dari senjata.
  - Lalu jari ditutup bertahap (proximal → distal) dan berhenti tepat sebelum menyentuh permukaan.
  - Untuk tangan kiri, jari tangan kanan dihitung sebagai kapsul penghalang.
- **Pemilihan posisi.**
  - Posisi tangan dan arah telapak dipilih lewat grid search: penetrasi = 0, kontak sebanyak mungkin, dan tangan tidak terdorong jauh.
- **AK-47.**
  - gunScale dinaikkan ke 1,15, karena grip asli terlalu pendek untuk jari tengah dan manis.
- **Hasil pengukuran jalur produksi** (`viewProfiles` modul, radius jari 0,035, telapak 0,05):
  - Pistol: 1 titik sedikit di bawah radius (jarak 0,03, tidak masuk mesh).
  - AK: 1 titik serupa.
  - Tidak ada titik di dalam mesh.
- Parity Studio = mirror: len 71413, FNV `e30bd1b2`.
- Bukti `12`–`20`: close-up kanan, kiri, depan, dan bawah, plus Play Solo 1P. Console bersih.

Batasan:
- Tabrakan antar-tangan hanya didekati dengan kapsul.
- Ketebalan jari diasumsikan 0,035 stud, karena mesh kulit tangan tidak bisa diukur langsung.
- Tangan kiri pistol menempel di sisi kiri grip dan tangan kanan, tetapi jarinya tidak melingkari jari kanan serapat pegangan nyata.

## Revisi 12:38 WIB: ukuran tangan
Pengguna bertanya apakah ukuran tangan sengaja dibuat aneh (screenshot `13`). Jawabannya: tidak disengaja.

Hasil pengukuran sebelum revisi (`H.measure`):
- Panjang tangan 0,90 stud dan panjang pistol 0,91 stud (rasio 1,02). Glock nyata sekitar 0,98.
- Telapaknya sempit (lebar/panjang 0,36, nyata ±0,45), sehingga jari tampak panjang dan gemuk.
- Close-up dari dekat membuat tangan yang lebih dekat ke kamera tampak lebih besar.
- Jari tangan kiri di pistol hampir lurus (curl 6–21°), jadi terlihat seperti "sosis" mengambang.

Perbaikan:
- `armsScale` 0,042 → 0,038 untuk kedua senjata. Panjang tangan kini 0,81: pistol = 1,12× tangan, AK = 4,5× tangan.
- `shoulderOffset` disesuaikan.
- Pose di-fit ulang dengan kapsul antar-tangan 0,75× dan bobot curl lebih besar, supaya jari tangan kiri benar-benar menekuk:
  - Jari kiri pistol: 39/27/15/9° (pangkal).
  - Jari kiri AK: 45–51°.
- Pengukuran jalur produksi: Pistol bad=1, AK bad=0, keduanya inside=0.
- Parity: len 71505, FNV `0ad0cf61`.
- Harness disimpan di `tools/qa/vm_harness.lua` untuk fitting ulang.
- Bukti `21`–`27`: close-up dan Play Solo 1P. Console bersih.

## Revisi 12:51 WIB: tangan kiri pistol menggumpal di tampilan 1P
Pengguna menandai tangan kiri di tampilan orang pertama (`28`).

Penyebab:
- Sudut tekuk pergelangan tangan kiri (antara arah lengan bawah dan arah tangan) 80°.
- Pergelangan berada tinggi di belakang grip, sementara tangan menunjuk ke bawah-depan.
- Dari kamera, punggung tangan dan tekukan itu terlihat sebagai gumpalan hitam.
- Pengecekan saya sebelumnya hanya mengukur tembus, tidak mengukur sudut sendi.

Perbaikan:
- Harness kini menghitung tekuk pergelangan (`H.bends`, `stats.bend`) dan memberi penalti bila tekuk melebihi 25°.
- Grid search diulang untuk tangan kiri pistol, termasuk variasi `elbowPole`.
- Hasil: tekuk kiri 30° (kanan 34°, AK 30/35°).
- Jari kiri kini melingkari jari kanan di depan grip (`31`). Tidak ada titik di dalam mesh.
- Parity: len 71610, FNV `518516c2`.
- Bukti `29`–`32`: Play Solo 1P di `32`. Console bersih.

## Bukti
| File | Isi |
|---|---|
| `00_attempt_too_close_rejected.jpg` | Percobaan awal: senjata terlalu dekat kamera, tangan tampak raksasa (tidak dipakai) |
| `01`–`02` | Pistol, Edit harness: tampak depan dan close-up kanan (telunjuk di guard) |
| `03`–`05` | AK-47, Edit harness: depan, kanan (tangan kiri melingkar handguard, kanan di grip), kiri (jempol kiri) |
| `06` | Play Solo 1P Pistol dengan HUD |
| `07` | Play Solo 1P AK-47 |
| `08` | AK-47 saat `Reloading=true` (pose reload tetap mengikuti) |
| `10`–`11` | **Sebelum revisi**: grip pistol menembus tangan |
| `12`–`15` | Pistol setelah revisi: kanan, kiri, depan, bawah |
| `16`–`18` | AK-47 setelah revisi: kanan, kiri, bawah |
| `19`–`20` | Play Solo 1P setelah revisi |
| `21`–`25` | Setelah revisi ukuran (armsScale 0,038): pistol kiri/kanan/depan, AK kanan/kiri |
| `26`–`27` | Play Solo 1P setelah revisi ukuran |
| `28` | Laporan pengguna: tangan kiri menggumpal (1P) |
| `29`–`32` | Setelah tekuk pergelangan diperbaiki: 1P Edit, kiri, depan, Play Solo |

## QA
- Play Solo:
  - Tool dipasang langsung ke karakter (bukan lewat rak), karena rak hanya bisa diambil saat flight.
  - Viewmodel muncul untuk kedua senjata dan pose reload jalan.
  - Console bersih (satu error `loadstring` berasal dari percobaan perintah QA saya, bukan game).
- 3P (fixture IK disalin dari `WeaponManager.applyTwoHandIK`):
  - Senjata mengarah ke depan dan tangan kanan menempel di handle.
  - Tangan kiri masih ±0,5 stud dari `LeftHandGripTarget`, padahal target masih dalam jangkauan lengan. Penyebabnya belum diteliti. Kode IK server tidak diubah. Avatar uji berlengan hoodie besar, jadi tampilan sulit dinilai.
- Belum diuji:
  - Menembak sungguhan lewat rak saat flight.
  - Layar phone/tablet.
  - Dua klien.
- Cleanup selesai:
  - Edit mode.
  - `_QA_*` 0.
  - `ServerStorage._Import_PistolVM/_Import_AK47VM` dihapus (asset tetap ada di akun).
  - `WeaponsLegacy_20261121` dibiarkan sebagai cadangan.

## Status
- Studio (place cloud): belum di-save atau publish oleh Claude.
- Belum ada commit.
- `assets/models/weapons/blender_src/_tmp_baked.lua` adalah file sementara yang belum terhapus, karena izin hapus di perangkat tidak aktif.

## Checkpoint Git (ditambahkan 21 Nov 16:40 WIB)
Status di atas adalah status pada waktu run. Setelahnya, `Fly High.rbxl` lokal (`3.590.804` B) disimpan pengguna 21 Nov 16:16 WIB, SHA-256 `120a7ad6…71b59432`; parser offline: 67/67 source sama persis dengan mirror setelah normalisasi (LF, spasi akhir), objek/model belum dibuka ulang. Laporan ini dikonsolidasikan ke commit & push `main` 21 Nov.
Revisi berikutnya (jempol, 21 Nov 16:00) ada di [fingers-hud-islets](../fingers-hud-islets-2026-11-21/README.md). `assets/models/weapons/blender_src/_tmp_baked.lua` sudah dihapus; `vm_pistol.py` (generator lengan stylized yang ditolak) tidak di-commit.
