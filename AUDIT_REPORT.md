# Audit teknis Fly High — 28 Oktober 2026
Status: dua revisi utama selesai dan disimpan ke `Fly High.rbxl`. Gameplay inti lolos regresi lokal. **Belum dinyatakan siap rilis publik** karena konfigurasi monetisasi, pengujian cloud/multiplayer, dan beberapa aset PRD masih belum lengkap.

## Lingkup dan bukti
- Membaca lengkap PRD_Fly_High.md dan HANDOVER.md; memeriksa 13 skrip awal, seluruh template balon/senjata/rintangan, lobby, koridor, dan istana pada Studio yang terhubung.
- Menambahkan ServerUtils (ModuleScript) dan PalaceManager (Script); total akhir **15 skrip**, seluruhnya dapat dikompilasi.
- Menjalankan beberapa sesi Play server/client, pemeriksaan RemoteEvent, interaksi UI/proximity prompt, dan fixture Luau di VM permainan.
- Place lokal yang diaudit: PlaceId=0, GameId=0. Tidak memublikasikan experience dan tidak melakukan transaksi Robux atau mengubah profil cloud.
- Backup sebelum perubahan: `audit/Fly High.before-audit.rbxl`.
- SHA256 backup: `C3D8D13DB1F95387B44D5B0E1C1E147853A09034AFC29E4D8D43E562D81BD21F`.
- SHA256 hasil terbaru setelah lima armada: `01276844CB57EC27D6D70FDA3BD14942ADB8AA2C34B391C43F567B2A47C51866`.
- Ekspor seluruh skrip di `audit/sources/` diverifikasi cocok dengan Source di Edit DataModel (15/15).
- Harness dan script QA hanya dimasukkan ke DataModel Play. Tidak terdapat AuditHarness/test fixture di place yang disimpan.

## Dua revisi PRD

| Revisi | Implementasi dan hasil |
| --- | --- |
| Safe Takeoff Zone 0–1.200 km | Konstanta SAFE_TAKEOFF_KM=1200. Pemunculan enemy/hazard ditolak di bawah batas; gerak obstacle tidak boleh membawa geometri ke bawah zona aman; ApplyPuncture juga menolak kerusakan di zona aman. Batas 1.199,99 dan 1.200 diuji. Pada laju 16,67 km/s, zona ini setara 72 detik. |
| Gondola diperbesar | BasketFloor 14×14 menjadi **28×28 stud**; RootPart, pagar, posisi helm, dua rak, stasiun tali, empat tiang dan sirine disesuaikan. |
| Definisi “2×” | Mengikuti arahan eksplisit handover untuk memperbesar dimensi/offset 2×. Artinya panjang dan lebar masing-masing 2×, sehingga luas lantai menjadi 4× baseline. |
| Batas tali mengikuti geometri | Deteksi menggunakan posisi lokal terhadap persegi panjang BasketFloor, termasuk batas vertikal. Ini menghindari peluruhan di sudut lantai yang akan terjadi jika hanya mengganti radius 8,5 menjadi 17. |
| Penyesuaian boarding | Titik spawn digeser 18 stud ke belakang pad agar lantai yang diperbesar tidak bertumpuk dengan konsol pod. Grup collision balon meniadakan tumbukan fisik antarmodel balon. |

## Temuan dan perbaikan

