import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/education/data/datasources/education_api.dart';
import 'package:pulsewise/features/education/data/models/education_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'education-token',
    });
  });

  group('EducationApi', () {
    test('fetchArticles sends authorized request with query filters', () async {
      late RequestOptions observedOptions;
      final api = EducationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse({
            'items': [_articleJson('article-1')],
            'pagination': {
              'limit': 5,
              'hasMore': true,
              'nextCursor': 'cursor-2',
            },
          });
        },
      )));

      final feed = await api.fetchArticles(const EducationFeedQuery(
        sort: 'popular',
        limit: 5,
        categorySlug: 'heart',
        keyword: 'diet',
        cursor: 'cursor-1',
      ));

      expect(observedOptions.method, 'GET');
      expect(observedOptions.path, '/education/articles');
      expect(
          observedOptions.headers['Authorization'], 'Bearer education-token');
      expect(observedOptions.queryParameters, {
        'sort': 'popular',
        'limit': 5,
        'category': 'heart',
        'q': 'diet',
        'cursor': 'cursor-1',
      });
      expect(feed.items.single.articleId, 'article-1');
      expect(feed.pagination.nextCursor, 'cursor-2');
    });

    test('fetchArticleDetail and comments parse response data', () async {
      final observedPaths = <String>[];
      final api = EducationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedPaths.add(options.path);
          if (options.path.endsWith('/comments')) {
            return _successResponse({
              'items': [_commentJson('comment-1')],
              'pagination': {'limit': 20},
            });
          }
          return _successResponse(_articleJson('article-1'));
        },
      )));

      final article = await api.fetchArticleDetail('healthy-heart');
      final comments = await api.fetchArticleComments('article-1');

      expect(observedPaths, [
        '/education/articles/healthy-heart',
        '/education/articles/article-1/comments',
      ]);
      expect(article.articleId, 'article-1');
      expect(comments.items.single.commentId, 'comment-1');
    });

    test('like and unlike parse explicit liked flags', () async {
      final observedMethods = <String>[];
      final api = EducationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedMethods.add(options.method);
          return _successResponse({
            'liked': options.method == 'POST',
          });
        },
      )));

      final liked = await api.likeArticle('article-1');
      final unliked = await api.unlikeArticle('article-1');

      expect(observedMethods, ['POST', 'DELETE']);
      expect(liked, isTrue);
      expect(unliked, isFalse);
    });

    test('comment mutations send request bodies and parse created comments',
        () async {
      final observedBodies = <Object?>[];
      final observedPaths = <String>[];
      final api = EducationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedPaths.add(options.path);
          observedBodies.add(options.data);
          if (options.path.endsWith('/replies')) {
            return _successResponse(_commentJson(
              'reply-1',
              parentCommentId: 'comment-1',
            ));
          }
          if (options.method == 'POST') {
            return _successResponse(_commentJson('comment-1'));
          }
          return const _FakeDioResponse({'success': true});
        },
      )));

      final comment = await api.createArticleComment(
        'article-1',
        content: 'New comment',
      );
      final reply = await api.replyToComment(
        'comment-1',
        content: 'New reply',
      );
      await api.updateComment('comment-1', content: 'Edited');
      await api.deleteComment('comment-1');

      expect(comment.commentId, 'comment-1');
      expect(reply.parentCommentId, 'comment-1');
      expect(observedPaths, [
        '/education/articles/article-1/comments',
        '/education/comments/comment-1/replies',
        '/education/comments/comment-1',
        '/education/comments/comment-1',
      ]);
      expect(observedBodies[0], {'content': 'New comment'});
      expect(observedBodies[1], {'content': 'New reply'});
      expect(observedBodies[2], {'content': 'Edited'});
    });

    test('maps Dio bad response message to exception', () async {
      final api = EducationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Artikel tidak ditemukan',
          },
          statusCode: 404,
        ),
      )));

      await expectLater(
        api.fetchArticleDetail('missing'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Artikel tidak ditemukan'),
          ),
        ),
      );
    });
  });
}

_FakeDioResponse _successResponse(Object data) {
  return _FakeDioResponse({
    'success': true,
    'message': 'OK',
    'data': data,
  });
}

Dio _dioWithAdapter(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.pulsewise.test'));
  dio.httpClientAdapter = adapter;
  return dio;
}

class _FakeDioResponse {
  const _FakeDioResponse(
    this.body, {
    this.statusCode = 200,
  });

  final Map<String, dynamic> body;
  final int statusCode;
}

class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter({required this.handler});

  final FutureOr<_FakeDioResponse> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = await handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _articleJson(String articleId) {
  return {
    'articleId': articleId,
    'authorUserId': 'doctor-1',
    'slug': 'healthy-heart',
    'title': 'Healthy Heart',
    'excerpt': 'Short summary',
    'contentMarkdown': '# Content',
    'coverImageUrl': 'cover.png',
    'status': 'published',
    'visibility': 'public',
    'likeCount': 1,
    'commentCount': 0,
    'viewCount': 10,
    'likedByMe': false,
  };
}

Map<String, dynamic> _commentJson(
  String commentId, {
  String? parentCommentId,
}) {
  return {
    'commentId': commentId,
    'articleId': 'article-1',
    'userId': 'user-1',
    'parentCommentId': parentCommentId,
    'content': 'Comment $commentId',
    'status': 'active',
    'canEdit': true,
    'canDelete': true,
  };
}
