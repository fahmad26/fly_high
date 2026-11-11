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
| GAME-01 | Tim 1–3, lima dermaga, boarding dan akses tim | Terpasang; layout busur dan jalur tersambung | [Regresi terbaru](audit/journey-regression-2026-11-11/README.md): lima klien dan lima summon lulus; manager launch/boarding, bukan lima penerbangan alami. | Regresi manual lima tim |
| GAME-02 | Lima lubang, freefall, Clutch Save, timeout daratan | Terpasang | [flight-controls-results](audit/flight-controls-results.json), [ending fixtures](audit/full-journey-summary.json), QA historis | Uji penerbangan terbaru |
| GAME-03 | Role eksklusif dan gas otomatis khusus pilot | Terpasang | [rigging-flow-results](audit/rigging-flow-results.json), QA historis | Regresi pergantian role |
| GAME-04 | Tali, katrol, tambal, rescue dan putus tali | Perbaikan hold, input native dan pemulihan katrol terpasang lokal | [QA reparasi 11 November](audit/repair-motion-2026-11-11/README.md): trio 40/40 dan solo native 11/11 lulus. Uji terkontrol, bukan penerbangan penuh. | OPEN-01: latency/perangkat fisik |
| GAME-05 | Senjata, kamera FPS, reload dan peluru | Terpasang | [weapon-bamboo-results](audit/weapon-bamboo-results.json), [flying-bullet-results](audit/flying-bullet-results.json), QA historis | Regresi manual mobile |
| GAME-06 | Rintangan mulai 300 km, sembilan band dan wave | Terpasang; prediksi vertikal aktual untuk balon turun | [QA health 1/5](audit/docks-critical-health-2026-11-11/README.md): 18 kombinasi musuh/gas memberi damage pada empat lubang; safe zone dan balon sehat lolos. | Perjalanan penuh, wave alami dan hazard berperingatan |
| GAME-07 | Dinding Badai dan loncatan kru | Terpasang; buffer tap 0,2 detik menunggu lantai valid | [Regresi role trio](audit/repair-motion-2026-11-11/repair-motion-trio-final-pass-2026-11-11.json) lulus; pilot tetap dilarang loncat | Uji sentuh/gamepad dan badai pada perjalanan penuh |
| GAME-08 | Kemudi mengikuti kru hidup, 1× / 0,75× / 0,6× | Terpasang, commit 4765f45 | Dilaporkan di sesi 11 November. Tiga klien, empat arah, dua kematian, sekitar 18 / 22,5 / 30 stud/detik. Log mentah belum diekspor. | Simpan regresi berikutnya |
| GAME-09 | Antrean istana, kemenangan tim dan rekor pribadi | Terpasang | [47/47 pemeriksaan terbaru](audit/journey-regression-2026-11-11/focused-results.json): lima klien, rekor mati, FIFO, revive, kredit tepat sekali dan cleanup. Warp/shield; bukan arrival dari perjalanan penuh. | Arrival manual, disconnect dan jaringan/perangkat fisik |
| INPUT-01 | Analog native dan kompatibilitas PlayerModule | Terpasang; baseline awal sebelum commit | Dilaporkan di sesi 11 November. Simulator iPad Pro M5 dan iPhone 17 Pro landscape, empat arah, input 0,625, kamera 180°, release ke nol dan lepas kemudi. | Uji perangkat fisik |
| UI-01 | HUD Sky Adventure dan layout | Terpasang | [Katalog aktif](assets/ui/sky-adventure/README.md) mencatat QA 7 November dengan fixture presentasi | Regresi layout setelah edit |
| UI-02 | Setelan dua rak dan hide/show overhead | Terpasang | Source dan PRD. Bukti E2E terbaru belum diindeks. | Uji sebelum summon dan selama flight |
| WORLD-01 | Pulau awal, laut, fauna dan lima armada | Terpasang | [fleet-results](audit/fleet-results.json), QA historis | Review visual manusia |
| WORLD-02 | Lima bioma dan polesan landmark | Terpasang, commit 4765f45 | [Inventaris scenery](design/SCENERY.md) membedakan screenshot awal dan hasil sesi lanjutan | QA final dan performa mobile |
| WORLD-03 | Istana, air terjun, sofa, ayunan, cloud walk dan barrier | Terpasang; 17 Beam memakai texture bawaan yang valid | [QA texture](audit/journey-regression-2026-11-11/README.md): preload dan screenshot Edit; solo pascaperbaikan bersih dari warning/error klien. Belum mencakup seluruh geometri plaza. | Audit collision dan posisi |
| DATA-01 | Receipt, kit dan AK-47 permanen | Terpasang | [product-results](audit/product-results.json) memakai mock | DEFER-01 |
| QA-01 | Perjalanan penuh solo/duo/trio | Run terbaru belum lulus | [Run 1.212 detik](audit/journey-regression-2026-11-11/README.md): solo fixture climb timeout 1.939 km, trio lima lubang/jatuh, duo timeout 8.283 km (149 reparasi). Regresi driver key-release 11/11 lulus terpisah. | OPEN-05; ulangi driver terkoreksi dan uji manusia sebelum tuning |
| DOC-01 | Konsolidasi dokumentasi dan baseline source | Selesai terverifikasi untuk inspeksi dokumentasi | [Baseline 11 November](audit/documentation-baseline-2026-11-11.json), 40 source cocok dan dua berbeda dari HEAD | Ulangi setelah source/save berubah |