| Prioritas awal | Temuan | Perbaikan |
| --- | --- | --- |
| P0 | WeaponFireEvent mempercayai origin dan fallback hitInstance client; tidak ada ammo, fire rate atau reload server. | Origin berasal dari muzzle server, hanya hasil raycast server digunakan. Validasi tipe/finite/range, kru hidup, senjata milik penerbangan, cadence, magazine dan reload dilakukan server. |
| P0 | ShopPurchaseEvent langsung memberikan item gratis; bukan pembayaran Roblox. | Menggunakan MarketplaceService dan ProcessReceipt; grant receipt dideduplikasi dan disimpan bersama profil. ID produk 0 menolak pembelian dengan pesan yang jelas. |
| P1 | Emergency Kit ditolak selama kebal pasif 5 detik, justru setelah lubang ke-5. | Timer shield berbayar dipisahkan dari invuln pasif. Clutch Save diperbolehkan selama masih di udara, membatalkan momentum jatuh, memulihkan seluruh lubang, dan memberikan shield 60 detik. |
| P1 | Pemain mati atau penerbangan terminal bisa mengakses beberapa aksi; respawn dapat dihitung sebagai kru hidup kembali. | Identitas karakter saat boarding dan status gugur disimpan per penerbangan. Respawn tidak menghidupkan kembali kru; kemudi/rak/tali/kit menolak pemain di luar kru hidup. |
| P1 | Repair menggunakan jumlah lubang sebagai indeks sehingga repair tidak berurutan bisa merusak hitungan/visual. | holeSet menyimpan lubang individual; repair lubang nonaktif/duplikat ditolak; semua repair manual terkunci pada 5 lubang. |
| P1 | Waktu tahan ProximityPrompt belum dibuktikan server. | Begin/Finish/Cancel perbaikan divalidasi waktunya, jarak, karakter, tali, balon dan status lubang. Bergerak keluar jarak membatalkan repair. |
| P1 | Rintangan dibuat per balon, bukan shared world; hazard belum lengkap per segmen. | Satu scheduler per segmen ketinggian yang sedang terisi, folder obstacle bersama, collision diperiksa terhadap semua penerbangan aktif. Sembilan segmen mendapat profil hazard/enemy dasar. |
| P1 | Angka altitude dan perpindahan fisik memakai kecepatan berbeda; docking ditimpa update berikutnya dan istana berada 2.000 stud di luar jalur. | Pemetaan tunggal 0,25 stud/km; altitude dihitung dari RootPart. Kondisi akhir keluar dari loop biasa. Istana dipindahkan ke atas kolom, pendekatan docking dilakukan bertahap, kru diturunkan ke dermaga. |
| P1 | Kemudi tidak memvalidasi Vector3/NaN/Inf, normalisasi, server cadence atau input stale. | Input pilot sah dibatasi, vektor dinormalisasi, sumbu Y diabaikan, kontrol berhenti tanpa heartbeat input. Batas horizontal dihitung server. |
| P1 | Tali/station slot tidak dibersihkan pada mati, keluar, respawn atau balon hancur; winch hanya teleport. | Pembersihan rope/attachment/slot, perpindahan halus relatif terhadap balon, snap menewaskan karakter saat durability nol; sinkronisasi tali 10 Hz. |
| P1 | Koridor lama memakai Part terlalu tinggi sehingga terpotong ke 2.048 stud dan tidak menjangkau tanah. | Delapan Part (dua segmen per sisi) menutup 0–2.600 stud, tepi ±150; pusat balon dibatasi ±120. |
| P1 | Crash tidak membersihkan balon; tidak ada mekanisme portal server; beberapa koneksi overhead menumpuk tiap respawn. | Cleanup terminal, portal tervalidasi, koneksi overhead dilepas saat GUI karakter dihancurkan. |
| P1 | Load gagal dapat disimpan sebagai profil default; SetAsync berpotensi menimpa sesi lain. | Mock hanya untuk Studio unpublished. Profil live menggunakan retry, UpdateAsync, session lease, autosave dan shutdown save. Load gagal tidak masuk gameplay. Implementasi cloud perlu uji khusus sebelum rilis. |
| P2 | Setup rack berulang menambah callback dan memakai jenis senjata lama. | Rack dipasang satu kali, jenis dibaca saat pickup; upgrade membersihkan senjata lama dan mempertahankan batas dua slot. Drop/pickup mempertahankan magazine, cadence dan deadline reload. |
| P2 | Tactical ping menerima teks/posisi sewenang-wenang dan dapat di-spam global. | Pesan dari allowlist, vektor finite dan jarak dibatasi, cooldown 2 detik, marker hanya dikirim ke kru terkait dan dibersihkan setelah 3,5 detik. |
| P2 | Prompt turun/repair mudah keluar layar; E dipakai beberapa interaksi; UI kit bertumpuk dengan status. | Tombol rigging pada HUD, F naik/Q turun, tahan tambal lewat HUD, pelepasan input/focus ditangani; penataan status dan kit diperbaiki. |

