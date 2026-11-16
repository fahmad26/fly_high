# Rencana revisi seni lingkungan dan aset Fly High

Tanggal: 15 November 2026, Asia/Jakarta. **Status: proposal setelah audit; belum diimplementasikan.** **Pembaruan 15 Nov 21:47 WIB:** Batch 1 masuk tahap graybox/preview (menunggu persetujuan) — [bukti](../../../audit/storm-batch1-2026-11-15/README.md). Pengguna meminta audit, instalasi skill yang aman dan rencana terperinci, serta melarang perubahan aset pada tahap ini.

Untuk AI penerima, baca [HANDOVER fitur](HANDOVER.md) dahulu: lokasi file lokal yang sudah tersimpan, status Studio, acuan source, skill dan urutan kerja. Status simpan lokal tidak berarti rencana ini sudah dikerjakan.

## 1. Kesimpulan audit

Masalah utama adalah komposisi dari kamera permainan, kualitas bentuk besar, dan perbedaan mutu antar-keluarga aset. Menyamakan MeshId berhasil membuat keluarga aset konsisten, tetapi belum membuat pemandangan bagus. Bentuk yang cukup terbaca pada galeri close-up dapat menjadi kecil, datar, terlalu dominan, atau menutup objek lain ketika dilihat dari balon.

Tiga jenis pekerjaan perlu dibedakan:

1. **Bangun ulang bentuk besar yang gagal:** tornado scenery, beberapa massa awan, sambungan tebing/pulau, aliran air terjun, serta struktur batu kristal berorbit.
2. **Poles aset yang sudah dikenali:** fauna, reruntuhan, drone, satelit, kapal, paviliun, gerbang, istana dan flora. Pertahankan bagian yang sudah berhasil.
3. **Perbaiki penataan dan varian jarak:** skala dalam layar, pengelompokan, lapisan kedalaman, posisi pada permukaan, perbedaan scenery/ancaman dan LOD. Banyak kasus tidak membutuhkan aset baru.

Tidak mengusulkan perubahan tema PRD, band rintangan, HP, spawn, damage, kapasitas senjata, reward, atau aturan puncak. HUD yang sudah disetujui juga tidak termasuk pekerjaan ini.

## 2. Dasar dan batas bukti

- [Screenshot penerbangan pengguna pada 2.421 km](../../../audit/environment-art-review-2026-11-15/user-flight-2421km.png) menjadi bukti komposisi Zona 2 yang gagal, bukan screenshot galeri.
- [Capture scenery terbaru](../../../audit/scenery-obstacle-consistency-2026-11-15/README.md) mencakup lima area dan plaza. Capture memakai fixture kamera; bukan penerbangan penuh/performa mobile fisik.
- [Galeri model rintangan](../../../audit/obstacle-polish-implementation-2026-11-15/README.md) dipakai menilai bentuk model, dengan keterbatasan jarak dan pencahayaan galeri tersebut.
- Inspeksi Studio **read-only** menemukan 18 template rintangan dan 18 landmark mesh. Source tornado latar masih memakai 29 volume elipsoid; lebar atas 175 stud dan tinggi 237 stud berasal dari source saat ini. Susunan tersebut menjelaskan siluet berundak yang terlihat pada gambar pengguna.
- Inspeksi Blender **read-only** pada 5.3.0 memeriksa 37 objek mesh: 34 komponen paket 18 model ditambah tiga komponen duplikat phoenix yang sudah ada sebelumnya. Duplikat itu dipertahankan dan tidak boleh ikut ekspor tanpa pemilihan eksplisit.
- Pada data mesh dasar yang diperiksa tidak ditemukan boundary edge, non-manifold non-boundary, face degenerat pada ambang yang dipakai, atau skala negatif. Ada n-gon, tetapi n-gon pada bidang datar bukan otomatis cacat. Ini bukan pemeriksaan penuh self-intersection, normals, UV, shading, z-fighting atau deformasi.
- [Bukti mentah dan inventaris](../../../audit/environment-art-review-2026-11-15/README.md). Temuan visual di bawah adalah penilaian terhadap bukti tersebut; bagian yang belum dipotret dari dekat diberi pekerjaan pemeriksaan, bukan dinyatakan rusak secara pasti.

