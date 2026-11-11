# Pemilihan skill

Gunakan skill terkecil yang sesuai tugas. Mulai dari spesialis tugas, tambahkan Luau/keamanan/QA hanya ketika memang dibutuhkan. Jangan menjalankan rantai “Next” seluruh paket secara otomatis.

## Lima tambahan yang sudah dipasang

Sumber [AshExplained/roblox-skills](https://github.com/AshExplained/roblox-skills), commit a3a7b940f0899d4a69c1a7df625996bdfc917388. Kelimanya sebelumnya belum ada dalam direktori skill lokal.

| Skill | Kegunaan di Fly High | Salinan yang diaudit |
| --- | --- | --- |
| roblox-debugging-bugfix | Reproduksi bug, hipotesis yang dapat diuji, fix kecil dan regresi | [SKILL](skills/ash/roblox-debugging-bugfix/SKILL.md) |
| roblox-world-level-design | Alur spawn → dermaga, landmark, sightline dan tata ruang bioma | [SKILL](skills/ash/roblox-world-level-design/SKILL.md) |
| roblox-mobile-playtest | Pemeriksaan HUD, touch dan orientasi ponsel/tablet | [SKILL](skills/ash/roblox-mobile-playtest/SKILL.md) |
| roblox-asset-pipeline | Konsistensi skala, warna, impor dan biaya aset | [SKILL](skills/ash/roblox-asset-pipeline/SKILL.md) |
| roblox-creator-store-security-audit | Mencegah backdoor pada model/Toolbox dan paket pihak ketiga | [SKILL](skills/ash/roblox-creator-store-security-audit/SKILL.md) |

Lokasi instalasi: C:/Users/fahma/.codex/skills/<nama-skill>/. Setiap folder baru memuat SKILL.md dan LICENSE. Isi Markdown cocok dengan arsip setelah normalisasi CRLF/LF; hash file aktual tersedia di installation-results.json.

## Skill yang sudah ada dan tetap dipertahankan

| Area | Skill | Prioritas pemakaian |
| --- | --- | --- |
| Bahasa | roblox-luau | Penulisan/refactor Luau, tipe dan lifecycle task |
| Struktur | roblox-architecture | Pemilik state dan lifecycle server/client |
| Replikasi | roblox-networking | Payload remote, sinkronisasi dan bandwidth |
| Keamanan | roblox-security, roblox-code-review | Validator, anti-exploit dan review perubahan |
| Kendaraan | roblox-physics | Balon, constraint, tabrakan, ownership dan raycast |
| Kontrol | roblox-input | Analog native, keyboard, gamepad dan kamera |
| Karakter | roblox-characters-animation | Seat, Tool, respawn, role dan animasi |
| Dunia | roblox-world-building | Terrain, mesh, material, lighting dan efek |
| UI | roblox-game-ux, roblox-ui, roblox-ui-implementation | Desain dahulu, implementasi responsif, lalu QA |
| Aksesibilitas | roblox-localization-accessibility | Teks terbaca, localization dan ikon |
| Feel | roblox-animation-audio-feedback, roblox-audio | Recoil, reload, peringatan dan transisi |
| NPC | roblox-npc-ai | Ayam, navigasi, perilaku dan cleanup |
| Sistem | roblox-game-systems | State gameplay, inventory, senjata dan progression |
| Data | roblox-data-stores | Penyimpanan, concurrency dan session lifecycle |
| Pembelian | roblox-monetization | Receipt, produk dan grant permanen |
| Observasi | roblox-analytics-liveops | Pengukuran funnel dan tuning berbasis data |
| Performa | roblox-performance | CPU/GPU/memori/replikasi dan mobile |
| QA | roblox-testing | Fixture, multi-client dan pengujian sistem |
| Studio | roblox-studio-mcp | Operasi Edit/Server/Client dan bukti visual |
| Toolchain | roblox-tooling | Formatter, type checking dan workflow Git; lihat batas keamanan |
| Cloud | roblox-open-cloud | Otomasi eksternal hanya bila tugas memerlukannya |
| Lintas server | roblox-teleport-matchmaking | Bila arsitektur kemudian membutuhkan multi-place |
| Chat | roblox-text-chat | Chat dan filtering teks pemain |

Arsip 23 skill inti berada di skills/el4cteo/skills/. Empat skill tambahan yang sudah ada sebelumnya berasal dari kategori UX/UI/feel; tidak ditimpa pada tugas ini. Jumlah 32 mencakup lima instalasi baru, bukan 32 skill baru.

## Routing kasus nyata

| Permintaan | Skill utama | Tambahan bila perlu |
| --- | --- | --- |
| Dermaga tidak rapi/jalur tertutup | world-level-design | world-building, physics, testing |
| Balon jitter atau avatar tertinggal | debugging-bugfix | physics, networking, testing |
| HUD iPad overlap | game-ux atau ui | mobile-playtest, localization-accessibility |
| Senjata/auto-aim mobile salah | debugging-bugfix | input, game-systems, security |
| Tambah model dari Toolbox | asset-pipeline | creator-store-security-audit |
| Receipt atau inventory tidak tersimpan | data-stores atau monetization | security, testing |
| Rintangan terlalu sulit/mudah | game-systems | analytics-liveops, testing; amati manusia juga |

## Kandidat yang tidak dipasang

- roblox-playtest-qa: [arsip](skills/ash/roblox-playtest-qa/SKILL.md). Tumpang tindih dengan testing/mobile; juga meminta human approval untuk penutupan roadmap. Tidak dijadikan gerbang tambahan Fly High.
- roblox-economy-balancing: [arsip](skills/ash/roblox-economy-balancing/SKILL.md). Opsional bila ada permintaan perubahan ekonomi; tidak diperlukan untuk perbaikan jalan/fisika saat ini.
- setup-roblox-skills dan router lifecycle paket penuh: tidak dipasang. Mengasumsikan workflow source hanya di cloud dan membuat konfigurasi CLAUDE.md, sedangkan Fly High memiliki mirror source Git dan pemilik dokumen sendiri.
- MSayib/roblox-dev-skill dan justOzy/Roblox-Skills: ditemukan saat pencarian, belum diaudit mendalam, tidak diunduh/dipasang. Cakupannya beririsan dengan fondasi yang tersedia.
- Skill Lua generik: tidak dipasang otomatis. Roblox memakai Luau; tutorial Lua 5.4/5.5 dapat mengajarkan library/syntax yang tidak sesuai sandbox Roblox.

Nama tool dalam panduan pihak ketiga bukan jaminan tool tersedia. set_active_studio tidak ada pada koneksi saat audit ini; pilih instance memakai list_roblox_studios dan teruskan studio_id. Rujukan roblox-performance-optimization dapat dilayani roblox-performance yang sudah ada, setelah memastikan tugasnya sesuai.
