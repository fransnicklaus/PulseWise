import 'package:dio/dio.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';

class AdminApi {
  AdminApi(this._dio);

  final Dio _dio;

  Future<String> _readBearerToken() {
    return AppSessionStore.requireToken(
      missingMessage:
          'Bearer token tidak ditemukan. Silakan login ulang sebagai admin.',
    );
  }

  Future<Options> _authorizedOptions() async {
    final token = await _readBearerToken();
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  Exception _requestError(DioException error, String fallbackMessage) {
    if (isNetworkRequestError(error)) {
      throw error;
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return Exception(message);
      }
    }

    return Exception(fallbackMessage);
  }

  Future<AdminOverview> fetchOverview() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/overview',
        options: await _authorizedOptions(),
      );

      final data = _extractDataMap(
        response.data,
        fallbackMessage: 'Gagal mengambil ringkasan admin',
      );
      return AdminOverview.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil ringkasan admin.');
    }
  }

  Future<AdminUsersPageData> fetchUsers({
    int page = 1,
    int limit = 20,
    String query = '',
    String? role,
    String? accountStatus,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    if ((role ?? '').trim().isNotEmpty) {
      params['role'] = role!.trim();
    }
    if ((accountStatus ?? '').trim().isNotEmpty) {
      params['accountStatus'] = accountStatus!.trim();
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/users',
        queryParameters: params,
        options: await _authorizedOptions(),
      );

      final data = _extractDataMap(
        response.data,
        fallbackMessage: 'Gagal mengambil daftar pengguna admin',
      );
      return AdminUsersPageData.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil daftar pengguna admin.');
    }
  }

  Future<AdminUserDetail> fetchUserDetail(String userId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/users/$userId',
        options: await _authorizedOptions(),
      );

      final data = _extractDataMap(
        response.data,
        fallbackMessage: 'Gagal mengambil detail pengguna',
      );
      return AdminUserDetail.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil detail pengguna.');
    }
  }

  Future<AdminMutationResult> updateUserStatus(
    String userId,
    AdminUpdateUserStatusRequest request,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admin/users/$userId/status',
      data: request.toJson(),
      options: await _authorizedOptions(),
    );

    return _extractMutationResult(
      response.data,
      fallbackMessage: 'Gagal memperbarui status pengguna',
    );
  }

  Future<List<AdminDoctorReviewItem>> fetchPendingDoctors() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/doctors/pending',
        options: await _authorizedOptions(),
      );

      final items = _extractDataList(
        response.data,
        fallbackMessage: 'Gagal mengambil daftar dokter pending',
      );
      return items
          .map(
            (item) => AdminDoctorReviewItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil daftar dokter pending.');
    }
  }

  Future<List<AdminDoctorReviewItem>> fetchDoctors({
    String status = AdminAccountStatuses.pendingAdminVerification,
  }) async {
    final params = <String, dynamic>{};
    if (status.trim().isNotEmpty) {
      params['status'] = status.trim();
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/doctors',
        queryParameters: params,
        options: await _authorizedOptions(),
      );

      final items = _extractDataList(
        response.data,
        fallbackMessage: 'Gagal mengambil daftar review dokter',
      );
      return items
          .map(
            (item) => AdminDoctorReviewItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil daftar review dokter.');
    }
  }

  Future<AdminDoctorDetail> fetchDoctorDetail(String doctorId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/doctors/$doctorId',
        options: await _authorizedOptions(),
      );

      final data = _extractDataMap(
        response.data,
        fallbackMessage: 'Gagal mengambil detail dokter',
      );
      return AdminDoctorDetail.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil detail dokter.');
    }
  }

  Future<AdminMutationResult> approveDoctor(
    String doctorId,
    AdminApproveDoctorRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/admin/doctors/$doctorId/approve',
      data: request.toJson(),
      options: await _authorizedOptions(),
    );

    return _extractMutationResult(
      response.data,
      fallbackMessage: 'Gagal menyetujui dokter',
    );
  }

  Future<AdminMutationResult> rejectDoctor(
    String doctorId,
    AdminRejectDoctorRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/admin/doctors/$doctorId/reject',
      data: request.toJson(),
      options: await _authorizedOptions(),
    );

    return _extractMutationResult(
      response.data,
      fallbackMessage: 'Gagal menolak dokter',
    );
  }

  Future<AdminMutationResult> suspendDoctor(
    String doctorId,
    AdminSuspendDoctorRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/admin/doctors/$doctorId/suspend',
      data: request.toJson(),
      options: await _authorizedOptions(),
    );

    return _extractMutationResult(
      response.data,
      fallbackMessage: 'Gagal menangguhkan dokter',
    );
  }

  Future<AdminMutationResult> reactivateDoctor(String doctorId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/admin/doctors/$doctorId/reactivate',
      data: const {},
      options: await _authorizedOptions(),
    );

    return _extractMutationResult(
      response.data,
      fallbackMessage: 'Gagal mengaktifkan kembali dokter',
    );
  }

  Map<String, dynamic> _extractDataMap(
    Map<String, dynamic>? body, {
    required String fallbackMessage,
  }) {
    if (body == null || body['success'] != true) {
      throw Exception((body?['message'] ?? fallbackMessage).toString());
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Respons admin tidak valid');
    }
    return data;
  }

  List<Map<String, dynamic>> _extractDataList(
    Map<String, dynamic>? body, {
    required String fallbackMessage,
  }) {
    if (body == null || body['success'] != true) {
      throw Exception((body?['message'] ?? fallbackMessage).toString());
    }

    final data = body['data'];
    if (data is! List) {
      throw Exception('Respons daftar admin tidak valid');
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  AdminMutationResult _extractMutationResult(
    Map<String, dynamic>? body, {
    required String fallbackMessage,
  }) {
    if (body == null || body['success'] != true) {
      throw Exception((body?['message'] ?? fallbackMessage).toString());
    }

    return AdminMutationResult.fromJson(body);
  }
}
