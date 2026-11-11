# Progres Fly High

Diperbarui 11 November 2026, Asia/Jakarta. Status mengacu pada workspace lokal. Implementasi dan QA dicatat terpisah.

## Definisi status

- **Terpasang** berarti kode/model tersedia di implementasi lokal.
- **QA historis** berarti ada bukti tersimpan untuk build lama, dengan cakupan dan tanggalnya sendiri.
- **Dilaporkan di sesi** berarti hasil diamati dalam percakapan pengerjaan, tetapi log mentah/screenshot lengkap belum diekspor.
- **Terbuka** berarti perlu investigasi atau pengujian lanjutan.
- **Ditunda pengguna** berarti menunggu instruksi pengguna.
- **Selesai terverifikasi** berarti kriteria penerimaan terpenuhi pada build yang dicatat, dengan bukti tersimpan sesuai WORKFLOW.

## Daftar fitur

Checkpoint tambahan 11 November: [perbaikan penerbangan/kemenangan tim](design/features/flight-arrival/design.md) terpasang. [Run lima klien](audit/flight-fixes-2026-11-11-results.json) lulus 47 pemeriksaan terkontrol, termasuk lima dermaga, rekor per anggota, empat kedatangan FIFO, revive anggota mati, kredit puncak tepat sekali dan overhead. [Percobaan delapan klien](audit/flight-fixes-2026-11-11-attempt1.json) gagal pada kesiapan pemain, bukan dihapus dari riwayat. [Screenshot tata letak](audit/flight-fixes-2026-11-11-docks.jpg) merekam posisi dermaga sesudah direnggangkan. Uji memakai warp, pemanggilan manager/boarding dari driver dan shield; bukan perjalanan penuh atau pengujian jaringan/perangkat fisik. Gerak naik diperiksa dua detik tanpa lompatan balik pada server; rasa jitter visual masih memerlukan review perangkat fisik. Driver telah dihapus dari place, jumlah test dipulihkan satu pemain.

| ID | Fitur | Implementasi lokal | Bukti dan batas QA | Berikutnya |
| --- | --- | --- | --- | --- |
| GAME-01 | Tim 1–3, lima dermaga, boarding dan akses tim | Terpasang; layout direnggangkan 11 November | [Run lima klien](audit/flight-fixes-2026-11-11-results.json): kelima dermaga launch, dermaga terisi tetap diblokir | Regresi interaksi manual dan scenery lobby |
| GAME-02 | Lima lubang, freefall, Clutch Save, timeout daratan | Terpasang | [flight-controls-results](audit/flight-controls-results.json), [ending fixtures](audit/full-journey-summary.json), QA historis | Uji penerbangan terbaru |
| GAME-03 | Role eksklusif dan gas otomatis khusus pilot | Terpasang | [rigging-flow-results](audit/rigging-flow-results.json), QA historis | Regresi pergantian role |
| GAME-04 | Tali, katrol, tambal, rescue dan putus tali | Terpasang | [rescue-comfort-results](audit/rescue-comfort-results.json), QA historis | OPEN-01 |
| GAME-05 | Senjata, kamera FPS, reload dan peluru | Terpasang | [weapon-bamboo-results](audit/weapon-bamboo-results.json), [flying-bullet-results](audit/flying-bullet-results.json), QA historis | Regresi manual mobile |
| GAME-06 | Rintangan mulai 300 km, sembilan band dan wave | Terpasang | [Desain gerak](design/features/obstacle-motion/design.md) melaporkan uji terkontrol. Hasil belum diikat ke hash build pada laporan tersebut. | Simpan QA band berikut |
| GAME-07 | Dinding Badai dan loncatan kru | Terpasang | [storm-jump-results](audit/storm-jump-results.json), QA historis | OPEN-02 |
| GAME-08 | Kemudi mengikuti kru hidup, 1× / 0,75× / 0,6× | Terpasang, commit 4765f45 | Dilaporkan di sesi 11 November. Tiga klien, empat arah, dua kematian, sekitar 18 / 22,5 / 30 stud/detik. Log mentah belum diekspor. | Simpan regresi berikutnya |
| GAME-09 | Antrean istana, kemenangan tim dan rekor pribadi | Terpasang; disertakan dalam paket commit perbaikan penerbangan | [47 pemeriksaan](audit/flight-fixes-2026-11-11-results.json) lulus pada fixture lima klien, [identitas build](audit/flight-fixes-2026-11-11-build.json) | Arrival manual, disconnect dan jaringan/perangkat fisik |
| INPUT-01 | Analog native dan kompatibilitas PlayerModule | Terpasang; baseline awal sebelum commit | Dilaporkan di sesi 11 November. Simulator iPad Pro M5 dan iPhone 17 Pro landscape, empat arah, input 0,625, kamera 180°, release ke nol dan lepas kemudi. | Uji perangkat fisik |
| UI-01 | HUD Sky Adventure dan layout | Terpasang | [Katalog aktif](assets/ui/sky-adventure/README.md) mencatat QA 7 November dengan fixture presentasi | Regresi layout setelah edit |
| UI-02 | Setelan dua rak dan hide/show overhead | Terpasang | Source dan PRD. Bukti E2E terbaru belum diindeks. | Uji sebelum summon dan selama flight |
| WORLD-01 | Pulau awal, laut, fauna dan lima armada | Terpasang | [fleet-results](audit/fleet-results.json), QA historis | Review visual manusia |
| WORLD-02 | Lima bioma dan polesan landmark | Terpasang, commit 4765f45 | [Inventaris scenery](design/SCENERY.md) membedakan screenshot awal dan hasil sesi lanjutan | QA final dan performa mobile |
| WORLD-03 | Istana, air terjun, sofa, ayunan, cloud walk dan barrier | Terpasang | Dilaporkan di sesi. Belum ada satu regresi geometri terkini yang mencakup seluruh polesan plaza. | Audit collision, posisi dan arrival |
| DATA-01 | Receipt, kit dan AK-47 permanen | Terpasang | [product-results](audit/product-results.json) memakai mock | DEFER-01 |
| QA-01 | Perjalanan penuh solo/duo/trio | QA historis dengan temuan terbuka | [full-journey-summary](audit/full-journey-summary.json), suite seluruhnya hijau masih false | OPEN-01 dan run build baru |
| DOC-01 | Konsolidasi dokumentasi dan baseline source | Selesai terverifikasi untuk inspeksi dokumentasi | [Baseline 11 November](audit/documentation-baseline-2026-11-11.json), 40 source cocok dan dua berbeda dari HEAD | Ulangi setelah source/save berubah |

