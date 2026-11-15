# Proposal poles visual rintangan Fly High

Status: **disetujui pengguna; implementasi tersedia dan QA terarah dilakukan**. Lihat [hasil, bukti dan QA tersisa](../../../audit/obstacle-polish-implementation-2026-11-15/README.md). Perjalanan bioma penuh, tembakan pemain/auto aim dan perangkat fisik belum terverifikasi. Audit visual 15 November 2026; acuan band mengikuti PRD, bukan pembagian scenery per 2.000 km. [Bukti dan batas inspeksi](../../../audit/obstacle-visual-review-2026-11-15/README.md).

## Temuan utama

Sembilan jenis musuh saat ini seluruhnya dibangun dari Part/WedgePart, tanpa MeshPart pada sampel yang diperiksa. Bentuk sering menyatukan bola kepala/badan dengan sayap wedge tipis, sehingga identitas hilang dari depan. Perbesaran skala membuat placeholder lebih terlihat, tetapi tidak mengubah siluet. FireBee cenderung seperti bola hitam berantena; CrystalWyvern tidak memperlihatkan leher/rahang/kaki naga; ShadowPhantom berupa bola berlapis ekor wedge; CelestialPhoenix terlalu dekat dengan burung biasa. Hailstone dan meteor terbentuk dari wedge saling menembus.

Rekomendasi arah seni: fantasi bergaya kartun dengan volume utuh, tepi dibulatkan seperlunya, normal/shading bersih dan material sederhana. Bentuk dasar harus terbaca sebelum detail kecil atau partikel ditambahkan. Es/kristal tetap punya bidang patahan yang disengaja; tidak semuanya dibulatkan. Target perhatian pertama adalah bentuk pada jarak muncul musuh sekitar 145+ stud dan jarak tembak, bukan hanya close-up Blender.

## Inventaris dan proposal

P1 = bentuk/identitas perlu dibangun ulang dahulu. P2 = poles struktur/material/gerak setelah acuan P1. P1/P2 adalah urutan kerja usulan, bukan status selesai atau bug gameplay.

| Aset | Band km | Prioritas | Usulan bentuk / pengerjaan |
| --- | --- | --- | --- |
| CrystalWyvern | 6.000–7.000 | P1 | Mesh Blender: moncong/rahang naga, leher melengkung, dua kaki bercakar, sayap bermembran dan ekor panjang. Kristal menjadi aksen punggung/sayap, tubuh cukup solid untuk dibaca. |
| ShadowPhantom | 7.000–8.000 | P1 | Mesh Blender: tudung dengan rongga wajah, bahu dan dua lengan, jubah berkibar dengan ujung meruncing. Mata redup terpusat; asap mengikuti ujung jubah, tidak menutup siluet. |
| CelestialPhoenix | 9.000–10.000 | P1 | Mesh Blender: badan burung ramping, leher dan paruh jelas, sayap melengkung bertingkat, mahkota dan ekor pita panjang. Warna merah/emas dengan bara hanya di ujung, berbeda dari camar/elang. |
| FireBee | 5.000–6.000 | P1 | Mesh Blender: kepala, thorax dan abdomen terpisah secara visual; abdomen belang kuning/hitam dan sengat, sepasang antena melengkung, empat sayap tipis membulat. Api sebagai aksen di belakang tubuh. |
| WildBird / kawanan camar dan elang | 300–2.000 | P1 | Dua varian mesh berbagi rig: camar putih berparuh kuning dan sayap meruncing; elang cokelat berparuh bengkok, sayap lebar dengan ujung bulu terpisah. Tubuh menyatu, paruh terhubung; formasi tidak saling menutup. Tetap satu target kawanan menurut mekanik sekarang. |
| StormBat | 2.000–3.000 | P1 | Mesh Blender: sayap kulit dengan lekuk khas kelelawar, tulang sayap yang jelas, telinga melengkung dan kaki kecil. Bentuk tetap terbaca saat kepakan/menukik dan pada latar badai gelap. |
| Hailstone | 3.000–4.000 | P1 | Mesh Blender berupa satu bongkah es utuh dengan pecahan tidak simetris, ujung jatuh dan retak es. Facet disusun mengitari volume; variasi 2–3 bentuk, transparansi terbatas. |
| GuardianDrone | 4.000–5.000 | P2 | Mesh Blender dengan cangkang berlapis dan bevel, lensa pusat di dalam housing, dua modul pendorong dan aperture peluncur. Material batu/logam emas menyatukan motif reruntuhan. |
| SatelliteDebris | 8.000–9.000 | P2 | Mesh Blender: badan satelit berlapis foil, dua panel surya dengan rangka, dish cekung dan feed arm. Satu panel rusak dan kabel pendek untuk identitas puing; siluet satelit tetap utuh. |
| Meteorit Mikro | 8.000–9.000 | P1 | Mesh batu basalt bervolume, kawah/lekuk besar dan retak pijar yang menyatu pada permukaan. Satu kepala meteor per lintasan; jejak api/asap mengikuti arah gerak, bukan menggantikan bentuk batu. Pertahankan tiga jalur/telegraph. |
| Puing Kuno | 4.000–5.000 | P2 | Kit Blender 3 varian: pecahan gerbang lengkung, pilar patah, teras/atap candi. Pilar tampak terhubung ke alas; kerusakan punya arah dan bidang patahan rapi. Tetap susunan berselang yang bisa dilalui. |
| Anomali Magnetik | 6.000–7.000 | P1 | Kristal Blender berpenampang jelas, tersusun teratur mengitari satu pusat. VFX medan melengkung/denyut dan arus yang menghubungkan beberapa kristal memberi identitas magnetik; hindari kumpulan neon wedge. |
| Angin Topan | 300–2.000 | P1 | Perbaikan VFX Roblox: funnel kontinu, pangkal menyempit dan bagian atas membesar, lapisan asap berputar dengan beda kecepatan, sedikit debris orbital. Beam menjadi aksen, bukan satu-satunya badan tornado. |
| Badai Gerbang Surgawi | 9.000–10.000 | P1 | VFX pusaran emas berskala besar dengan pusat gelap dan mahkota awan. Siluet/irama sambaran berbeda dari tornado awal; pertahankan peringatan tiga detik dan tiga sambaran bergiliran. |
| Awan Petir | 2.000–3.000 | P2 | Awan cumulonimbus dengan massa menyatu dan puncak lebih datar, undersurface gelap; flash dari dalam sebelum petir bercabang. Perbaikan volume native/VFX dahulu, mesh hanya bila siluet masih gagal. |
| Jetstream Crosswind | 3.000–4.000 | P2 | VFX aliran lateral yang panjang dan searah dengan gust pendek berirama; sedikit embun membantu menunjukkan arah dorong. Identitas berbeda dari front panas dan medan magnet. |
| Gelombang Panas | 5.000–6.000 | P2 | VFX front udara hangat berlapis dengan gradasi amber dan shimmer halus. Percikan jarang dan terarah; keterbacaan batas front utama harus tetap jelas. Tidak memerlukan model solid baru. |
| Kabut Hampa | 7.000–8.000 | P2 | Lapisan kabut ungu bergerak dengan tepi memudar, kedalaman dan rongga; aksen debu lambat. Target Phantom harus tetap terbaca pada jarak reaksi yang wajar. Tidak memerlukan mesh baru. |
| Dinding Badai / StormCurtain | Gelombang besar PRD | P2 | Evaluasi Union cloud yang sudah ada; poles beberapa lapis kedalaman, tepi bawah berawan dan petir yang menyatu dengan massa. Batas aman untuk turun tetap terbaca. Baru ganti mesh jika native volume tidak memenuhi standar; tidak perlu memodelkan ulang seluruh dinding sejak awal. |
| Paku Sihir | Proyektil drone | P2 | Mesh kristal berbentuk anak panah/spindle, pangkal dan ujung jelas, dimensi padat terbaca saat meluncur. Trail tipis berada di belakang; tidak menyamarkan arah proyektil. |

