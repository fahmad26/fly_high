# Review visual rintangan — 15 November 2026

Status: inspeksi dan proposal; **tidak mengimplementasikan perbaikan aset**. [Daftar 20 entri dan proposal](../../design/features/obstacle-visual-polish/proposal.md).

Baseline Git `969892d`, working tree memuat pekerjaan dokumentasi/ikon Daily Login sebelumnya. Tiga source Studio diperiksa dengan GetEditorSource dan dibandingkan isi mirror setelah CRLF→LF/trimEnd: ObstacleArt, ObstacleManager, LargeChallengeManager sama. Ini bukan bukti parity seluruh place. [Manifest build](build.json).

Lingkungan Windows Studio Play Solo, satu klien. Fixture hanya membuat klona model yang sudah ada dalam folder runtime QA_ObstacleVisualAudit di `(5000,100,5000)`; helper tidak mengubah source produksi. Musuh dinormalisasi ke dimensi maksimum 20 stud dan yaw 22 derajat agar bentuk mudah dibandingkan. Skala ini **bukan skala gameplay**. Hazard mempertahankan ukuran builder, dalam keadaan awal builder/warning tanpa lifecycle Manager. Kamera inspeksi dan HUD off sementara; percobaan awal kamera ditimpa kontrol pemain dan tidak dipakai sebagai bukti.

[Log inspeksi mentah](inspection.json) memuat jumlah parts/wedge/mesh, ukuran asli, faktor presentasi dan inventaris template StormCurtain. Semua sembilan musuh pada sampel tidak memiliki MeshPart. Screenshot musuh cukup untuk menilai bentuk statis; bukan animasi gameplay.

| Screenshot | Isi (urut kiri → kanan pada gambar) |
| --- | --- |
| [enemies-1](enemies-1.jpg) | Hailstone, StormBat, WildBird |
| [enemies-2](enemies-2.jpg) | CrystalWyvern, FireBee, GuardianDrone |
| [enemies-3](enemies-3.jpg) | CelestialPhoenix, SatelliteDebris, ShadowPhantom |
| [hazards-1](hazards-1.jpg) | Storm, Tornado |
| [hazards-2](hazards-2.jpg) | Magnetic, Lightning |
| [hazards-3](hazards-3.jpg) | Meteor, Debris |
| [hazards-4](hazards-4.jpg) | Fog, Heat, Wind; kabut tidak terbaca pada capture statis ini |

**Batas:** capture hazard tidak membuktikan rendering partikel/fase aktif lengkap; Fog dan beberapa detail partikel tidak tampak. Rekomendasi VFX juga berasal dari source, bukan klaim seluruh hazard sudah diamati dalam penerbangan. Foto flight historis [phoenix](../obstacle-scale-spawn-and-hull-sfx-2026-11-15/02-playtest-scaled-enemies-phoenix.jpg) dan [flock/meteor](../obstacle-scale-spawn-and-hull-sfx-2026-11-15/03-playtest-flock-spike-meteor-magnetic.jpg) dipakai sebagai konteks, bukan QA baru. StormCurtain/proyektil dinilai melalui template/source, belum capture dekat pada run ini. Belum menilai performa/physical mobile/animasi baru atau memberi persentase kelayakan.

Cleanup: folder fixture dan dua helper _G dihapus, Play Solo dihentikan; kembali Edit, 0 pemain, kamera/default FOV dipulihkan ke snapshot sebelumnya. Place tidak disimpan ulang atau diubah aset/source produksinya pada review ini. Tidak commit/push.
