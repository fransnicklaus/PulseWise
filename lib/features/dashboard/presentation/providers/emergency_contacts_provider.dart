import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';

final emergencyContactsProvider =
    StateNotifierProvider<EmergencyContactsNotifier, EmergencyContactsState>(
  (ref) => EmergencyContactsNotifier(ref.watch(apiDioProvider)),
);

class EmergencyContactsNotifier extends StateNotifier<EmergencyContactsState> {
  EmergencyContactsNotifier(this._dio) : super(const EmergencyContactsState());

  final Dio _dio;

  static const _defaultLimit = 20;

  Future<String> _readBearerToken() {
    return AppSessionStore.requireToken();
  }

  Future<String> _readPatientId() {
    return AppSessionStore.requireUserId(
      missingMessage: 'patientId tidak ditemukan. Silakan login ulang.',
    );
  }

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
      final result = await _fetchPage(page: 1, limit: _defaultLimit);
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
      final result = await _fetchPage(page: nextPage, limit: _defaultLimit);
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
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$patientId/emergency-contacts',
      data: {
        'contactLabel': contactLabel,
        'contactNumber': contactNumber,
        'isPriority': isPriority,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal menambah kontak darurat').toString(),
      );
    }
  }

  Future<void> updateEmergencyContact({
    required String emergencyContactId,
    required String contactLabel,
    required String contactNumber,
    required bool isPriority,
  }) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.put<Map<String, dynamic>>(
      '/users/$patientId/emergency-contacts/$emergencyContactId',
      data: {
        'contactLabel': contactLabel,
        'contactNumber': contactNumber,
        'isPriority': isPriority,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal memperbarui kontak darurat').toString(),
      );
    }
  }

  Future<void> updateEmergencyContactPriority({
    required String emergencyContactId,
    required String contactLabel,
    required bool isPriority,
  }) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.put<Map<String, dynamic>>(
      '/users/$patientId/emergency-contacts/$emergencyContactId',
      data: {
        'contactLabel': contactLabel,
        'isPriority': isPriority,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal memperbarui prioritas kontak').toString(),
      );
    }
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
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.delete<Map<String, dynamic>>(
      '/users/$patientId/emergency-contacts/$emergencyContactId',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal menghapus kontak darurat').toString(),
      );
    }
  }

  Future<_PageResult> _fetchPage(
      {required int page, required int limit}) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$patientId/emergency-contacts',
      queryParameters: {'page': page, 'limit': limit},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final body = response.data;
    if (body == null || body['data'] == null) {
      throw Exception('Respons emergency contact tidak valid.');
    }

    final data = body['data'] as Map<String, dynamic>;
    final rawItems = (data['items'] as List?) ?? const [];
    final items = rawItems
        .map((item) => EmergencyContact.fromJson(item as Map<String, dynamic>))
        .toList();

    final pagination =
        (data['pagination'] as Map<String, dynamic>?) ?? const {};
    final totalPages = (pagination['totalPages'] as num?)?.toInt() ?? page;
    final currentPage = (pagination['page'] as num?)?.toInt() ?? page;
    final hasMore = currentPage < totalPages;

    return _PageResult(items: items, page: currentPage, hasMore: hasMore);
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

class EmergencyContact {
  final String emergencyContactId;
  final String userId;
  final String contactLabel;
  final String contactNumber;
  final DateTime? createdAt;
  final bool? isPrioritas;

  const EmergencyContact({
    required this.emergencyContactId,
    required this.userId,
    required this.contactLabel,
    required this.contactNumber,
    required this.createdAt,
    required this.isPrioritas,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    final dynamic priorityRaw = json['isPriority'] ?? json['isPrioritas'];

    return EmergencyContact(
      emergencyContactId: (json['emergencyContactId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      contactLabel: (json['contactLabel'] ?? '').toString(),
      contactNumber: (json['contactNumber'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      isPrioritas: priorityRaw is bool
          ? priorityRaw
          : (priorityRaw?.toString().toLowerCase() == 'true'),
    );
  }
}

class _PageResult {
  final List<EmergencyContact> items;
  final int page;
  final bool hasMore;

  const _PageResult({
    required this.items,
    required this.page,
    required this.hasMore,
  });
}
