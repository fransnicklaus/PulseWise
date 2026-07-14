# Subbab 4.4.4 Implementasi Integrasi Model Machine Learning

## Pemanfaatan Hasil Machine Learning pada Sisi Dokter

Pada sisi dokter, integrasi Machine Learning digunakan untuk membantu proses pemantauan kondisi pasien yang telah terhubung dengan akun dokter. Dokter tidak melakukan komputasi Machine Learning secara langsung pada aplikasi Flutter, melainkan mengakses hasil inferensi yang telah diproses oleh backend. Aplikasi Flutter berperan sebagai antarmuka untuk mengambil, menampilkan, dan dalam modul tertentu memicu proses prediksi melalui endpoint API.

Alur pemanfaatan Machine Learning pada sisi dokter dimulai dari halaman daftar pasien. Setelah dokter memilih salah satu pasien, aplikasi membuka dashboard detail pasien. Pada halaman tersebut, sistem mengambil data ringkasan pasien, data vital, serta hasil rekomendasi Machine Learning terbaru. Hasil prediksi ditampilkan dalam bentuk skor risiko, waktu pembuatan prediksi, dan rekomendasi perubahan gaya hidup yang dapat digunakan dokter sebagai informasi pendukung dalam pemantauan pasien.

Selain menampilkan rekomendasi Machine Learning umum, aplikasi juga menyediakan modul prediksi Heart Risk. Modul ini berbeda dari rekomendasi umum karena dokter dapat mengisi asesmen risiko pasien, menyimpan asesmen tersebut, mengecek kesiapan data, kemudian menjalankan prediksi baru. Dengan demikian, pada modul Heart Risk dokter tidak hanya menjadi pengguna yang melihat hasil prediksi, tetapi juga berperan dalam memasukkan data klinis yang dibutuhkan model.

## Ringkasan Alur Fitur ML Sisi Dokter

1. Dokter membuka halaman utama dokter melalui route `/doctor/home`.
2. Dokter memilih tab `Pasien`.
3. Aplikasi memuat daftar pasien yang terhubung ke dokter.
4. Dokter memilih pasien tertentu untuk membuka dashboard detail pasien.
5. Aplikasi mengambil ringkasan pasien, data vital, dan hasil rekomendasi ML terbaru.
6. Hasil rekomendasi ML ditampilkan sebagai skor risiko dan daftar rekomendasi.
7. Dokter dapat membuka riwayat prediksi atau rekomendasi ML pasien.
8. Untuk modul Heart Risk, dokter dapat membuka halaman khusus prediksi risiko jantung.
9. Dokter dapat mengisi form asesmen Heart Risk.
10. Setelah asesmen disimpan, aplikasi mengecek readiness data.
11. Jika data sudah lengkap, aplikasi memanggil endpoint untuk menjalankan prediksi Heart Risk.
12. Hasil prediksi Heart Risk ditampilkan sebagai probabilitas risiko dan kategori risiko.

## Daftar File Penting

| File | Class/Function/Widget | Fungsi | Bukti Kode Singkat |
|---|---|---|---|
| `lib/features/doctor_shell/presentation/pages/doctor_dashboard_page.dart` | `DoctorDashboardPage` | Menyediakan shell utama dokter yang memuat tab pasien, QR, edukasi, dan profil. | `DoctorPatientsTab()` |
| `lib/features/doctor/presentation/pages/tabs/doctor_tabs.dart` | `DoctorPatientsTab` | Memuat daftar pasien yang terhubung dengan dokter. | `loadPatients()` |
| `lib/features/doctor/presentation/pages/tabs/doctor_tabs.dart` | `_DoctorPatientListCard` | Mengarahkan dokter ke detail pasien. | `context.push('/doctor/home/patients/${patient.patientId}')` |
| `lib/features/doctor/presentation/providers/doctor_patients_provider.dart` | `DoctorPatientsNotifier.loadPatients` | Mengatur state daftar pasien dokter. | `_api.fetchPatients(page: page, limit: limit)` |
| `lib/features/doctor/data/datasources/doctor_dashboard_api.dart` | `fetchPatients` | Mengambil daftar pasien dokter dari backend. | `/doctors/$doctorId/dashboard/patients` |
| `lib/features/doctor/data/datasources/doctor_dashboard_api.dart` | `fetchLatestPatientMlRecommendation` | Mengambil hasil rekomendasi ML terbaru pasien untuk dokter. | `/ml-recommendations/latest` |
| `lib/features/doctor/presentation/pages/doctor_patient_dashboard_page.dart` | `_loadDashboard` | Mengambil data ringkasan pasien, data vital, dan rekomendasi ML terbaru. | `fetchLatestPatientMlRecommendation(widget.patientId)` |
| `lib/features/doctor/presentation/pages/doctor_patient_dashboard_page.dart` | `_DoctorPredictionSection` | Menampilkan skor prediksi dan rekomendasi ML pada dashboard dokter. | `PredictionMetricCard(...)` |
| `lib/features/doctor/presentation/providers/doctor_recommendation_history_provider.dart` | `DoctorRecommendationHistoryNotifier` | Mengatur state riwayat rekomendasi ML pasien. | `fetchPatientMlRecommendationHistory(_patientId)` |
| `lib/features/doctor/presentation/pages/doctor_ml_recommendation_history_page.dart` | `DoctorMlRecommendationHistoryPage` | Menampilkan riwayat prediksi dan rekomendasi ML yang dapat dilihat dokter. | `Riwayat Prediksi ML` |
| `lib/features/doctor/presentation/pages/doctor_patient_heart_risk_page.dart` | `DoctorPatientHeartRiskPage` | Menampilkan prediksi Heart Risk terbaru dan asesmen terakhir. | `fetchLatestPatientHeartRiskPrediction` |
| `lib/features/doctor/presentation/pages/doctor_patient_heart_risk_form_page.dart` | `_submit` | Menyimpan asesmen Heart Risk, mengecek readiness, dan menjalankan prediksi. | `runPatientHeartRiskPrediction(...)` |
| `lib/features/doctor/presentation/pages/doctor_patient_heart_risk_history_page.dart` | `_loadHistory` | Menampilkan riwayat prediksi Heart Risk pasien. | `fetchPatientHeartRiskPredictionHistory(...)` |
| `lib/features/doctor/data/models/doctor_heart_risk_models.dart` | `DoctorHeartRiskPredictionResult` | Model data hasil prediksi Heart Risk. | `probability`, `riskLevel`, `threshold` |

