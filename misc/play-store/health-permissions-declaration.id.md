# Health Data Permissions Declaration - Bahasa Indonesia

## Ringkasan Release

PulseWise adalah aplikasi wellness konsumen yang membantu pengguna mencatat kebiasaan harian, rutinitas pribadi, dan ringkasan wearable dalam satu tempat. Build release ini hanya membaca data Health Connect jika pengguna secara sukarela menghubungkan wearable dan memberikan izin baca yang diminta.

Data Health Connect digunakan hanya untuk:
- menyinkronkan data wearable ke catatan harian PulseWise;
- menampilkan ringkasan aktivitas, tidur, detak jantung, dan langkah dalam tampilan wellness non-diagnostik;
- mengurangi kebutuhan input manual;
- membantu pengguna melihat pola kebiasaan pribadi dari waktu ke waktu.

Data ini tidak digunakan untuk iklan, profiling iklan, penjualan data, penentuan kelayakan kredit atau asuransi, diagnosis, pengobatan, atau rekomendasi medis.

Catatan: build release ini tidak meminta izin `android.permission.ACTIVITY_RECOGNITION`. Akses aktivitas dan kebugaran pada aplikasi ini dilakukan melalui Health Connect setelah pengguna memberikan persetujuan.

---

## Exercise

### `android.permission.health.READ_EXERCISE`

PulseWise meminta izin `android.permission.health.READ_EXERCISE` agar aplikasi dapat membaca sesi aktivitas atau olahraga dari wearable yang terhubung ke Health Connect setelah pengguna memberikan izin.

Data exercise digunakan untuk:
- mengisi catatan aktivitas secara otomatis di catatan harian;
- menampilkan durasi, waktu, dan jenis aktivitas dalam ringkasan pribadi;
- merangkum kebiasaan aktivitas mingguan secara sederhana;
- mengurangi kebutuhan input manual ketika pengguna sudah memakai wearable.

PulseWise hanya meminta akses baca. Data ini digunakan untuk fitur yang terlihat langsung oleh pengguna di dalam aplikasi dan tidak digunakan untuk iklan atau tujuan tersembunyi lainnya.

---

## Steps

### `android.permission.health.READ_STEPS`

PulseWise meminta izin `android.permission.health.READ_STEPS` agar aplikasi dapat membaca data langkah dari Health Connect setelah pengguna memilih sinkronisasi wearable.

Data langkah digunakan untuk:
- menampilkan total langkah pengguna dari wearable atau perangkat yang terhubung;
- membantu pengguna memverifikasi bahwa sinkronisasi wearable sudah berjalan;
- menambah konteks aktivitas harian di catatan dan ringkasan wellness;
- mengurangi kebutuhan pencatatan manual untuk aktivitas ringan sehari-hari.

PulseWise hanya membaca data langkah yang diizinkan oleh pengguna. Data ini tidak digunakan untuk iklan, penjualan data, diagnosis, atau keputusan medis.

---

## Sleep

### `android.permission.health.READ_SLEEP`

PulseWise meminta izin `android.permission.health.READ_SLEEP` agar aplikasi dapat membaca data tidur dari Health Connect setelah pengguna menyetujui sinkronisasi wearable.

Data tidur digunakan untuk:
- mengisi catatan tidur secara otomatis di dalam aplikasi;
- menampilkan jam tidur, jam bangun, dan durasi tidur dalam ringkasan harian;
- membantu pengguna melihat pola tidur pribadi dari waktu ke waktu;
- mengurangi kebutuhan input manual.

Data tidur dipakai hanya untuk fungsi wellness yang terlihat oleh pengguna dan tidak dipakai untuk iklan, penjualan data, diagnosis, atau pengobatan.

---

## Heart rate

### `android.permission.health.READ_HEART_RATE`

PulseWise meminta izin `android.permission.health.READ_HEART_RATE` agar aplikasi dapat membaca data detak jantung dari Health Connect setelah pengguna memberikan izin.

Data detak jantung digunakan untuk:
- mengisi metrik tubuh secara otomatis bila data tersedia dari wearable;
- menampilkan ringkasan detak jantung sebagai bagian dari catatan dan insight wellness pribadi;
- membantu pengguna membandingkan data dari waktu ke waktu tanpa harus selalu mengetik manual;
- melengkapi konteks data tidur dan aktivitas yang sudah dipilih pengguna untuk disinkronkan.

PulseWise hanya meminta akses baca terhadap data ini. Data detak jantung tidak digunakan untuk iklan, penjualan data, diagnosis, pengobatan, atau skor risiko medis.
