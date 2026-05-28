import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/diary/data/datasources/diary_api.dart';
import 'package:pulsewise/features/diary/presentation/pages/riwayat_diari_page.dart';
import 'package:pulsewise/features/diary/presentation/providers/diary_history_provider.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_patient_diary_history_provider.dart';

class DoctorPatientDiaryHistoryPage extends StatelessWidget {
  const DoctorPatientDiaryHistoryPage({
    super.key,
    required this.patientId,
  });

  final String patientId;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        diaryHistoryProvider.overrideWith(
          (ref) => DoctorPatientDiaryHistoryNotifier(
            ref.watch(diaryApiProvider),
            patientId,
          ),
        ),
      ],
      child: const RiwayatDiariPage(
        title: 'Riwayat Diari Pasien',
        subtitle: 'Semua catatan harian pasien yang terhubung',
      ),
    );
  }
}
