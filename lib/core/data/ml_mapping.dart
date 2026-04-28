class MlMapping {
  MlMapping._();

  static const List<String> tipe = ['selection', 'range', ''];

  static Map<String, Map<String, dynamic>> demog1 = {
    "riagendr": riagendr,
    "ridreth3": ridreth3,
    "dmdeduc": dmdeduc,
    "dmdfmsiz": dmdfmsiz,
    "dmdhhsiz": dmdhhsiz,
    "dmdhhsza": dmdhhsza,
    "dmdhhszb": dmdhhszb,
    "dmdhhsze": dmdhhsze,
    "dmdmartl": dmdmartl
  };

  static Map<String, dynamic> riagendr = {
    'pertanyaan': 'Gender',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      1: 'Laki-laki',
      2: 'Perempuan',
    })
  };

  static Map<String, dynamic> ridreth3 = {
    'pertanyaan': 'Ras/Etnis',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      1: 'Meksiko-Amerika',
      2: 'Hispanik Lainnya',
      3: 'Putih Non-Hispanik',
      4: 'Hitam Non-Hispanik',
      6: 'Asia Non-Hispanik',
      7: 'Ras Lainnya'
    })
  };

  static Map<String, dynamic> dmdeduc = {
    'pertanyaan': 'Pendidikan tertinggi yang diselesaikan',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      1: 'Di bawah kelas 9',
      2: 'Kelas 9 - 12',
      3: 'Lulus SMA atau sederajat',
      4: 'Mahasiswa atau sederajat',
      6: 'Lulus kuliah atau sederajat',
    })
  };

  static Map<String, dynamic> dmdfmsiz = {
    'pertanyaan': 'jumlah anggota keluarga',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      1: '1 orang',
      2: '2 orang',
      3: '3 orang',
      4: '4 orang',
      6: '6 orang',
      7: '7 orang atau lebih',
    })
  };

  static Map<String, dynamic> dmdhhsiz = {
    'pertanyaan': 'Jumlah orang yang tinggal serumah',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      1: '1 orang',
      2: '2 orang',
      3: '3 orang',
      4: '4 orang',
      6: '6 orang',
      7: '7 orang atau lebih',
    })
  };

  static Map<String, dynamic> dmdhhsza = {
    'pertanyaan': 'Jumlah orang dengan umur 5 tahun di bawah dalam rumah',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      0: '0 orang',
      1: '1 orang',
      2: '2 orang',
      3: '3 orang atau lebih',
    })
  };

  static Map<String, dynamic> dmdhhszb = {
    'pertanyaan': 'Jumlah orang dengan umur 6-17 tahun di bawah dalam rumah',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      0: '0 orang',
      1: '1 orang',
      2: '2 orang',
      3: '3 orang atau lebih',
    })
  };

  static Map<String, dynamic> dmdhhsze = {
    'pertanyaan': 'Jumlah orang dengan umur 60 tahun di bawah dalam rumah',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      0: '0 orang',
      1: '1 orang',
      2: '2 orang',
      3: '3 orang atau lebih',
    })
  };

  static Map<String, dynamic> dmdmartl = {
    'pertanyaan': 'Status pernikahan',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      1: 'Menikah',
      2: 'Janda/Duda',
      3: 'Cerai',
      4: 'Pisah Ranjang',
      5: 'Belum Pernah Menikah',
      6: 'Tinggal Bersama Pasangan',
      77: 'Menolak Menjawab',
      99: 'Tidak Tahu',
    })
  };

  static Map<String, Map<String, dynamic>> exam1 = {
    "bpxpls": bpxpls,
  };

  static Map<String, dynamic> bpxpls = {
    'pertanyaan': 'Detak Jantung',
    'tipe': 'range',
    'data': Map<String, dynamic>.from({
      'start': 34,
      'end': 136,
      'unit': 'bpm',
    })
  };

  static Map<String, Map<String, dynamic>> labor1 = {
    "lbdtcsi": lbdtcsi,
  };

  static Map<String, Map<String, dynamic>> labor2 = {
    "lbdtcsi": lbdtcsi,
    "urdflow1": urdflow1,
    "urdtime1": urdtime1,
    "urxvol1": urxvol1,
  };

  static Map<String, dynamic> lbdtcsi = {
    'pertanyaan': 'Total kolesterol',
    'tipe': 'range',
    'data': Map<String, dynamic>.from({
      'start': 1.97,
      'end': 11.53,
      'unit': 'mmol/L',
    })
  };

  static Map<String, dynamic> urdflow1 = {
    'pertanyaan': 'Laju aliran urin pertama',
    'tipe': 'range',
    'data': Map<String, dynamic>.from({
      'start': 0,
      'end': 53,
      'unit': 'mL/min',
    })
  };

  static Map<String, dynamic> urdtime1 = {
    'pertanyaan':
        'Berapa menit antara pengukuran urinasi terakhir dan pengukuran pertama',
    'tipe': 'range',
    'data': Map<String, dynamic>.from({
      'start': 2,
      'end': 1406,
      'unit': 'menit',
    })
  };

  static Map<String, dynamic> urxvol1 = {
    'pertanyaan': 'Volume urin pertama',
    'tipe': 'range',
    'data': Map<String, dynamic>.from({
      'start': 0,
      'end': 455,
      'unit': 'mL',
    })
  };

  static Map<String, Map<String, dynamic>> quest1 = {
    "alq111": alq111,
  };

  static Map<String, Map<String, dynamic>> quest3 = {
    "cdq009": cdq009,
    "cdq010": cdq010,
  };

  static Map<String, Map<String, dynamic>> quest7 = {
    "diq010": diq010,
  };

  static Map<String, Map<String, dynamic>> quest9 = {
    "dlq050": dlq050,
  };

  static Map<String, Map<String, dynamic>> quest11 = {
    "hiqhiq011": hiq011,
  };

  static Map<String, Map<String, dynamic>> quest12 = {
    "heq010": heq010,
    "heq030": heq030,
  };

  static Map<String, Map<String, dynamic>> quest15 = {
    "kiq022": kiq022,
    "kiq026": kiq026,
  };

  static Map<String, Map<String, dynamic>> quest16 = {
    "mcq010": mcq010,
    "mcq160b": mcq160b,
    "mcq220": mcq220,
    "mcq300a": mcq300a,
    "mcq300c": mcq300c,
  };

  static Map<String, Map<String, dynamic>> quest17 = {
    "dpq020": dpq020,
    "dpq030": dpq030,
    "dpq040": dpq040,
  };

  static Map<String, Map<String, dynamic>> quest20 = {
    "pfq061b": pfq061b,
    "pfq061c": pfq061c,
    "pfq061h": pfq061h,
  };

  static Map<String, Map<String, dynamic>> quest22 = {
    "smq020": smq020,
    "smq890": smq890,
    "smq900": smq900,
  };

  static Map<String, Map<String, dynamic>> quest23 = {
    "smd470": smd470,
  };

  static Map<String, dynamic> smq020 = {
    'pertanyaan': 'Pernah merokok setidaknya 100 batang dalam hidup',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> smq890 = {
    'pertanyaan': 'Pernah merokok setidaknya 1 cigar',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> smq900 = {
    'pertanyaan': 'Pernah menggunakan e-cigarette',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> smd470 = {
    'pertanyaan': 'Jumlah orang yang merokok di dalam rumah',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      0: 'Tidak ada',
      1: '1 orang',
      2: '2 orang',
      3: '3 orang atau lebih',
      777: 'Menolak Menjawab',
      999: 'Tidak tahu'
    })
  };

  static Map<String, dynamic> alq111 = {
    'pertanyaan': 'Pernah meminum alkohol sekalipun',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> hiq011 = {
    'pertanyaan':
        'Apakah Anda memiliki asuransi atau program jaminan kesehatan lainnya?',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> heq010 = {
    'pertanyaan': 'Pernah didiagnosis dengan penyakit Hepatitis B',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> heq030 = {
    'pertanyaan': 'Pernah didiagnosis dengan penyakit Hepatitis C',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> kiq022 = {
    'pertanyaan':
        'Pernah didiagnosis dengan ginjal yang lemah atau gagal ginjal?',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> kiq026 = {
    'pertanyaan': 'Pernah mengalami batu ginjal?',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> mcq010 = {
    'pertanyaan': 'Pernah didiagnosis dengan penyakit asma?',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> mcq160b = {
    'pertanyaan': 'Pernah diberitahu bahwa menderita gagal jantung kongestif?',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> mcq220 = {
    'pertanyaan': 'Pernah diberitahu bahwa menderita kanker atau tumor ganas?',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> mcq300a = {
    'pertanyaan':
        'Apakah ada kerabat dekat yang pernah mengalami serangan jantung?',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> mcq300c = {
    'pertanyaan': 'Apakah ada kerabat dekat yang menderita diabetes?',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> dpq020 = {
    'pertanyaan':
        'Selama 2 minggu terakhir, seberapa sering Anda terganggu oleh masalah berikut: merasa sedih, depresi, atau putus asa?',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      0: 'Tidak sama sekali',
      1: 'Beberapa hari',
      2: 'Lebih dari setengah hari (>7 hari)',
      3: 'Hampir setiap hari',
      7: 'Menolak Menjawab',
      9: 'Tidak tahu'
    })
  };

  static Map<String, dynamic> dpq030 = {
    'pertanyaan':
        'Selama 2 minggu terakhir, seberapa sering Anda terganggu oleh masalah berikut: Sulit tidur atau mudah terbangun, atau terlalu banyak tidur?',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      0: 'Tidak sama sekali',
      1: 'Beberapa hari',
      2: 'Lebih dari setengah hari (>7 hari)',
      3: 'Hampir setiap hari',
      7: 'Menolak Menjawab',
      9: 'Tidak tahu'
    })
  };

  static Map<String, dynamic> dpq040 = {
    'pertanyaan':
        'Selama 2 minggu terakhir, seberapa sering Anda terganggu oleh masalah berikut: Merasa lelah atau memiliki sedikit energi??',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      0: 'Tidak sama sekali',
      1: 'Beberapa hari',
      2: 'Lebih dari setengah hari (>7 hari)',
      3: 'Hampir setiap hari',
      7: 'Menolak Menjawab',
      9: 'Tidak tahu'
    })
  };

  static Map<String, dynamic> pfq061b = {
    'pertanyaan':
        'Seberapa sulit bagi Anda untuk berjalan sejauh 400 meter sendirian tanpa alat bantu?',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      1: 'Tidak Sulit',
      2: 'Sedikit Sulit',
      3: 'Sangat Sulit',
      4: 'Tidak Mampu Melakukan',
      5: 'Tidak Melakukan Aktivitas Ini',
      7: 'Menolak Menjawab',
      9: 'Tidak tahu'
    })
  };

  static Map<String, dynamic> pfq061c = {
    'pertanyaan':
        'Seberapa sulit bagi Anda untuk naik 10 anak tangga tanpa beristirahat, sendirian, dan tanpa alat bantu?',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      1: 'Tidak Sulit',
      2: 'Sedikit Sulit',
      3: 'Sangat Sulit',
      4: 'Tidak Mampu Melakukan',
      5: 'Tidak Melakukan Aktivitas Ini',
      7: 'Menolak Menjawab',
      9: 'Tidak tahu'
    })
  };

  static Map<String, dynamic> pfq061h = {
    'pertanyaan':
        'Seberapa sulit bagi Anda untuk berjalan dari satu ruangan ke ruangan lain di lantai yang sama, sendirian dan tanpa alat bantu?',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      1: 'Tidak Sulit',
      2: 'Sedikit Sulit',
      3: 'Sangat Sulit',
      4: 'Tidak Mampu Melakukan',
      5: 'Tidak Melakukan Aktivitas Ini',
      7: 'Menolak Menjawab',
      9: 'Tidak tahu'
    })
  };

  static Map<String, dynamic> cdq009 = {
    'pertanyaan': 'Di bagian mana Anda merasakan nyeri atau ketidaknyamanan',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> cdq010 = {
    'pertanyaan':
        'Apakah Anda merasa sesak napas saat sedang berjalan terburu-buru di jalan yang rata atau saat berjalan mendaki di bukit yang landai?',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, dynamic> diq010 = {
    'pertanyaan': 'Apakah Anda diberitahu dokter bahwa Anda memiliki diabetes?',
    'tipe': 'selection',
    'data': Map<int, String>.from({
      1: 'Ya',
      2: 'Tidak',
      3: 'Ambang Batas',
      7: 'Menolak Menjawab',
      9: 'Tidak tahu'
    })
  };

  static Map<String, dynamic> dlq050 = {
    'pertanyaan':
        'Apakah Anda memiliki kesulitan serius untuk berjalan atau menaiki tangga?',
    'tipe': 'selection',
    'data': Map<int, String>.from(
        {1: 'Ya', 2: 'Tidak', 7: 'Menolak Menjawab', 9: 'Tidak tahu'})
  };

  static Map<String, Map<String, Map<String, dynamic>>> codeMaps = {
    'demog': demog1,
    'demog1': demog1,
    'exam': exam1,
    'labor1': labor1,
    'labor2': labor2,
    'quest1': quest1,
    'quest3': quest3,
    'quest7': quest7,
    'quest9': quest9,
    'quest11': quest11,
    'quest12': quest12,
    'quest15': quest15,
    'quest16': quest16,
    'quuest17': quest17,
    'quest20': quest20,
    'quest22': quest22,
    'quest23': quest23,
  };

  // Dynamic ML questionnaire mapping.
  // Update this list to add/remove/reorder fields shown in the form.
  static const List<String> form_mapping = [
    'demog1_riagendr',
    'demog1_ridreth3',
    'demog1_dmdeduc',
    'demog1_dmdfmsiz',
    'demog1_dmdhhsiz',
    'demog1_dmdhhsza',
    'demog1_dmdhhszb',
    'demog1_dmdhhsze',
    'demog1_dmdmartl',
    'quest22_smq020',
    'quest22_smq890',
    'quest22_smq900',
    'quest23_smd470',
    'quest1_alq111',
  ];

  // Reserved for future static forms.
  static const List<String> static_form_mapping = [];

  static String? getGroupFromFieldKey(String fieldKey) {
    final idx = fieldKey.indexOf('_');
    if (idx <= 0) return null;
    return fieldKey.substring(0, idx);
  }

  static String? getCodeIdFromFieldKey(String fieldKey) {
    final idx = fieldKey.indexOf('_');
    if (idx <= 0 || idx >= fieldKey.length - 1) return null;
    return fieldKey.substring(idx + 1);
  }

  static bool isValidFieldKey(String fieldKey) {
    final group = getGroupFromFieldKey(fieldKey);
    final codeId = getCodeIdFromFieldKey(fieldKey);
    if (group == null || codeId == null) return false;
    return hasCode(group, codeId);
  }

  static Map<String, dynamic>? getCodeData(String group, String codeId) {
    return codeMaps[group]?[codeId];
  }

  static String? getQuestion(String group, String codeId) {
    final item = getCodeData(group, codeId);
    return item?['pertanyaan'] as String?;
  }

  static String? getType(String group, String codeId) {
    final item = getCodeData(group, codeId);
    return item?['tipe'] as String?;
  }

  static bool isSelection(String group, String codeId) {
    return getType(group, codeId) == 'selection';
  }

  static bool isRange(String group, String codeId) {
    return getType(group, codeId) == 'range';
  }

  static Map<int, String> getOptions(String group, String codeId) {
    final item = getCodeData(group, codeId);
    final data = item?['data'];

    if (data is Map<int, String>) {
      return data;
    }

    if (data is Map) {
      return data.map((key, value) {
        final parsedKey = key is int ? key : int.tryParse(key.toString());
        if (parsedKey == null) {
          return MapEntry(-1, value.toString());
        }
        return MapEntry(parsedKey, value.toString());
      })
        ..remove(-1);
    }

    return <int, String>{};
  }

  static String? getOptionLabel(String group, String codeId, int optionKey) {
    return getOptions(group, codeId)[optionKey];
  }

  static Map<String, dynamic>? getRangeData(String group, String codeId) {
    final item = getCodeData(group, codeId);
    final data = item?['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static num? getRangeStart(String group, String codeId) {
    return getRangeData(group, codeId)?['start'] as num?;
  }

  static num? getRangeEnd(String group, String codeId) {
    return getRangeData(group, codeId)?['end'] as num?;
  }

  static String? getRangeUnit(String group, String codeId) {
    return getRangeData(group, codeId)?['unit'] as String?;
  }

  static bool hasGroup(String group) {
    return codeMaps.containsKey(group);
  }

  static bool hasCode(String group, String codeId) {
    return codeMaps[group]?.containsKey(codeId) ?? false;
  }

  static List<String> getCodeIds(String group) {
    return codeMaps[group]?.keys.toList() ?? <String>[];
  }

  static List<String> getGroups() {
    return codeMaps.keys.toList();
  }
}