## 3. Skill tambahan dan cara penggunaannya

Lima skill dari EL4CTEO/blender-skills versi 1.2.0, commit `b1b21dfb73bc40b874ebf2aa12645931bfed3523`, sudah dipasang setelah audit. [Putusan, file, hash dan batas keamanan](../../../docs/roblox-development/blender-skills-review-2026-11-15/README.md).

| Skill | Pemakaian saat implementasi kelak |
| --- | --- |
| blender-core | Memastikan versi/API, melindungi scene pengguna dan menyimpan salinan kerja. Ini fondasi, bukan alasan memuat semua skill Blender. |
| blender-environment-kits | Metrik kit, pivot, sambungan bangunan/pulau dan penempatan aset pada permukaan nyata. |
| blender-hardsurface-modeling | Struktur prop/arsitektur, bevel seperlunya, normals dan urutan bentuk utama sebelum detail kecil. |
| blender-weather-fx | Rancangan lapisan hujan/petir/kabut, mask dan batas pemindahan hasil Blender ke Roblox. Bukan generator tornado otomatis. |
| blender-asset-qa | Pemeriksaan geometri dan review multi-sudut sebelum ekspor; warning yang disengaja harus dijelaskan. |

Skill Roblox yang sudah tersedia tetap menangani komposisi, VFX native, impor dan pengujian. Script upstream belum dijalankan pada tugas audit ini. Shader toon/volume Blender dan Geometry Nodes hujan tidak dianggap dapat diekspor langsung ke Roblox. Blender dipakai untuk bentuk, tekstur/mask dan sumber model; VFX akhir dibuat serta diperiksa di Studio.

## 4. Arah seni dan aturan bersama

**Pembaruan arah 15 Nov 2026, 21:48 WIB (keputusan pengguna):** scenery dan aset dibuat **semi-realistis** — awan bertekstur lembut dengan cahaya/bayangan meyakinkan, palet tetap mengikuti tema PRD per zona. Ketentuan kartun di bawah berlaku sejauh tidak bertentangan.

**Arah:** fantasi petualangan bergaya kartun, dengan volume yang utuh, tepian terkontrol, material mudah dibaca dan warna sesuai lima tema PRD. Siluet dan komposisi didahulukan daripada detail kecil.

- Bentuk organik memakai peralihan kurva yang halus. Batu dan kristal boleh berbidang tajam secara sengaja; jangan membulatkan semuanya menjadi plastik atau menambah subdivision merata.
- Setiap aset memiliki bentuk utama, bentuk pendukung dan aksen. Ornamen tidak menutupi identitas objek atau menjadi kumpulan garis neon.
- Gunakan keluarga material yang konsisten: batu gading agak kasar, emas dengan kilap terbatas, kayu hangat, kristal berbidang, awan dengan bayangan lembut. Hindari semua material tampak sama mengilapnya.
- Bedakan varian **aktif**, **ambient**, **statue/ornament**, dan **jauh**. Mereka berbagi siluet/motif, tetapi tidak harus memakai seluruh geometri, efek dan animasi yang sama.
- Dekorasi tidak diberi tanda target, warning ring, hitbox atau gerak menerjang pemain. Musuh aktif mempunyai arah pendekatan dan peringatan yang terbaca; pembeda tidak bergantung pada warna saja.
- Nilai skala dalam layar pada kamera yang dipakai pemain. Pembesaran global bukan solusi otomatis: objek dominan dapat diperkecil/dijauhkan, sementara kumpulan titik kecil dapat digabung menjadi satu kelompok yang lebih jelas.

## 5. Daftar aset dan tindakan

