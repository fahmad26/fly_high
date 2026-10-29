# Audit teknis Fly High — 28 Oktober 2026
Status: dua revisi utama selesai dan disimpan ke `Fly High.rbxl`. Gameplay inti lolos regresi lokal. **Belum dinyatakan siap rilis publik** karena pengujian monetisasi/cloud/multiplayer dan beberapa aset PRD masih belum lengkap.

## Lingkup dan bukti
- Membaca lengkap PRD_Fly_High.md dan HANDOVER.md; memeriksa 13 skrip awal, seluruh template balon/senjata/rintangan, lobby, koridor, dan istana pada Studio yang terhubung.
- Menambahkan ServerUtils (ModuleScript) dan PalaceManager (Script); total akhir **15 skrip**, seluruhnya dapat dikompilasi.
- Menjalankan beberapa sesi Play server/client, pemeriksaan RemoteEvent, interaksi UI/proximity prompt, dan fixture Luau di VM permainan.
- Place lokal yang diaudit: PlaceId=0, GameId=0. Tidak memublikasikan experience dan tidak melakukan transaksi Robux atau mengubah profil cloud.
- Backup sebelum perubahan: `audit/Fly High.before-audit.rbxl`.
- SHA256 backup: `C3D8D13DB1F95387B44D5B0E1C1E147853A09034AFC29E4D8D43E562D81BD21F`.
- SHA256 hasil terbaru setelah Dinding Badai dan loncatan kru: `70BBC2E0F5EA3E8DB37358EAC41F43BDBD4B8F31F4C3750E6DEA5A3C50E36211`.
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
- Kapasitas solo/duo/trio telah diuji melalui template dan tiga client native Studio (lihat QA multiplayer 29 Oktober). Lima tim simultan serta playtest manusia/server publik belum diuji.
- Belum dilakukan soak test panjang, profiling memori, simulasi latency/packet loss, perangkat mobile fisik, atau controller nyata.
- ProcessReceipt, DataStore live, kegagalan jaringan cloud dan retry lintas server belum dijalankan pada universe uji terpublikasi.
- Portal dan photobooth telah diperiksa dari kode; interaksi pemain pada keduanya belum masuk skenario regresi yang lulus.

## Kesenjangan PRD yang masih terbuka

| Bagian | Status akhir |
| --- | --- |
| Developer Products | **Dikonfigurasi 29 Oktober 2026:** EmergencyKit=3723339056 (29 Robux), AK47Upgrade=3723339246 (79 Robux). Harga dan status jual terverifikasi; transaksi pada universe tujuan masih perlu diuji. |
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

## Tindak lanjut: spawn, kontrol, tabrakan dan daratan

- Spawn putih diganti pelataran kayu/batu dengan inlay kompas kuningan, pakis dan papan sambutan yang diperkecil/dipindahkan ke samping.
- Kontrol relatif kamera memakai satu fungsi bersama untuk WASD/panah/touch/gamepad. Ditambah aksi lepas kemudi, lepas tali, serta gas otomatis yang tidak bergantung pada pilot tetap duduk. Senjata tetap dapat dikembalikan ke rak.
- Clearance antarpusat balon 60 stud horizontal/64 vertikal diterapkan server. Collision group antarbalon diaktifkan; kontak memberi satu lubang pada kedua balon dan tidak berulang selama kontak yang sama. Okupansi lintas dermaga diperiksa pada API LaunchBalloon dan ditampilkan pada panel.
- Balon sendiri dapat ditembak; balon tim lain dikecualikan dari raycast damage. Asal tembakan palsu tetap diabaikan. Damage Collision/SelfShot berlaku mulai 0 km; rintangan tetap tidak ada di bawah 1.200 km. Shield dan grace period lama tetap berlaku.
- Lima lubang kini turun 666,67 km/detik, dengan pemindahan kru yang masih di gondola/bertali mengikuti dek. Clutch Save menghentikan jatuh dan memulihkan lubang sebelum tanah.
- Penghitung daratan 60 detik berada pada server, disinkronkan ke HUD dan memicu EndFlight, kematian kru serta cleanup. Saat menguji, umur penghitung dipercepat menjadi 59,8 detik; bukan menunggu satu menit nyata.
- Race lifecycle tambahan diperbaiki: U.Flight tidak lagi mengembalikan flight yang modelnya sudah tidak memiliki Parent ketika callback Destroying masih tertunda.
- Backlog tantangan rintangan besar dan loncatan kru ditambahkan ke PRD; **tidak diimplementasikan pada runtime**.