## Temuan terbuka

| ID | Temuan | Syarat penutupan |
| --- | --- | --- |
| OPEN-01 / COOP-LATERAL-POSITION | Perbaikan input hold dan recovery katrol sudah lulus uji lokal bergerak; akar seluruh kasus desync publik belum terbukti selesai. | Lanjutkan latency/jitter, perangkat fisik, avatar lain dan perjalanan penuh. Jarak validasi akhir tetap 10 stud. |
| OPEN-03 / SCENERY-EVIDENCE | Laporan pasca-handover lama menyebut 1.850 km, handover lama 1.900 km. Bukti belum menetapkan satu nilai benar. | Simpan sebagai konflik historis. Run baru harus mencatat altitude target dan aktual, screenshot, log dan build. |
| OPEN-04 / RELEASE-QA | Perangkat fisik, internet publik, performa ramai dan kenyamanan manusia belum terverifikasi pada build terbaru. | Uji dengan lingkungan serta build yang dicatat. |
| OPEN-05 / JOURNEY-REGRESSION | Run terbaru tidak mencapai puncak alami. Driver solo menahan WASD setelah lepas helm; trio melakukan aksi pose sesudah lima lubang; duo mencapai timeout dengan tekanan reparasi tinggi. | Ulangi perjalanan dengan key-release/terminal guard yang benar. Driver exit-role sudah lulus 11/11 terarah. Uji manusia diperlukan sebelum menyimpulkan balancing terlalu sulit. |
| DEFER-01 | Publikasi experience, Robux nyata dan persistensi cloud ditunda pengguna. | Instruksi pengguna untuk melanjutkan, kemudian uji di universe yang sesuai. |

## Riwayat checkpoint

OPEN-02 / JUMP-ROLE-FIXTURE: jalur produksi normal telah diverifikasi pada run trio akhir 11 November, dengan balon tidak di-anchor selama pengukuran loncat. Enam kondisi role diterima server dan pilot tetap diblokir. Anomali fixture anchored lama tetap merupakan bukti historis, bukan alasan melonggarkan validator. Lihat [QA terbaru](audit/repair-motion-2026-11-11/README.md).

| Tanggal | Checkpoint | Status versi dan bukti |
| --- | --- | --- |
| 31 Oktober 2026 | Perjalanan penuh dan focused ending fixtures | JSON historis. Temuan lateral tetap terbuka. |
| 7 November 2026 | HUD Sky Adventure | Katalog aset mencatat hasil simulator. |
| 10 November 2026 | Scenery pass awal | Lima screenshot tersimpan, diikuti polesan tambahan. |
| 11 November 2026 | Commit 4765f45 | Scenery dan pengali kemudi dipush menurut sesi sebelumnya. |
| 11 November 2026 | Analog native | Dua mirror dan place lokal berubah setelah commit tersebut. |
| 11 November 2026 | Konsolidasi dokumentasi | Inspeksi 40 source. Tidak ada Playtest gameplay baru. |
| 11 November 2026 | Perbaikan reparasi dan input role | Tiga source berubah lokal; [QA](audit/repair-motion-2026-11-11/README.md) dan [build](audit/repair-motion-2026-11-11/build.json). Belum commit/push. |

Ubah baris fitur yang sama setelah pekerjaan. Catat tanggal, versi kode, bukti yang dapat dibuka, perangkat dan penggunaan fixture. Pisahkan status save/commit/push/QA. Standar ada di [WORKFLOW](docs/WORKFLOW.md).