Prioritas di bawah adalah urutan pengerjaan visual, bukan klaim adanya bug keamanan/gameplay. P0 = paling merusak tampilan penerbangan; P1 = dibutuhkan untuk kesatuan kelima area; P2 = polesan lanjutan setelah bentuk dan komposisi lolos.

### A. Cuaca dan efek rintangan

| Aset | Temuan / risiko | Rencana konkret | Syarat penerimaan |
| --- | --- | --- | --- |
| **P0 · Tornado scenery / WideStormVortex** | Terlihat seperti tumpukan cincin; kepala/kaki kurang menyatu; mendominasi frame dan menyerupai ancaman aktif | Ganti susunan 29 elipsoid dengan funnel kontinu berkurva yang diuji sebagai mesh sederhana ber-shading halus. Kepala menyatu dengan massa awan; kaki menjadi hembusan yang melebar lalu memudar, tanpa piringan. Tambahkan sedikit detail spiral melalui VFX native, bukan garis setiap tingkat. Evaluasi ukuran lebih kecil dan posisi lebih jauh di sisi frame | Tidak terlihat undakan, tutup datar, ujung bola atau sambungan terlepas pada samping/depan/bawah. Tetap terbaca ketika partikel minimum. Tidak mengisi pusat pandangan atau memakai telegraph aktif |
| **P0 · ThunderheadCliff, StormAnvil, gumpalan lepas** | Terlihat sebagai bola terpisah, sebagian besar massa berada di atas kamera | Susun massa utama yang bertemu dengan shelf/anvil dan undersurface. Gabung/hilangkan puff yang tidak menyumbang siluet; variasikan bentuk besar, bukan sekadar rotasi bentuk yang sama. Kurangi lapisan atas berlebihan dan isi kedalaman menengah secara terarah | Awan terbaca sebagai satu sistem cuaca dari balon; tidak tampak seperti gelembung melayang. Hazard aktif masih memiliki kontras lebih tinggi |
| **P1 · Tornado aktif dan badai surgawi** | Badan lebih jelas setelah opacity fix, tetapi pita/volume berpotensi terlihat sebagai kartu dan terlalu mirip latar | Gunakan bahasa funnel yang sama dengan varian latar; ukuran, kecepatan, warna pusat dan telegraph khusus varian aktif. Pertahankan warning/damage timing. Periksa sepanjang umur partikel, bukan burst saja | Batas bahaya terbaca; tidak muncul sisi kartu, pola tile atau model hilang pada grafis rendah |
| **P1 · Awan petir aktif dan StormCurtain** | Bentuk bola/union masih terasa kasar; flash dan sambaran perlu menyatu dengan badan | Bentuk awan menyatu dengan dasar lebih gelap, flash internal yang terbatas dan bolt bercabang. Rapikan siluet bawah dinding serta transisi kabut; jalur aman tetap jelas | Terlihat berbeda dari dekorasi; arah sambaran dan ruang aman dapat dibaca sebelum aktif |
| **P1 · Hujan miring / crosswind** | Garis panjang lurus seragam dapat terasa seperti kawat, tirai atau kartu | Pecah menjadi beberapa lapisan kedalaman dengan panjang dan opacity terkontrol, mengikuti satu arah angin. Latar memakai aksen jarang; crosswind aktif memakai aliran yang lebih jelas. Hujan tidak menempel mengikuti rotasi kamera | Ada kesan gerak searah, tidak menjadi pagar garis dan tidak menutup crosshair/target |
| **P2 · Heat, Fog, Magnetic, Meteor trail** | Front/medan dapat berbentuk bidang datar; terlalu banyak glow menyamarkan benda padat | Perjelas tepi front panas, rongga kabut dan arah aliran; medan magnet memakai beberapa hubungan kristal yang disengaja; jejak meteor keluar dari belakang batu sesuai kecepatan | Hazard berbeda satu sama lain; Phantom/meteor/kristal tetap terbaca di dalam efek |

