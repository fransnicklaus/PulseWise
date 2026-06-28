import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/emergency_contacts/data/datasources/emergency_contacts_api.dart';
import 'package:pulsewise/features/emergency_contacts/data/models/emergency_contact_models.dart';
import 'package:pulsewise/features/emergency_contacts/presentation/providers/emergency_contacts_provider.dart';

void main() {
  group('EmergencyContactsNotifier', () {
    test('fetchInitial loads first page and stores pagination state', () async {
      final notifier = EmergencyContactsNotifier(_FakeEmergencyContactsApi(
        fetchPageHandler: ({required int page, required int limit}) async {
          return EmergencyContactsPageResult(
            items: [_contact('contact-1')],
            page: page,
            hasMore: true,
          );
        },
      ));

      await notifier.fetchInitial();

      expect(notifier.state.isLoadingInitial, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.items.single.emergencyContactId, 'contact-1');
      expect(notifier.state.page, 1);
      expect(notifier.state.hasMore, isTrue);
    });

    test('fetchInitial stores error when request fails', () async {
      final notifier = EmergencyContactsNotifier(_FakeEmergencyContactsApi(
        fetchPageHandler: ({required int page, required int limit}) async {
          throw Exception('Kontak gagal dimuat');
        },
      ));

      await notifier.fetchInitial();

      expect(notifier.state.isLoadingInitial, isFalse);
      expect(notifier.state.error, 'Kontak gagal dimuat');
      expect(notifier.state.errorCause, isA<Exception>());
      expect(notifier.state.items, isEmpty);
    });

    test('fetchNextPage appends items and advances page', () async {
      final notifier = EmergencyContactsNotifier(_FakeEmergencyContactsApi(
        fetchPageHandler: ({required int page, required int limit}) async {
          return EmergencyContactsPageResult(
            items: [_contact('contact-$page')],
            page: page,
            hasMore: page < 2,
          );
        },
      ));

      await notifier.fetchInitial();
      await notifier.fetchNextPage();

      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items.first.emergencyContactId, 'contact-1');
      expect(notifier.state.items.last.emergencyContactId, 'contact-2');
      expect(notifier.state.page, 2);
      expect(notifier.state.hasMore, isFalse);
    });

    test('fetchNextPage is skipped when no more pages are available', () async {
      final api = _FakeEmergencyContactsApi(
        fetchPageHandler: ({required int page, required int limit}) async {
          return EmergencyContactsPageResult(
            items: [_contact('contact-1')],
            page: page,
            hasMore: false,
          );
        },
      );
      final notifier = EmergencyContactsNotifier(api);

      await notifier.fetchInitial();
      await notifier.fetchNextPage();

      expect(api.fetchPageCalls, 1);
      expect(notifier.state.items, hasLength(1));
    });

    test('add, update, priority update, and delete delegate to API', () async {
      final api = _FakeEmergencyContactsApi();
      final notifier = EmergencyContactsNotifier(api);

      await notifier.addEmergencyContact(
        contactLabel: 'Ibu',
        contactNumber: '+6281',
        isPriority: true,
      );
      await notifier.updateEmergencyContact(
        emergencyContactId: 'contact-1',
        contactLabel: 'Ayah',
        contactNumber: '+6282',
        isPriority: false,
      );
      await notifier.updateEmergencyContactPriority(
        emergencyContactId: 'contact-2',
        contactLabel: 'Kakak',
        isPriority: true,
      );
      await notifier.deleteEmergencyContact('contact-3');

      expect(api.addRequests.single.contactLabel, 'Ibu');
      expect(api.addRequests.single.contactNumber, '+6281');
      expect(api.addRequests.single.isPriority, isTrue);
      expect(api.updateRequests.single.emergencyContactId, 'contact-1');
      expect(api.updateRequests.single.contactLabel, 'Ayah');
      expect(api.updateRequests.single.contactNumber, '+6282');
      expect(api.updateRequests.single.isPriority, isFalse);
      expect(api.priorityRequests.single.emergencyContactId, 'contact-2');
      expect(api.priorityRequests.single.contactLabel, 'Kakak');
      expect(api.priorityRequests.single.isPriority, isTrue);
      expect(api.deleteRequests, ['contact-3']);
    });

    test('switchPrimaryEmergencyContact swaps priority and refreshes list',
        () async {
      final contacts = [
        _contact('contact-1', label: 'Ibu', isPriority: true),
        _contact('contact-2', label: 'Ayah', isPriority: false),
      ];
      final api = _FakeEmergencyContactsApi(
        fetchPageHandler: ({required int page, required int limit}) async {
          return EmergencyContactsPageResult(
            items: List<EmergencyContact>.from(contacts),
            page: 1,
            hasMore: false,
          );
        },
        updatePriorityHandler: ({
          required String emergencyContactId,
          required String contactLabel,
          required bool isPriority,
        }) async {
          final index = contacts.indexWhere(
            (item) => item.emergencyContactId == emergencyContactId,
          );
          contacts[index] = _contact(
            emergencyContactId,
            label: contactLabel,
            isPriority: isPriority,
          );
        },
      );
      final notifier = EmergencyContactsNotifier(api);

      await notifier.fetchInitial();
      await notifier.switchPrimaryEmergencyContact('contact-2');

      expect(api.priorityRequests, hasLength(2));
      expect(api.priorityRequests[0].emergencyContactId, 'contact-1');
      expect(api.priorityRequests[0].isPriority, isFalse);
      expect(api.priorityRequests[1].emergencyContactId, 'contact-2');
      expect(api.priorityRequests[1].isPriority, isTrue);
      expect(api.fetchPageCalls, 2);
      expect(
        notifier.state.items
            .singleWhere((item) => item.emergencyContactId == 'contact-2')
            .isPrioritas,
        isTrue,
      );
    });

    test('switchPrimaryEmergencyContact throws when selected contact is absent',
        () async {
      final notifier = EmergencyContactsNotifier(_FakeEmergencyContactsApi(
        fetchPageHandler: ({required int page, required int limit}) async {
          return EmergencyContactsPageResult(
            items: [_contact('contact-1')],
            page: 1,
            hasMore: false,
          );
        },
      ));

      await notifier.fetchInitial();

      await expectLater(
        notifier.switchPrimaryEmergencyContact('missing-contact'),
        throwsA(isA<Exception>()),
      );
    });
  });
}

