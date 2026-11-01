# AI Challenge — Cara Membaca Folder Ini

Codelab Minggu 6 meminta empat hal disimpan: **prompt**, **output awal AI**,
**daftar perbaikan manual**, dan **tabel hasil uji**. Semuanya ada di sini.

| File | Isi |
| --- | --- |
| [`01-prompt.md`](01-prompt.md) | Tiga prompt yang dipakai, apa adanya |
| [`02-draf-awal-ai.md`](02-draf-awal-ai.md) | Kode draf pertama + hasil `flutter analyze` pertamanya |
| [`03-perbaikan-manual.md`](03-perbaikan-manual.md) | 13 temuan: 5 dari analyzer, 8 dari pembacaan ulang |
| [`../uji-tiga-state.md`](../uji-tiga-state.md) | Tabel uji foreground/background/terminated |

## Inti yang perlu bisa dijelaskan saat demo

**Hanya 5 dari 13 masalah yang dilaporkan analyzer.** Sisanya tidak akan pernah
muncul di terminal, dan sebagian besar justru yang paling mahal:

- channel notifikasi tidak dibuat → banner FCM background dibuang Android
  tanpa error,
- token hanya di-print → backend menyimpan nilai basi, push berhenti diam-diam
  setelah reinstall,
- deep link hilang saat sesi habis → pengguna mendarat di beranda dan mengira
  aplikasinya rusak.

Ketiganya lolos `flutter analyze` dengan nilai 100%.

## Yang saya tolak dari draf AI

| Draf | Alasan ditolak |
| --- | --- |
| `initFcmToken(onToken: ...)` menyerahkan pengiriman ke pemanggil | Tidak ada jaminan token benar-benar dikirim; checklist codelab menolak pola ini |
| `String? pendingDeepLink` global | Tidak bisa di-reset, hanya dibaca sekali, tidak bisa menampung lebih dari satu klik |
| `message.data['route'] ?? '/'` | Meloloskan nilai non-string ke router |
| `_local.show(message.hashCode, ...)` | Hash bisa bertabrakan; banner baru menimpa yang lama |
| `handleTerminated()` dipanggil sebelum `runApp` | Router belum ada, `go()` tidak berefek |

## Yang saya terima meski terlihat "kurang rapi"

| Draf | Alasan diterima |
| --- | --- |
| Background handler kosong | Sudah benar: navigasi dilakukan saat klik, bukan di isolate background |
| `@pragma('vm:entry-point')` | Wajib, mencegah fungsi dibuang AOT compiler |
| Izin iOS lewat `FirebaseMessaging.requestPermission` | Menghindari dua dialog berurutan; `DarwinInitializationSettings` di-set `false` |

## Batasan yang jujur

- Tabel uji tiga state **belum terisi** karena butuh perangkat dengan Google
  Play Services dan `google-services.json` dari Firebase Console.
- Jalur lokal (tombol **Kirim notifikasi uji**) bisa dipakai untuk membuktikan
  banner dan deep link tanpa Firebase, tetapi tidak membuktikan perilaku
  `notification payload` FCM yang asli.
- `firebase_messaging` 17 memakai `register()`/`onRegistered` (Installation ID),
  bukan `getToken()` gaya lama. Backend perlu menyesuaikan bila belum.
