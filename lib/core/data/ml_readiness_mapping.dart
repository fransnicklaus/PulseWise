import 'ml_mapping.dart';

enum MlReadinessGroupType {
  profile,
  mlQuestionnaire,
  mlAssessment,
  diaryBodyMetrics,
  diaryConsumption,
  diaryActivity,
  diarySleep,
  diarySymptoms,
  unknown,
}

class MlReadinessGroup {
  const MlReadinessGroup({
    required this.type,
    required this.title,
    required this.description,
    required this.fieldCodes,
    required this.fieldLabels,
    this.buttonLabel,
    this.diarySectionTitle,
  });

  final MlReadinessGroupType type;
  final String title;
  final String description;
  final List<String> fieldCodes;
  final List<String> fieldLabels;
  final String? buttonLabel;
  final String? diarySectionTitle;

  bool get hasAction => (buttonLabel ?? '').trim().isNotEmpty;
}

class _MlReadinessGroupTemplate {
  const _MlReadinessGroupTemplate({
    required this.title,
    required this.description,
    this.buttonLabel,
    this.diarySectionTitle,
  });

  final String title;
  final String description;
  final String? buttonLabel;
  final String? diarySectionTitle;
}

final Set<String> _mlQuestionnaireFields =
    MlMapping.form_mapping.map((field) => field.trim().toUpperCase()).toSet();

final Set<String> _mlAssessmentFields = MlMapping.dynamic_form_mapping
    .map((field) => field.trim().toUpperCase())
    .toSet();

const Map<MlReadinessGroupType, _MlReadinessGroupTemplate> _groupTemplates = {
  MlReadinessGroupType.profile: _MlReadinessGroupTemplate(
    title: 'Profil Dasar',
    description:
        'Lengkapi tanggal lahir dan tinggi badan pasien. Tinggi badan juga bisa dibantu dari catatan metrik kesehatan harian.',
    buttonLabel: 'Edit profil',
  ),
  MlReadinessGroupType.mlQuestionnaire: _MlReadinessGroupTemplate(
    title: 'Kuesioner Profil ML',
    description:
        'Lengkapi data demografis, kebiasaan, dan lingkungan rumah pada kuesioner profil ML.',
    buttonLabel: 'Isi kuesioner ML',
  ),
  MlReadinessGroupType.mlAssessment: _MlReadinessGroupTemplate(
    title: 'Asesmen ML',
    description:
        'Lengkapi asesmen medis dan pertanyaan kesehatan agar prediksi ML bisa dijalankan.',
    buttonLabel: 'Isi asesmen ML',
  ),
  MlReadinessGroupType.diaryBodyMetrics: _MlReadinessGroupTemplate(
    title: 'Metriks Kesehatan Harian',
    description:
        'Isi berat badan, BMI, atau tekanan darah pada diari hari ini agar metrik kesehatan terbaca.',
    buttonLabel: 'Buka metrik kesehatan',
    diarySectionTitle: 'Metriks Kesehatan',
  ),
  MlReadinessGroupType.diaryConsumption: _MlReadinessGroupTemplate(
    title: 'Konsumsi Harian',
    description:
        'Isi konsumsi harian yang memiliki snapshot nutrisi agar kalori dan makro makanan ikut terbaca.',
    buttonLabel: 'Buka konsumsi harian',
    diarySectionTitle: 'Konsumsi Harian',
  ),
  MlReadinessGroupType.diaryActivity: _MlReadinessGroupTemplate(
    title: 'Aktivitas Harian',
    description:
        'Isi aktivitas kerja, transportasi, rekreasi, atau menit di luar ruangan pada diari hari ini.',
    buttonLabel: 'Buka aktivitas',
    diarySectionTitle: 'Aktivitas',
  ),
  MlReadinessGroupType.diarySleep: _MlReadinessGroupTemplate(
    title: 'Data Tidur',
    description:
        'Isi waktu tidur dan durasi tidur agar data istirahat harian lengkap.',
    buttonLabel: 'Buka data tidur',
    diarySectionTitle: 'Tidur',
  ),
  MlReadinessGroupType.diarySymptoms: _MlReadinessGroupTemplate(
    title: 'Gejala Harian',
    description:
        'Isi gejala yang relevan pada diari, terutama gejala nyeri dada yang terstruktur bila memang dialami.',
    buttonLabel: 'Buka gejala',
    diarySectionTitle: 'Gejala',
  ),
  MlReadinessGroupType.unknown: _MlReadinessGroupTemplate(
    title: 'Data Lainnya',
    description:
        'Masih ada beberapa field yang belum dikenali oleh aplikasi. Periksa data pasien atau hubungi tim backend bila perlu.',
  ),
};

