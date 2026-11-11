# Knowledge dan skill development Fly High

Diperiksa 11 November 2026. Dokumen ini adalah referensi kerja; aturan produk tetap di [PRD](../../PRD_Fly_High.md), bukti/status fitur di [PROGRESS](../../PROGRESS.md), dan gerbang sinkronisasi di [WORKFLOW](../WORKFLOW.md).

| Dokumen | Isi |
| --- | --- |
| [SKILLS](SKILLS.md) | Skill yang dipasang, pemilihan sesuai tugas, dan salinan sumber |
| [KNOWLEDGE](KNOWLEDGE.md) | Dasar Lua/Luau, Roblox, fisika, UI, data, keamanan dan performa |
| [CHECKLIST](CHECKLIST.md) | Prosedur kerja dan QA agar kesalahan lama tidak berulang |
| [SECURITY_REVIEW](SECURITY_REVIEW.md) | Ruang lingkup audit, temuan, versi commit dan batas kepercayaan |

Hasil: **5 skill baru dipasang**, **32 skill Roblox lokal terinventarisasi**. Arsip menyimpan 23 skill EL4CTEO beserta referensinya dan tujuh kandidat AshExplained; hanya lima kandidat baru yang diaktifkan melalui instalasi. Dua lainnya adalah bahan pembanding.

Skill baru tersedia pada turn berikutnya setelah katalog skill aplikasi dimuat ulang. Pemasangan membuat skill tersedia; bukan perintah untuk menjalankan seluruh skill.

Bukti mesin:

- [Manifest arsip dan SHA-256](skills-manifest.json).
- [Verifikasi instalasi](installation-results.json).
- [Inventaris skill lokal](local-skill-inventory.json).
- [Pencarian pola sensitif](security-scan.json), yang mencakup false positive dari contoh keamanan.
- [Metadata sumber](repository-inventory.json).
- [Verifikasi akhir](verification.json): 56 file cocok dengan blob Git/SHA-256, lima instalasi cocok, 82 tautan lokal valid. [Pemeriksa lokal](verify_snapshot.py) dapat dijalankan ulang untuk integritas file, bukan untuk menjamin keamanan semantik.

Folder skills/ adalah arsip Markdown dengan lisensi MIT dari masing-masing sumber. Jangan menganggap semua file dalam arsip sebagai instruksi aktif. Clone audit tidak di-checkout dan setup/installer milik upstream tidak dijalankan.