Bukti QA disimpan di audit/flight-controls-results.json. Uji server/client lokal mencakup arah kamera pada 0/90/180/270 derajat, gas otomatis + keluar kursi, pasang/lepas tali, ambil/kembalikan pistol, tembakan sendiri (1 lubang dan amunisi 8→7), tembakan ke fixture balon tim lain (0 lubang), Clutch Save, jatuh 2.000 km sekitar 3,02 detik dan kematian saat tanah, expiry daratan, serta fixture tabrakan/okupansi lintas dermaga. Fixture tabrakan memakai dua model dan state server; ini **bukan multiplayer dengan dua pemain nyata**. Input sentuh/gamepad fisik, latency dan soak test masih belum diuji. Produk dan cloud live tetap terbuka sebagaimana laporan awal.

- Regresi akhir: **5/5 armada** kembali lulus; **21/21 skrip** lolos kompilasi dan snapshot Source cocok. Uji input keyboard native dengan kamera menghadap +Z (180° dari arah awal) + Up menghasilkan perpindahan +32,50 stud pada Z; Z lalu H menghasilkan gas otomatis aktif dan pilot sudah tidak duduk. Konsol hanya berisi informasi mock data serta reset kamera QA, tanpa error/warning.

- Deteksi daratan juga memakai raycast di bawah gondola pada 5 Hz, sehingga balon yang berhenti di atas bukit/batu tidak lolos dari penghitung. Fixture permukaan tinggi terdeteksi; setelah diangkat 15 stud, status berubah menjadi mengudara. Raycast daratan mengecualikan air, balon lain dan karakter.

## Konfigurasi Developer Products — 29 Oktober 2026

- EmergencyKit: **3723339056**, Emergency Repair & Shield, harga dasar terverifikasi **29 Robux**.
- AK47Upgrade: **3723339246**, AK-47 Tactical Upgrade, harga dasar terverifikasi **79 Robux**.
- Kedua produk dilaporkan IsForSale=true oleh MarketplaceService:GetProductInfoAsync. Hubungan produk dengan universe tujuan belum dapat diverifikasi dari file lokal (PlaceId=0, GameId=0).
- FlyHighConfig.PRODUCT_IDS terisi; UI toko mengambil harga melalui GetProductInfoAsync pada client dan memperbarui label saat toko dibuka (cache 60 detik). Harga perkiraan ~30/~75 dihapus. Pembatalan prompt mengembalikan tombol; client tidak memberikan item.
- GrantReceipt kini mengembalikan status sukses dan penanda receipt baru. Receipt duplikat tetap PurchaseGranted setelah ledger terverifikasi, tetapi tidak memicu pemasangan AK-47 lagi atau mengonsumsi kredit berikutnya.
- Marketplace.ProcessReceipt memakai handler server FlyHighShopManager.ProcessReceipt yang sama dengan jalur QA. Unknown product, pemain hilang dan penyimpanan gagal tetap NotProcessedYet.
- QA lokal: **14/14 pemeriksaan receipt lulus** memakai adapter penyimpanan mock dan handler receipt produksi. Meliputi grant satu kit/kredit, idempotensi, gagal simpan tanpa grant, retry, mapping kedua ID, receipt duplikat AK dan kasus pending.
- UI Play menampilkan 29 dan 79 Robux dari API; request toko pada unpublished place menghasilkan instruksi publikasi dan tombol kembali normal. **21 skrip lolos kompilasi; konsol 0 error/0 warning.**
- Tidak ada pembelian Robux, pengujian DataStore cloud, publikasi experience atau perubahan produk di Creator Dashboard pada sesi ini. Adapter/mock/harness hanya di Play, tidak dimasukkan ke place akhir.
- Langkah berikutnya: unggah/publikasikan versi place ini ke experience yang memiliki kedua Developer Products, kemudian lakukan uji end-to-end pembelian/pembatalan dan persistensi pada universe uji sebelum rilis.
- Backup: audit/Fly High.before-products.rbxl. Bukti: audit/product-results.json. Harness: audit/product_receipt_playtest.luau dan audit/product_data_qa_adapter.luau.

## QA multiplayer native — 29 Oktober 2026

Sesi menggunakan StudioTestService:ExecuteMultiplayerTestAsync(3, ...) dengan tiga client Studio dan Player1/Player2/Player3 (UserId -1/-2/-3), bukan dua model fixture. Client mengirim event gameplay melalui koneksi masing-masing. Start/pickup menggunakan VirtualInput untuk tombol proximity prompt; avatar memakai automatic network ownership. Posisi awal skenario diatur server.

