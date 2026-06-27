# PulseWise

PulseWise adalah aplikasi health monitoring berbasis Flutter untuk membantu pemantauan pasien gagal jantung. Aplikasi ini menyediakan alur pasien, dokter, dan admin dengan fitur pencatatan harian, pengingat obat, integrasi wearable melalui Google Health Connect, notifikasi FCM, serta prediksi/rekomendasi berbasis Machine Learning melalui backend.

Repository ini berisi aplikasi frontend Flutter. Model Machine Learning dan proses bisnis utama dijalankan dari backend, sementara aplikasi bertugas mengelola autentikasi, pengambilan data, sinkronisasi perangkat, dan penyajian hasil ke pengguna.

## Fitur Utama

- Autentikasi pengguna untuk pasien, dokter, dan admin.
- Dashboard pasien untuk ringkasan kondisi, diary, edukasi, reminder, kontak darurat, dan laporan.
- Dashboard dokter untuk monitoring pasien, riwayat diary, riwayat rekomendasi ML, dan evaluasi risiko.
- Dashboard admin untuk manajemen pengguna dan verifikasi dokter.
- Integrasi Google Health Connect pada Android untuk membaca data kesehatan dari wearable.
- Sinkronisasi data aktivitas, detak jantung, dan tidur ke diary pasien.
- Kuisioner ML statis dan asesmen ML dinamis sebagai sumber input prediksi.
- Prediksi dan rekomendasi ML melalui backend, termasuk riwayat rekomendasi.
- Firebase Cloud Messaging dan local notification untuk kebutuhan notifikasi.
- Pembuatan dan pembacaan laporan berbasis PDF.

## Tech Stack

- Flutter dan Dart
- Riverpod untuk state management
- go_router untuk routing
- Dio untuk komunikasi API
- SharedPreferences dan Hive untuk local storage
- Firebase Cloud Messaging dan flutter_local_notifications
- Google Sign-In
- flutter_health_connect untuk integrasi Health Connect Android
- Syncfusion Gauge/PDF Viewer dan fl_chart untuk visualisasi
- PDF, printing, Excel, dan share_plus untuk reporting

## Struktur Project

Kode utama aplikasi berada di dalam folder `lib`.

```text
lib/
|-- main.dart                  # Entry point aplikasi
|-- core/                      # Infrastruktur bersama lintas fitur
|   |-- config/                # Routing dan environment config
|   |-- constants/             # Konstanta aplikasi
|   |-- data/                  # Mapping data bersama, termasuk ML mapping
|   |-- network/               # Dio provider, logger, dan error utility
|   |-- notifications/         # FCM dan local notification
|   |-- platform/              # Helper platform-specific
|   |-- session/               # Reset state berbasis akun
|   |-- storage/               # Session/local storage helper
|   |-- ui/
|   |-- utils/
|   `-- widgets/
|
`-- features/
    |-- auth/                  # Login, register, OTP, profile setup
    |-- dashboard_shell/       # Shell utama pasien
    |-- home_dashboard/        # Dashboard pasien
    |-- diary/                 # Diary dan sharing diary
    |-- medication/            # Pengingat obat
    |-- emergency_contacts/    # Kontak darurat
    |-- health_connect/        # Integrasi Google Health Connect
    |-- ml_questionnaire/      # Kuisioner statis ML
    |-- ml_assessment/         # Asesmen dinamis ML
    |-- ml_recommendation/     # Rekomendasi dan histori ML
    |-- reports/               # Laporan pasien
    |-- doctor_shell/          # Shell utama dokter
    |-- doctor/                # Fitur monitoring dokter
    |-- admin_shell/           # Shell utama admin
    `-- admin/                 # Fitur manajemen admin
```

Arsitektur yang digunakan bersifat feature-first dan role-aware. Kode yang digunakan bersama banyak fitur ditempatkan di `core`, sedangkan logika bisnis dan UI spesifik domain ditempatkan pada folder masing-masing di `features`.

## Role dan Routing

Routing aplikasi dikelola secara terpusat melalui `lib/core/config/routes.dart`. Setelah login, aplikasi membaca role dari session dan mengarahkan pengguna ke area yang sesuai.

```text
/login
/login/register
/login/forgot-password
/login/google-verify-otp

/home                         # Pasien
/home/update-profile
/home/contacts
/home/diary
/home/reminder/...
/home/health-connect
/home/patient-dashboard

/doctor/home                  # Dokter
/doctor/home/update-profile
/doctor/home/patients/:patientId
/doctor/home/patients/:patientId/...