## Yang sudah baik dan dipertahankan
- Pemisahan tanggung jawab server/client/config sudah memudahkan audit.
- Tabel efek 0–5 lubang, 8/30 peluru, waktu reload dan durasi repair solo/duo/trio sesuai arah PRD.
- Dua rak, lima pod, master, overhead, biome Lighting dan elemen dasar istana sudah tersedia.
- HUD gas khusus pilot, sinkronisasi penerbangan 10 Hz, passive invulnerability serta konsep Clutch Save merupakan fondasi yang tepat.
- Struktur template memungkinkan perluasan geometri tanpa mengganti keseluruhan aset balon.

## Hasil QA

### Regresi otomatis terakhir
**43/43 pemeriksaan lulus**, meliputi batas spawn/damage aman, passive grace, repair duplikat/tidak berurutan, critical freefall, clutch, anti-waste, sekali per flight, geometri keranjang, konfigurasi tali 1/1/2, waktu repair 1,5/2/3 detik, input NaN/Inf/tipe salah, dan metadata telegraph 3 detik untuk sembilan segmen.

### Pengujian integrasi/interaktif
- Masuk pod dan memulai penerbangan melalui prompt; master terdeteksi.
- Duduk helm, HUD gas muncul, menahan gas menghasilkan kenaikan posisi fisik; input berhenti saat dilepas.
- Pasang tali → winch naik → tahan tombol HUD repair hingga satu lubang tertutup → turun kembali ke keranjang: **lulus**.
- Peluruhan tali di luar keranjang teramati; snap pada nol membersihkan tali dan memicu Total Crew Wipe solo: **lulus**.
- Timer tali dibekukan khusus saat audit interaksi bertahap untuk mengatasi jeda antar tool. Pengujian decay/snap dilakukan terpisah; tidak mengklaim seluruh alur lima lubang sebagai run tanpa fixture.
- Burst 100 permintaan tembakan menurunkan magazine dari 8 menjadi 7; input rusak tidak menghasilkan error.
- Raycast terhadap target uji server berhasil menghancurkan target meskipun client mengirim origin palsu.
- Drop/pickup setelah tembakan mempertahankan magazine 7; reload biasa sebelumnya diuji mencapai 8. Uji gabungan drop *saat* reload belum memberi hasil observasi lengkap; tidak dihitung lulus.
- Permintaan toko pada place tanpa Product ID tidak menambah stok; tidak ada pemberian gratis.
- Ping tim diterima client; validasi input dan cooldown ada pada server.
- Menyentuh 10.000 km: Victory=true, SummitCount +1, MaxAltitude=10000, kru mendarat dekat dermaga dalam keadaan tidak anchored: **lulus**.
- Terjun bebas 5 lubang dari dekat tanah: GameOver=true, Humanoid.Health=0 dan RootPart.Y=groundY=12,5: **lulus**.
- Output sesi regresi terakhir: **0 error, 0 warning**, hanya informasi mock mode untuk place unpublished.
- Kesalahan helper QA selama pengembangan (query balon sesudah sesi sudah berakhir) dicatat terpisah di console-during-development.txt; tidak dianggap sebagai kelulusan skenario permainan.

### Batas verifikasi
- Skenario akselerasi altitude memakai fixture; belum melakukan satu penerbangan natural penuh 600 detik.
- Kapasitas/durasi solo/duo/trio diuji lewat template setup; belum ada 2–3 pemain nyata atau lima tim simultan.
- Belum dilakukan soak test panjang, profiling memori, simulasi latency/packet loss, perangkat mobile fisik, atau controller nyata.
- ProcessReceipt, DataStore live, kegagalan jaringan cloud dan retry lintas server belum dijalankan pada universe uji terpublikasi.
- Portal dan photobooth telah diperiksa dari kode; interaksi pemain pada keduanya belum masuk skenario regresi yang lulus.

## Kesenjangan PRD yang masih terbuka

