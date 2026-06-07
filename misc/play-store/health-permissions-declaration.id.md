# Health Data Permissions Declaration - Bahasa Indonesia

## Catatan Penting

Izin `android.permission.ACTIVITY_RECOGNITION` saat ini terlihat ada di manifest, tetapi saya tidak menemukan penggunaan langsung sensor langkah/aktivitas Android di kode aplikasi. Saat ini PulseWise membaca data kesehatan melalui Health Connect. Untuk review Google Play, opsi paling aman adalah:

1. hapus `ACTIVITY_RECOGNITION` dari manifest jika memang tidak dipakai, atau
2. jika tetap dipertahankan, jelaskan secara konservatif dan jangan klaim fitur yang belum benar-benar dipakai.

Di bawah ini saya tetap siapkan teks untuk semua field yang Anda tunjukkan.

---

## Activity recognition

### `android.permission.ACTIVITY_RECOGNITION`

PulseWise adalah aplikasi kesehatan yang membantu pengguna memantau kebiasaan kesehatan harian, termasuk aktivitas, tidur, detak jantung, pengobatan, dan catatan kesehatan lainnya. Izin `android.permission.ACTIVITY_RECOGNITION` diminta untuk mendukung fitur aktivitas dan kebugaran yang berkaitan dengan data aktivitas pengguna di perangkat Android.

Dalam implementasi aplikasi kami, fitur kesehatan yang berhubungan dengan aktivitas terutama ditampilkan dan dikelola melalui integrasi dengan Health Connect. Data aktivitas ini membantu pengguna melihat gambaran aktivitas harian mereka sebagai bagian dari pemantauan kesehatan secara menyeluruh.

Tujuan penggunaan data aktivitas dalam PulseWise adalah:
- membantu pengguna memantau aktivitas harian sebagai bagian dari fitur kesehatan dan kebugaran;
- melengkapi konteks data kesehatan lain seperti tidur, detak jantung, dan catatan harian kesehatan;
- mendukung fitur analisis kesehatan dan pemrosesan data kesehatan otomatis yang nantinya digunakan untuk insight dan alur machine learning di dalam aplikasi;
- menampilkan data aktivitas yang relevan agar pengguna dapat memahami pola kesehatannya dengan lebih baik.

Kami tidak menggunakan data ini untuk iklan, profiling iklan, penjualan data, atau tujuan yang tidak terkait langsung dengan fitur kesehatan di aplikasi. Data hanya digunakan untuk fungsi yang terlihat oleh pengguna di dalam PulseWise dan untuk mendukung fitur kesehatan yang memang diminta oleh pengguna.

Jika Google Play menilai izin ini tidak diperlukan untuk implementasi saat ini, kami siap menghapus izin tersebut dari manifest dan hanya menggunakan izin Health Connect yang benar-benar dibutuhkan.

---

## Exercise

### `android.permission.health.READ_EXERCISE`

PulseWise meminta izin `android.permission.health.READ_EXERCISE` agar pengguna dapat menghubungkan aplikasi dengan Health Connect dan mengizinkan PulseWise membaca data sesi aktivitas/olahraga dari perangkat atau wearable yang sudah terhubung.

Data exercise digunakan untuk fitur berikut:
- mengambil data aktivitas/olahraga pengguna secara otomatis dari Health Connect;
- menampilkan aktivitas pengguna di dalam fitur kesehatan dan pemantauan harian;
- mengubah data exercise menjadi catatan aktivitas di diary kesehatan pengguna di PulseWise;
- membantu pengguna memantau durasi aktivitas, waktu mulai dan selesai, serta konteks aktivitas fisik harian;
- melengkapi data kesehatan lain yang digunakan untuk analisis pola kesehatan;
- mendukung kesiapan data untuk fitur machine learning, prediksi kesehatan, dan rekomendasi berbasis data yang tersedia di aplikasi.

Secara teknis, aplikasi membaca data exercise session dari Health Connect setelah pengguna memberikan izin. Data yang dibaca kemudian dipakai untuk mengisi catatan aktivitas secara otomatis di PulseWise, termasuk informasi seperti waktu aktivitas, durasi aktivitas, jenis aktivitas, dan jika tersedia konteks tambahan seperti sampel detak jantung terkait sesi aktivitas tersebut.

Izin ini diminta hanya untuk fitur kesehatan yang terlihat dan bermanfaat langsung bagi pengguna. Kami tidak menggunakan data exercise untuk iklan, penjualan data, atau tujuan lain yang tidak diungkapkan kepada pengguna.