## Cuplikan Kode Program dan Penjelasan Akademik

### 1. Pengambilan Rekomendasi ML Terbaru Pasien oleh Dokter

```dart
Future<MlRecommendationResponse?> fetchLatestPatientMlRecommendation(
  String patientId,
) async {
  final token = await _readBearerToken();
  final doctorId = await _readDoctorId();

  final response = await _dio.get<Map<String, dynamic>>(
    '/doctors/$doctorId/dashboard/patients/$patientId/ml-recommendations/latest',
    options: Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    ),
  );

  return MlRecommendationResponse.fromJson(response.data!);
}
```

Cuplikan kode tersebut menunjukkan bahwa dokter mengambil hasil rekomendasi ML melalui endpoint khusus dokter. Parameter `doctorId` dan `patientId` digunakan untuk memastikan bahwa data yang ditampilkan merupakan data pasien yang berada dalam cakupan akses dokter. Token autentikasi dikirim melalui header `Authorization` untuk menjaga keamanan akses data medis.

### 2. Integrasi Data Rekomendasi ML pada Dashboard Pasien Dokter

```dart
final recommendation =
    await api.fetchLatestPatientMlRecommendation(widget.patientId);

setState(() {
  _latestRecommendation = recommendation;
});
```

Kode tersebut menunjukkan bahwa halaman dashboard pasien pada sisi dokter tidak menghasilkan prediksi secara lokal. Aplikasi mengambil hasil inferensi dari backend, kemudian menyimpannya ke dalam state `_latestRecommendation` agar dapat ditampilkan pada antarmuka dokter.

### 3. Visualisasi Skor Risiko ML pada Dashboard Dokter

```dart
PredictionMetricCard(
  title: 'Prediksi',
  icon: Icons.insights_rounded,
  iconColor: const Color(0xFFE13D5A),
  description:
      'Dihasilkan pada: ${_doctorGeneratedDateStr(latestRecommendation)}',
  score: _doctorProbability(latestRecommendation),
)
```

Cuplikan ini menunjukkan bagaimana hasil prediksi Machine Learning divisualisasikan menjadi skor risiko. Nilai risiko yang diterima dari backend dikonversi menjadi indikator visual agar dokter dapat membaca tingkat risiko pasien secara lebih cepat.

### 4. Penyimpanan Asesmen dan Eksekusi Prediksi Heart Risk

```dart
final savedAssessment = await api.savePatientHeartRiskAssessment(
  widget.patientId,
  assessmentId: _assessmentId,
  payload: {
    'assessmentDate': _formatDate(_assessmentDate),
    'age': age,
    'sex': _sex,
    'chest_pain_type': _chestPainType,
    'resting_bp_s': _normalizeNumber(restingBp),
    'fasting_blood_sugar': _fastingBloodSugar,
    'max_heart_rate': _normalizeNumber(maxHeartRate),
    'exercise_angina': _exerciseAngina,
    'old_peak': _normalizeNumber(oldPeak),
    'st_slope': _stSlope,
  },
);

final readiness =
    await api.fetchPatientHeartRiskReadiness(widget.patientId);

if (!readiness.ready) {
  await _showMissingFieldsSheet(readiness.missingFields);
  return;
}

await api.runPatientHeartRiskPrediction(
  widget.patientId,
  includePayload: true,
);
```