### B. Landmark dan scenery perjalanan

| Aset | Temuan / risiko | Rencana konkret |
| --- | --- | --- |
| **P0 · Komposisi lima area** | Tumpukan massa di atas kamera, ruang bawah kosong, aset kecil terpencar dan skala tidak seimbang | Tata ulang dengan lapisan dekat–menengah–jauh dan landmark utama per segmen. Tempatkan sebagian scenery di samping serta sedikit di bawah garis pandang. Gunakan beberapa komposisi yang bergantian selama naik; jangan memenuhi setiap ruang kosong |
| **P1 · Dawn / CoastalIslet / FloatingRockIslet** | Beberapa top pulau terasa seperti keping datar; bibir tanah dan batu bawah belum selalu menyatu | Buat 3–4 varian pulau dengan bentuk dasar berbeda, ketebalan tanah masuk akal, undercut dan bibir batu. Tanam pohon/batu pada permukaan, bukan berdasarkan bounding-box kasar saja. Perahu/pulau pesisir menjadi konteks, tidak dibesarkan merata |
| **P1 · Sunset island, split crag, twin peak** | Bentuk seperti pelat atau kerucut terpotong; strata dan ledge bisa menembus atau menggantung | Bangun profil tebing terpadu dengan top/shelf yang benar-benar bertemu. Atur akar dari tebing ke bawah, bukan melayang. Satukan palet relief/temple dengan kit Ruin; hindari batu besar yang hanya ditempel sebagai balok |
| **P1 · Air terjun, outlet, kolam dan mist** | Pita air bersegi/zigzag dan kolam seperti cakram datar; sambungan pada bibir bangunan/pulau perlu diperiksa lagi | Buat sumber air yang jelas: cekungan/kanal → bibir spillway → lembar jatuh → pecah menjadi beberapa aliran → mist. Kurva halus, lebar bervariasi, UV/arah tekstur konsisten. Kolam dibentuk mengikuti cekungan, bukan elips tempelan. Arsitektur outlet dirapikan dahulu | 
| **P1 · Cosmic landmark / CrystalSatellite / CosmicArcStone** | Kristal/batu berorbit terasa seperti bentuk geometris mengambang dengan cincin neon terang | Bedakan rock host, kristal utama, kristal kecil yang tumbuh menempel dan fragmen yang sengaja melayang. Kurangi bentuk simetris berulang. Cincin hanya pada landmark tertentu; sebagian menjadi jejak partikel/arus redup. Kristal ChargedCrystal yang sudah efisien tetap dipertahankan |
| **P1 · FloatingObservatory / orbital outpost** | Paviliun awan dan satelit modern terasa ditempel; skala sambungan belum membentuk cerita yang kuat | Jadikan outpost sebagai struktur observatorium kuno dengan zona perangkat yang jelas: alas, instrumen, dudukan antena, bagian rusak dan orbit puing. Satelit luar punya hubungan posisi dengan observatorium, bebas dari massa awan. Tidak cukup hanya menambah satelit di dua sisi |
| **P1 · Aurora, bintang dan debu** | Risiko pita datar/bersegmen, neon terlalu kuat dan bintang tersebar merata | Buat pita yang bergelombang pada kedalaman berbeda, amplitudo dan opacity tidak seragam. Kelompokkan bintang menjadi gugus dan area tenang. Hindari arah gerak yang menyerupai jalur meteor aktif |
| **P1 · CloudSailer/Ketch/Cutter** | Siluet sudah dikenali, tetapi lambung, layar, rigging dan haluan masih sederhana; figurehead bisa tertutup atau tampak ditempel | Poles kurva sheer lambung, ketebalan gunwale, dudukan tiang, layar mengembung dan beberapa tali struktural yang tersambung. Tempatkan figurehead pada dudukan haluan yang menyatu, dengan versi ornamen lebih ringan. Bedakan tiga kapal melalui proporsi/rig, bukan skala saja |
| **P1 · HorizonArch/Spire/Pavilion, crystal gate** | Siluet menara terlalu kerucut, material bidang besar polos, beberapa alas/ornamen menonjol seperti rak | Tambahkan bevel sesuai skala, kurva lengkung teratur dan ketebalan kolom/alas. Gunakan modul cornice, finial, relief dan jendela yang konsisten dengan istana. Dudukan patung menyatu dengan teras; beri ruang agar akar/pot/lampu tidak bertabrakan |
| **P1 · PalaceCloud / HorizonCloud / UpperSkyCloud / ZenithCloud** | Bentuk awan belum satu keluarga; beberapa seperti pancake/balon berlapis | Buat kit cloud dengan massa besar terhubung, tepian lembut dan variasi profil. Dekat memiliki bentuk lebih rinci, jauh lebih sederhana. Terapkan bahasa yang sama ke dasar istana, pulau paviliun dan langit atas; jangan mengandalkan opacity tinggi untuk menyembunyikan sambungan |
| **P2 · Flora: sakura, pohon, fern, bunga** | Kanopi masih berbidang tajam dan bunga kecil dapat seperti titik/cetakan datar | Rapikan cabang dan hubungan daun–batang. Kelompokkan dedaunan menjadi massa dengan lobus besar, beri ketebalan seperlunya. Variasikan tinggi dan fase bunga; buat patch habitat lebah dengan kelompok bunga yang terbaca, tidak berjajar merata |
| **P2 · Balon cuaca, perahu laut, batu/pot/lonceng kecil** | Aset pendukung mudah kehilangan bentuk pada jarak jauh | Rapikan titik ikat, tiang, dudukan dan siluet yang besar; detail kecil dibake atau dihilangkan pada LOD. Tinjau peletakannya setelah komposisi utama, bukan menambah jumlah dahulu |

