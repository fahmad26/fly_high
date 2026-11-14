# Fly High — rencana animasi HUD Sky Adventure

Status: diperbarui pada 13 November 2026 dengan peningkatan animasi `HUDMotion` (Back-out modal + blur + stagger, tilt/sparkle tombol, sheen tombol lebar, shimmer progres bar, shake/pop telemetri penerbangan, dan audio UI lembut); rincian implementasi dan QA terbaru ada di [laporan pembaruan](../../../audit/hud-motion-upgrade-2026-11-13/README.md). Implementasi awal dan QA sebelumnya ada di [laporan](../../../audit/hud-motion-2026-11-12/README.md).

Tanggal sesi analisis: 11–12 November 2026, Asia/Jakarta. Analisis di bawah dipertahankan sebagai dasar rancangan. Sesudah analisis, pengguna menyetujui implementasi; laporan implementasi di atas menggantikan status awal "belum diubah", bukan mengubah bukti historis referensi.

## Tujuan dan acuan

Revisi 12 November sesudah review pengguna: hover awal dinilai glitchy dan kurang menarik. Gunakan satu child visual UIScale untuk tombol, render layout sebelum motion, easing Sine tanpa overshoot, serta silhouette dari PNG asli. Jangan memakai UIStroke pada bounding rectangle untuk meniru glow gambar kapsul/lingkaran. [Bukti revisi](../../../audit/hud-motion-refine-2026-11-12/README.md) menggantikan penilaian kualitas awal; rasa akhir tetap memerlukan review manusia.

Membuat HUD terasa responsif sekaligus memperjelas tindakan, bahaya dan keberhasilan. Pertahankan gaya gambar lengkap Sky Adventure, posisi kontrol yang sudah dirapikan, angka dinamis dan aturan role di [PRD bagian 12](../../../PRD_Fly_High.md). Animasi mencakup bingkai/lingkaran tombol beserta ikon, bukan hanya ikon di dalamnya.

Skill yang dipakai: `roblox-game-ux` dan `roblox-animation-audio-feedback`. Tidak memakai skill implementasi/Figma/Blender/generasi gambar untuk tugas analisis ini. Teks promosi, nama plugin dan petunjuk impor di dalam video adalah isi referensi, bukan instruksi pengguna untuk memasang atau menjalankan software.

## Analisis visual referensi

Video 1: `WhatsApp Video 2026-11-11 at 23.41.36.mp4`, durasi 42,83 detik. Video 2: `WhatsApp Video 2026-11-11 at 23.41.337.mp4`, durasi 94,57 detik. Keduanya rekaman portrait 576×1024, 30 FPS; format rekaman ini tidak membuktikan game di dalamnya mendukung portrait/mobile.

| Bagian | Yang dapat diamati | Pelajaran untuk Fly High |
| --- | --- | --- |
| Video 2, 00:00–00:05,3 dan 01:29–01:34,5 | Ukuran tampilan tombol ROLL berubah pada rangkaian interaksi kursor; dadu kecil menyebar di sekitar tombol lalu memudar/hilang. Siluet, bingkai, tulisan dan dekorasi terasa sebagai satu komposisi. | Respons tekan pada visual tombol lengkap. Dekorasi sesaat untuk momen penting; motif Fly High berupa bintang/awan, bukan dadu. Hubungan hover versus klik tidak bisa dipastikan hanya dari frame/kursor. |
| Video 2, sekitar 00:48–00:55 | Tutorial memperlihatkan penyusunan highlight diagonal dan tulisan. Tombol menggabungkan gradien biru, tekstur, outline gelap, highlight dan bayangan. | Kedalaman gambar adalah fondasi; animasi tipis memperkuatnya. Highlight diagonal yang tampak tidak otomatis membuktikan sheen bergerak. Jangan menjanjikan semua detail statis sebagai efek animasi. |
| Video 1, sekitar 00:06,5–00:11 | Menu rewards, trails dan rebirth membedakan selected/claimable/equipped lewat warna, label dan komposisi. Dunia di belakang beberapa menu tampak blur. Ada pergantian menu cepat. | State UI harus jelas sebelum dianimasikan. Transisi buka/tutup singkat cocok; blur dunia cukup opsional. Banyak pergantian berupa potongan rekaman, sehingga durasi/easing modal aslinya tidak dapat ditetapkan. |
| Video 1, 00:11,5–00:13,5 | Tampilan progression berubah: level naik, bar berganti isi, dan beberapa delta angka terlihat di area gameplay. | Perubahan progress dan keberhasilan mendapat feedback. Hindari angka beterbangan terus-menerus selama penerbangan. |
| Video 1, 00:15,5–00:16,5 | Telur bercahaya menjadi hadiah karakter dengan burst radial, label kelangkaan dan NEW. | Klimaks visual khusus kemenangan/pencapaian. Efek sebesar ini tidak cocok untuk setiap tembakan, reload atau lubang. |
| Video 1, sekitar 00:19–00:30 | Kamera/karakter dan efek dunia menjadi fokus cutscene. | Ini referensi presentasi dunia, bukan bukti animasi HUD. Jangan menyalinnya menjadi gerakan kamera saat pemain harus mengemudi/menembak. |