- **Hasil akhir: 50/50 pemeriksaan lulus**; durasi suite 64,59 detik setelah mulai sesi; log runtime server serta tiga client tidak memiliki error/warning.
- Antrean tiga kru, pemindahan Master ketika pemimpin keluar pad, urutan bergabung kembali, dan peluncuran trio lewat prompt berhasil.
- Pilot dapat melepas kursi sementara gas otomatis tetap naik; client lain mengambil pistol dan memasang tali. Semua client melihat Tool dan SafetyRope kru lain.
- Tembakan sendiri menghabiskan 1 peluru dan membuat 1 lubang. Konfigurasi trio: 2 tali, hold repair 3 detik; climb, repair, descend, detach dan pengembalian senjata lulus. Fixture engineer di-anchor saat hold untuk mengisolasi timing dari gerak berjalan.
- Clutch Save melalui remote client memulihkan balon dan menyelamatkan ketiga kru. Kit disediakan dalam inventori mock Studio; tidak ada pembelian. Timeout daratan membunuh ketiga kru dan membersihkan flight; clock dipercepat menjadi 59,7 detik, bukan menunggu satu menit penuh.
- Tim A berisi dua pemain dan tim B satu pemain. Balon dari A yang diparkir di E memblokir summon E; A kembali tersedia setelah balon menjauh. Team B bisa meluncur setelah clearance.
- Dua pilot client mengarahkan balon saling mendekat selama 8 detik: kedua tim mendapat **tepat 1 lubang**, tidak terus rusak selama kontak yang sama, jarak minimum root **60,00023 stud**, ownership fisika tetap server.
- Prompt tim lain tersembunyi. Percobaan pickup paksa pada rak tim lain tetap ditolak server; tether lintas tim ditolak; tembakan tidak merusak balon lawan.
- Client ketiga keluar melalui StudioTestService:LeaveTest; PlayerRemoving, cleanup tali/perlengkapan dan penghancuran flight solo terkonfirmasi. Dua kru di tim tersisa tetap hidup dan flight berlanjut.

**Bug produksi yang diperbaiki:** WeaponClientController mengakses b.TetherStation pada RenderStepped saat referensi balon sudah direplikasi tetapi child tersebut belum tiba pada client. Run awal menangkap error ini di Player1. Guard FindFirstChild ditambahkan untuk TetherStation, HoleSlots dan PatchPrompt agar HUD aman terhadap replikasi parsial dan cleanup. Pengujian akhir tidak menangkap error tersebut lagi.

Run antara disimpan untuk transparansi: run1 juga berhenti ketika fixture memposisikan avatar di luar sisi kanan basket (rack X=12 ditambah offset +3 menghasilkan X=15 di luar setengah lantai 14). Fixture dipindahkan ke sisi dalam. Run2/run3 menemukan driver InputHoldBegin kurang andal untuk client simulasi; driver beralih ke VirtualInput:SendKey dan menempatkan avatar antrean terpisah serta kamera menghadap console. Ini perubahan harness, bukan perubahan aturan gameplay.

Batasan: tiga client simulasi pada satu komputer; tidak ada tiga manusia/perangkat nyata, server publik, simulasi packet loss/latency, pengujian cloud atau transaksi Robux. Tantangan besar dan mekanika loncat tetap backlog dokumentasi.

Artefak: audit/multiplayer-results.json (hasil akhir), audit/multiplayer-run1.json sampai run3.json (diagnostik), audit/multiplayer_server_playtest.luau dan multiplayer_client_playtest.luau. Backup: audit/Fly High.before-multiplayer.rbxl. Seluruh Script/LocalScript/Remote QA sudah dihapus dari place. **21 skrip produksi lolos kompilasi**; smoke Play setelah cleanup juga tanpa error/warning.

