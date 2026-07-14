# Lampiran Pertanyaan Form ML PulseWise

Dokumen ini merangkum daftar pertanyaan yang digunakan pada form Machine
Learning PulseWise berdasarkan `lib/core/data/ml_mapping.dart`.

Sumber mapping:

- Pertanyaan statis: `MlMapping.form_mapping`
- Pertanyaan dinamis: `MlMapping.dynamic_form_mapping`

## Pertanyaan Statis

| Field Key | Pertanyaan | Pilihan |
|---|---|---|
| `demog1_riagendr` | Gender | Laki-laki; Perempuan |
| `demog1_ridreth3` | Ras/Etnis | Meksiko-Amerika; Hispanik Lainnya; Putih Non-Hispanik; Hitam Non-Hispanik; Asia Non-Hispanik; Ras Lainnya |
| `demog1_dmdeduc` | Pendidikan tertinggi yang diselesaikan | Di bawah kelas 9; Kelas 9 - 12; Lulus SMA atau sederajat; Mahasiswa atau sederajat; Lulus kuliah atau sederajat |
| `demog1_dmdfmsiz` | jumlah anggota keluarga | 1 orang; 2 orang; 3 orang; 4 orang; 6 orang; 7 orang atau lebih |
| `demog1_dmdhhsiz` | Jumlah orang yang tinggal serumah | 1 orang; 2 orang; 3 orang; 4 orang; 6 orang; 7 orang atau lebih |
| `demog1_dmdhhsza` | Jumlah orang dengan umur 5 tahun di bawah dalam rumah | 0 orang; 1 orang; 2 orang; 3 orang atau lebih |
| `demog1_dmdhhszb` | Jumlah orang dengan umur 6-17 tahun di bawah dalam rumah | 0 orang; 1 orang; 2 orang; 3 orang atau lebih |
| `demog1_dmdhhsze` | Jumlah orang dengan umur 60 tahun di bawah dalam rumah | 0 orang; 1 orang; 2 orang; 3 orang atau lebih |
| `demog1_dmdmartl` | Status pernikahan | Menikah; Janda/Duda; Cerai; Pisah Ranjang; Belum Pernah Menikah; Tinggal Bersama Pasangan; Menolak Menjawab; Tidak Tahu |
| `quest22_smq020` | Pernah merokok setidaknya 100 batang dalam hidup | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest22_smq890` | Pernah merokok setidaknya 1 cigar | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest22_smq900` | Pernah menggunakan e-cigarette | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest23_smd470` | Jumlah orang yang merokok di dalam rumah | Tidak ada; 1 orang; 2 orang; 3 orang atau lebih; Menolak Menjawab; Tidak tahu |
| `quest1_alq111` | Pernah meminum alkohol sekalipun | Ya; Tidak; Menolak Menjawab; Tidak tahu |

## Pertanyaan Dinamis

| Field Key | Pertanyaan | Pilihan |
|---|---|---|
| `exami1_bpxpls` | Detak Jantung | Input angka, rentang 34 - 136 bpm |
| `labor1_lbdtcsi` | Total kolesterol | Input angka, rentang 1.97 - 11.53 mmol/L |
| `labor2_urdflow1` | Laju aliran urin pertama | Input angka, rentang 0 - 53 mL/min |
| `labor2_urdtime1` | Berapa menit antara pengukuran urinasi terakhir dan pengukuran pertama | Input angka, rentang 2 - 1406 menit |
| `labor2_urxvol1` | Volume urin pertama | Input angka, rentang 0 - 455 mL |
| `quest11_hiq011` | Apakah Anda memiliki asuransi atau program jaminan kesehatan lainnya? | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest12_heq010` | Pernah didiagnosis dengan penyakit Hepatitis B | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest12_heq030` | Pernah didiagnosis dengan penyakit Hepatitis C | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest15_kiq022` | Pernah didiagnosis dengan ginjal yang lemah atau gagal ginjal? | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest15_kiq026` | Pernah mengalami batu ginjal? | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest16_mcq010` | Pernah didiagnosis dengan penyakit asma? | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest16_mcq160b` | Pernah diberitahu bahwa menderita gagal jantung kongestif? | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest16_mcq220` | Pernah diberitahu bahwa menderita kanker atau tumor ganas? | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest16_mcq300a` | Apakah ada kerabat dekat yang pernah mengalami serangan jantung? | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest16_mcq300c` | Apakah ada kerabat dekat yang menderita diabetes? | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest17_dpq020` | Selama 2 minggu terakhir, seberapa sering Anda terganggu oleh masalah berikut: merasa sedih, depresi, atau putus asa? | Tidak sama sekali; Beberapa hari; Lebih dari setengah hari (>7 hari); Hampir setiap hari; Menolak Menjawab; Tidak tahu |
| `quest17_dpq030` | Selama 2 minggu terakhir, seberapa sering Anda terganggu oleh masalah berikut: Sulit tidur atau mudah terbangun, atau terlalu banyak tidur? | Tidak sama sekali; Beberapa hari; Lebih dari setengah hari (>7 hari); Hampir setiap hari; Menolak Menjawab; Tidak tahu |
| `quest17_dpq040` | Selama 2 minggu terakhir, seberapa sering Anda terganggu oleh masalah berikut: Merasa lelah atau memiliki sedikit energi?? | Tidak sama sekali; Beberapa hari; Lebih dari setengah hari (>7 hari); Hampir setiap hari; Menolak Menjawab; Tidak tahu |
| `quest20_pfq061b` | Seberapa sulit bagi Anda untuk berjalan sejauh 400 meter sendirian tanpa alat bantu? | Tidak Sulit; Sedikit Sulit; Sangat Sulit; Tidak Mampu Melakukan; Tidak Melakukan Aktivitas Ini; Menolak Menjawab; Tidak tahu |
| `quest20_pfq061c` | Seberapa sulit bagi Anda untuk naik 10 anak tangga tanpa beristirahat, sendirian, dan tanpa alat bantu? | Tidak Sulit; Sedikit Sulit; Sangat Sulit; Tidak Mampu Melakukan; Tidak Melakukan Aktivitas Ini; Menolak Menjawab; Tidak tahu |
| `quest20_pfq061h` | Seberapa sulit bagi Anda untuk berjalan dari satu ruangan ke ruangan lain di lantai yang sama, sendirian dan tanpa alat bantu? | Tidak Sulit; Sedikit Sulit; Sangat Sulit; Tidak Mampu Melakukan; Tidak Melakukan Aktivitas Ini; Menolak Menjawab; Tidak tahu |
| `quest3_cdq009` | Di bagian mana Anda merasakan nyeri atau ketidaknyamanan | Lengan Kanan; Dada Kanan; Leher; Dada atas / Upper sternum; Dada bawah / Lower sternum; Dada kiri; Lengan kiri; Ulu hati / Epigastric area |
| `quest3_cdq010` | Apakah Anda merasa sesak napas saat sedang berjalan terburu-buru di jalan yang rata atau saat berjalan mendaki di bukit yang landai? | Ya; Tidak; Menolak Menjawab; Tidak tahu |
| `quest7_diq010` | Apakah Anda diberitahu dokter bahwa Anda memiliki diabetes? | Ya; Tidak; Ambang Batas; Menolak Menjawab; Tidak tahu |
| `quest9_dlq050` | Apakah Anda memiliki kesulitan serius untuk berjalan atau menaiki tangga? | Ya; Tidak; Menolak Menjawab; Tidak tahu |
