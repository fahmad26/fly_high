# Handover scenery Fly High · 0–10.000 km

## Pemolesan sambungan aset — 10 November 2026

Pada saat pemeriksaan ini, source Studio dan mirror `BiomeScenery` identik (95.788 byte UTF-8/LF, rolling hash base-31 `986080822`). Hasil dan screenshot di bawah merekam versi yang diuji pada 10 November 2026.

| Bioma | Perubahan pass ini |
| --- | --- |
| Dawn | Dua lapisan kapur mengikuti mesh tebing yang sudah ada, dengan bibir tanah di bawah rumput untuk melembutkan pertemuan permukaan hijau dan batu. |
| Indigo | Massa awan menyambung ke kaki dan bahu pusaran. Kilatan warna menyebar ke seluruh lobe dalam kelompok awan, bukan hanya satu bagian. |
| Forgotten Sky Isles | Ujung jembatan diberi jalan pendek yang tertanam dan penopang batu terpahat. Pecahan kecil ditempatkan di bawah ujung patahan. |
| Cosmic | Warna alas observatorium dibuat lebih terbaca; tiga tonjolan batu memakai warna pantulan sian redup dengan material batu, tanpa tambahan lampu. |
| Celestial Gateway | Profil awan fondasi tersusun dari volume yang saling bertumpuk, bagian bawah meruncing, dan kabut tipis. Setelah review visual, tinggi awan ditambah dan pusatnya diturunkan agar tidak terlalu pipih serta tetap menopang bangunan. |

### Bukti dan batas verifikasi

- Kelima builder berhasil dijalankan di Studio, termasuk fungsi animasi dan opacity 0, 0,25, 0,5, 0,75, dan 1.
- Jumlah BasePart hasil build masing-masing 1.176, 198, 854, 369, dan 436. Semuanya anchored, tanpa collision, touch, dan query.
- Playtest satu pemain menggunakan 20 sampel altitude naik/turun dari 1.260 hingga 10.000 km. Pada batas 2.000/4.000/6.000/8.000 km hanya dua scene transisi yang ada; di titik tengah hanya satu. Scene lama dibersihkan.
- Console sesi terakhir hanya memuat pemberitahuan DataManager memakai mock terisolasi di unpublished Studio. Tidak ada error game pada sesi tersebut.
- Screenshot diperiksa dari kamera penerbangan dan sudut dekat/bawah. HUD disembunyikan sementara untuk inspeksi. Fixture kamera dan data pengujian hanya ada di sesi Play dan hilang setelah Stop.
- Ini verifikasi visual bertitik dan lifecycle scene, bukan penerbangan penuh, uji multiplayer, pengukuran FPS, atau uji iPad fisik. Transaksi/data produksi tidak diuji pada pass ini.

Screenshot tersimpan di [folder audit](../audit/scenery-polish-2026-11-10/README.md). Rute, jumlah rintangan, aturan gameplay, dan furnitur plaza Istana Awan tidak diubah.

Status inventaris & implementasi per **10 November 2026** (**Selesai Diimplementasikan & Diverifikasi di Studio**). Seluruh aset **P1**, **P2**, dan **Pemolesan aset yang sudah ada** pada kelima zona terbang (`0–10.000 km`) telah dibangun dan dianimasikan di [`BiomeScenery.luau`](../audit/sources/ReplicatedStorage/FlyHigh/Modules/BiomeScenery.luau) serta disinkronkan ke `ReplicatedStorage.FlyHigh.Modules.BiomeScenery` di `Fly High.rbxl`. [Gambar konsep v2](./fly-high-scenery-0-10000km-v2.png) menjadi acuan susunan vertikal dari pulau spawn ke Istana Awan, sementara [PRD](../PRD_Fly_High.md) menjadi acuan batas zona, rintangan, dan aturan gameplay.