### C. Fauna, musuh dan benda padat

| Keluarga | Rencana polesan |
| --- | --- |
| **P1 · Camar dan elang** | Pisahkan ciri spesies lebih kuat: bentuk paruh, proporsi kepala/leher, ujung bulu dan warna sayap. Kurvakan sayap/camber dan transisi bahu agar tidak seperti dua papan. Buat LOD ambient; variasikan glide, kepakan dan formasi tanpa menabrakkan anggota kawanan |
| **P1 · StormBat** | Perjelas membran bertulang, lekuk sayap dan sambungan bahu. Pose terbang tenang berbeda dari pendekatan musuh. Pertahankan mata/telinga yang terbaca saat gelap; tubuh tidak ditenggelamkan dalam glow |
| **P2 · FireBee** | Pertahankan tubuh bersegmen dan belang yang sudah dikenali. Rapikan antena, bentuk abdomen/sengat, ketebalan sayap dan kontras wajah. Sederhanakan varian habitat yang kecil. Versi aktif memakai bara terarah, bukan seluruh tubuh tertutup api |
| **P1 · CrystalWyvern** | Model sudah lebih dikenali, tetapi sayap/torso masih terasa kaku. Poles rahang, leher, bahu dan membran melengkung; kristal punggung mengikuti struktur tubuh. Pose istirahat perlu kaki/ekor menapak pada sarang, tidak sekadar model terbang ditempel di tanah |
| **P2 · ShadowPhantom** | Jubah diberi lapisan dan volume yang lebih alami, rongga tudung jelas, lengan menyatu dengan bahu. Gerak kain ringan. Untuk monumen, buat versi batu dengan pedestal dan relief yang disengaja, bukan seluruh model dicat satu warna tanpa adaptasi bentuk |
| **P1 · CelestialPhoenix** | Sayap bertingkat/camber, mahkota, leher dan ekor dibuat lebih anggun. Buat versi ornamen/relief khusus untuk gerbang, pintu dan kapal, tetap satu motif. Tidak memakai mesh full-detail terbang di setiap ornamen jauh |
| **P2 · GuardianDrone** | Tambahkan pembacaan cangkang, inset aperture dan sisi pendorong dengan bevel/normal yang terkontrol. Penjaga nonaktif diberi dock/pedestal yang pas dan lensa mati; versi aktif tetap jelas arah tembaknya |
| **P1 · SatelliteDebris** | Pertahankan identitas badan/panel/dish. Kurangi geometri sel panel, pindahkan grid/baut kecil ke tekstur. Rapikan arm dish, rangka panel dan lokasi kerusakan; puing lepas dikelompokkan, tidak menjadi serpihan acak. Buat varian jarak |
| **P2 · Hailstone 1–3** | Budget dasar sudah rendah; tidak perlu dibuat bulat halus. Variasikan bentuk patahan dan retak es yang besar, dengan sedikit perbedaan proporsi. Hindari tiga batu yang hanya tampak seperti rotasi/pewarnaan ulang |
| **P2 · Meteor** | Bentuk saat ini cenderung bongkah bulat gelap mengilap. Buat kawah/cekungan besar, facet patahan dan retak pijar yang mengikuti permukaan; material basalt lebih kasar. Pertahankan jejak dan arah gerak yang jelas |
| **P2 · Ruin1–3** | Pecahan arch/pilar/teras memakai keluarga struktur utuh yang sama dengan pulau kuil. Potongan patah punya arah dan ketebalan, bevel terukur, relief besar seperlunya. Kurangi tampilan alas mengambang/terpotong tanpa hubungan dengan bangunan |
| **Pertahankan; poles ringan · ChargedCrystal / MagicSpike** | 68 dan 44 segitiga pada data dasar sudah efisien. Periksa normal, tip dan transisi ke VFX. Tidak perlu meningkatkan kepadatan atau menambahkan lapisan neon hanya untuk menambah detail |

