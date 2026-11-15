# Poles model dan cuaca rintangan — 15 November 2026

Status: implementasi tersedia di Studio dan file lokal; QA terarah lulus, perjalanan penuh dan perangkat fisik masih terbuka. Acuan Git `969892d826627383d70a5a27c1df906958159f6d`; working tree sudah berisi pekerjaan dokumentasi/ikon sebelum tugas ini. Tidak commit/push pada tugas ini.

## Implementasi

- Paket Blender asli: 18 model, 34 komponen mesh, 57.768 segitiga keseluruhan; komponen terbesar 5.760 segitiga. [Manifest](../../assets/models/obstacles/generated/manifest.json), [generator](../../tools/build_obstacle_models.py), [metadata pivot/ukuran](../../assets/models/obstacles/generated/components.json).
- Model Roblox `99873351598859`, atlas hasil impor `98805576529305`, moderasi Approved. Tidak memakai aset Toolbox pihak ketiga atau generator berbayar. [Respons aset](asset.json).
- Template produksi `ReplicatedStorage.FlyHigh.Templates.ObstacleMeshes`: 18 model / 34 MeshPart. Hasil impor mentah dipertahankan di ServerStorage. Koreksi ukuran meter menjadi stud, pusat per komponen dan rotasi geometri Y 180° diperlukan setelah impor. [Properti akhir](model-properties.json), [skrip penyiapan template](../../tools/import_obstacle_models.luau).
- `ObstacleArt` memakai template terverifikasi dengan fallback bentuk lama bila template belum tersedia. Semua 9 musuh memakai mesh; WildBird tetap satu kawanan/target dengan 3 burung, Hailstone bergilir pada 3 varian. Sayap tetap direct child agar driver animasi lama bekerja.
- Reruntuhan memakai 3 varian pada 4 posisi. Meteor memiliki satu kepala mesh per lajur; kristal magnet dan proyektil drone memakai mesh. Nama MeteorFragment, ChargedCrystal dan Aperture dipertahankan untuk lifecycle/query/charging.
- `ObstacleVisuals` menambah funnel asap bertingkat, awan petir bertepi lembut, aliran angin lateral, kabut ungu berlapis dan front panas amber. Dinding badai tetap memakai Union yang ada dengan badan lebih transparan dan dua lapis uap awan; tidak menambah geometri dinding baru. HP, band, laju spawn, damage dan telegraph tidak dituning.

## Bukti visual

[Wyvern / phantom / phoenix](hero-models.jpg), [burung / kelelawar / lebah](early-models.jpg), [drone / es / satelit](object-models.jpg), [meteor / reruntuhan / kristal](solid-models.jpg).

[Tornado](tornado.jpg), [awan petir final](lightning-final.jpg), [angin](wind.jpg), [panas](heat.jpg), [kabut](fog.jpg), [magnet](magnetic.jpg), [meteor](meteor.jpg), [puing kuno](debris.jpg), [badai surgawi](celestial-storm.jpg), [dinding badai final](storm-curtain-final.jpg).

Capture visual: Studio Windows, Edit, viewport capture 1920×690, latar langit netral, fixture model terpisah. Kontak model memakai skala review 1,6×. Capture cuaca memakai Emit(8), badai surgawi Emit(20), bukan pengukuran jumlah partikel steady-state. Capture menilai bentuk/material/komposisi; bukan bukti penerbangan bioma, performa mobile atau fase runtime yang direkam.

## QA runtime terisolasi

Studio Windows Run, 0 pemain, target balon sintetis; [fixture](runtime-fixture.luau) adalah salinan ObstacleManager produksi dengan `_G` lokal, container terpisah, dan mock puncture. Tidak menonaktifkan skrip produksi, tidak memasukkan fixture ke activeFlights produksi dan tidak memakai data pemain. Akses data cloud tidak dilonggarkan.