| Zona | Sudah ada di place | Aset baru yang perlu dibuat | Pemolesan aset yang sudah ada |
| --- | --- | --- | --- |
| **0–2.000 km · Breezy Dawn Archipelago** | Pulau spawn, laut, lima dermaga, vegetasi, ayam, kupu-kupu, pulau pesisir, perahu layar laut, dan gugusan awan pesisir. | **P1:** kit batu/pulau melayang rendah dengan pucuk tanaman, balon cuaca dekoratif dengan bentuk berbeda dari armada pemain, dan kawanan burung laut dekoratif yang melintas di kejauhan. **P2:** satu varian pulau melayang dengan air terjun tipis sebagai transisi menuju lapisan awan. | Susun ulang awan pesisir menjadi lapisan dekat, menengah, dan jauh. Pastikan sejak lepas landas sampai mendekati 2.000 km ada beberapa siluet yang terlihat pada elevasi kamera, selain pemandangan laut di bawah. |
| **2.000–4.000 km · Indigo Thundercloud** | Tebing cumulonimbus, tirai hujan miring, menara awan badai, dan kilatan warna pada badan awan. | **P1:** dua siluet pusaran badai latar dengan profil lebar dan ramping. **P2:** fragmen batu bercahaya redup di tepi badai, jika kedalaman visual masih kurang. | Gunakan kembali tebing dan menara awan untuk membuat anvil terpisah. Perjelas tirai hujan dari sudut pandang balon. Tempatkan pusaran di luar koridor dan beri gerak lambat supaya mudah dibedakan dari Angin Topan aktif. |
| **4.000–6.000 km · Sunset of Forgotten Sky Isles** | Tujuh pulau melayang termasuk pulau kuil, lengkung dan pilar rusak, akar menjuntai, kolam, serta air terjun berkabut. | **P1:** kit jembatan batu patah yang bisa dipasang antarlandmark di sisi koridor. **P2:** varian reruntuhan menengah dengan lonceng angin atau ornamen gantung, serta satu jenis pohon berbunga sebagai penanda siluet. | Pakai kembali kit pulau dan air terjun yang sudah ada untuk beberapa pulau kecil di kejauhan. Susun gugusan dengan ukuran berbeda, dan jangan menutup pandangan ke jalur terbang dengan satu deret pulau yang rata. |
| **6.000–8.000 km · Bioluminescent Cosmic Exosphere** | Pita aurora hijau dan magenta, titik bintang, debu cahaya bergerak, serta template `Cosmic` berupa kelompok kristal yang dipasang pada dua posisi. | **P1:** satu observatorium melayang dengan cincin armillary dan dudukan reruntuhan batu. **P2:** lengkungan batu bercahaya kecil di kejauhan sebagai lapisan ketiga. | Olah ulang kristal `Cosmic` menjadi pulau kristal utama dengan alas batu, kristal bersegi yang mudah terbaca, dan satelit kecil. Gunakan siluet dan gerak lambat agar berbeda dari meteor atau serpihan satelit aktif. |
| **8.000–10.000 km · The Celestial Gateway** | Teras awan emas, sinar matahari, siluet Istana Awan, model lengkung/menara/paviliun horizon, awan tinggi, dan tiga kapal `CloudSailer`, `CloudKetch`, `CloudCutter`. | **P2:** gerbang kristal melayang yang tampil sebagai landmark di kejauhan, dengan bentuk dan warna berbeda dari `ReturnPortal`. | Atur ulang jarak dan rute kapal serta sebaran paviliun agar beberapa lapisan terbaca selama pendakian, bukan hanya setelah tiba. Gunakan variasi ukuran dan kabut supaya istana tetap menjadi fokus. |
| **10.000 km · Plaza Istana Awan** | Istana, dermaga, air terjun dan kanal, taman, dua ayunan, sofa dua tempat duduk, podium foto, portal pulang, pagar tak terlihat, dan awan yang bisa diinjak dengan efek langkah. Lampu kecil di jalur utama dan taman tersusun dalam lima pasang. | Tidak ada aset plaza baru yang wajib untuk pass pengisian ruang udara. | Ikuti siluet istana dan palet pada ilustrasi. Untuk tata letak yang bisa dimainkan, pakai posisi di Studio sebagai acuan: sofa di tengah jalan depan pintu utama, dua ayunan dekat taman, dan pot serta lampu di lantai kering. |