---

## Steps

### `android.permission.health.READ_STEPS`

PulseWise meminta izin `android.permission.health.READ_STEPS` untuk membaca data langkah dari Health Connect sebagai bagian dari fitur pemantauan kesehatan dan kebugaran pengguna.

Data langkah digunakan untuk:
- menampilkan data langkah pengguna yang berasal dari perangkat atau wearable yang terhubung melalui Health Connect;
- membantu pengguna memverifikasi bahwa integrasi Health Connect sudah aktif dan data kebugaran sudah berhasil terbaca di dalam aplikasi;
- memberi konteks tambahan mengenai tingkat aktivitas harian pengguna sebagai bagian dari pemantauan kesehatan secara keseluruhan;
- mendukung fitur kesehatan dan analisis kebiasaan harian di dalam aplikasi.

Dalam implementasi saat ini, PulseWise membaca data langkah dari Health Connect untuk kebutuhan tampilan dan pemeriksaan data aktivitas di dalam aplikasi. Data ini merupakan bagian dari gambaran kesehatan pengguna bersama data tidur, aktivitas, detak jantung, pengobatan, dan diary kesehatan lainnya.

Kami hanya meminta akses baca terhadap data langkah yang dibutuhkan untuk fitur yang terlihat oleh pengguna. Kami tidak menggunakan data langkah untuk iklan, penjualan data, atau tujuan lain yang tidak berkaitan langsung dengan fungsi kesehatan di PulseWise.

---

## Sleep

### `android.permission.health.READ_SLEEP`

PulseWise meminta izin `android.permission.health.READ_SLEEP` agar aplikasi dapat membaca data tidur pengguna dari Health Connect dan menggunakannya untuk fitur pemantauan kesehatan harian.

Data tidur digunakan untuk:
- mengambil data tidur secara otomatis dari Health Connect;
- mengisi catatan tidur pengguna di diary kesehatan PulseWise tanpa harus input manual;
- membantu pengguna memantau jam tidur, jam bangun, dan durasi tidur;
- memberikan konteks penting untuk evaluasi kebiasaan kesehatan harian;
- melengkapi data kesehatan yang dipakai untuk analisis pola kesehatan, prediksi berbasis machine learning, dan rekomendasi kesehatan di dalam aplikasi.

Secara teknis, setelah pengguna memberikan izin, PulseWise membaca sleep session dari Health Connect lalu menggunakannya untuk mengisi data tidur di fitur diary kesehatan. Otomatisasi ini membantu mengurangi input manual dan membuat data kesehatan yang dipakai oleh fitur analisis serta machine learning menjadi lebih lengkap dan konsisten.

Izin ini hanya digunakan untuk fitur kesehatan yang diminta oleh pengguna dan tidak digunakan untuk iklan, penjualan data, atau tujuan lain di luar fungsi inti aplikasi.

---

## Heart rate

### `android.permission.health.READ_HEART_RATE`

PulseWise meminta izin `android.permission.health.READ_HEART_RATE` agar aplikasi dapat membaca data detak jantung pengguna dari Health Connect untuk mendukung pemantauan kesehatan dan analisis data kesehatan harian.

Data detak jantung digunakan untuk:
- mengambil data detak jantung dari perangkat atau wearable yang terhubung melalui Health Connect;
- mengisi metrik tubuh pengguna secara otomatis di diary kesehatan PulseWise;
- membantu pengguna memantau kondisi kesehatan hariannya bersama data tidur, aktivitas, obat, dan catatan kesehatan lain;
- melengkapi data kesehatan yang digunakan untuk analisis tren kesehatan;
- mendukung fitur machine learning, prediksi kesehatan, dan rekomendasi berbasis data di dalam aplikasi.

Dalam implementasi aplikasi saat ini, PulseWise membaca data heart rate dari Health Connect, menghitung ringkasan yang relevan untuk penggunaan di aplikasi, lalu menggunakannya untuk memperkaya catatan kesehatan pengguna. Dengan cara ini, pengguna tidak perlu selalu memasukkan data detak jantung secara manual, dan fitur analisis kesehatan di dalam aplikasi dapat bekerja dengan data yang lebih lengkap.

Izin ini diminta hanya untuk fungsi inti kesehatan yang jelas terlihat oleh pengguna. Kami tidak menggunakan data detak jantung untuk iklan, penjualan data, atau tujuan lain yang tidak berkaitan langsung dengan fitur kesehatan PulseWise.