## Urutan usulan

1. Tetapkan acuan mutu melalui CrystalWyvern, ShadowPhantom dan CelestialPhoenix. Bentuk paling bermasalah dan paling khas diselesaikan dahulu, berikut satu uji impor Roblox.
2. Terapkan acuan tersebut pada WildBird/StormBat/FireBee, lalu Hailstone dan Meteor. Bagian awal perjalanan harus mendapat mutu setara dengan klimaks.
3. Rapikan GuardianDrone, satelit, kit reruntuhan, kristal magnetik dan proyektil.
4. Poles volume/VFX sembilan hazard reguler dan dinding badai, lalu validasi keterbacaan seluruhnya bersama scenery dan gerak permainan.

Implementasi memakai Blender untuk makhluk/benda padat dan native Roblox untuk VFX cuaca. Generator, GLB, atlas dan template impor sudah tersedia; tidak perlu membangun ulang backlog model di atas. Detail anggaran, impor dan batas QA ada pada laporan implementasi.

Perbaikan keterlihatan 15 November tersedia: [steady-state Play Solo, kualitas rendah, mask alpha dan screenshot sebelum/sesudah](../../../audit/weather-readability-2026-11-15/README.md). Jangan menjadikan capture Emit burst sebagai satu-satunya bukti opacity.

## Standar penerimaan untuk implementasi berikutnya

- Setiap model dikenali tanpa nama/label dari depan, samping dan sudut tiga perempat, lalu diperiksa saat kepakan, menukik atau berputar.
- Periksa dekat, jarak tembak dan jarak muncul sekitar 145+ stud, dengan pencahayaan bioma sebenarnya, latar awan/scenery, kualitas grafis rendah dan viewport ponsel/tablet.
- Tidak ada sambungan melayang, lubang mesh yang tidak disengaja, permukaan saling menembus/z-fighting, atau normal terbalik. Bevel dan smooth shading dipakai sesuai material; lekuk/bulu dibuat berkelompok agar tidak menjadi noise.
- Gunakan mesh seperlunya dengan LOD/anggaran segitiga dan atlas sederhana yang diukur pada satu wave penuh. Jangan memperbanyak Part transparan, lapisan glow, atau lampu dinamis demi detail yang tidak terbaca di mobile.
- Pivot, bagian sayap dan attachment kompatibel dengan animasi/lifecycle sekarang. Siluet yang terlihat dan area terkena tembakan harus cocok; pertahankan aturan HP, band, wave, damage dan telegraph kecuali ada permintaan gameplay terpisah.
- Nilai model di Studio setelah impor, bukan hanya render Blender. Dokumentasikan screenshot model dan penerbangan aktual, source/import version, hitbox, serta hasil QA mobile. Proposal ini belum membuktikan performa, animasi baru, collision, atau uji terbang penuh.
