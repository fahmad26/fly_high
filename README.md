# 🎈 Fly High (Roblox Game)

> **Co-op Vertical Hot Air Balloon Survival & Adventure to the Floating Cloud Palace at 10,000 km.**

**Status audit 28 Oktober 2026:** Safe Takeoff Zone 1.200 km dan gondola 28×28 stud sudah diterapkan. Regresi lokal 43/43 lulus; konfigurasi produk Robux, uji cloud/multiplayer serta beberapa aset visual/audio masih perlu diselesaikan sebelum rilis. Lihat [laporan audit lengkap](./AUDIT_REPORT.md).

**Pulau hidup:** laut Terrain, pesisir berpasir, 20 pohon, 60 rumpun tanaman, 56 bunga, batu/kerikil, 6 ayam berkeliaran dan 14 kupu-kupu beranimasi sudah ditambahkan. Jalur lobby tetap terbuka.

## 📖 Ringkasan Game

**Fly High** adalah game petualangan kooperatif 1–3 pemain di Roblox di mana para pemain menaiki balon udara bersama-sama di dalam satu ruang udara global (*shared sky*) yang luas. Seluruh kru harus bekerja sama membagi tugas mengemudikan balon, menembak rintangan terbang, menambal kebocoran kubah menggunakan tali pengaman dan katrol winch, hingga mencapai Istana Awan (*Cloud Palace*) di ketinggian 10.000 km.

---

## 🚀 Fitur Utama

- **Ruang Udara Global (*Shared Sky*) & Safe Takeoff Zone 6x Lipat (0 – 1.200 km)**:
  - Seluruh balon terbang di ruang udara bersama dan dapat saling melihat balon tim lain.
  - Safe Takeoff Zone lapang (0 - 1.200 km) bebas rintangan untuk mencegah tabrakan dan memberikan waktu menyebar formasi.
- **Keranjang Balon Lapang (2x Lipat)**:
  - Keranjang gondola dirancang lega untuk kebebasan gerak 1–3 pemain.
  - Fasilitas kemudi fisik (*HelmSeat*), 2 rak senjata, stasiun tali pengaman & katrol winch, serta sirine peringatan.
- **Pembagian Peran Dinamis**:
  - **Pilot**: Navigasi horizontal (WASD) dan tombol UI khusus `[ 🔥 GAS / NAIK ]`.
  - **Gunner**: Menembak burung liar dan bongkahan es dengan Pistol (8 peluru) atau AK-47 Master (30 peluru) + mobile aim assist.
  - **Engineer**: Memasang tali pengaman berdurabilitas (100 HP, -5 HP/s di luar keranjang), naik ke kubah dengan katrol winch, dan menambal robekan balon (1.5s Solo / 2.0s Duo / 3.0s Trio).
  - **Ghost Spotter**: Pemain yang gugur dapat memunculkan beacon 3D (*tactical ping*) untuk mendeteksi bahaya bagi kru yang masih hidup.
- **Sistem Kerusakan 5 Lubang & Clutch Save**:
  - Setiap lubang mengurangi gaya angkat vertikal. Pada 5 lubang, balon terjun bebas ke tanah.
  - Pemakaian *Emergency Repair Kit* saat terjun bebas memicu **Clutch Save** (memulihkan 0 lubang + shield kebal 60 detik).
- **5 Bioma Estetik Setiap 2.000 km**:
  - `0 - 2.000 km`: Breezy Dawn Archipelago
  - `2.000 - 4.000 km`: Indigo Thundercloud
  - `4.000 - 6.000 km`: Sunset of Forgotten Sky Isles
  - `6.000 - 8.000 km`: Bioluminescent Cosmic Exosphere
  - `8.000 - 10.000 km`: The Celestial Gateway of Elysium
- **Puncak Kemenangan (10.000 km)**:
  - Mendarat di dermaga Istana Awan kristal, photo spot dengan penyembunyi HUD, papan rekor, dan portal pulang.

---

## 📂 Struktur Proyek

- `Fly High.rbxl`: File tempat Roblox Studio utama (Lobby 5 Pod, Balon Udara, Rintangan, Senjata, Skrip Server & Client).
- `PRD_Fly_High.md`: Dokumen Spesifikasi Produk (PRD) lengkap dan komprehensif.
- `HANDOVER.md`: Dokumen panduan handover, peta arsitektur DataModel, dan checklist audit teknis untuk reviewer/developer.

---

## 🛠️ Dokumentasi Lengkap
Untuk detail mendalam mengenai seluruh formula fisika, tabel kerusakan, arsitektur skrip, dan sistem monetisasi, silakan baca [PRD_Fly_High.md](./PRD_Fly_High.md).


Pembaruan 28 Oktober 2026 mencakup audit gameplay, zona aman 1.200 km, gondola 28×28, laut Terrain, vegetasi/fauna bergerak serta lima dermaga dan armada balon bertema. Lihat [laporan audit dan batas pengujian](./AUDIT_REPORT.md) serta [preview lima armada](./audit/five-fleets-preview.jpg).

Pembaruan berikutnya menambahkan Dinding Badai pada lima milestone dan loncatan kru untuk menurunkan balon. Pilot/engineer dibatasi sesuai peran; efek turun dibagi agar solo, duo dan trio seimbang. Rincian balancing dan hasil QA ada di PRD serta AUDIT_REPORT.

QA perangkat 29 Oktober 2026 memperbaiki tata letak HP dan tombol lompat sentuh. HUD ringkas menyediakan panel AKSI, menu toko dapat digulir, dan tombol sentuh minimal 44 piksel. Regresi tiga client 101/101 lulus; hasil serta batas pengujian ada di [laporan audit](./AUDIT_REPORT.md), [hasil QA perangkat](./audit/device-qa-results.json), dan [preview HP](./audit/device-phone-preview.jpg).

Audio peringatan tali, badai dan balon kritis kini tersedia dengan mute lokal lewat AKSI. Pendaratan katrol juga distabilkan; dua engineer memakai titik landing berbeda. QA akhir 139/139 lulus. Lihat [hasil audio](./audit/warning-audio-results.json) dan [laporan audit](./AUDIT_REPORT.md).