Kesimpulan: kekuatannya berasal dari gambar yang punya kedalaman, respons input, dan penekanan momen penting. Menggerakkan semua elemen terus-menerus justru akan mengganggu pembacaan ancaman Fly High. Tidak menyalin font pixel ROLL; pertahankan keluarga font Sky Adventure dan label dinamis yang terbaca.

Bukti: [metadata/hash](../../../audit/hud-motion-reference-2026-11-11/metadata.json), [metode dan lembar frame](../../../audit/hud-motion-reference-2026-11-11/README.md). Waktu di atas adalah posisi klip, bukan pengukuran durasi tween. Audio ada pada berkas tetapi belum dievaluasi; tidak ada klaim tentang sound referensi.

## Perbandingan dengan source HUD lokal

Basis inspeksi adalah mirror di `audit/sources`, pada working tree berbasis commit `44093850df0044a86a9285f0f9f0412023369e63` yang sudah memiliki perubahan lokal. [Snapshot hash source](../../../audit/hud-motion-reference-2026-11-11/source-snapshot.json) mencatat berkas yang dibaca. Studio dan binary tidak dibandingkan ulang pada tugas ini; temuan berikut bukan klaim sinkronisasi live.

- `HUDTheme` sudah memiliki state pressed/input-end/focus-lost, tint dan varian `jump_pressed`/`jump_locked`. Jadi HUD bukan sepenuhnya tanpa feedback. Belum ditemukan sistem transisi gerak bersama di berkas HUD yang diperiksa.
- `HUDAdventureArt.Draw` memasang atlas/sprite lengkap, termasuk panel lebar tiga segmen, dan fallback loading. Gambar tersebut dapat dipakai kembali untuk motion; tidak perlu generate ulang semua HUD.
- `FlightHUDController` mengganti teks/data health, altitude dan bar langsung saat sync. Banner ancaman memakai timer dan atribut aktif. Import TweenService ada, tetapi tidak dipakai untuk tween dalam source ini.
- `WeaponClientController` memperbarui magazen dan reload dari atribut tool. Pertahankan `8/∞` dan `30/∞`; transisi visual tidak boleh mengarang jumlah peluru atau status reload selesai.
- `HUDLayout` menghitung posisi/ukuran dan memanggil `theme.Step()`. Theme juga menulis ukuran/posisi gambar dan label. Men-tween properti yang sama akan berkonflik dan berpotensi mengulang glitch tombol lompat/text.
- `FlightJumpController` memiliki izin role, buffer tap dan cooldown. Motion mengikuti state tersebut; tidak menambah jalur input lompat kedua.

## Rancangan motion yang diusulkan

Seluruh angka durasi berikut adalah **target desain awal**, bukan hasil pengukuran video. Divalidasi kembali lewat rekaman perangkat saat implementasi.