| Skenario | Hasil aktual | Bukti |
| --- | --- | --- |
| 9 musuh | 9/9 revisi 2; semua mesh queryable setelah fade; health 50/50/70/70/70/85/85/100/100 | [Log](runtime-enemies.json) |
| Sayap | Gerak relatif sayap terukur pada WildBird, StormBat, FireBee, CrystalWyvern dan CelestialPhoenix | [Log](runtime-enemies.json) |
| 9 hazard | Belum aktif pada sekitar 0,9 dtk; semua aktif pada sekitar 3,37 dtk; puing 4 mesh, magnet 5, meteor 3 dengan 2 terlihat pada sampel fase | [Log](runtime-hazards.json) |
| Drone | Charging terlihat, fired=true, proyektil mesh queryable, dot arah visual/kecepatan=1, cleanup remaining=0 | [Log](runtime-drone.json) |
| Akhir | 53 source berhasil dikompilasi; 3 source yang diubah identik setelah LF/trimEnd; fixture dibersihkan, 0 flag disable tersisa, Edit/0 pemain dipulihkan | [Cleanup](cleanup.json), [source](source-studio.json), [build](build.json) |

Poles opacity/partikel Lightning dan StormCurtain dilakukan sesudah run runtime tersebut; source final dikompilasi dan konstruksi/capture Edit diulang. Trace runtime sebelum polesan properti tersebut tidak mengklaim pengujian ulang seluruhnya pada VFX final.

## Kegagalan dan batas

- Play Solo pada universe baru tidak dapat memuat data: Enable Studio Access to API Services belum aktif. DataManager sekarang melihat GameId nonzero, sehingga mock khusus GameId=0 tidak berlaku. Percobaan dihentikan; tidak mengaktifkan akses cloud atau melakukan checkout. [Console asli](console.json) berisi kegagalan data tersebut dan percobaan fixture loadstring yang tidak tersedia, bukan console run bersih.
- Peninjauan otomatis menolak usulan awal disable banyak skrip; aksi tersebut tidak dijalankan. Diganti fixture ModuleScript lokal di atas. Usulan pengisian izin direktori juga sempat ditolak sebelum pengguna memberi izin khusus; setelah persetujuan, direktori disimpan melalui tombol Save. Tidak memindah file atau melewati pembatasan unggah.
- screen_capture pada viewport Server/Run gagal `missing field data`. Screenshot bukti akhir menggunakan Edit dan burst partikel eksplisit, bukan screenshot runtime yang gagal.
- Tersisa: penerbangan normal 300–10.000 km dengan scenery/pencahayaan tiap band, keterbacaan pada jarak spawn/tembak di phone/tablet, pengujian raycast tembakan pemain/auto aim terhadap mesh, uji ramai dan performa perangkat fisik, serta buka ulang binary. Bukan QA release penuh.
- Scene Blender awal Cube/Camera/Light dipertahankan. Atelier disimpan sebagai copy; ada satu duplikat phoenix tambahan pada scene aktif yang dipertahankan, tidak termasuk GLB paket 34 mesh yang diunggah. Jangan ekspor seluruh scene tanpa memfilter root 18 model pada manifest.

## Penyimpanan dan cloud

Experience `Fly High - Private Development`, universe `10776821830`, place `97043730132219`, user `8635452105`: visibility PRIVATE terverifikasi melalui API. [Bukti](private-experience.json). Team Create dan data sharing dimatikan saat pembuatan. Folder unggah yang disetujui pengguna hanya `assets/models/obstacles/generated`.

save_place mengembalikan Saved / LocalFile: `E:/Antigravity/Fly High/Fly High.rbxl`, 2.161.622 B, SHA-256 `FF730ED77A450F69745B3033C1CE209001FD8E439B6BCD62637566B1AC4D8608`. Binary belum dibuka ulang. UI Save to Roblox juga dipilih setelah simpan lokal, tetapi tidak memberikan bukti versi cloud baru; updateTime API place tetap checkpoint pembuatan. Jangan menganggap source cloud terbaru identik dengan lokal tanpa membuka/memverifikasi versi tersimpan. [Build](build.json).
