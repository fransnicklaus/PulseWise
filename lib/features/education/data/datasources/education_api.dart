import 'package:dio/dio.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/education/data/models/education_models.dart';

class EducationApi {
  EducationApi(this._dio);

  final Dio _dio;

  Future<String> _readBearerToken() {
    return AppSessionStore.requireToken(
      missingMessage:
          'Bearer token tidak ditemukan. Silakan login ulang untuk membuka edukasi.',
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

  Future<EducationArticlesFeed> fetchArticles(EducationFeedQuery query) async {
    final token = await _readBearerToken();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/education/articles',
        queryParameters: {
          'sort': query.sort,
          'limit': query.limit,
          if ((query.categorySlug ?? '').trim().isNotEmpty)
            'category': query.categorySlug,
          if ((query.keyword ?? '').trim().isNotEmpty) 'q': query.keyword,
          if ((query.cursor ?? '').trim().isNotEmpty) 'cursor': query.cursor,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal mengambil daftar artikel edukasi')
              .toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return EducationArticlesFeed.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil daftar artikel edukasi.');
    }
  }

  Future<EducationArticle> fetchArticleDetail(String slug) async {
    final token = await _readBearerToken();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/education/articles/$slug',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal mengambil detail artikel edukasi')
              .toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return EducationArticle.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil detail artikel edukasi.');
    }
  }

  Future<EducationCommentsPage> fetchArticleComments(
    String articleId, {
    int limit = 20,
  }) async {
    final token = await _readBearerToken();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/education/articles/$articleId/comments',
        queryParameters: {
          'limit': limit,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal mengambil komentar artikel edukasi')
              .toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return EducationCommentsPage.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil komentar artikel edukasi.');
    }
  }

  Future<bool> likeArticle(String articleId) async {
    final token = await _readBearerToken();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/education/articles/$articleId/likes',
        data: const <String, dynamic>{},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal menyukai artikel edukasi').toString(),
        );
      }

      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return data['liked'] == true;
      }

      return true;
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal menyukai artikel edukasi.');
    }
  }

  Future<bool> unlikeArticle(String articleId) async {
    final token = await _readBearerToken();

    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/education/articles/$articleId/likes',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal membatalkan like artikel edukasi')
              .toString(),
        );
      }

      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return data['liked'] == true;
      }

      return false;
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal membatalkan like artikel edukasi.');
    }
  }

  Future<EducationComment> createArticleComment(
    String articleId, {
    required String content,
  }) async {
    final token = await _readBearerToken();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/education/articles/$articleId/comments',
        data: {
          'content': content,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal mengirim komentar artikel edukasi')
              .toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return EducationComment.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengirim komentar artikel edukasi.');
    }
  }

  Future<EducationComment> replyToComment(
    String commentId, {
    required String content,
  }) async {
    final token = await _readBearerToken();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/education/comments/$commentId/replies',
        data: {
          'content': content,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal mengirim balasan komentar').toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return EducationComment.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengirim balasan komentar.');
    }
  }

  Future<void> updateComment(
    String commentId, {
    required String content,
  }) async {
    final token = await _readBearerToken();

    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/education/comments/$commentId',
        data: {
          'content': content,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal memperbarui komentar').toString(),
        );
      }
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal memperbarui komentar.');
    }
  }

  Future<void> deleteComment(String commentId) async {
    final token = await _readBearerToken();

    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/education/comments/$commentId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal menghapus komentar').toString(),
        );
      }
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal menghapus komentar.');
    }
  }
}
