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
| [Indeks riwayat](docs/ARCHIVE.md) | Laporan lama dan peta penggabungan dokumen |

## Snapshot 11 November 2026

- Place kerja adalah Fly High.rbxl. Source mirror berada di audit/sources/. Sinkronisasinya manual.
- Rintangan lingkungan dimulai dari 300 km. Lima bioma berganti setiap 2.000 km.
- HUD aktif memakai Sky Adventure. Kontrol sentuh lokal terbaru memakai Dynamic Thumbstick native.
- Pengali kemudi horizontal mengikuti kru hidup, yaitu 1× / 0,75× / 0,6× untuk 1 / 2 / 3 pemain.
- Pemeriksaan dokumentasi mencocokkan 40 source Studio dengan mirror. Dua source kontrol analog dan place berbeda dari HEAD.
- Publikasi experience, transaksi Robux nyata dan persistensi cloud ditunda pengguna.

Status pengujian mengikuti entri PROGRESS dan versi build pada buktinya. Hasil audit historis tersimpan di audit/.
