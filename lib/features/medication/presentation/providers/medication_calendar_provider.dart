import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/medication/data/models/medication_models.dart';

import 'medication_api_provider.dart';

class MedicationCalendarRangeQuery {
  final DateTime from;
  final DateTime to;

  const MedicationCalendarRangeQuery({
    required this.from,
    required this.to,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicationCalendarRangeQuery &&
        _dateOnlyKey(other.from) == _dateOnlyKey(from) &&
        _dateOnlyKey(other.to) == _dateOnlyKey(to);
  }

  @override
  int get hashCode => Object.hash(
        _dateOnlyKey(from),
        _dateOnlyKey(to),
      );

  static String _dateOnlyKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

final medicationCalendarRangeProvider = FutureProvider.autoDispose
    .family<MedicationCalendarResponse, MedicationCalendarRangeQuery>(
  (ref, query) async {
    return ref.watch(medicationApiProvider).fetchMedicationCalendar(
          from: query.from,
          to: query.to,
        );
  },
);

void invalidateMedicationCalendarCache(WidgetRef ref) {
  ref.invalidate(medicationCalendarRangeProvider);
}
