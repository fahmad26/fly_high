# Polesan gondola — 11 November 2026

Enam template diperbarui langsung di Studio: HotAirBalloon dan lima BalloonVariants. Tidak ada perubahan source gameplay atau aset pihak ketiga. Generator Edit tersimpan di [build-baskets.luau](build-baskets.luau); generator tidak dipasang sebagai script produksi.

## Desain

Badan panel anyaman berbingkai kayu gelap, delapan sisi dengan sudut serong, handrail silinder, aksen kuningan dan pita warna tema, binding kulit berwarna gelap dengan stud, fascia bawah miring, dek teak berbilah dengan compass inlay, ferrule tiang dan dua lentera belakang. GondolaFinish dan anyaman/binding/rim lama diganti agar lapisan visual tidak bertumpuk. Winch, wheel, rack dan rigging lama dipertahankan.

252 part kosmetik per template, massless, dilas ke RootPart, collision/touch/query false. Tidak menambah lampu dinamis atau script. Batas geometris lantai/collider tetap sama. Hull bawah hanya dekorasi dan tidak memberi permukaan pijakan baru. Miniatur dermaga belum didesain ulang.

## Bukti

- [Build results](build-results.json), [QA enam template](template-qa.json): floor 28×1.2×28; helm (0,1.8,-10), rack ±12/2.5/-4, tether (0,2,11); nol dekorasi dengan flag/weld salah.
- [Runtime QA](runtime-qa.json): 252 dekorasi pada clone produksi DawnExplorer; nol pelanggaran flag/weld.
- [Access QA](access-qa.json): native character_navigation berhasil dari tengah ke rak kiri; TryEquip true, Cleanup, kemudian warp dekat stasiun dan attachHandlers produksi memberi role Engineer. Ini menguji validasi manager, bukan klik semua prompt.
- [Motion QA](motion-qa.json): Sit di kursi produksi memberi Pilot, AutoGas true, root dilepas dari anchor, naik 15.105 stud selama empat detik, nol lubang. Fixture launch melalui manager/BoardReady, AFK grace +600 detik, anchor sementara dan teleport awal; bukan penerbangan penuh.
- [Screenshot exterior](basket-exterior.jpg): Play DawnExplorer setelah pengujian gerak. ScreenGui dimatikan sementara hanya untuk foto; Stop membuang perubahan UI runtime.
- [Console](console.json): info offline mock dan pemberitahuan tool mengembalikan CameraType; tidak ada error gameplay. Capture Edit awal menghasilkan viewport kosong, sehingga tidak dipakai sebagai bukti before/after. Screenshot Play berhasil.

## Build dan cleanup

Lihat [build.json](build.json) untuk HEAD dasar, dirty files dan hash place. Perubahan lokal audit sebelumnya dipertahankan. Tidak mengklaim source disk otomatis tersinkron; source tidak disentuh dalam pekerjaan model ini. Kecocokan 41/41 pada audit patch sebelumnya tetap bukti historis untuk source yang sama.

Stop menghapus seluruh __BasketQA fixture dan __BasketPreview sudah dihancurkan di Edit. Kembali Edit/Test/satu pemain, kamera pulau dan viewport default. [Save](save.json) berhasil ke file lokal; binary belum dibuka ulang. Belum commit/push.

QA visual memakai satu varian di native Studio solo. Semua varian diperiksa propertinya, tetapi foto/interaksi seluruh varian, tiga pemain, perangkat fisik, avatar tinggi dan penerbangan panjang masih belum diuji ulang. Tidak ada benchmark performa baru.