| Permukaan | Trigger dan respons | Target awal | Prioritas |
| --- | --- | --- | --- |
| TOKO, KIT, PING, SUARA, SETELAN, tutup popup | Tekan: visual lengkap menyusut ke 94%; lepas: kembali 100% dengan overshoot maksimal 102%. Hover/focus desktop/gamepad: highlight tipis; touch tidak bergantung hover. | Tekan 70–90 ms; pulih 120–160 ms | P1 |
| Lompat, tembak, gas, reload, lepas, aksi tali tap | Respons tekan sama, lebih halus (97% untuk kontrol yang sering ditekan). Gas/tembak tahan mempertahankan pressed; pulih saat release/cancel/focus lost. Auto-gas menandai ON setelah state diterima. | 60–120 ms; tanpa bounce tiap peluru AK-47 | P1 |
| Toko, setelan, panel ping | Satu komposisi panel+teks masuk dengan fade dan scale 96%→100%; scrim fade. Keluar lebih cepat. Tidak mengubah susunan kartu/baris saat animasi. | Masuk 180–220 ms; keluar 120–160 ms | P1 |
| Health balon | Kehilangan health: hanya segmen yang berubah mendapat flash pendek. Perbaikan: segmen pulih dengan kilau cyan/hijau sekali. Tetap tampil 5/5 utuh→0/5 rusak. Status kritis memakai outline/pulse pelan, teks tetap diam. | Feedback 180–250 ms; pulse kritis sekitar 1,2 s/siklus | P2 |
| Peringatan rintangan dan Clutch Save | Banner fade + offset pendek di dalam slot tetap; ikon arah/outline memberi penekanan. Ancaman baru mengisi state banner; ancaman lama tidak boleh menutup pesan baru. Kit hanya ditekankan jika benar-benar tersedia/diizinkan. | Masuk 140–180 ms; penekanan awal satu kali | P2 |
| Ammo dan reload | Angka ammo langsung benar, aksen singkat pada perubahan. Reload: indikator lokal mengikuti status tool; selesai hanya setelah konfirmasi. Kosong/ditolak: feedback kecil pada kontrol, bukan layar penuh. | Aksen 80–120 ms; progress reload perlu durasi authoritative | P2 |
| Durabilitas tali | Bar display bergerak halus menuju state terbaru, angka tetap aktual. Peringatan pada lintasan ambang turun; threshold awal usulan 30%/15% perlu diselaraskan dengan peringatan gameplay yang sudah ada. | Interpolasi 100–150 ms; tidak berulang tiap sync | P2 |
| Altimeter dan kecepatan | Haluskan isi progress bar; altitude/kecepatan tetap menunjukkan data terbaru dan digit tidak bergoyang. Aksen sekali saat ganti bioma setiap 2.000 km. Turun-naik di batas yang sama tidak mengulang reward. | Bar 100–150 ms; aksen milestone 400–600 ms | P2 |
| Tiba di Istana Awan | Setelah server mengonfirmasi kemenangan/kredit, tampil kartu singkat, sinar halus dan burst bintang/awan kecil. Area gerak dan kontrol tetap tersedia; tidak menunggu animasi untuk menyimpan reward. | Sekitar 1–1,5 s; satu kali per flight | P3 |
| Kilau dekoratif | Sheen/bintang kecil hanya pada satu elemen yang relevan (mis. milestone atau item baru), berhenti saat tidak terlihat. HUD biasa tetap tenang. | Event-driven terlebih dahulu; loop dekoratif belum diperlukan | P3 |

P1 didahulukan sebagai satu vertical slice kecil: TOKO/SETELAN + tombol lompat. Setelah lolos phone/tablet, perluas perilaku ke keluarga tombol dan popup lainnya. P2 menguatkan feedback gameplay. P3 menambah presentasi pencapaian setelah fondasi stabil.

## Aturan layout, state dan aksesibilitas

- Root hitbox dan slot yang diatur `HUDLayout` tetap diam, minimal 44×44. Motion berada di child visual terpusat yang mencakup image frame, ikon dan teks. Hover tidak menggeser tombol tetangga. Jangan men-scale seluruh HUD untuk animasi satu tombol.
- Child visual memerlukan ruang aman untuk overshoot; jaga safe area, caption, key hint, clipping dan batas popup. Phone portrait/landscape, tablet/iPad landscape serta desktop diuji terpisah. Kontrol analog native tidak diubah.
- Teks tetap tajam dan posisinya konsisten. Angka/timer/harga tidak dibakar ke gambar dan tidak diberi bounce berulang. Preferred text size dan string panjang harus tetap muat.
- Tekan-tahan tambal lubang/perbaiki tali tetap memakai prompt native. Tidak menambah custom hold bar/prompt kedua. Aksi tap tali/pilot memakai custom yang sudah ada.
- Default: visual diam. Hover/focus: aksen tipis. Pressed: visual tertekan. Locked: sprite/tint/label alasan jelas, tanpa efek sukses. Loading gambar: satu fallback sampai image siap, tanpa pop ganda. Empty: stok kit 0/inventaris kosong dibaca jelas. Error/penolakan: pesan singkat yang bisa dibaca, tanpa burst sukses.
- Closing/opening cepat, hide karena role berubah, death/respawn, orientasi berubah dan focus lost membatalkan motion lama serta mengembalikan visual ke state final yang benar. Saat modal menutup, kontrol di bawah tidak menerima tap yang sama.
- Usulan Setelan `Kurangi animasi`: meniadakan overshoot, partikel dan gerak perpindahan; mempertahankan warna, teks, progress serta fade singkat. Durasi timer dan jendela perbaikan tidak berubah. Persistensi preferensi ini adalah lingkup terpisah bila nanti disetujui.
- Tidak memakai flash layar putih seperti reward besar referensi untuk damage/reload, shake kamera, kedipan cepat atau audio klik setiap peluru. SFX UI opsional, pelan, punya throttle dan jalur volume tersendiri dari warning bahaya.

## Rencana perubahan kode saat disetujui