const Map<String, String> _manualFieldLabels = {
  'DEMOG1_RIDAGEYR': 'Umur dari tanggal lahir',
  'EXAMI2_BMXHT': 'Tinggi badan',
  'EXAMI2_BMXWT': 'Berat badan',
  'EXAMI2_BMXBMI': 'BMI',
  'EXAMI1_SYSPULSE': 'Tekanan darah sistolik',
  'EXAMI1_DIAPULSE': 'Tekanan darah diastolik',
  'DIETA1_DR1TKCAL': 'Kalori harian',
  'DIETA1_DR1TPROT': 'Protein harian',
  'DIETA1_DR1TCARB': 'Karbohidrat harian',
  'DIETA1_DR1TSUGR': 'Gula harian',
  'DIETA1_DR1TFIBE': 'Serat harian',
  'DIETA1_DR1TTFAT': 'Lemak total harian',
  'DIETA1_DR1TSFAT': 'Lemak jenuh harian',
  'DIETA1_DR1TMFAT': 'Lemak tak jenuh tunggal harian',
  'DIETA1_DR1TPFAT': 'Lemak tak jenuh ganda harian',
  'DIETA1_DR1TCHOL': 'Kolesterol harian',
  'DIETA1_DR1TCALC': 'Kalsium harian',
  'QUEST19_PAD615': 'Durasi aktivitas kerja berat',
  'QUEST19_PAQ610': 'Aktivitas kerja berat',
  'QUEST19_PAD645': 'Durasi transport jalan atau sepeda',
  'QUEST19_PAQ635': 'Aktivitas transport jalan atau sepeda',
  'QUEST19_PAQ640': 'Hari transport jalan atau sepeda',
  'QUEST19_PAD660': 'Durasi aktivitas rekreasi berat',
  'QUEST19_PAQ655': 'Aktivitas rekreasi berat',
  'QUEST6_DED1225': 'Menit di luar ruangan',
  'QUEST21_SLQ3032': 'Waktu tidur',
  'QUEST21_SLD123': 'Durasi tidur',
  'QUEST3_CDQ008': 'Gejala nyeri dada terstruktur',
};

const Set<String> _profileFields = {
  'DEMOG1_RIDAGEYR',
  'EXAMI2_BMXHT',
};

const Set<String> _bodyMetricFields = {
  'EXAMI2_BMXWT',
  'EXAMI2_BMXBMI',
  'EXAMI1_SYSPULSE',
  'EXAMI1_DIAPULSE',
};

const Set<String> _consumptionFields = {
  'DIETA1_DR1TKCAL',
  'DIETA1_DR1TPROT',
  'DIETA1_DR1TCARB',
  'DIETA1_DR1TSUGR',
  'DIETA1_DR1TFIBE',
  'DIETA1_DR1TTFAT',
  'DIETA1_DR1TSFAT',
  'DIETA1_DR1TMFAT',
  'DIETA1_DR1TPFAT',
  'DIETA1_DR1TCHOL',
  'DIETA1_DR1TCALC',
};

const Set<String> _activityFields = {
  'QUEST19_PAD615',
  'QUEST19_PAQ610',
  'QUEST19_PAD645',
  'QUEST19_PAQ635',
  'QUEST19_PAQ640',
  'QUEST19_PAD660',
  'QUEST19_PAQ655',
  'QUEST6_DED1225',
};

