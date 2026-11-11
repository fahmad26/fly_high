# Indeks arsip dan penggabungan dokumentasi

Konsolidasi 11 November 2026. Dokumen aktif dibuka dari [README](../README.md). Materi historis mencatat keadaan build saat ditulis dan tidak otomatis berlaku pada workspace terbaru.

## Peta penggabungan

| Dokumen sebelumnya | Tujuan informasi aktif | Riwayat |
| --- | --- | --- |
| AI_CONTEXT.md dan HANDOVER.md lama | HANDOVER untuk konteks/arsitektur, PROGRESS untuk status | Versi asli tersedia pada commit 4765f45 di bawah |
| AUDIT_REPORT.md | PROGRESS untuk temuan tersisa | Narasi lengkap digabung ke audit/DEVELOPMENT_HISTORY.md |
| audit/HUD_IMAGE_INTEGRATION.md dan audit/HUD_ARCADE_REDESIGN.md | Katalog Sky Adventure untuk aset aktif | Narasi digabung ke DEVELOPMENT_HISTORY |
| design/SCENERY_HANDOVER.md dan design/SCENERY_POST_HANDOVER_REPORT.md | design/SCENERY.md | Laporan pasca-handover digabung ke DEVELOPMENT_HISTORY, handover asli tetap di Git |
| UI_IMAGE_ASSET_PLAN.md | Katalog Sky Adventure dan desain hud-generated-art | Kandidat aset lama tetap tersedia di Git |

## Versi asli yang dapat dipulihkan

Tautan berikut menunjuk commit tetap sebelum konsolidasi.

- [HANDOVER lama](https://github.com/fahmad26/fly_high/blob/4765f4594e8cdf793a25ebb58c4b6c1e40d98a12/HANDOVER.md)
- [AI_CONTEXT lama](https://github.com/fahmad26/fly_high/blob/4765f4594e8cdf793a25ebb58c4b6c1e40d98a12/AI_CONTEXT.md)
- [AUDIT_REPORT lama](https://github.com/fahmad26/fly_high/blob/4765f4594e8cdf793a25ebb58c4b6c1e40d98a12/AUDIT_REPORT.md)
- [SCENERY_HANDOVER lama](https://github.com/fahmad26/fly_high/blob/4765f4594e8cdf793a25ebb58c4b6c1e40d98a12/design/SCENERY_HANDOVER.md)
- [Laporan pasca-handover lama](https://github.com/fahmad26/fly_high/blob/4765f4594e8cdf793a25ebb58c4b6c1e40d98a12/design/SCENERY_POST_HANDOVER_REPORT.md)
- [Rencana aset UI lama](https://github.com/fahmad26/fly_high/blob/4765f4594e8cdf793a25ebb58c4b6c1e40d98a12/UI_IMAGE_ASSET_PLAN.md)

Pemulihan lokal dapat memakai git show dengan commit dan path yang sesuai. Hindari mengembalikan judul status aktif dari dokumen lama tanpa audit.

## Bukti yang dipertahankan

- [Riwayat pengembangan gabungan](../audit/DEVELOPMENT_HISTORY.md)
- [Metodologi dan batas perjalanan penuh 31 Oktober](../audit/FULL_JOURNEY_QA.md)
- [Ringkasan JSON perjalanan penuh](../audit/full-journey-summary.json)
- [Screenshot scenery pass awal](../audit/scenery-polish-2026-11-10/README.md)

File JSON, screenshot, harness dan backup place historis tetap berada di audit/. Katalog paket aset lama tetap disimpan untuk identifikasi fallback dan proses reproduksi. Desain fitur bertanggal menjadi rekaman keputusan, sedangkan status penerapannya mengikuti PROGRESS.