### D. Istana, lobby dan balon milik pemain

- **Istana Awan — P1 setelah area perjalanan:** pertahankan siluet kubah/menara. Poles profil kubah, finial, ketebalan lengkung, column capitals dan cornice; sederhanakan pengulangan detail kecil yang tidak terbaca. Perbaiki material marmer/emas agar tidak semua permukaan mengilap rata. Tinjau outlet air, kolam dan awan sebagai satu komposisi.
- **Plaza/sofa/ayunan/lampu/pot — P2:** audit kedudukan kaki/dudukan, simetri yang memang dimaksudkan dan ruang sirkulasi. Sofa/ayunan tetap berfungsi dan barrier tetap melindungi pemain; perubahan visual tidak boleh memindahkan Seat, portal atau jalur arrival secara diam-diam.
- **Awan solid istana:** pisahkan mesh visual dan collider. Polesan tepian tidak boleh mengembalikan bug pemain menembus awan atau jatuh dari tepian. Efek langkah diuji ulang setelah pergantian visual.
- **Keranjang dan skin balon — review P2:** bukan prioritas pertama dari screenshot ini. Setelah lingkungan stabil, periksa transisi tepi kayu, sambungan tiang/tali, attachment burner, skala ornamen serta konsistensi metal/wood. Pusat massa, deck, rak senjata, kursi pilot dan ruang gerak kru dipertahankan.
- **Lobby/jalan/dermaga — regresi saat reuse kit:** tidak dibangun ulang dalam batch scenery. Bila material/modul bersama berubah, uji ulang sambungan A/E, tepi jalan dan akses summon. Hindari membuka ulang bug lama karena mengganti kit global.

## 6. Penataan per tema PRD