Referensi API: [StudioTestService](https://create.roblox.com/docs/reference/engine/classes/StudioTestService) dan [VirtualInput](https://create.roblox.com/docs/reference/engine/classes/VirtualInput).

## Implementasi Dinding Badai dan Loncatan Kru — 29 Oktober 2026

Backlog loncatan dan rintangan besar kini menjadi fitur runtime, dengan tiga skrip baru: JumpManager, LargeChallengeManager dan FlightJumpController. **Jumlah produksi: 24 skrip.**

- Dinding Badai muncul pada milestone 1.800/3.600/5.400/7.200/9.000 km. Volume 360×120×32 stud menyapu seluruh koridor dari Z=-260 ke Z=260 pada 60 stud/detik setelah warning 6 detik. Objek global dibagi oleh seluruh tim di area; satu wave per milestone, maksimal dua aktif.
- Wujud berupa bank awan/wisp CSG dengan 30 segmen kilat di dua sisi serta penunjuk dunia. Percobaan generasi mesh tidak tersedia pada sesi ini; model native dibuat dengan build_storm_curtain.luau sehingga place tidak bergantung pada aset hasil generasi tersebut.
- Awan tidak bisa ditembak, tidak menjadi platform fisik, dan menggunakan swept volume server untuk mendeteksi balon. Maksimal satu puncture per wave per flight; shield/grace tetap dihormati. Flight yang baru masuk menerima warning personal. Peserta menunda spawn obstacle reguler selama tantangan; milestone yang ditandai tidak dipicu ulang saat turun lalu naik.
- Pilot yang masih duduk, engineer di katrol/kubah dan pemain yang sedang repair tidak bisa melompat. Gunner, kru bebas dan pemain bertali di gondola tetap bisa. Power/height/state asli disimpan dan dipulihkan, baik pada pergantian peran, akhir flight maupun respawn.
- Client Request tidak memuat jumlah drop yang dipercaya. Server memeriksa kru hidup, posisi gondola, pijakan, perpindahan/kecepatan takeoff, Jumping event, cooldown 1,05 detik serta landing sebelum menghitung ulang. Koneksi Humanoid dibersihkan pada perubahan karakter/flight dan PlayerRemoving.
- Satu loncatan memberi jatah 18/eligibleCrew stud, dikonsumsi halus maksimal 22 stud/detik dengan antrean maksimum 36. Jika semua kru yang eligible melompat sekali, totalnya 18 stud untuk solo/duo/trio. Gas dan efek lubang tetap memengaruhi perpindahan aktual.
- Lima lubang mempertahankan kecepatan freefall lama; efek lompat tambahan diabaikan. Clutch Save dan EndFlight mengosongkan sisa jatah turun.
- HUD baru menampilkan tombol Space/A/touch, alasan blokir, cooldown, countdown dan jarak ke posisi aman. Peringatan menggantikan panel status biasa sementara, menampilkan jumlah lubang dan tidak menutupi Emergency Kit; panel status dipulihkan setelah tantangan. Responsiveness dan prioritas panel diperiksa secara visual.

### Bukti pengujian fitur baru

**51/51 pemeriksaan native tiga client lulus**, log server dan ketiga client pada iterasi akhir kosong dari error/warning. Client memakai VirtualInput Space dan automatic avatar network ownership.

- Satu putaran loncatan: solo 1 jump, duo 2, trio 3; masing-masing total jatah **18 stud**. Penurunan terukur sekitar 21,4–21,8 stud karena ditambah descent pasif selama jendela sampel.
- 100 request tanpa loncatan tidak menambah efek; pemain di luar flight ditolak. Pilot tidak keluar kursi ketika Space ditekan; kembali dari helm/katrol memulihkan izin lompat.
- Gunner dan pemain bertali dapat melompat. Engineer di kubah tidak memberikan impulse.
- Safe zone menolak spawn, satu model dibagi dua tim, warning tidak merusak. Kedua tim di sisi koridor yang tetap tinggi mendapat masing-masing satu lubang.
- Solo/duo/trio melakukan empat putaran lompat dengan gas off; turun sekitar 83 stud dan melewati sapuan penuh tanpa lubang.
- Scheduler milestone, penandaan anti-retrigger, cleanup wave dan pemulihan lompat di lobby lulus.

Regresi multiplayer sebelumnya dijalankan lagi: **50/50 lulus**, termasuk Master handoff, pembagian peran, repair, Clutch Save, timeout daratan, okupansi lintas dermaga, collision, proteksi lintas tim dan disconnect cleanup. Total sesi final: **101 pemeriksaan lulus**.

Iterasi antara disimpan: run1 membaca visibility banner sebelum heartbeat UI berikutnya; fixture diberi jeda replikasi. Run2 tidak menghasilkan hop saat key hold 0,08 detik pada client simulasi; driver memakai hold 0,25 detik dan server memperkuat observasi takeoff lewat Jumping event/kecepatan fisik. Run3 meluluskan seluruh skenario gameplay tetapi satu client menangkap error bawaan CoreGui CreatorType. Pengulangan final dan regresi berikutnya bersih; sumber error tersebut bukan skrip Fly High.

Batasan: posisi awal diatur server; tiga client adalah simulasi Studio pada satu komputer. Uji avoidance memakai gas off, empat putaran lompat; belum merupakan human playtest atau tuning kesulitan akhir. Perangkat sentuh/gamepad fisik, latency/packet loss, pembelian Robux dan persistensi cloud tetap belum diuji. Tidak memublikasikan experience.

Artefak: audit/storm-jump-results.json, audit/storm-jump-regression.json, audit/storm-jump-run1.json sampai run3.json, audit/storm_jump_server_playtest.luau, audit/storm_jump_client_playtest.luau, audit/build_storm_curtain.luau dan audit/storm-jump-preview.jpg. Backup: audit/Fly High.before-storm-jumps.rbxl. Harness hanya digunakan untuk QA dan dihapus dari DataModel akhir.

## QA Perangkat dan Kenyamanan HUD — 29 Oktober 2026

Dua masalah konkret ditemukan saat interaksi simulator: tata letak layar kecil keluar batas dan tombol LOMPAT HUD menerima klik tanpa menghasilkan lompatan. Keduanya diperbaiki di place dan snapshot source.

### Perbaikan

- Skala lama mengecilkan ukuran tanpa memperbaiki offset. Pada GUI Galaxy A06 705×279, ShopModal berada Y=-40,5; JumpPanel pada Y=265 dengan tinggi 72 melewati layar. HUDLayout kini menjadi satu pemilik layout, memetakan posisi/dimensi secara konsisten dan memakai ukuran area aman ScreenGui.
- Mode ringkas menempatkan informasi utama di atas dan LOMPAT/AKSI di bawah tengah. Kontrol peran tambahan berada dalam tray yang dapat digulir; GAS/TEMBAK tetap tampil sesuai peran. Mode desktop/tablet mempertahankan penataan sebelumnya dengan offset yang ikut diskalakan.
- Tombol sentuh minimal 44 piksel, termasuk tombol toko/ping tablet. ShopModal menjadi ScrollingFrame sehingga seluruh produk tetap dapat dijangkau; close memakai huruf X yang terbaca dan hitbox 44×44.
- FlightJumpController tidak lagi menimpa skala HUD sendiri. Pada mode sentuh, setelan Humanoid.Jump sesaat ditimpa controller bawaan; tombol kini memasuki state Jumping biasa setelah pemeriksaan local role/health/grounded. Tidak ada tambahan velocity buatan atau efek drop yang dipercaya dari client. Pembatasan server tidak diubah.

### Verifikasi

| Profil simulator | Area GUI yang diukur | Panel keluar batas | Tombol root <44 px |
| --- | --- | --- | --- |
| Samsung Galaxy A06 | 705×279 | 0 | 0 |
| iPhone 17 Pro | 748×323 | 0 | 0 |
| iPad Pro M5 13in | 1373×971 | 0 | 0 |

StarterGui.ScreenOrientation tetap LandscapeSensor, sehingga portrait tidak termasuk orientasi yang didukung. FlyHighHUD menggunakan CoreUISafeInsets; [referensi Roblox](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets) menyatakan mode ini mencakup area aman perangkat serta UI inti.

Klik nyata melalui input simulator memverifikasi tombol LOMPAT (JumpCount server bertambah dari 0 menjadi 1), AKSI buka/tutup, gas otomatis tetap aktif setelah lepas kemudi, serta menu toko yang dapat digulir (CanvasPosition.Y=127). Tombol beli tetap tinggi 44 dan close 44×44; tidak menjalankan transaksi.

Regresi produksi dijalankan ulang memakai tiga client native: **50/50 multiplayer** dan **51/51 badai/lompat**, total **101/101**, dengan **0 error/0 warning** pada server dan semua client di sesi final. Jatah solo/duo/trio tetap 18 stud per putaran bersama; avoidance menghasilkan penurunan sekitar 83 stud dan 0 lubang. Semua **25 skrip produksi** dapat dikompilasi.

Run antara pertama memerlukan pembaruan lookup harness AutoGasButton menjadi rekursif agar mendukung reparent ke tray. Dua run selanjutnya lulus seluruh 50 skenario gameplay, tetapi masing-masing menangkap CoreGui CreatorType (15 log client) dan warning unduh asset HTTP 502 (1 log). Keduanya disimpan tanpa menyembunyikan log. Pengulangan akhir bersih; tidak ada perubahan CoreGui atau publikasi untuk mengatasi kondisi lingkungan ini.

Artefak final: audit/device-qa-results.json, audit/device-multiplayer-results.json, audit/device-storm-results.json, audit/device-phone-preview.jpg. Diagnostik: audit/device-multiplayer-coregui-run.json dan audit/device-multiplayer-cdn-run.json. Driver reproducible: audit/device_review_server.luau dan audit/device_layout_probe.luau; semuanya berada di luar place produksi. Backup: audit/Fly High.before-device-qa.rbxl.

Batas pengujian: simulator pada satu komputer, klik mouse dalam mode sentuh, posisi flight disiapkan server. Belum mengukur kenyamanan pemain manusia, touchscreen/gamepad fisik, latency/packet loss internet atau sesi natural panjang. Pembelian Robux, penyimpanan cloud dan publikasi tetap ditunda sesuai permintaan pengguna. Studio berakhir Edit dengan viewport default; seluruh driver/remote QA sementara telah dihapus.

Build tersimpan: Fly High.rbxl **831.155 byte**, SHA256 **08BD6AAB900F416323099504292405523FE6A8202EC45FF7B68D687CFE8E7AA2**.

## Koreksi Akses Gas Otomatis

Pengguna meminta GAS OTOMATIS tersedia tanpa membuka AKSI. AutoGasButton kini tetap menjadi child FlyHighHUD; mode ringkas menempatkannya di bawah tengah (140×48), di antara LOMPAT dan AKSI dengan jarak 8 piksel. Pengujian klik nyata pada simulator Galaxy A06 memastikan satu tap menyalakan, tombol tetap terlihat dan gas aktif setelah kemudi dilepas, lalu satu tap langsung mematikan. Tombol tidak berada di tray; konsol bersih. Ini pemeriksaan terarah atas perubahan layout; suite 101 skenario tidak dijalankan ulang untuk koreksi posisi ini. Bukti: audit/direct-autogas-results.json.

## Alur Tali dan LEPAS KEMUDI — 29 Oktober 2026

LEPAS KEMUDI dipindah dari AKSI ke HUD utama (140×48 piksel pada mode ringkas), bersama GAS OTOMATIS. Panel lompat disembunyikan saat pemain duduk sebagai pilot dan muncul kembali setelah melepas kemudi.

### Temuan dan perbaikan

- RopeConstraint lama menggabungkan avatar dan balon dalam satu mekanisme fisika. Repro dua client menunjukkan avatar berpindah ke ownership server dan posisi relatifnya bergeser dari X≈2 menjadi X≈−12 saat balon bergerak. [Dokumentasi network ownership Roblox](https://create.roblox.com/docs/physics/network-ownership) menjelaskan bahwa ownership berlaku bagi seluruh assembly dalam mekanisme. Visual kini memakai Beam agar avatar tetap client-owned dan balon tetap server-owned; tidak menyatukan karakter dengan assembly balon.
- Katrol menghitung transform dari CFrame balon terkini setiap frame. Setelah perjalanan selesai, anchor/AutoRotate/ownership karakter dipulihkan. Pembersihan ownership memeriksa IsDescendantOf(workspace), termasuk saat pemain disconnect, sehingga tidak memanggil API pada karakter yang sudah dilepas dari Workspace.
- Durabilitas dipindah ke slot tali persisten selama flight (satu solo/duo, dua trio). Memasang ulang tidak menambah HP. Tali yang dilepas tetap aus; hanya interaksi PERBAIKI TALI di stasiun saat pemain tidak memakai tali yang dapat memulihkannya. Hold empat detik memakai konfigurasi 100/25 yang sudah ada.
- Server mencadangkan slot saat diperbaiki; pemain lain tidak bisa mengambilnya. Worn-slot, noncrew, jarak jauh, karakter berganti/mati, finish tanpa begin, finish terlalu cepat serta pemain menjauh ditolak/dibatalkan. Cancel tidak diblokir cooldown request awal, sehingga hold singkat tidak meninggalkan reservasi.
- Turun ke gondola otomatis melepas tali setelah katrol tiba. Pemain juga dapat melepas tali tanpa naik. Stage Basket/Climbing/Catwalk/Descending membatasi tambal pada titian dan menyembunyikan interaksi yang belum valid.
- Prompt tambal memerlukan jarak server 10 stud tetapi tidak memerlukan line of sight kamera, karena kubah/ornamen sendiri menutupi ray prompt. Pengujian interaksi asli menemukan masalah ini; perbaikannya diterapkan ke template dasar dan lima varian. Prompt turun menjangkau ring 28 stud. Shortcut: E pasang/tambal, F naik, Q turun+lepas, T/L2 lepas, C/R3 tahan perbaiki tali.
- Hold HUD mengikat pembatalan ke input yang memulainya, sehingga sentuhan jari lain tidak membatalkan tambal/perbaikan. Hold singkat membatalkan reservasi; hold penuh memulihkan satu slot ke 100.

### Hasil pengujian

**137/137 pemeriksaan gameplay lulus:** 36 pemeriksaan alur tali, 50 regresi multiplayer dan 51 badai/lompat. Ketiga suite memakai tiga client native; server dan seluruh client pada hasil akhir bersih dari error/warning.

Pengujian alur tali menggunakan prompt asli dan berjalan dengan Humanoid di sepanjang ring. Solo menambal empat lubang satu per satu saat balon bergerak, lalu turun dan otomatis lepas; tidak memindahkan karakter/menahan anchor untuk bagian berjalan dan menambal ini. Tali tersisa sekitar 11,34 HP. Pemeriksaan gerak enam detik mencatat kenaikan balon 25,48 stud dan drift relatif maksimum sekitar 0,00003 stud, dengan avatar tetap client-owned. Pembatasan 5 lubang, durasi tambal tim dan decay 5 HP/detik tetap berlaku.

Smoke Galaxy A06 (simulator) memverifikasi LEPAS KEMUDI satu klik tanpa AKSI, gas otomatis tetap berjalan, panel lompat kembali setelah unseat, dan tombol PERBAIKI TALI HUD: hold 4,4 detik mengubah HP 50→100; hold 0,1 detik mempertahankan HP 50 dan membebaskan reservasi. Semua 25 skrip produksi terkompilasi dan lima snapshot source yang diubah cocok dengan Studio.

Run diagnostik disimpan: prompt tambal tertutup line of sight; error cleanup ownership pada karakter yang keluar Workspace; satu warning asset CDN HTTP 502. Dua masalah kode diperbaiki, dan pengulangan multiplayer akhir bersih.

Artefak: audit/rigging-flow-results.json, rigging-native-results.json, rigging-multiplayer-results.json, rigging-storm-results.json; repro sebelum/isolasi Beam di tether-motion-before.json dan tether-motion-beam-isolation.json; diagnostik rigging-hole-los-run.json, rigging-cleanup-run.json, rigging-cdn-run.json. Driver ada di audit/rigging_flow_server_playtest.luau, rigging_flow_client_playtest.luau dan tether_motion_repro.luau. Backup: audit/Fly High.before-rigging-flow.rbxl.

Seluruh driver/remote QA sementara dihapus dari place; Studio kembali Edit dan viewport default. Pengujian perangkat fisik, manusia, jaringan internet, Robux/cloud tetap belum dilakukan; tidak memublikasikan experience.

Build tersimpan: 833464 byte; SHA256 **7F90136DF83732E2FEC33BAB36FF2312A0574BB67287B707016F2BC28587EF5B**.

## Audio Peringatan dan Handoff Katrol — 29 Oktober 2026

Audio kini tersedia untuk tali menipis/kritis, Dinding Badai, empat/lima lubang dan warning hazard reguler. Implementasi lokal tidak memengaruhi validasi gameplay atau memberikan item berbayar.

### Implementasi

- WarningAudioController memakai dua aset gratis Creator Store: [Warning Tone Beep — BunnyNabbit](https://create.roblox.com/store/asset/17761221095) (0,2666 detik) dan [siren alarm — baba_kakat](https://create.roblox.com/store/asset/129496339606661) (1,0449 detik). Keduanya dimuat dan diputar di Studio dengan kemajuan TimePosition serta PlaybackLoudness positif. Manifest: audit/warning-audio-assets.json. Fallback volume_slider.ogg berasal dari konten bawaan Roblox.
- Audio hanya untuk kru penerima event. Urutan prioritas 5 lubang > tali ≤15% > badai > 4 lubang > hazard reguler > tali ≤30%. Satu voice, jadwal beep/sirine dibatasi cadence; paket duplikat tidak mereset siklus setiap frame.
- Tali berhenti mengingatkan saat Descending, di basket atau dilepas. Badai berhenti untuk tim yang sudah di bawah batas aman, atau setelah event Ended/expiry. Perbaikan/Clutch Save, death, ghost, game over, victory dan pergantian flight membersihkan status yang selesai. Controller memiliki pool tetap berisi tiga Sound (termasuk fallback) dan satu SoundGroup.
- Opsi SUARA PERINGATAN di AKSI hanya mematikan kanal tersebut; preferensi tetap selama sesi/respawn. Primary controls LEPAS KEMUDI/GAS OTOMATIS tidak dipindah. Label tali mendapat peringatan visual amber/merah dan instruksi turun.
- Pool diparent ke controller agar otomatis terhapus saat script dihapus. Tombol memiliki ObjectValue ControllerOwner; HUDLayout membersihkan tombol orphan dan referensi original GUI yang telah dihancurkan. Ini mengatasi cleanup saat pengembangan tanpa membuat janitor atau pool baru setiap flight.
- Aset Sound tidak perlu berada di SoundService untuk pemutaran global: [referensi Sound Roblox](https://create.roblox.com/docs/reference/engine/classes/Sound) menjelaskan suara yang bukan child BasePart/Attachment bersifat global. Penempatan di controller telah diverifikasi menghasilkan sinyal pemutaran.
- Volume/ambang/cadence berada di FlyHighConfig.AUDIO_WARNINGS. Panduan konfigurasi Roblox ditinjau; konfigurasi cloud dan eksperimen tidak ditambahkan karena sesi tetap file lokal dan publikasi masih ditunda.

### Masalah katrol yang ditemukan saat sampling audio

Avatar yang diam setelah katrol dapat terdorong dari ring: bagian tubuh masih bertabrakan ketika pose dipindahkan melewati kubah dan kendali fisika dikembalikan sebelum pose akhir stabil. Diagnostik mencatat kecepatan menyamping sekitar 85 stud/detik meskipun MoveDirection nol. Menambah clearance saja tidak menyelesaikannya.

Perbaikan memakai collision group sementara FlyHighWinching selama perjalanan; seluruh collision group karakter semula disimpan/dipulihkan. Gerak 1,3 detik diikuti hold pose akhir 0,3 detik sebelum unanchor/ownership, sehingga total durasi tetap 1,6 detik. Kecepatan sudut dibersihkan dan tidak lagi memberi MoveTo menuju koordinat dunia yang sudah tertinggal. Cancel mengembalikan pemain ke titik aman asal sebelum memulihkan tabrakan. Tinggi pijakan memakai HipHeight dan ukuran root; untuk R6 ditambah tinggi kaki sesuai [rumus resmi Humanoid.HipHeight](https://create.roblox.com/docs/reference/engine/classes/Humanoid).

Dua engineer memakai titik landing yang berbeda (depan/belakang ring; X=-4/+4 saat turun). Native QA mengonfirmasi dua engineer dapat naik dan turun bersamaan, grup collision pulih, tali otomatis dilepas, dan cancel tidak meninggalkan anchor/grup sementara. Sampel idle akhir tetap pada ring (Y relatif sekitar 20,56, Z sekitar -20,12) dengan FloorMaterial WoodPlanks, bukan terlempar.

### Verifikasi dan batasnya

**139/139 lulus:** 49 audio, 40 alur tali dan 50 multiplayer. Tiga client native, log final server dan semua client kosong dari error/warning. Semua **26 skrip produksi** terkompilasi dan lima source yang berubah cocok antara disk/Studio.

Uji audio meliputi muatan/sinyal kedua aset, silent lobby/healthy flight, isolasi antar-tim, 20 event duplikat, prioritas tali kritis, suppression ketika turun, sirine 4/5 lubang, Clutch Save, mute/unmute tanpa mematikan audio rekan, badai global/posisi aman/Ended, ghost/death, relaunch tanpa stale alert atau pertambahan pool, dan penghapusan controller. Pengamatan suara aktif maksimum satu. Smoke Galaxy A06 memakai klik tombol aktual: mute mengatur volume 0 dan label OFF, unmute kembali 0,4; hitbox 224×44 dan dua primary control tetap di FlyHighHUD.

Run1–8 dipertahankan untuk diagnostik: awalnya fixture kehilangan pijakan ketika sampling tali, pembersihan script sendiri belum menghapus objek eksternal, satu client mengalami CoreGui CreatorType, dan fixture PlayerModule lama tidak tersedia pada native client. Fixture diperbaiki tanpa menghapus log; pengujian akhir memakai avatar berfisika normal di ring dan input netral selama idle, bukan mengunci posisi karakter. Status HP/posisi awal tetap diatur server untuk mencapai kasus uji. R15 diuji secara fisik; dukungan tinggi R6 mengikuti rumus API dan belum merupakan human playtest R6.

Bukti: audit/warning-audio-results.json, warning-audio-native-results.json, warning-audio-rigging-results.json, warning-audio-multiplayer-results.json; diagnostik warning-audio-run1.json sampai run8.json. Driver: audit/warning_audio_client_playtest.luau dan warning_audio_server_playtest.luau; rigging driver diperluas untuk dua engineer. Semua driver/remote QA telah dihapus dari DataModel produksi. Backup: audit/Fly High.before-warning-audio.rbxl.

Human listening review, kenyamanan volume di HP/controller fisik, latency internet, pembelian Robux dan cloud tetap belum diuji. Tidak menerbitkan experience.

Build tersimpan **837808 byte**; SHA256 **34C9563D4747D3DB7EF0F2A90185871EB7E3CC37A4336C7B6BC3F64E63A55C3A**.

## Perbaikan overlap interaksi tali — 29 Oktober 2026

Prompt bawaan Pasang/Lepas dan Naik/Perbaiki memakai UIOffset dua baris terpisah 96 piksel pada keenam template dan setup runtime. Prompt baru dimask sebelum pass visibilitas pertama. HUD desktop/tablet mengalokasikan baris berdasarkan aksi tali yang terlihat, sehingga Pasang/Perbaiki dan Tambal/Turun/Lepas tidak memakai koordinat sama.

Simulator iPad Pro M5 mengukur Pasang/Perbaiki masing-masing 150×44 dengan gap 8 piksel; Galaxy A06 mengukur Lepas/Naik 224×44 pada baris AKSI terpisah. Native BillboardGui ditinjau lewat jendela Studio karena capture viewport MCP menghilangkannya. Game tetap LandscapeSensor; gas otomatis dan lepas kemudi tetap di HUD utama. **40/40 regresi tali tiga client lulus**, log server/client bersih; seluruh 26 skrip terkompilasi. Bukti: audit/prompt-layout-results.json. Driver/remote QA dihapus dan simulator dikembalikan default. Perangkat fisik belum diuji.