typedef _FetchPageHandler = Future<EmergencyContactsPageResult> Function({
  required int page,
  required int limit,
});

typedef _UpdatePriorityHandler = Future<void> Function({
  required String emergencyContactId,
  required String contactLabel,
  required bool isPriority,
});

class _FakeEmergencyContactsApi extends EmergencyContactsApi {
  _FakeEmergencyContactsApi({
    this.fetchPageHandler,
    this.updatePriorityHandler,
  }) : super(Dio());

  final _FetchPageHandler? fetchPageHandler;
  final _UpdatePriorityHandler? updatePriorityHandler;

  final addRequests = <_ContactMutationRequest>[];
  final updateRequests = <_ContactMutationRequest>[];
  final priorityRequests = <_ContactPriorityRequest>[];
  final deleteRequests = <String>[];

  int fetchPageCalls = 0;

  @override
  Future<EmergencyContactsPageResult> fetchPage({
    required int page,
    required int limit,
  }) async {
    fetchPageCalls++;
    final handler = fetchPageHandler;
    if (handler != null) {
      return handler(page: page, limit: limit);
    }
    return EmergencyContactsPageResult(
      items: const [],
      page: page,
      hasMore: false,
    );
  }

  @override
  Future<void> addEmergencyContact({
    required String contactLabel,
    required String contactNumber,
    required bool isPriority,
  }) async {
    addRequests.add(_ContactMutationRequest(
      contactLabel: contactLabel,
      contactNumber: contactNumber,
      isPriority: isPriority,
    ));
  }

  @override
  Future<void> updateEmergencyContact({
    required String emergencyContactId,
    required String contactLabel,
    required String contactNumber,
    required bool isPriority,
  }) async {
    updateRequests.add(_ContactMutationRequest(
      emergencyContactId: emergencyContactId,
      contactLabel: contactLabel,
      contactNumber: contactNumber,
      isPriority: isPriority,
    ));
  }

  @override
  Future<void> updateEmergencyContactPriority({
    required String emergencyContactId,
    required String contactLabel,
    required bool isPriority,
  }) async {
    priorityRequests.add(_ContactPriorityRequest(
      emergencyContactId: emergencyContactId,
      contactLabel: contactLabel,
      isPriority: isPriority,
    ));

    final handler = updatePriorityHandler;
    if (handler != null) {
      await handler(
        emergencyContactId: emergencyContactId,
        contactLabel: contactLabel,
        isPriority: isPriority,
      );
    }
  }

  @override
  Future<void> deleteEmergencyContact(String emergencyContactId) async {
    deleteRequests.add(emergencyContactId);
  }
}

class _ContactMutationRequest {
  const _ContactMutationRequest({
    this.emergencyContactId,
    required this.contactLabel,
    required this.contactNumber,
    required this.isPriority,
  });

  final String? emergencyContactId;
  final String contactLabel;
  final String contactNumber;
  final bool isPriority;
}

class _ContactPriorityRequest {
  const _ContactPriorityRequest({
    required this.emergencyContactId,
    required this.contactLabel,
    required this.isPriority,
  });

  final String emergencyContactId;
  final String contactLabel;
  final bool isPriority;
}

EmergencyContact _contact(
  String emergencyContactId, {
  String label = 'Ibu',
  bool isPriority = false,
}) {
  return EmergencyContact(
    emergencyContactId: emergencyContactId,
    userId: 'user-1',
    contactLabel: label,
    contactNumber: '+62812345678',
    createdAt: DateTime(2026, 6, 28),
    isPrioritas: isPriority,
  );
}
