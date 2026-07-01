# PulseWise Integration Test

Termin 1 berisi fondasi E2E untuk auth flow memakai package resmi Flutter
`integration_test`.

## File

- `integration_test/auth_flow_test.dart`
- `integration_test/patient_shell_flow_test.dart`
- `integration_test/patient_medication_flow_test.dart`
- `integration_test/patient_medication_lifecycle_test.dart`
- `integration_test/helpers/e2e_test_config.dart`
- `integration_test/helpers/e2e_test_helpers.dart`

## Skenario Termin 1

- App tanpa session terbuka ke halaman login.
- Login dengan email/password kosong menampilkan validasi.
- Login dengan credential salah tetap berada di halaman login dan menampilkan error.
- Login pasien valid masuk ke home pasien.
- Logout pasien kembali ke halaman login.

## Skenario Termin 2

- Pasien valid login ke shell pasien.
- Pasien dapat membuka tab utama: Beranda, Edukasi, Diari, Pengingat, dan
  Profil.
- Setiap tab utama menampilkan konten khasnya, tanpa membuat atau mengubah data
  backend.

## Skenario Termin 3

- Pasien valid membuka tab Pengingat.
- Pasien membuka halaman Kelola Pengingat.
- Pasien membuka form Tambah Pengingat.
- Form tambah pengingat menampilkan validasi ketika nama/bentuk obat belum
  diisi.
- Form tambah pengingat menampilkan validasi ketika dosis kosong atau bukan
  angka.
- Test Termin 3 tidak menyimpan pengingat baru, sehingga tidak mengubah data
  backend.

## Skenario Termin 4

- Pasien valid membuat pengingat obat dummy dengan nama unik.
- Pengingat yang dibuat muncul di halaman Kelola Pengingat.
- Pengingat yang dibuat muncul di kalender obat pada tab Pengingat.
- Pengingat yang dibuat muncul di ringkasan Pengingat Obat pada Beranda.
- Pasien menandai pengingat sebagai `Diminum`.
- Pasien membuka detail obat dari bottom sheet kalender.
- Pasien menghapus pengingat dummy dan test memastikan item hilang dari daftar
  Kelola Pengingat.

Termin 4 menyentuh data backend, tetapi memakai nama obat unik dan melakukan
cleanup lewat UI pada akhir test.

## Konfigurasi Backend

Test yang menyentuh backend tidak dijalankan secara default. Ini disengaja agar
test tidak menembak backend production tanpa sengaja.

Siapkan akun dummy pasien di backend testing/staging:

- `E2E_PATIENT_EMAIL`
- `E2E_PATIENT_PASSWORD`

Jalankan test lokal yang tidak menyentuh backend:

```bash
flutter test integration_test/auth_flow_test.dart
```

Jalankan auth flow penuh ke backend testing/staging:

```bash
flutter test integration_test/auth_flow_test.dart \
  --dart-define=E2E_RUN_BACKEND_TESTS=true \
  --dart-define=API_BASE_URL=https://your-staging-api.example.com \
  --dart-define=E2E_PATIENT_EMAIL=patient.e2e@example.com \
  --dart-define=E2E_PATIENT_PASSWORD=change-me
```

Jika memang ingin memakai default API app, tambahkan flag eksplisit:

```bash
--dart-define=E2E_ALLOW_DEFAULT_API=true
```

Jalankan Termin 2 patient shell flow:

```bash
flutter test integration_test/patient_shell_flow_test.dart \
  --dart-define=E2E_RUN_BACKEND_TESTS=true \
  --dart-define=API_BASE_URL=https://your-staging-api.example.com \
  --dart-define=E2E_PATIENT_EMAIL=patient.e2e@example.com \
  --dart-define=E2E_PATIENT_PASSWORD=change-me
```

Jalankan Termin 3 medication reminder validation flow:

```bash
flutter test integration_test/patient_medication_flow_test.dart \
  --dart-define=E2E_RUN_BACKEND_TESTS=true \
  --dart-define=API_BASE_URL=https://your-staging-api.example.com \
  --dart-define=E2E_PATIENT_EMAIL=patient.e2e@example.com \
  --dart-define=E2E_PATIENT_PASSWORD=change-me
```

Jalankan Termin 4 medication lifecycle flow:

```bash
flutter test integration_test/patient_medication_lifecycle_test.dart \
  --dart-define=E2E_RUN_BACKEND_TESTS=true \
  --dart-define=API_BASE_URL=https://your-staging-api.example.com \
  --dart-define=E2E_PATIENT_EMAIL=patient.e2e@example.com \
  --dart-define=E2E_PATIENT_PASSWORD=change-me
```

## Device/Emulator

Untuk menjalankan di device tertentu:

```bash
flutter test integration_test/auth_flow_test.dart -d emulator-5554
```

atau:

```bash
flutter devices
flutter test integration_test/auth_flow_test.dart -d <device-id>
```

## Catatan

- Credential asli tidak ditulis di source code.
- Akun pasien untuk test logout harus sudah memiliki profil lengkap.
- Jika backend lambat atau credential salah, test backend akan gagal dengan
  pesan error dari UI login.