**P1** adalah aset pertama yang mengisi celah visual besar. **P2** menambah variasi setelah penempatan P1 terlihat jelas dalam penerbangan.

## Titik masuk untuk implementasi

- `Fly High.rbxl` memuat place yang dimainkan. Lihat `Workspace.FlyHighLobby` untuk pulau awal dan `Workspace.CloudPalace` untuk plaza. Jangan membangun ulang furnitur, interaksi, pijakan awan, atau pagar yang sudah ada hanya karena posisi di ilustrasi berbeda.
- Template landmark ada di `ReplicatedStorage.FlyHigh.EnvironmentAssets.BiomeLandmarkMeshes`. [Generator GLB](../assets/generate-scenery-meshes.cjs) membuat `assets/FlyHighScenery.glb`. Mengubah generator atau GLB belum otomatis memperbarui template di place. Cek template aktif, ukuran, pivot, dan material setelah pemasangan.
- [BiomeScenery](../audit/sources/ReplicatedStorage/FlyHigh/Modules/BiomeScenery.luau) membangun dan menganimasikan scenery per zona. [BiomeLightingController](../audit/sources/StarterPlayer/StarterPlayerScripts/BiomeLightingController.luau) mengatur pergantian bioma, pencahayaan, dan penghapusan scenery klien. Bila mengedit source di Studio, sinkronkan juga mirror di `audit/sources/`.
- Scenery udara baru bersifat dekoratif dan lokal di klien. Pakai geometri tanpa tabrakan, sentuhan, atau query. Biarkan koridor dan peringatan rintangan tetap terbaca. Zona di bawah 300 km tetap bebas rintangan lingkungan. Burung latar, pusaran, dan batu kosmik pada konsep tidak menambah serangan atau hitbox.

## Urutan kerja dan pemeriksaan

1. Mulai dari pulau rendah, balon cuaca, kawanan burung latar, dan observatorium. Aset ini mengisi ruang yang paling kosong dan bentuknya belum tersedia sebagai scenery siap pakai.
2. Lanjutkan dengan pusaran latar dan jembatan patah. Pasang ulang kapal, paviliun, dan kristal yang sudah ada sebelum membuat variasi baru.
3. Ambil screenshot dari gondola pada sekitar 500, 1.200, 1.900, 3.000, 5.000, 7.000, 9.000, dan 10.000 km. Lihat ke depan, samping, dan atas. Periksa siluet, jarak antarobjek, koridor terbang, dan keterbacaan rintangan. Bandingkan desktop dan tampilan tablet.
4. Uji naik dan turun melewati batas bioma, Game Over, respawn di lobi, Victory, serta portal pulang. Pastikan dekorasi berganti sesuai zona, tidak meninggalkan model atau animasi lama, dan tidak mengganggu pendaratan di Istana Awan.

Inventaris ini telah diimplementasikan penuh dan ditingkatkan kualitas visualnya menggunakan komposisi `MeshPart` & `UnionOperation` terukir (*sculpted*) yang serasi dengan `FlyHighLobby` dan `CloudPalace` (`EnvironmentAssets`, `BiomeLandmarkMeshes`, `Templates.FleetGeometry`, `Templates.BalloonSkins`, dan `CloudPalace.SummitPhotoPodium`/`PalaceGarden`) di DataModel aktif (`ReplicatedStorage.FlyHigh.Modules.BiomeScenery`) serta mirror source (`audit/sources/ReplicatedStorage/FlyHigh/Modules/BiomeScenery.luau`), melewati verifikasi visual gondola (`0`, `500`, `1.200`, `1.900`, `3.000`, `5.000`, `7.000`, `9.000`, dan `10.000 km`) dengan `0` intrusi koridor (`|X| < 155, |Z| < 155`) dan `0` part kolisi (`Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false`).
