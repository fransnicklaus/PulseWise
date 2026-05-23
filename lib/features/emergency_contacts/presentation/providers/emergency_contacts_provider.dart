import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/emergency_contacts/data/datasources/emergency_contacts_api.dart';
import 'package:pulsewise/features/emergency_contacts/data/models/emergency_contact_models.dart';

final emergencyContactsApiProvider = Provider<EmergencyContactsApi>((ref) {
  return EmergencyContactsApi(ref.watch(apiDioProvider));
});

final emergencyContactsProvider =
    StateNotifierProvider<EmergencyContactsNotifier, EmergencyContactsState>(
  (ref) => EmergencyContactsNotifier(ref.watch(emergencyContactsApiProvider)),
);

class EmergencyContactsNotifier extends StateNotifier<EmergencyContactsState> {
  EmergencyContactsNotifier(this._api) : super(const EmergencyContactsState());

  final EmergencyContactsApi _api;

  static const _defaultLimit = 20;

  Future<void> fetchInitial() async {
    if (state.isLoadingInitial) return;

    state = state.copyWith(
      isLoadingInitial: true,
      isLoadingMore: false,
      error: null,
      items: const [],
      page: 1,
      hasMore: true,
    );

    try {
      final result = await _api.fetchPage(page: 1, limit: _defaultLimit);
      state = state.copyWith(
        isLoadingInitial: false,
        items: result.items,
        page: result.page,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingInitial: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoadingInitial || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final nextPage = state.page + 1;
      final result = await _api.fetchPage(page: nextPage, limit: _defaultLimit);
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...result.items],
        page: result.page,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addEmergencyContact({
    required String contactLabel,
    required String contactNumber,
    required bool isPriority,
  }) async {
    await _api.addEmergencyContact(
      contactLabel: contactLabel,
      contactNumber: contactNumber,
      isPriority: isPriority,
    );
  }

  Future<void> updateEmergencyContact({
    required String emergencyContactId,
    required String contactLabel,
    required String contactNumber,
    required bool isPriority,
  }) async {
    await _api.updateEmergencyContact(
      emergencyContactId: emergencyContactId,
      contactLabel: contactLabel,
      contactNumber: contactNumber,
      isPriority: isPriority,
    );
  }

  Future<void> updateEmergencyContactPriority({
    required String emergencyContactId,
    required String contactLabel,
    required bool isPriority,
  }) async {
    await _api.updateEmergencyContactPriority(
      emergencyContactId: emergencyContactId,
      contactLabel: contactLabel,
      isPriority: isPriority,
    );
  }

  Future<void> switchPrimaryEmergencyContact(String newPrimaryId) async {
    final newPrimary = state.items
        .where((item) => item.emergencyContactId == newPrimaryId)
        .cast<EmergencyContact?>()
        .firstWhere(
          (item) => item != null,
          orElse: () => null,
        );

    if (newPrimary == null) {
      throw Exception('Kontak darurat yang dipilih tidak ditemukan.');
    }

    final currentPrimary = state.items
        .where((item) => item.isPrioritas == true)
        .cast<EmergencyContact?>()
        .firstWhere(
          (item) => item != null,
          orElse: () => null,
        );

    if (currentPrimary != null &&
        currentPrimary.emergencyContactId != newPrimary.emergencyContactId) {
      await updateEmergencyContactPriority(
        emergencyContactId: currentPrimary.emergencyContactId,
        contactLabel: currentPrimary.contactLabel,
        isPriority: false,
      );
    }

    if (newPrimary.isPrioritas != true) {
      await updateEmergencyContactPriority(
        emergencyContactId: newPrimary.emergencyContactId,
        contactLabel: newPrimary.contactLabel,
        isPriority: true,
      );
    }

    await fetchInitial();
  }

  Future<void> deleteEmergencyContact(String emergencyContactId) async {
    await _api.deleteEmergencyContact(emergencyContactId);
  }
}

class EmergencyContactsState {
  final List<EmergencyContact> items;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const EmergencyContactsState({
    this.items = const [],
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  EmergencyContactsState copyWith({
    List<EmergencyContact>? items,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return EmergencyContactsState(
      items: items ?? this.items,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
    );
  }
}
