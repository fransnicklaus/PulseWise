# PulseWise Integration Test

Termin 1 berisi fondasi E2E untuk auth flow memakai package resmi Flutter
`integration_test`.

## File

- `integration_test/auth_flow_test.dart`
- `integration_test/forgot_password_flow_test.dart`
- `integration_test/forgot_password_navigation_flow_test.dart`
- `integration_test/login_empty_validation_flow_test.dart`
- `integration_test/login_form_input_flow_test.dart`
- `integration_test/patient_shell_flow_test.dart`
- `integration_test/patient_medication_flow_test.dart`
- `integration_test/patient_medication_lifecycle_test.dart`
- `integration_test/patient_diary_history_flow_test.dart`
- `integration_test/patient_profile_edit_flow_test.dart`
- `integration_test/patient_emergency_contacts_flow_test.dart`
- `integration_test/patient_education_article_flow_test.dart`
- `integration_test/patient_dashboard_overview_flow_test.dart`
- `integration_test/patient_health_ml_navigation_flow_test.dart`
- `integration_test/patient_delete_account_navigation_flow_test.dart`
- `integration_test/patient_diary_qr_share_flow_test.dart`
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
- Setelah simpan berhasil, pasien kembali ke tab Pengingat/Kalender Obat.
- Test memastikan form tambah pengingat sudah tertutup.

Termin 4 menyentuh data backend dan memakai nama obat unik. Untuk saat ini test
tidak melakukan cleanup lewat UI karena validasi kalender/detail/delete dipisah
dari flow create agar stabil.

## Skenario Termin 5

- Pasien valid membuka tab Diari.
- Pasien membuka halaman Riwayat Diari.
- Pasien kembali ke tab Diari.

Termin 5 hanya melakukan navigasi dan membaca data; test tidak membuat atau
mengubah data backend.

## Skenario Termin 6

- Pasien valid membuka tab Profil.
- Pasien membuka halaman Edit Profil.
- Pasien kembali ke tab Profil tanpa menyimpan perubahan.

Termin 6 hanya melakukan navigasi dan membaca data profil; test tidak membuat
atau mengubah data backend.

## Skenario Termin 7

- Pasien valid membuka Beranda.
- Pasien membuka halaman Kontak Darurat.
- Pasien kembali ke Beranda tanpa menambah atau mengubah kontak.

Termin 7 hanya melakukan navigasi dan membaca data kontak darurat; test tidak
membuat atau mengubah data backend.

## Skenario Termin 8

- Pasien valid membuka tab Edukasi.
- Pasien membuka artikel edukasi pertama dari daftar.
- Pasien melihat halaman detail artikel.
- Pasien kembali ke tab Edukasi.

Termin 8 hanya melakukan navigasi dan membaca artikel; test tidak memberi like,
komentar, atau mengubah data backend.

## Skenario Termin 9

- Pasien valid membuka Beranda.
- Pasien membuka halaman Dashboard Pasien dari kartu Status Kesehatan.
- Pasien melihat tab/area dashboard kesehatan.
- Pasien kembali ke Beranda.

Termin 9 hanya melakukan navigasi dan membaca data dashboard; test tidak
menjalankan prediksi, print report, atau mengubah data backend.

## Skenario Termin 10

- User membuka halaman Lupa Sandi dari login.
- User mencoba lanjut tanpa mengisi email.
- Form menampilkan validasi email wajib diisi.
- User kembali ke halaman login.

Termin 10 hanya menguji validasi lokal form lupa sandi; test tidak mengirim OTP
atau menembak backend.

## Skenario Termin 11

- User membuka halaman Lupa Sandi dari login.
- Halaman Lupa Sandi menampilkan langkah masukkan email dan field email.
- User kembali ke halaman login.

Termin 11 hanya menguji navigasi halaman lupa sandi; test tidak mengirim OTP
atau menembak backend.

## Skenario Termin 12

- User membuka halaman login.
- User menekan tombol masuk tanpa mengisi email dan kata sandi.
- App menampilkan peringatan input wajib diisi.

Termin 12 hanya menguji validasi lokal login kosong; test tidak menembak
backend.

## Skenario Termin 13

- User membuka halaman login.
- User mengisi email dan kata sandi.
- Form login tetap menampilkan tombol masuk tanpa melakukan submit.

Termin 13 hanya menguji input lokal form login; test tidak menembak backend.

## Skenario Termin 14-16

- Pasien valid membuka tab Edukasi.
- Pasien membuka panduan Health Connect tanpa menekan tombol native install,
  settings, atau permission.
- Pasien membuka Kuisioner ML dari tab Profil tanpa mengirim kuisioner.
- Pasien membuka Dashboard Pasien dari Beranda.
- Pasien membuka Form Asesmen ML tanpa menyimpan asesmen.
- Jika tombol history tersedia di dashboard, pasien membuka Riwayat Prediksi ML
  lalu kembali.

Termin 14-16 hanya melakukan navigasi dan membaca halaman Health Connect/ML;
test tidak submit kuisioner, tidak submit asesmen, dan tidak menjalankan aksi
native Health Connect.

