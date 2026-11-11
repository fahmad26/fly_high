# Regresi perjalanan dan kedatangan — 11 November 2026

Build dasar 8e02af0 dengan perubahan lokal reparasi, dermaga dan prediksi rintangan. [Hash mirror](mirror-hashes.json) serta [perbandingan Studio](studio-mirror-comparison.json) merekam 41/41 source identik setelah normalisasi CRLF/LF akhir, dan kompilasi lulus. Identitas lengkap ada di [build](build.json).

## Hasil perjalanan: belum lulus

[Run enam klien](continuous-results.json), 10:52:49–11:13:01 UTC (Asia/Jakarta +7), menjalankan solo/duo/trio secara bersamaan selama 1.212 detik. Altitude memakai integrasi produksi, spawning rintangan dan badai tetap aktif, tanpa shield, warp altitude atau perubahan kecepatan. Penempatan awal karakter, walking goals, virtual WASD, aim bot dan pemanggilan Begin/Finish reparasi adalah fixture. Ini bukan pengukuran kemampuan manusia atau perangkat fisik.

| Tim | Hasil aktual | Interpretasi |
| --- | --- | --- |
| Solo | Berhenti di 1.938,60 km, satu reparasi, climb timeout; karakter berada jauh dari stasiun | Driver virtual-key tidak melepas WASD setelah keluar dari helm. Belum menjadi bukti bug katrol produksi. |
| Duo | 8.283,14 km pada timeout 1.150 detik per tim; 149 reparasi, 21 respons dodge | Run belum mencapai puncak. Beban ancaman terhadap bot tinggi; belum cukup untuk mengubah balancing bagi pemain manusia. |
| Trio | Lima lubang dan jatuh hingga 0 km; 21 reparasi; sampel sebelumnya mencatat 4.418,49 km | Game Over riil. Error pose setelah freefall adalah driver yang mencoba reparasi pada penerbangan yang telah gagal; bukan bukti kegagalan teleport biasa. |

Tidak ada kemenangan alami pada run ini. Antrean/landing dari run terpisah tidak mengubah status perjalanan menjadi hijau. Sampel 30 detik menyimpan ketinggian aktual, jumlah lubang dan reparasi. Level health 1/5 serta freefall tercapai secara alami pada trio. [Regresi kritis terdahulu](../docks-critical-health-2026-11-11/README.md) tetap merupakan bukti terkontrol sembilan musuh × gas on/off, bukan pengganti perjalanan ini.

[Percobaan pertama](attempt1.json) gagal pada departure lane: pengiriman remote driver bertabrakan dengan input HUD produksi. Driver diganti virtual WASD pada run kedua. Source fixture keduanya disimpan: attempt1.server/client, server/client. client-fixed-keys merupakan koreksi driver untuk run mendatang; perjalanan penuh dengan koreksi itu belum dijalankan. Tidak ada pengurangan validasi gameplay agar bot lulus.

## Regresi lima klien: lulus 47/47

[Hasil](focused-results.json), 11:13:18–11:14:26 UTC: lima summon, okupansi dermaga yang sama, rekor mati 200/1.000/4.000 km, all-dead failure, kedatangan empat balon FIFO, invulnerability, revive anggota mati, puncak tepat sekali, overhead dan destroy balon lulus. Nol runtime error server.

Fixture memakai manager launch/boarding, altitude warp dan shield. Ini bukan lima penerbangan alami atau pengujian ProximityPrompt semua dermaga. Source: [driver lima klien](focused-five-clients.server.luau).

## Temuan texture dan perbaikannya

Run perjalanan mencatat warning texture 72109765799973. [Audit perubahan](water-texture-fix.json) menemukan 17 Beam air terjun Istana Awan yang memakainya. Pada 11:06:29 UTC di sesi Edit, texture diganti ke bawaan rbxasset://textures/particles/smoke_main.dds yang berhasil di-preload. Perubahan Edit tidak memengaruhi clone run perjalanan yang sudah berjalan. Geometri, damage dan source gameplay tetap sama. [Screenshot Edit sesudah perbaikan](palace-texture.jpg) bukan screenshot perjalanan/landing.

Pemeriksaan input driver dan log solo pascaperbaikan dicatat di driver-key-results.json. Hasil run penuh tetap gagal walaupun regresi terarah lulus.

## Sisa pekerjaan

- Ulangi perjalanan dengan driver yang melepas key saat keluar helm, serta berhenti melakukan aksi setelah Game Over/Victory.
- Uji manusia solo/duo/trio untuk membedakan tekanan rintangan dari keterbatasan aim/repair bot sebelum mengubah frekuensi atau damage.
- Latency/jitter, perangkat fisik dan kenyamanan visual tetap terbuka; tidak ada klaim QA mobile/internet publik.
- Place disimpan lokal setelah cleanup. Isi binary belum diverifikasi dengan membuka ulang; commit/push dilaporkan terpisah melalui Git.
