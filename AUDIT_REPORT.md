# Audit teknis Fly High — 28 Oktober 2026
Status: dua revisi utama selesai dan disimpan ke `Fly High.rbxl`. Gameplay inti lolos regresi lokal. **Belum dinyatakan siap rilis publik** karena pengujian monetisasi/cloud/multiplayer dan beberapa aset PRD masih belum lengkap.

## Lingkup dan bukti
- Membaca lengkap PRD_Fly_High.md dan HANDOVER.md; memeriksa 13 skrip awal, seluruh template balon/senjata/rintangan, lobby, koridor, dan istana pada Studio yang terhubung.
- Menambahkan ServerUtils (ModuleScript) dan PalaceManager (Script); total akhir **15 skrip**, seluruhnya dapat dikompilasi.
- Menjalankan beberapa sesi Play server/client, pemeriksaan RemoteEvent, interaksi UI/proximity prompt, dan fixture Luau di VM permainan.
- Place lokal yang diaudit: PlaceId=0, GameId=0. Tidak memublikasikan experience dan tidak melakukan transaksi Robux atau mengubah profil cloud.
- Backup sebelum perubahan: `audit/Fly High.before-audit.rbxl`.
- SHA256 backup: `C3D8D13DB1F95387B44D5B0E1C1E147853A09034AFC29E4D8D43E562D81BD21F`.
- SHA256 hasil terbaru setelah perbaikan HUD multiplayer: `CE66A8E25E3C33ED8839E051472AAF964E91296659785899D0B6D5C36DA326CE`.
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