| Bagian | Status akhir |
| --- | --- |
| Developer Products | PRODUCT_IDS.EmergencyKit dan AK47Upgrade masih **0**. Pemilik perlu memasukkan ID produk milik universe dan memverifikasi harga di Creator Dashboard. |
| Persistensi/monetisasi live | Wajib uji pada universe terpisah sebelum rilis; belum ada bukti transaksi atau penyimpanan cloud dari audit lokal ini. |
| Model musuh dan hazard per segmen | Scheduler dan profil mekanik dasar tersedia, tetapi beberapa musuh memakai ulang model WildBird dengan warna/nama baru; hazard memakai volume telegraph sederhana. Belum setara visual/mechanic bespoke PRD (drone penembak paku, labirin reruntuhan, laser kilat, kombinasi badai klimaks). |
| Lima biome | Lima transisi Lighting tersedia beserta efek dasar. Pemandangan pulau melayang/air terjun, aurora animasi dan komposisi bintang sesuai PRD belum lengkap. |
| Audio alarm | **Tidak ada Sound instance** pada place; audio sirine PRD belum terimplementasi. Lampu dan banner peringatan tersedia. |
| Pulau dan lautan | **Diperbaiki pada tindak lanjut 28 Oktober 2026.** Terrain rumput luar pulau diganti air Terrain 4096×4096 stud, kedalaman 64 stud, permukaan Y=0. Pulau berpesisir rumput/pasir dibentuk di sekitar lobby. Sampling luar pulau kini mengenai Water; pusat lobby tetap Grass Y=10. |
| Hall of Fame | Belum ada papan peringkat persisten di istana. |
| UI lintas perangkat | Kontrol sentuh/gamepad dasar tersedia; perlu uji layout dan ergonomi pada viewport/perangkat nyata. |

## Berkas yang diserahkan
- `Fly High.rbxl`: place lokal yang sudah disimpan melalui Studio.
- `audit/sources/`: snapshot seluruh Source Luau untuk review diff; bukan sistem live-sync/Rojo.
- `audit/baseline.json`: snapshot Source sebelum perubahan.
- `audit/apply_geometry.luau`: catatan perubahan geometri yang dapat ditinjau.
- `audit/playtest_harness.luau`, `audit/playtest_cases.luau`: alat QA khusus Play; jangan dimasukkan ke place produksi.
- `audit/results.json`, `audit/console-final.txt`: bukti hasil.
- `audit/Fly High.before-audit.rbxl`: backup pemulihan.

Referensi API pembayaran yang diperiksa: [MarketplaceService / ProcessReceipt](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService).

## Tindak lanjut: laut di sekitar pulau awal

Pengamatan pengguna dikonfirmasi: terrain bawaan sebelumnya menutupi balok kaca OceanWater. Perbaikan membatasi perubahan terrain di area rendah, mengganti hamparan luar pulau dengan air Terrain Roblox, serta membentuk pesisir berpasir dengan variasi tepian. Objek kaca lama disimpan dalam keadaan tersembunyi dan tidak berinteraksi dengan fisika; IslandGround tetap menjadi penopang tersembunyi untuk fasilitas lobby.

- Backup sebelum perubahan: `audit/Fly High.before-ocean.rbxl`.
- Skrip perubahan: `audit/apply_ocean.luau`; bukti: `audit/ocean-results.json`.
- Verifikasi visual Edit dan Play: pulau terlihat dikelilingi laut biru.
- Sampling pusat pulau: Grass Y=10; sampling pada (150,0), (300,0), (800,800), (1000,0), (1500,0): Water Y=0.
- Playtest antrean dan peluncuran balon berhasil; root balon Y=12,5 dan kru tetap hidup.
- Konsol playtest: tidak ada error/warning, hanya informasi mock data pada place lokal.
- Perubahan tersimpan di `Fly High.rbxl`; tidak ada perubahan skrip gameplay pada tindak lanjut laut ini.

## Tindak lanjut: vegetasi, dekorasi dan fauna pulau

Pulau mendapat pepohonan dan palem dengan siluet bercabang/berdaun, pakis mesh, bunga CSG berkelopak dan berdaun, batu berfaset, kerikil pesisir, batu pijakan, bukit kecil serta jalur tanah. Material LeafyGrass merapikan area fasilitas agar detail kecil tidak tertutup rumput tinggi.