## Temuan terbuka

| ID | Temuan | Syarat penutupan |
| --- | --- | --- |
| OPEN-01 / COOP-LATERAL-POSITION | Manuver horizontal cepat dapat menyebabkan beda jarak repair client/server lalu Hanging. | Reproduksi duo/trio pada build terbaru, ukur kedua sisi, uji perbaikan dengan validator produksi. |
| OPEN-02 / JUMP-ROLE-FIXTURE | Fixture anchored pernah menerima Activated client setelah ganti role tetapi counter server tidak bertambah. | Reproduksi dengan role/gas/ownership/balon bergerak. Pisahkan kegagalan fixture dan bug produksi. |
| OPEN-03 / SCENERY-EVIDENCE | Laporan pasca-handover lama menyebut 1.850 km, handover lama 1.900 km. Bukti belum menetapkan satu nilai benar. | Simpan sebagai konflik historis. Run baru harus mencatat altitude target dan aktual, screenshot, log dan build. |
| OPEN-04 / RELEASE-QA | Perangkat fisik, internet publik, performa ramai dan kenyamanan manusia belum terverifikasi pada build terbaru. | Uji dengan lingkungan serta build yang dicatat. |
| DEFER-01 | Publikasi experience, Robux nyata dan persistensi cloud ditunda pengguna. | Instruksi pengguna untuk melanjutkan, kemudian uji di universe yang sesuai. |

## Riwayat checkpoint

| Tanggal | Checkpoint | Status versi dan bukti |
| --- | --- | --- |
| 31 Oktober 2026 | Perjalanan penuh dan focused ending fixtures | JSON historis. Temuan lateral tetap terbuka. |
| 7 November 2026 | HUD Sky Adventure | Katalog aset mencatat hasil simulator. |
| 10 November 2026 | Scenery pass awal | Lima screenshot tersimpan, diikuti polesan tambahan. |
| 11 November 2026 | Commit 4765f45 | Scenery dan pengali kemudi dipush menurut sesi sebelumnya. |
| 11 November 2026 | Analog native | Dua mirror dan place lokal berubah setelah commit tersebut. |
| 11 November 2026 | Konsolidasi dokumentasi | Inspeksi 40 source. Tidak ada Playtest gameplay baru. |

Ubah baris fitur yang sama setelah pekerjaan. Catat tanggal, versi kode, bukti yang dapat dibuka, perangkat dan penggunaan fixture. Pisahkan status save/commit/push/QA. Standar ada di [WORKFLOW](docs/WORKFLOW.md).