| Rentang | Fokus suasana dan komposisi |
| --- | --- |
| 0–2.000 km · Breezy Dawn Archipelago | Laut/pesisir menjadi dasar; pulau dan kelompok burung sebagai fokus menengah; lapisan awan mengantar ke badai. Sedikit landmark besar dengan bentuk berbeda, bukan banyak islet identik |
| 2.000–4.000 km · Indigo Thundercloud | Koridor badai berdinding awan yang terhubung; satu tornado latar di sisi jauh. Hujan, batu ber-es dan fauna menjadi aksen. Bagian tengah untuk ancaman aktif; jangan meninggalkan seluruh ruang bawah sebagai void |
| 4.000–6.000 km · Sunset of Forgotten Sky Isles | Pulau kuil/air terjun sebagai fokus; jembatan/gerbang rusak menjadi penghubung; flora dan lebah memberi skala hidup. Hindari kumpulan pelat pulau dengan tinggi/ukuran seragam |
| 6.000–8.000 km · Bioluminescent Cosmic Exosphere | Pulau sarang, observatorium dan lengkungan tersusun sebagai landmark yang bisa diingat. Aurora dan gugus bintang memberi kedalaman atas. Glow diatur agar monster/medan aktif tetap terbaca |
| 8.000–10.000 km · The Celestial Gateway | Outpost 8–9k menjadi sisa zona kosmik yang mengantar ke emas/awan surgawi. Armada, gerbang dan paviliun membingkai istana; pintu/kubah menjadi tujuan visual. Siluet istana bertambah jelas tanpa dikerumuni prop kecil |

Untuk setiap area buat view depan, kiri, kanan, atas dan sedikit ke bawah dari gondola. Hadirkan detail dekat/menengah/jauh yang berbeda melalui parallax dan gerak lambat; jangan mengisi kekosongan dengan menaruh objek tepat di dekat kamera.

## 7. Skala, LOD dan biaya render

Temuan terukur dari manifest dan inspeksi Blender dasar: camar 4.972 tris, elang 5.196, FireBee 5.976, wyvern 6.210, phoenix 5.788 dan satelit 8.444. Panel satelit sendiri 5.760 tris (~68% total). 19 camar + 4 elang scenery setara **115.252 tris sumber** sebelum LOD/culling; bukan hitungan GPU/draw call/FPS terukur.

Rencana:

1. Buat varian active/near, ambient/mid dan far yang berbagi palet serta bentuk utama. Untuk burung/lebah kecil, target awal ambient sekitar 250–800 tris dan varian dekat disesuaikan bentuk yang terlihat. Ini anggaran desain yang harus diuji, bukan aturan wajib engine.
2. Ornamen phoenix/monumen jauh memakai mesh relief/LOD; panel satelit memakai tekstur untuk grid kecil. Simpan geometri bagi silhouette, engsel, rangka dan bentuk dish.
3. Pertahankan mesh/atlas bersama agar variasi tidak menghasilkan asset ID dan material unik tanpa manfaat. Tinjau salinan tint yang mengganti atlas agar tidak merusak batching secara berlebihan.
4. Awasi transparency overdraw, jumlah lapisan yang menutupi pixel yang sama, ukuran sprite di layar dan jumlah perubahan properti VFX. Jangan memperbaiki bentuk awan dengan ratusan part transparan.
5. Tentukan threshold LOD berdasarkan jarak/ukuran layar dan transisi tanpa popping. Profilkan satu area, wave aktif, dua area saat transisi dan plaza dengan kru; jangan memakai hitungan segitiga saja untuk mengklaim performa.