Kode ini merupakan bagian paling penting dalam integrasi model Heart Risk pada sisi dokter. Proses dimulai dari penyimpanan asesmen, kemudian dilanjutkan dengan pengecekan kesiapan data. Jika semua data yang diperlukan model telah tersedia, aplikasi memanggil endpoint prediksi. Dengan demikian, Flutter bertindak sebagai penghubung antara input klinis dokter dan layanan inferensi Machine Learning pada backend.

### 5. Tampilan Hasil Prediksi Heart Risk

```dart
final upstream = prediction!.upstream?.body;
final probability = (upstream?.probability ?? 0).toDouble();
final riskLevel = (upstream?.riskLevel ?? '').trim();

Text('${(probability * 100).toStringAsFixed(1)}%')
```

Kode tersebut menunjukkan bahwa hasil prediksi Heart Risk dikembalikan dalam bentuk probabilitas dan kategori risiko. Probabilitas dikalikan 100 agar dapat ditampilkan sebagai persentase. Kategori risiko, seperti `low`, `medium`, atau `high`, digunakan untuk memberi interpretasi terhadap hasil prediksi.

## Data yang Dibutuhkan pada Form Heart Risk Dokter

Tabel berikut hanya memuat data yang secara langsung diisi dokter pada form Heart Risk. Data ini digunakan untuk menyimpan asesmen dokter, mengecek kesiapan data, dan menjalankan prediksi Heart Risk pasien.

| Field Key (jika ada) | Pertanyaan | Pilihan atau Rentang |
|---|---|---|
| `assessmentDate` | Tanggal asesmen | Tanggal dipilih melalui date picker |
| `age` | Usia pasien saat asesmen | Angka bulat, contoh: 58 |
| `sex` | Jenis kelamin | `female`: Perempuan; `male`: Laki-laki |
| `chest_pain_type` | Jenis nyeri dada | `typical_angina`: Nyeri dada khas angina; `atypical_angina`: Nyeri dada tidak khas angina; `non_anginal_pain`: Nyeri dada non-angina; `asymptomatic`: Tanpa gejala nyeri dada |
| `resting_bp_s` | Tekanan darah sistolik saat istirahat | Angka, contoh: 151 |
| `fasting_blood_sugar` | Gula darah puasa | `lte_120_mg_dl`: Gula darah puasa <= 120 mg/dL; `gt_120_mg_dl`: Gula darah puasa > 120 mg/dL |
| `max_heart_rate` | Detak jantung maksimum | Angka, contoh: 118 |
| `exercise_angina` | Angina saat aktivitas | `no`: Tidak; `yes`: Ya |
| `old_peak` | Old Peak | Angka desimal, contoh: 0.5 |
| `st_slope` | Kemiringan segmen ST | `upsloping`: Naik; `flat`: Datar; `downsloping`: Menurun |

## Perbedaan Alur ML Dokter dan Pasien

Alur Machine Learning pada sisi pasien dan dokter memiliki perbedaan fungsi. Pada sisi pasien, aplikasi menyediakan kuesioner profil ML, asesmen ML, readiness check, dan pemanggilan rekomendasi ML melalui endpoint berbasis `/users/{patientId}` atau `/patients/{patientId}`. Dengan demikian, pasien menjadi sumber utama data statis dan data dinamis yang dibutuhkan model rekomendasi umum.

Pada sisi dokter, aplikasi lebih berfokus pada pemantauan hasil prediksi pasien. Dokter dapat melihat rekomendasi ML terbaru, membuka riwayat rekomendasi, dan membaca detail hasil prediksi. Namun, untuk modul Heart Risk, dokter memiliki fungsi tambahan, yaitu mengisi asesmen khusus dan menjalankan prediksi baru. Perbedaan ini menunjukkan bahwa role dokter tidak hanya sebagai penerima informasi, tetapi juga dapat menjadi aktor klinis dalam modul prediksi tertentu.

## Kesimpulan Status Hak Akses Dokter terhadap Fitur ML

Berdasarkan hasil penelusuran kode Flutter, status pemanfaatan fitur Machine Learning pada sisi dokter adalah sebagai berikut:

1. Dokter dapat melihat hasil prediksi dan rekomendasi ML pasien.
2. Dokter dapat melihat riwayat prediksi atau riwayat rekomendasi ML pasien.
3. Dokter dapat membuka modul prediksi Heart Risk pasien.
4. Dokter dapat mengisi asesmen khusus Heart Risk.
5. Dokter dapat menjalankan prediksi baru pada modul Heart Risk.
6. Dokter tidak ditemukan mengisi kuesioner profil ML umum pasien.
7. Dokter tidak ditemukan menjalankan rekomendasi ML umum baru dari dashboard dokter.

Dengan demikian, pembahasan mengenai pemanfaatan hasil Machine Learning pada sisi dokter lebih tepat ditempatkan pada Subbab 4.4.4 "Implementasi Integrasi Model Machine Learning" karena fitur ini berhubungan langsung dengan integrasi frontend, backend, readiness data, endpoint inferensi, dan visualisasi hasil prediksi.