/admin/home                   # Admin
/admin/home/users
/admin/home/users/:userId
/admin/home/doctors
```

Session pengguna disimpan melalui `AppSessionStore` dengan data utama seperti token, user id, role, next step, dan account status.

## Integrasi Penting

### API Backend

Konfigurasi base URL API berada di `lib/core/config/app_env.dart` dan digunakan oleh Dio provider di `lib/core/network/api_dio_provider.dart`. Nilai default `API_BASE_URL` saat ini adalah:

```text
https://pulsewise-api.algoritme.tech
```

Nilai tersebut dapat diganti saat build/run menggunakan `--dart-define`.

### Health Connect

Integrasi wearable dilakukan melalui Google Health Connect dan hanya ditampilkan pada platform Android. Permission Android utama yang digunakan:

- `android.permission.health.READ_EXERCISE`
- `android.permission.health.READ_HEART_RATE`
- `android.permission.health.READ_SLEEP`

Health Connect digunakan sebagai perantara standar untuk membaca data dari aplikasi/wearable yang kompatibel, lalu data tersebut disinkronkan ke diary pasien.

### Machine Learning

Integrasi ML pada aplikasi dilakukan melalui backend, bukan langsung di perangkat. Alur utamanya:

1. Aplikasi mengumpulkan data statis dari kuisioner ML.
2. Aplikasi mengumpulkan data dinamis dari asesmen, diary, dan Health Connect.
3. Aplikasi mengecek readiness melalui endpoint `/users/{patientId}/ml-readiness`.
4. Jika data lengkap, aplikasi memanggil endpoint `/users/{patientId}/ml-recommendations/`.
5. Response ML ditampilkan sebagai skor risiko, rekomendasi, dan histori rekomendasi.

### Firebase Cloud Messaging

FCM digunakan untuk notifikasi aplikasi. Panduan konfigurasi lebih detail tersedia di `FCM_SETUP.md`.

## Prasyarat Development

- Flutter SDK dengan Dart `^3.5.4`
- Android Studio atau Android SDK
- Android SDK compile/target 35 dan min SDK 26
- Node.js dan npm, hanya jika menggunakan script deployment atau FCM test
- Firebase project untuk fitur FCM
- Google Health Connect pada perangkat Android untuk pengujian integrasi wearable

## Setup Lokal

Clone repository dan install dependency Flutter:

```bash
flutter pub get
```

Jika ingin menggunakan script Node.js yang tersedia:

```bash
npm install
```

Jalankan aplikasi:

```bash
flutter run
```

Contoh menjalankan aplikasi dengan konfigurasi API custom:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example.com
```

Untuk web release build:

```bash
flutter build web --release
```

Atau gunakan script yang sudah disediakan:

```bash
npm run build:web:vercel
```

## Environment Variable

Konfigurasi build dibaca melalui `String.fromEnvironment`. Variable yang umum digunakan:

```text
API_BASE_URL
GOOGLE_WEB_CLIENT_ID
GOOGLE_CLIENT_ID
GOOGLE_SERVER_CLIENT_ID
GOOGLE_WEB_CLIENT_ID_PLAY_STORE
CLOUDINARY_FOLDER
```

Untuk kebutuhan testing tertentu, tersedia juga fallback env seperti `AUTH_TOKEN`, `BEARER_TOKEN`, `PATIENT_ID`, `AUTH_ROLE`, `USER_ROLE`, `AUTH_NEXT_STEP`, dan `AUTH_ACCOUNT_STATUS`.

Jangan commit file credential atau secret lokal seperti `.env`, Firebase service account JSON, Google client secret JSON, atau private key lainnya.

## Firebase dan FCM

Untuk Android, siapkan Firebase app dengan application ID:

```text
com.rdib.pulsewise
```

Letakkan file konfigurasi Firebase di:

```text
android/app/google-services.json
```

Setelah itu jalankan:

```bash
flutter clean
flutter pub get
flutter run
```

Untuk mengirim test push notification, lihat `FCM_SETUP.md` dan script:

```bash
npm run fcm:test
```

## Quality Check

Jalankan analyzer sebelum membuat commit:

```bash
dart analyze
```

Jalankan test:

```bash
flutter test
```

## Script yang Tersedia

```bash
npm run build:web:vercel
npm run deploy:web:prod
npm run fcm:test
```

## Catatan Pengembangan

- Pertahankan struktur feature-first: setiap fitur sebaiknya memiliki page, provider, model, datasource, dan repository-nya sendiri.
- Letakkan kode lintas fitur di `lib/core`, bukan di salah satu fitur.
- Pisahkan batas role pasien, dokter, dan admin agar tidak kembali menjadi satu dashboard besar.
- Hasil Machine Learning pada aplikasi bersifat alat bantu monitoring, bukan pengganti diagnosis klinis.
- Integrasi Health Connect saat ini berfokus pada Android dan bergantung pada ketersediaan aplikasi Google Health Connect.
