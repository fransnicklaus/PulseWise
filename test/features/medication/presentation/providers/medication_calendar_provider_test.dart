import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/medication/data/datasources/medication_api.dart';
import 'package:pulsewise/features/medication/data/models/medication_models.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_api_provider.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_calendar_provider.dart';

void main() {
  group('MedicationCalendarRangeQuery', () {
    test('compares date-only values and ignores time components', () {
      final first = MedicationCalendarRangeQuery(
        from: DateTime(2026, 6, 1, 8),
        to: DateTime(2026, 6, 30, 20),
      );
      final second = MedicationCalendarRangeQuery(
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 6, 30),
      );
      final different = MedicationCalendarRangeQuery(
        from: DateTime(2026, 6, 2),
        to: DateTime(2026, 6, 30),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first == different, isFalse);
    });
  });

  group('medicationCalendarRangeProvider', () {
    test('fetches calendar for requested range through MedicationApi',
        () async {
      late DateTime observedFrom;
      late DateTime observedTo;
      final api = _FakeMedicationApi(
        fetchMedicationCalendarHandler: ({
          required DateTime from,
          required DateTime to,
        }) async {
          observedFrom = from;
          observedTo = to;
          return MedicationCalendarResponse(
            range: MedicationCalendarRange(from: from, to: to),
            totalItems: 1,
            items: const [
              MedicationCalendarItem(
                eventId: 'event-1',
                scheduledDate: null,
                scheduledTime: '08:00',
                reminderId: 'reminder-1',
                medicationId: 'med-1',
                medicationLogId: null,
                name: 'Aspirin',
                color: '#FFFFFF',
                singleDose: 1,
                singleDoseUnit: 'tablet',
                status: 'open',
              ),
            ],
          );
        },
      );
      final container = ProviderContainer(
        overrides: [
          medicationApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);

      final query = MedicationCalendarRangeQuery(
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 6, 30),
      );

      final response = await container.read(
        medicationCalendarRangeProvider(query).future,
      );

      expect(observedFrom, query.from);
      expect(observedTo, query.to);
      expect(response.totalItems, 1);
      expect(response.items.single.eventId, 'event-1');
    });
  });
}

class _FakeMedicationApi extends MedicationApi {
  _FakeMedicationApi({this.fetchMedicationCalendarHandler}) : super(Dio());

  final Future<MedicationCalendarResponse> Function({
    required DateTime from,
    required DateTime to,
  })? fetchMedicationCalendarHandler;

  @override
  Future<MedicationCalendarResponse> fetchMedicationCalendar({
    required DateTime from,
    required DateTime to,
  }) async {
    final handler = fetchMedicationCalendarHandler;
    if (handler != null) {
      return handler(from: from, to: to);
    }
    return MedicationCalendarResponse(
      range: MedicationCalendarRange(from: from, to: to),
      totalItems: 0,
      items: const [],
    );
  }
}
