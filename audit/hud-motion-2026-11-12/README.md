# Motion HUD — 12 November 2026

Implementasi langsung Studio tanpa Figma, tanpa mengganti gambar/font Sky Adventure. [Desain disetujui](../../design/features/hud-motion/design.md). Basis `94591f0`; [build/hash source dan place](build.json) mencatat dirty state. Belum commit/push tugas motion ini.

## Implementasi

- HUDMotion terpisah dari input/gameplay. Root tombol dan ukuran target sentuh tetap; presentasi anak tombol mengecil saat ditekan, pulih dengan easing, serta mendapat hover/focus desktop/gamepad.
- Popup Toko/Setelan/Ping memakai fade dan scale masuk, fade keluar serta token/cancel saat dibuka ulang. Scrim mempertahankan blok input selama penutupan.
- HUDLayout merestorasi geometri dasar sebelum theme/layout, lalu mengambil snapshot baru. Render motion memakai snapshot tersebut, tidak mengalikan scale berulang. Penulisan ukuran bar dari controller dideteksi supaya interpolasi tidak menghapus target terbaru.
- Isi altitude/tali dihaluskan; angka tetap data aktual. Segmen health yang berubah mendapat pulse; ammo/reload mendapat pulse singkat dengan throttle. Ambang tali memakai config warning yang sudah ada.
- Bioma naik setiap 2.000 km dan victory mendapat notice singkat/burst maksimal delapan bintang; dekorasi berhenti pada Reduce Motion dan disembunyikan saat modal/banner aktif. Milestone didedup pada ketinggian tertinggi sesi flight; reward tetap server-owned.
- Setelan menyediakan `Animasi: Penuh/Ringan` berdampingan dengan preferensi nama pemain. Ini preferensi lokal sesi, belum persistensi cloud. Caption footer dipersingkat saat flight; navy inset popup diberi ruang aman.
- Native hold repair tidak diubah. Tidak menambah UI hold, efek kamera atau suara baru.

## QA dan bukti

Native Studio satu klien, unpublished mock; simulasi iPhone 17 Pro landscape (viewport 749×381), iPad Pro M5 13in (1375×1030). Portrait 400×776 dipaksa sebagai stress tambahan; game tetap LandscapeSensor. Desktop/default juga diperiksa. Ini bukan perangkat fisik atau benchmark mobile.

| Run | Hasil aktual |
| --- | --- |
| [Runtime regression](runtime-results.json), [fixture](runtime.client.luau) | 9/9: buka, opacity selesai, tutup, reopen cepat 20×, root tetap, reduce flag, instance stabil 10 siklus, target bar tidak hilang, tidak mengubah status flight. Fixture mengubah presentasi bar/health, bukan gameplay. |
| [Presentation/cleanup](presentation-results.json), [fixture](presentation.client.luau) | 5/5: notice terlihat, burst delapan, reduce menyembunyikan bintang, expiry, destroy membersihkan record. Assert menunggu deferred Destroying. |
| [Senjata](weapon-results.json), [fixture launch](flight.server.luau) | Gamepad R2: pistol 8→7. Gamepad X: kembali 8/∞, Reloading=false. Mouse click pada simulator tidak menurunkan ammo; tidak dihitung lulus input sentuh. |
| Damage fixture | Manager ApplyPuncture SelfShot empat kali dengan invulnerability direset menghasilkan holes=4, tampilan 1/5. Tidak dianggap uji balancing/serangan alami. |
| [Kompilasi/source](source-comparison.json) | 42 source lolos loadstring; lima source baru/diubah sama persis dengan mirror. Awal pekerjaan: 41 source cocok panjang/hash rolling normalisasi; bukan klaim seluruh binary sama. |
| [Konsol final](console.json) | Hanya pemberitahuan isolated mock; tidak ada error runtime atau warning aset pada run final. |

Screenshot: [Setelan phone](phone-settings.png), [flight phone](phone-flight.png), [flight iPad](ipad-flight.png), [portrait stress](phone-forced-portrait.png). Gambar diperiksa visual; angka timeout >60 pada screenshot flight berasal dari fixture `groundedSince` masa depan agar tidak mati AFK. Screenshot sebelum guard callback cleanup terakhir; guard tersebut tidak mengubah tampilan. Screenshot statis bukan bukti easing/timing; hasil runtime melengkapi bukti state.

Percobaan awal tidak dihitung lulus: setter orientation sebelum device aktif ditolak; _G pada command sandbox tidak mengakses runtime manager; PlayerScripts tidak ada pada server. Fixture kemudian dipasang runtime lewat PlayerGui. Memanggil require/Start dari command sandbox membuat konteks pengujian berbeda, sehingga hasil alpha dari metode itu tidak dipakai. Run final memakai LocalScript runtime dan opacitySettled=true. Assert cleanup awal tanpa jeda deferred signal false; guard bind sesudah state.dead ditambahkan, kemudian 14/14 pemeriksaan diulang lulus.

Cleanup: [Edit/default viewport, fixture runtime hilang](cleanup.json). Tidak mengubah setting multi-client; native Play dijalankan satu klien. Place disimpan lokal, belum dibuka ulang untuk membandingkan binary. Test mode/jumlah pemain dari sesi sebelumnya tidak diubah; tidak menjalankan test tiga pemain.

## Batas dan QA tersisa

- Input sentuh fisik, kenyamanan/performa, rapid orientation saat hold, respawn berulang dan latensi masih perlu diuji. Tidak mengklaim FPS mobile atau full journey.
- Milestone/victory notice diuji sebagai presentasi atribut; kedatangan alami, dedup remote victory berulang dan transisi role penuh belum diuji ulang.
- Health/tali mendapat pulse, belum flash/kilau khusus atau loop kritis. Reload memakai status tool dan label yang ada, belum indikator progress waktu authoritative. SFX UI dan sheen dekoratif tetap opsional, belum dipasang.
- Pilihan nama pemain tetap menyimpan preferensi sesuai mekanik lama; Reduce Motion hanya sesi. Harga/receipt/weapon gameplay tidak diubah.
