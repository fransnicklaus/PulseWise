import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/medication/presentation/utils/medication_status_ui.dart';

void main() {
  group('medicationStatusUiLabel', () {
    test('returns localized labels for known statuses', () {
      expect(medicationStatusUiLabel('taken'), 'Diminum');
      expect(medicationStatusUiLabel('missed'), 'Terlewat');
      expect(medicationStatusUiLabel('skipped'), 'Dilewati');
      expect(medicationStatusUiLabel('open'), 'Belum Ditandai');
    });

    test('handles known statuses case-insensitively', () {
      expect(medicationStatusUiLabel('TAKEN'), 'Diminum');
      expect(medicationStatusUiLabel('Missed'), 'Terlewat');
    });

    test('returns fallback label for empty statuses', () {
      expect(medicationStatusUiLabel(null), 'Belum Ditandai');
      expect(medicationStatusUiLabel(''), '-');
      expect(medicationStatusUiLabel('   '), '-');
    });

    test('preserves unknown status text', () {
      expect(medicationStatusUiLabel('paused'), 'paused');
    });
  });
}
