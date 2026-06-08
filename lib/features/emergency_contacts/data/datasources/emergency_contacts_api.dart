import 'package:dio/dio.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/emergency_contacts/data/models/emergency_contact_models.dart';

class EmergencyContactsApi {
  EmergencyContactsApi(this._dio);

  final Dio _dio;

  Future<String> _readBearerToken() {
    return AppSessionStore.requireToken();
  }

  Future<String> _readPatientId() {
    return AppSessionStore.requireUserId(
      missingMessage: 'patientId tidak ditemukan. Silakan login ulang.',
    );
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
        (body?['message'] ?? 'Gagal menambah kontak dukungan').toString(),
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
        (body?['message'] ?? 'Gagal memperbarui kontak dukungan').toString(),
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
        (body?['message'] ?? 'Gagal menghapus kontak dukungan').toString(),
      );
    }
  }

  Future<EmergencyContactsPageResult> fetchPage({
    required int page,
    required int limit,
  }) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    try {
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
          .map(
              (item) => EmergencyContact.fromJson(item as Map<String, dynamic>))
          .toList();

      final pagination =
          (data['pagination'] as Map<String, dynamic>?) ?? const {};
      final totalPages = (pagination['totalPages'] as num?)?.toInt() ?? page;
      final currentPage = (pagination['page'] as num?)?.toInt() ?? page;
      final hasMore = currentPage < totalPages;

      return EmergencyContactsPageResult(
        items: items,
        page: currentPage,
        hasMore: hasMore,
      );
    } on DioException catch (e) {
      if (isNetworkRequestError(e)) {
        rethrow;
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception('Gagal mengambil kontak dukungan.');
    }
  }
}