Dasar engine: [Roblox — Improve performance](https://create.roblox.com/docs/performance-optimization/improve), [Design for performance](https://create.roblox.com/docs/performance-optimization/design). Studio emulator dipakai untuk layout/rasio; klaim performa mobile memerlukan perangkat fisik.

## 8. Urutan pelaksanaan setelah diperintahkan

**Batch 1 — patokan mutu Area 2:** satu tornado latar, satu keluarga storm cloud, hujan dan satu komposisi penerbangan. Buat varian/graybox dan review dengan kamera yang mendekati screenshot 2.421 km. Putuskan bentuk, ukuran dan perbedaan hazard/scenery sebelum direplikasi. Jangan langsung membangun seluruh lima area dengan patokan yang belum lolos.

**Batch 2 — pulau dan air:** satu pulau Dawn, satu pulau Sunset dan satu waterfall/outlet yang rapi. Pastikan contact point tanah/batu/pohon serta air tidak bersegi/zigzag, lalu perluas menjadi kit variasi.

**Batch 3 — kosmik dan fauna:** batu kristal/orbit, aurora, sarang dan observatorium; varian LOD fauna. Tempatkan kembali kelompok ambient setelah landmark besar selesai.

**Batch 4 — gerbang surgawi dan istana:** kapal dengan rigging/figurehead, paviliun/gerbang, cloud kit dan material istana. Pertahankan hubungan vista dengan plaza aktual; verifikasi landing dan cloud walk terpisah.

**Batch 5 — rintangan dan polesan kecil:** sesuaikan kualitas musuh/puing/prop terhadap kit yang sudah disetujui; lakukan review satu wave dan transisi. P2 hanya diterapkan pada aset yang masih membutuhkan perbaikan setelah dibandingkan pada jarak permainan.

Setiap batch menghasilkan source Blender/generator yang dapat diedit, manifest model/tekstur/ID, preview sebelum–sesudah dengan sudut sebanding dan source mirror yang cocok. Simpan source asli; apply modifier dan triangulasi pada salinan ekspor. Uji impor ulang GLB ke sesi terpisah sebelum integrasi Studio.

## 9. Gerbang penerimaan dan bukti

- **Bentuk:** dikenali tanpa label pada jarak main; diperiksa depan/samping/belakang/bawah dan ketika bergerak. Tidak cukup render Blender yang bagus atau capture galeri saja.
- **Geometri:** jalankan pemeriksaan baru pada salinan kerja setelah implementasi diizinkan; simpan errors/warnings asli. Fix z-fighting, normals keliru dan sambungan yang tidak disengaja. Bagian melayang yang memang dimaksudkan (kristal/efek) diberi pengecualian eksplisit, bukan di-snap otomatis.
- **Komposisi:** review dari FPS/third person dan posisi repair, termasuk melihat atas/bawah, naik/turun dan saat ada hazard. Landmark tidak menutupi tujuan/ancaman; aset latar tidak terlihat sebagai musuh palsu.
- **Ukuran layar:** cek desktop, phone landscape dan tablet. Gunakan contact sheet atau crop kecil untuk menguji silhouette; bukan memperbesar setiap aset karena close-up terlihat kurang detail.
- **VFX:** steady emission, awal warning, aktif, akhir dan cleanup; terang/gelap dan kualitas rendah. Bukan hanya Emit burst atau screenshot frame terbaik. Hindari flash beruntun yang menyilaukan.
- **Akses/collision:** uji terpisah dari visual: deck/keranjang, jalan/dermaga, arrival, seat/sofa/ayunan, portal, cloud walk/barrier; dekorasi tetap tidak queryable dan tidak memengaruhi auto aim.
- **Lifecycle:** scene keluar benar pada transisi, Game Over, respawn dan portal pulang; tidak ada loop, koneksi atau efek yang tertinggal. Uji overlap dua bioma.
- **QA perjalanan:** titik sebelum/sesudah tiap 2.000 km, kedua band 1.000 km dalam tiap area, serta arrival dan plaza 10.000 km. Catat altitude target dan aktual. Sertakan satu run alami penuh; fixture warp/shield dilabeli terpisah.
- **Bukti:** build/source hash, lingkungan, posisi kamera, fixture, log mentah dan screenshot/video disimpan dalam satu folder run. Persetujuan visual, lolos teknis, simpan binary, commit dan push dicatat terpisah sesuai WORKFLOW.

Tidak memakai persentase "kemiripan" atau "sudah final" tanpa kriteria/rujukan yang disepakati. Status perbaikan tetap **rencana**, hingga pengguna memberikan instruksi implementasi.