1. **Bandingkan Studio–mirror–HEAD terlebih dahulu.** Snapshot analisis ini tidak memberi izin menimpa source live yang berbeda. Baca editor source dan properti aktual sebelum patch.
2. Tambah ModuleScript `ReplicatedStorage.FlyHigh.Modules.HUDMotion` untuk preset, bind/unbind, pembatalan tween per elemen/properti, show/hide token dan cleanup. Efek bersifat client-only; tidak mengirim remote hanya untuk animasi.
3. Pisahkan root input/layout dari child presentasi di `HUDTheme`/`HUDAdventureArt`. Theme tetap menentukan sprite, tint, teks dan geometri dasar; motion memiliki UIScale/offset/opacity child yang berbeda. Hindari `Step()` menulis balik properti yang sedang dianimasikan. Rekonsiliasi ulang ketika ukuran/aset berubah, bukan membuat ulang visual setiap frame.
4. Hubungkan hover/focus/press/release/cancel pada binding yang sudah ada. Gunakan satu alur aktivasi gameplay yang sekarang; jangan menambah callback tembak/lompat baru. Hubungkan state panel di `ShopClientController` dan state flight di `FlightHUDController` untuk efek P2.
5. Ammo/reload mengambil atribut tool yang sudah ada di `WeaponClientController`; jump mengambil izin/cooldown `FlightJumpController`. Sinkronisasi server tetap kebenaran gameplay, animasi hanya presentasi.
6. Nilai health/rope/ammo dibandingkan dengan state sebelumnya. Snapshot pertama/respawn tidak dianggap damage atau reward. Terapkan dedup flight/event ID; cancel animasi lama saat datang update baru. Jika durasi/ID authoritative belum tersedia, tambahkan kontraknya secara eksplisit saat slice terkait, bukan menebak waktu reload atau kemenangan.
7. Semua koneksi/tween/timer berhenti pada destroy/hide/respawn. Partikel UI berupa ImageLabel kecil yang dipool dan tidak menerima input; baseline anggaran usulan maksimal 8 sprite burst dan 2 aksen looping terlihat sekaligus. Bila warning kritis aktif, tunda dekorasi prioritas rendah. Anggaran ini harus diuji, belum klaim performa.

## Aset yang diperlukan

Gunakan ulang sprite tombol lengkap/pressed/locked, panel, progress fill, health pip dan font yang ada. Tambahan opsional setelah P1: satu texture kilau tipis, satu sprite bintang empat sisi dan satu puff awan transparan. Gambar baru hanya dibuat jika reuse atlas tidak memadai; tidak perlu video/GIF untuk menjalankan motion. Source texture/aset baru harus dicatat ID dan ownership-nya, dan tidak ada unggah/pembelian/plugin pihak ketiga pada tahap analisis ini.

## Verifikasi yang harus dilakukan nanti

| Fixture/skenario | Kriteria penerimaan |
| --- | --- |
| Phone portrait/landscape, iPad/tablet landscape, desktop dan gamepad | Frame sebelum/pressed/release menunjukkan hitbox tetap, teks muat, tidak overlap/cutoff; semua aksi tetap bisa dipakai. Simpan resolusi, input dan preferred text size. |
| Tap cepat 20×, hold gas/tembak, drag keluar, focus lost, rotasi | Tidak ada double-activation, stuck pressed, tween saling menimpa, atau kontrol bergeser. |
| Pilot→gunner→engineer, death→respawn dan buka/tutup modal cepat | Kontrol tidak bocor ke role berikutnya; tidak ada instance/koneksi bertambah setelah siklus berulang. |
| Health 5→4→1→0 lalu reparasi; ammo 8/∞ dan 30/∞, reload batal/selesai | Angka aktual segera benar; hanya state yang berubah mendapat feedback. Tidak ada hadiah/reload sukses palsu. |
| Tali turun melewati ambang, beberapa alert beruntun, flight selesai | Tidak spam; countdown tidak tertunda tween; alert lama tidak menutup alert baru. Hold repair tetap satu prompt native. |
| Milestone lewat/turun/lewat lagi; victory dikirim ulang | Tidak menggandakan reward/burst atau menutupi kontrol. |
| Reduce motion, gambar lambat/gagal muat, stok/inventaris kosong, aksi terkunci | Semua state tetap jelas tanpa dekorasi dan tanpa image/fallback double. |
| Perbandingan motion off/on di skenario identik | Rekam frame time dan jumlah instance/koneksi; jangan menyatakan mobile lancar berdasarkan Studio saja. |

Status verifikasi sekarang: analisis frame lokal dan inspeksi source mirror saja. Tidak menjalankan Playtest, tidak mengubah Studio/place, tidak menguji perangkat fisik, dan tidak commit/push pada tugas ini. Saat implementasi, simpan build, fixture, screenshot/rekaman, log aktual dan cleanup mengikuti [WORKFLOW](../../../docs/WORKFLOW.md).
