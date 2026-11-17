# Fly High

Game Roblox kooperatif untuk 1–3 pemain. Kru menerbangkan balon, menembak rintangan, memperbaiki kubah, dan mencapai Istana Awan di 10.000 km.

## Mulai bekerja

| Dokumen | Fungsi |
| --- | --- |
| [HANDOVER](HANDOVER.md) | Keadaan lokal, arsitektur dan sumber kode |
| [PROGRESS](PROGRESS.md) | Progres fitur, temuan terbuka dan bukti QA |
| [PRD](PRD_Fly_High.md) | Aturan produk dan desain yang disetujui |
| [WORKFLOW](docs/WORKFLOW.md) | Aturan sinkronisasi Studio–mirror–Git dan pencatatan QA |
| [Scenery](design/SCENERY.md) | Inventaris kelima bioma dan status pemolesan |
| [Katalog HUD aktif](assets/ui/sky-adventure/README.md) | Gambar Sky Adventure, atlas dan ID Roblox |
| [Lokalisasi](assets/localization/README.md) | Katalog bahasa, proses build dan status Dashboard |
| [Game details](assets/marketing/cloud-palace/GAME_DETAILS.md) | Draft deskripsi English untuk Creator Dashboard |
| [Indeks riwayat](docs/ARCHIVE.md) | Laporan lama dan peta penggabungan dokumen |

## Snapshot 18 November 2026

- Place kerja adalah Fly High.rbxl. Source mirror berada di audit/sources/. Sinkronisasinya manual.
- Rintangan lingkungan dimulai dari 300 km. Lima bioma berganti setiap 2.000 km.
- HUD aktif memakai Sky Adventure. Kontrol sentuh lokal terbaru memakai Dynamic Thumbstick native.
- Pengali kemudi horizontal mengikuti kru hidup, yaitu 1× / 0,75× / 0,6× untuk 1 / 2 / 3 pemain.
- Lokalisasi lokal berisi 500 teks/59 format. Prompt touch diperbesar sedikit; layout keyboard dipertahankan. [QA terarah dan batasnya](audit/localization-touch-2026-11-18/README.md).
- Checkpoint terbaru mencocokkan 64 source Studio dan binary lokal dengan mirror. File tersimpan belum dibuka ulang; kecocokan source tidak membuktikan semua objek/properti place sama.
- Implementasi terbaru tersimpan di Cloud v44 tanpa Publish. Impor manual tabel bahasa Dashboard, QA iPad fisik/teks Large dan mixed-language clients masih terbuka. Transaksi Robux nyata dan persistensi cloud belum diuji.

Status pengujian mengikuti entri PROGRESS dan versi build pada buktinya. Hasil audit historis tersimpan di audit/.