- Isi scene akhir: **20 pohon, 60 rumpun tanaman, 56 bunga, 12 batu besar, 114 kerikil, 7 batu pijakan, 6 ayam dan 14 kupu-kupu**.
- Prefab: `ReplicatedStorage.FlyHigh.EnvironmentAssets`; penempatan: `Workspace.FlyHighLobby.IslandNature`.
- Ayam memilih tujuan aman, berjalan, berhenti dan mematuk; kaki dan kepala dianimasikan pada client. Kupu-kupu berkeliling tanaman sambil mengepakkan sayap. Daun mendapat goyangan halus.
- Area spawn, jalur ke antrean dan radius lepas landas dikecualikan dari dekorasi besar. Pohon memiliki collider batang sederhana; batu besar memiliki collision, sedangkan tanaman, kerikil dan fauna tidak menghambat gerak pemain.
- Dua skrip baru: IslandWildlifeController (server) dan IslandNatureAnimator (client). **Total terbaru 17 skrip; semuanya lolos kompilasi.**
- Server memperbarui root ayam pada 20 Hz; pose mesh, sayap dan dedaunan dirender client pada 30 Hz dengan pembatasan jarak.
- Snapshot scene: 1.097 BasePart, termasuk 584 MeshPart dan 112 UnionOperation. Dekorasi tidak mengandung skrip aset bawaan.
- QA: semua enam ayam berubah posisi pada sampel server; 14/14 kupu-kupu bergerak pada sampel client; gerak kaki teramati; tidak ada error/warning pada konsol playtest.
- Antrean berhasil mengenali Party Master. API produksi LaunchBalloon diuji pada scene baru dan berhasil memunculkan balon di Y=12,5 dengan pemain tetap hidup. Ini bukan klaim uji ulang multiplayer atau transaksi cloud.
- Backup: `audit/Fly High.before-island-life.rbxl`. Manifest aset: `audit/nature-assets.json`. Bukti pengujian: `audit/island-life-results.json`. Preview: `audit/island-life-preview.jpg`.

## Tindak lanjut: dermaga A–E dan lima armada

- Lima tema sesuai konsep yang disetujui: Penjelajah Fajar, Taman Mengapung, Koi Langit, Pengelana Saturnus dan Lentera Istana.
- Dek antrean berbentuk bundar dengan lapisan batu/kayu, pinggiran kuningan, panel status SurfaceGui tunggal, lampu dan miniatur balon. Teks antrean tidak lagi bertumpuk di udara.
- Kubah menggunakan mesh khusus, ditambah CSG kelopak teratai, cincin Saturnus dan bintang. Gondola memiliki anyaman, aksen botani/perahu/observatorium/paviliun sesuai tema.
- Animasi kosmetik client: miniatur berputar/mengambang, ekor/sirip koi, orbit bintang, rumbai lentera. Prompt katrol/tambal/rak disaring berdasarkan konteks kru dan posisi.
- BalloonThemes memetakan pod ke template pada server; PodManager dan BalloonManager memakai pemetaan ini. Total terbaru **19 skrip**, seluruhnya lolos kompilasi dan diekspor ulang.
- Regresi Play: **5/5 armada** berhasil diluncurkan melalui API produksi. Lantai setiap armada 28×28; semua bagian merupakan satu assembly tanpa bagian anchored, network ownership server, drift lepas landas di bawah 2 stud, lima titik kerusakan dan seluruh stasiun tersedia. Puncture ditolak pada 1.199 km dan diterima/diperbaiki pada 1.500 km. Cleanup menghapus flight aktif setelah setiap kasus.
- Interaksi native StartPrompt pada Pod_C berhasil memilih SkyKoi; panel menampilkan jumlah kru dan Master dengan benar. Client menemukan lima panel dan lima miniatur.
- Konsol sesi terakhir: **0 error, 0 warning**; satu pesan informasi mock data pada place unpublished. Pengujian ini tidak menggantikan multiplayer nyata, soak test atau transaksi cloud yang masih terbuka di atas.
- Ornamen tidak menambah collision. Lantai, collider utama dan mekanika identik antartema; bentuk visual koi/cincin bersifat dekoratif.
- File tersimpan: Fly High.rbxl (529.324 byte). Tidak ada model review/tekstur sementara atau harness QA di Edit DataModel akhir.
- Bukti: audit/fleet-results.json, audit/fleet-assets.json, audit/five-fleets-preview.jpg. Harness runtime: audit/fleet_playtest.luau. Backup sebelum perubahan: audit/Fly High.before-five-fleets.rbxl.