const Set<String> _sleepFields = {
  'QUEST21_SLQ3032',
  'QUEST21_SLD123',
};

const Set<String> _symptomFields = {
  'QUEST3_CDQ008',
};

List<MlReadinessGroup> buildMlReadinessGroups(List<String> missingFields) {
  final groupedFields = <MlReadinessGroupType, List<String>>{};
  final groupedLabels = <MlReadinessGroupType, List<String>>{};

  for (final rawField in missingFields) {
    final normalizedField = _normalizeFieldCode(rawField);
    if (normalizedField.isEmpty) {
      continue;
    }

    final groupType = _resolveGroupType(normalizedField);
    final label = _resolveFieldLabel(normalizedField);

    final codes = groupedFields.putIfAbsent(groupType, () => <String>[]);
    if (!codes.contains(normalizedField)) {
      codes.add(normalizedField);
    }

    final labels = groupedLabels.putIfAbsent(groupType, () => <String>[]);
    if (!labels.contains(label)) {
      labels.add(label);
    }
  }

  const orderedTypes = [
    MlReadinessGroupType.profile,
    MlReadinessGroupType.mlQuestionnaire,
    MlReadinessGroupType.mlAssessment,
    MlReadinessGroupType.diaryBodyMetrics,
    MlReadinessGroupType.diaryConsumption,
    MlReadinessGroupType.diaryActivity,
    MlReadinessGroupType.diarySleep,
    MlReadinessGroupType.diarySymptoms,
    MlReadinessGroupType.unknown,
  ];

  return orderedTypes.where(groupedFields.containsKey).map((type) {
    final template = _groupTemplates[type]!;
    return MlReadinessGroup(
      type: type,
      title: template.title,
      description: template.description,
      buttonLabel: template.buttonLabel,
      diarySectionTitle: template.diarySectionTitle,
      fieldCodes: List.unmodifiable(groupedFields[type]!),
      fieldLabels: List.unmodifiable(groupedLabels[type]!),
    );
  }).toList(growable: false);
}

String _normalizeFieldCode(String rawField) {
  return rawField.trim().replaceAll('-', '_').replaceAll(' ', '').toUpperCase();
}

MlReadinessGroupType _resolveGroupType(String normalizedField) {
  if (_profileFields.contains(normalizedField)) {
    return MlReadinessGroupType.profile;
  }
  if (_mlQuestionnaireFields.contains(normalizedField)) {
    return MlReadinessGroupType.mlQuestionnaire;
  }
  if (_mlAssessmentFields.contains(normalizedField)) {
    return MlReadinessGroupType.mlAssessment;
  }
  if (_bodyMetricFields.contains(normalizedField)) {
    return MlReadinessGroupType.diaryBodyMetrics;
  }
  if (_consumptionFields.contains(normalizedField)) {
    return MlReadinessGroupType.diaryConsumption;
  }
  if (_activityFields.contains(normalizedField)) {
    return MlReadinessGroupType.diaryActivity;
  }
  if (_sleepFields.contains(normalizedField)) {
    return MlReadinessGroupType.diarySleep;
  }
  if (_symptomFields.contains(normalizedField)) {
    return MlReadinessGroupType.diarySymptoms;
  }
  return MlReadinessGroupType.unknown;
}

String _resolveFieldLabel(String normalizedField) {
  final manual = _manualFieldLabels[normalizedField];
  if (manual != null && manual.isNotEmpty) {
    return manual;
  }

  final lowerField = normalizedField.toLowerCase();
  final group = MlMapping.getGroupFromFieldKey(lowerField);
  final codeId = MlMapping.getCodeIdFromFieldKey(lowerField);
  if (group != null && codeId != null) {
    final question = MlMapping.getQuestion(group, codeId);
    if (question != null && question.trim().isNotEmpty) {
      return question.trim();
    }
  }

  return normalizedField;
}
