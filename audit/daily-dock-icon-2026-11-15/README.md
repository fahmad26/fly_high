# Ikon Daily Login konsisten dengan HUD — 15 November 2026

## Build dan perubahan

Baseline Git `969892d826627383d70a5a27c1df906958159f6d`, perubahan dokumentasi sebelumnya dipertahankan. [Manifest SHA-256](build.json) mencatat PNG, dua SVG sumber, mirror katalog dan place tersimpan. Satu source produksi berubah: ID `daily_normal` di `HUDAdventureCatalog`, dari `74634924421515` ke `109624962100172`. PNG baru 256×256 RGBA, 30.036 byte. Mirror/katalog aset diperbarui; tidak commit/push.

Figma baru berhasil dipakai: akun `Fikri Ahmad`; session `338471a6-da08-494e-9931-1f4940034888`; konteks node `6:2` terlalu besar (metadata sparse), sehingga panel `6:428` dan glyph `6:439` dibaca terpisah. Panel memberikan konteks detail dan screenshot. Mockup memang berlatar emas; bingkai ikon diadaptasi ke keluarga navy/emas/cyan game sesuai permintaan konsistensi pengguna. Glyph kalender/bintang memakai SVG asli tanpa menggambar ulang. Screenshot referensi tidak dipakai sebagai tekstur implementasi.

## QA aktual

Windows Studio Play Solo, satu klien `Fikki2621`, unpublished isolated mock data. [Log mentah](qa.json), [parity source/compile/cleanup](source-parity.json).

| Skenario | Hasil |
| --- | --- |
| Desktop native 2090×752 (area HUD memperhitungkan inset) | Ikon baru tampil, badge merah, frame selaras dengan dock lain. Target 50×58, ikon 38×38. |
| Fixture portrait 390×844, QA_Touch=true | Target seluruh dock yang dibandingkan 50×54, ikon 34×34, gambar termuat. |
| Fixture tablet 1024×768, QA_Touch=true | Target 50×58, ikon 38×38; fixture claimed pada klien menampilkan badge centang hijau. |
| Fixture landscape 844×390 | Target 50×54, ikon 34×34, gambar termuat. |
| Klik mouse melalui jalur tombol nyata | Popup DailyLoginModal terbuka. Tidak menekan Klaim/mengubah data hadiah. |
| InFlight client fixture | HARIAN tersembunyi; muncul kembali setelah fixture dibersihkan. |
| Preload pada ImageLabel | Success; IsLoaded=true. Probe awal memakai string mengembalikan Failure, dicatat di qa.json, bukan disembunyikan. |
| Source final | Isi katalog Studio/mirror sama setelah CRLF→LF dan trimEnd; loadstring katalog lulus. |

Screenshot asli tersimpan: [desktop](desktop.jpg), [phone layout](phone.jpg), [tablet dengan badge sudah klaim](tablet.jpg). Nama phone/tablet menyatakan fixture layout; gambar tetap screenshot viewport Studio native, bukan perangkat/emulator. [Ikon lama](before.png).

## Cleanup dan batas

Fixture `QA_ViewportSize`/`QA_Touch` dibersihkan; Play Solo dihentikan, kembali Edit/0 pemain, kamera `[0,48,25]`; tidak mengubah mode Test atau jumlah klien. Kedua server HTTP localhost sementara untuk upload dihentikan. Place disimpan melalui Studio; SHA-256/byte di build.json. Binary belum dibuka ulang. Perangkat fisik, checkout/hadiah server sungguhan, serta multiplayer tidak diuji untuk perubahan ikon ini. Console hanya memuat pemberitahuan mock DataManager, tanpa error gameplay pada run ini.