## Skenario Termin 17

- Pasien valid membuka tab Profil.
- Pasien membuka halaman Hapus Akun.
- Halaman menampilkan tahap konfirmasi penghapusan dan tombol kirim OTP.
- Pasien kembali ke tab Profil tanpa mengetik konfirmasi dan tanpa mengirim OTP.

Termin 17 hanya melakukan navigasi ke halaman hapus akun; test tidak menghapus
akun dan tidak menembak endpoint penghapusan akun.

## Skenario Termin 18

- Pasien valid membuka tab Diari.
- Pasien membuka halaman QR Share Pasien.
- Halaman menampilkan QR share atau state error pembuatan QR.
- Pasien kembali ke tab Diari tanpa membuka scanner kamera.

Termin 18 tidak membuka halaman scan QR. Halaman QR share dapat membuat token
share sementara di backend karena itu adalah perilaku halaman saat dibuka.

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

Jalankan Termin 10 forgot password validation flow:

```bash
flutter test integration_test/forgot_password_flow_test.dart
```

Jalankan Termin 11 forgot password navigation flow:

```bash
flutter test integration_test/forgot_password_navigation_flow_test.dart
```

Jalankan Termin 12 login empty validation flow:

```bash
flutter test integration_test/login_empty_validation_flow_test.dart
```

Jalankan Termin 13 login form input flow:

```bash
flutter test integration_test/login_form_input_flow_test.dart
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

Jalankan Termin 4 medication create flow:

```bash
flutter test integration_test/patient_medication_lifecycle_test.dart \
  --dart-define=E2E_RUN_BACKEND_TESTS=true \
  --dart-define=API_BASE_URL=https://your-staging-api.example.com \
  --dart-define=E2E_PATIENT_EMAIL=patient.e2e@example.com \
  --dart-define=E2E_PATIENT_PASSWORD=change-me
```

Jalankan Termin 5 diary history flow:

```bash
flutter test integration_test/patient_diary_history_flow_test.dart \
  --dart-define=E2E_RUN_BACKEND_TESTS=true \
  --dart-define=API_BASE_URL=https://your-staging-api.example.com \
  --dart-define=E2E_PATIENT_EMAIL=patient.e2e@example.com \
  --dart-define=E2E_PATIENT_PASSWORD=change-me
```

Jalankan Termin 6 profile edit navigation flow:

```bash
flutter test integration_test/patient_profile_edit_flow_test.dart \
  --dart-define=E2E_RUN_BACKEND_TESTS=true \
  --dart-define=API_BASE_URL=https://your-staging-api.example.com \
  --dart-define=E2E_PATIENT_EMAIL=patient.e2e@example.com \
  --dart-define=E2E_PATIENT_PASSWORD=change-me
```

Jalankan Termin 7 emergency contacts navigation flow:

```bash
flutter test integration_test/patient_emergency_contacts_flow_test.dart \
  --dart-define=E2E_RUN_BACKEND_TESTS=true \
  --dart-define=API_BASE_URL=https://your-staging-api.example.com \
  --dart-define=E2E_PATIENT_EMAIL=patient.e2e@example.com \
  --dart-define=E2E_PATIENT_PASSWORD=change-me
```

Jalankan Termin 8 education article detail flow:

```bash
flutter test integration_test/patient_education_article_flow_test.dart \
  --dart-define=E2E_RUN_BACKEND_TESTS=true \
  --dart-define=API_BASE_URL=https://your-staging-api.example.com \
  --dart-define=E2E_PATIENT_EMAIL=patient.e2e@example.com \
  --dart-define=E2E_PATIENT_PASSWORD=change-me
```

Jalankan Termin 9 patient dashboard overview flow:

```bash
flutter test integration_test/patient_dashboard_overview_flow_test.dart \
  --dart-define=E2E_RUN_BACKEND_TESTS=true \
  --dart-define=API_BASE_URL=https://your-staging-api.example.com \
  --dart-define=E2E_PATIENT_EMAIL=patient.e2e@example.com \
  --dart-define=E2E_PATIENT_PASSWORD=change-me
```

Jalankan Termin 14-16 patient Health Connect + ML navigation flow:

```bash
flutter test integration_test/patient_health_ml_navigation_flow_test.dart \
  --dart-define=E2E_RUN_BACKEND_TESTS=true \
  --dart-define=API_BASE_URL=https://your-staging-api.example.com \
  --dart-define=E2E_PATIENT_EMAIL=patient.e2e@example.com \
  --dart-define=E2E_PATIENT_PASSWORD=change-me
```

Jalankan Termin 17 delete account navigation flow:

```bash
flutter test integration_test/patient_delete_account_navigation_flow_test.dart \
  --dart-define=E2E_RUN_BACKEND_TESTS=true \
  --dart-define=API_BASE_URL=https://your-staging-api.example.com \
  --dart-define=E2E_PATIENT_EMAIL=patient.e2e@example.com \
  --dart-define=E2E_PATIENT_PASSWORD=change-me
```

Jalankan Termin 18 diary QR share flow:

```bash
flutter test integration_test/patient_diary_qr_share_flow_test.dart \
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
