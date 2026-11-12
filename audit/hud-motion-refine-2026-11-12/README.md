# Revisi hover dan glitch — 12 November 2026

Pengguna menolak rasa animasi pertama dan menemukan kotak cyan yang tidak mengikuti bentuk PNG tombol beli. Hasil 14/14 sebelumnya hanya memeriksa state/presentasi, bukan bukti kualitas motion yang memuaskan. Temuan ini membuka kembali UI-01.

## Perubahan

- Gambar, caption, hint dan badge tombol sekarang berada pada child terpusat `HUDMotionVisual`, memakai satu UIScale. GuiButton asli tetap pemilik input dan ukuran layout. Theme mengukur geometri dari root yang tidak di-scale; atlas wide tidak mengukur ulang dari container yang sedang membesar.
- Hover menggunakan Sine Out sekitar 220 ms, scale 1→1,08 dan lift visual maksimal dua piksel; tekan menuju 0,94. Tidak memakai Back overshoot. Hover dihentikan untuk tombol terkunci atau tertutup scrim. Efek bintang sesaat dipool empat instance, bukan loop partikel semua tombol.
- Layout dan motion kini sama-sama BindToRenderStep, dengan layout Last+10 dan motion Last+20. RenderStepped tanpa urutan tidak lagi bersaing dengan penulisan motion. Ini juga memperbaiki regresi target progress bar yang ditemukan selama revisi.
- Outline UIStroke cyan dihapus. Sheen sekarang ImageLabel yang menyalin Image/ImageRect/ScaleType sprite sebenarnya, memakai alpha PNG. Tidak menggambar shape rectangle pengganti. Untuk gambar wide tiga segmen yang tidak bisa disalin sebagai satu silhouette, sheen dinonaktifkan; scale tetap bekerja.
- Shop choice caption/art dicari di child visual agar pemilihan senjata dan toggle Setelan tetap memakai objek yang sama.

## Bukti dan batas

[Hasil mentah](results.json), [fixture hover](hover.client.luau), [hover tombol beli setelah koreksi](buy-hover-corrected.png). Source awal HUDMotion disimpan sebagai `HUDMotion.before.luau`, bukan script produksi. Build/hash ada di build.json. Basis Git 94591f0 dengan perubahan motion yang belum di-commit dari sesi sebelumnya.

Native Studio solo, default desktop, unpublished mock. Regresi runtime memakai fixture lokal dari [run sebelumnya](../hud-motion-2026-11-12/runtime.client.luau): **9/9 lulus**, termasuk target bar, popup fade, reopen cepat, root stabil dan instance stabil. Tidak memanggil receipt/pembelian nyata.

Pointer hover asli menghasilkan 12 sampel render selama sekitar 0,74 detik: scale 1,00→1,0365→1,0653→1,0792→1,08, kemudian stabil. Tidak ada reset scale pada sampel; posisi/ukuran root tetap di semua sampel. Ini bukti temporal terbatas, bukan rekaman video 60 FPS atau jaminan rasa di perangkat fisik. Sampling Studio berjarak sekitar 66 ms; tidak dipakai untuk menyimpulkan performa mobile.

Tiga cek shape lulus: ImageLabel mask, tidak ada outline tambahan, sprite/rect sama dengan gambar asli. Screenshot diperiksa pada tombol beli yang di-hover; kotak cyan di luar kapsul tidak terlihat lagi. Kelima source revisi sama persis dengan editor Studio; 42 source compile, nol fixture QA di Edit. Konsol run final hanya pemberitahuan isolated mock.

Selama revisi beberapa batch sinkronisasi terputus; status file kemudian diperiksa ulang, bukan menganggap seluruh batch selesai. Satu regresi target bar sempat gagal sebelum urutan layout diperbaiki; run 9/9 di atas adalah sesudah perbaikan. Screenshot awal saat gambar belum loaded tidak dijadikan hasil akhir.

Cleanup: mouse dilepas, simulator kembali default dan Play dihentikan ke Edit, satu klien, tanpa fixture produksi. Place disimpan lokal; binary belum dibuka ulang. Belum commit/push. Pemeriksaan simulator phone hanya smoke viewport, bukan regresi lengkap touch/tablet setelah revisi. Review rasa motion pengguna, mobile fisik dan hold/respawn berulang masih terbuka.
