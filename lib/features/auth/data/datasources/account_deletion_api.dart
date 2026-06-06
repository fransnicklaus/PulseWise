import 'package:dio/dio.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/auth/data/models/account_deletion_models.dart';

class AccountDeletionApi {
  AccountDeletionApi(this._dio);

  final Dio _dio;

  Future<AccountDeletionRequestResult> requestAccountDeletion({
    required String confirmationText,
    required String reauthMethod,
  }) async {
    final token = await AppSessionStore.requireToken();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/account-deletion/request',
        data: {
          'confirmationText': confirmationText,
          'reauthMethod': reauthMethod,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return _parseRequestResponse(response.data);
    } on DioException catch (error) {
      _throwFromDioException(
        error,
        fallbackMessage: 'Gagal membuat permintaan penghapusan akun.',
      );
    }
  }

  Future<AccountDeletionConfirmResult> confirmAccountDeletion({
    required String deletionToken,
    String? password,
    String? otp,
    String? googleIdToken,
  }) async {
    final token = await AppSessionStore.requireToken();
    final data = <String, dynamic>{
      'deletionToken': deletionToken,
    };
    if ((password ?? '').trim().isNotEmpty) {
      data['password'] = password!.trim();
    }
    if ((otp ?? '').trim().isNotEmpty) {
      data['otp'] = otp!.trim();
    }
    if ((googleIdToken ?? '').trim().isNotEmpty) {
      data['googleIdToken'] = googleIdToken!.trim();
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/account-deletion/confirm',
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return _parseConfirmResponse(response.data);
    } on DioException catch (error) {
      _throwFromDioException(
        error,
        fallbackMessage: 'Gagal mengonfirmasi penghapusan akun.',
      );
    }
  }

  AccountDeletionRequestResult _parseRequestResponse(
      Map<String, dynamic>? body) {
    final payload = body ?? const <String, dynamic>{};
    if (payload['success'] == true && payload['data'] is Map<String, dynamic>) {
      return AccountDeletionRequestResult.fromJson(
        payload['data'] as Map<String, dynamic>,
      );
    }

    _throwFromBody(
      payload,
      fallbackMessage: 'Gagal membuat permintaan penghapusan akun.',
    );
  }

  AccountDeletionConfirmResult _parseConfirmResponse(
      Map<String, dynamic>? body) {
    final payload = body ?? const <String, dynamic>{};
    if (payload['success'] == true && payload['data'] is Map<String, dynamic>) {
      return AccountDeletionConfirmResult.fromJson(
        payload['data'] as Map<String, dynamic>,
      );
    }

    _throwFromBody(
      payload,
      fallbackMessage: 'Gagal mengonfirmasi penghapusan akun.',
    );
  }

  Never _throwFromDioException(
    DioException error, {
    required String fallbackMessage,
  }) {
    if (isNetworkRequestError(error)) {
      throw Exception(
        'Koneksi internet tidak tersedia atau sedang tidak stabil.',
      );
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      _throwFromBody(data, fallbackMessage: fallbackMessage);
    }

    final message = (error.message ?? '').trim();
    throw Exception(message.isEmpty ? fallbackMessage : message);
  }

  Never _throwFromBody(
    Map<String, dynamic> body, {
    required String fallbackMessage,
  }) {
    final details = body['details'];
    throw AccountDeletionException(
      (body['message'] ?? fallbackMessage).toString(),
      availableReauthMethods: details is Map<String, dynamic>
          ? parseAccountDeletionMethods(details['availableReauthMethods'])
          : const [],
      fieldErrors: parseAccountDeletionFieldErrors(details),
    );
  }
}
