# PulseWise Integration Test

Termin 1 berisi fondasi E2E untuk auth flow memakai package resmi Flutter
`integration_test`.

## File

- `integration_test/auth_flow_test.dart`
- `integration_test/helpers/e2e_test_config.dart`
- `integration_test/helpers/e2e_test_helpers.dart`

## Skenario Termin 1

- App tanpa session terbuka ke halaman login.
- Login dengan email/password kosong menampilkan validasi.
- Login dengan credential salah tetap berada di halaman login dan menampilkan error.
- Login pasien valid masuk ke home pasien.
- Logout pasien kembali ke halaman login.

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
