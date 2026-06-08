import 'package:flutter/foundation.dart';
import 'package:pulsewise/features/diary/presentation/providers/current_diary_provider.dart';

class HealthConnectSyncService {
  final CurrentDiaryNotifier diaryNotifier;

  HealthConnectSyncService({required this.diaryNotifier});

  Future<void> syncAll() async {
    debugPrint('[HC Sync] Disabled for Play Store release.');
  }
}
