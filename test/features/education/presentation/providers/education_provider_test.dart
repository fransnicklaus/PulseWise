import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/education/data/datasources/education_api.dart';
import 'package:pulsewise/features/education/data/models/education_models.dart';
import 'package:pulsewise/features/education/presentation/providers/education_provider.dart';

void main() {
  group('EducationArticleDetailState', () {
    test('copyWith replaces article/comments and clears comments error', () {
      final state = EducationArticleDetailState(
        article: _article(likeCount: 1),
        commentsPage: _commentsPage([_comment('comment-1')]),
      ).withCommentsError(Exception('Komentar gagal'), StackTrace.current);

      final updated = state.copyWith(
        article: _article(likeCount: 2),
        commentsPage: _commentsPage([_comment('comment-2')]),
      );

      expect(updated.article.likeCount, 2);
      expect(updated.commentsPage!.items.single.commentId, 'comment-2');
      expect(updated.commentsError, isNull);
      expect(updated.commentsStackTrace, isNull);
    });
  });

  group('EducationArticleDetailController', () {
    test('loads article and comments on init', () async {
      final api = _FakeEducationApi();
      final controller = EducationArticleDetailController(
        api: api,
        slug: 'healthy-heart',
      );
      addTearDown(controller.dispose);

      final state = await _waitForData(controller);

      expect(api.fetchArticleDetailCalls, 1);
      expect(api.fetchArticleCommentsCalls, 1);
      expect(state.article.slug, 'healthy-heart');
      expect(state.commentsPage!.items.single.commentId, 'comment-1');
    });

    test('keeps article data and stores comments error when comments fail',
        () async {
      final api = _FakeEducationApi(
        fetchCommentsHandler: (articleId) async {
          throw Exception('Komentar gagal');
        },
      );
      final controller = EducationArticleDetailController(
        api: api,
        slug: 'healthy-heart',
      );
      addTearDown(controller.dispose);

      final state = await _waitForData(controller);

      expect(state.article.articleId, 'article-1');
      expect(state.commentsPage, isNull);
      expect(state.commentsError, isA<Exception>());
    });

    test('toggleLike updates article and calls like or unlike API', () async {
      final api = _FakeEducationApi();
      final controller = EducationArticleDetailController(
        api: api,
        slug: 'healthy-heart',
      );
      addTearDown(controller.dispose);
      await _waitForData(controller);

      await controller.toggleLike();
      var state = controller.state.valueOrNull!;
      expect(api.likeArticleCalls, 1);
      expect(state.article.likedByMe, isTrue);
      expect(state.article.likeCount, 2);

      await controller.toggleLike();
      state = controller.state.valueOrNull!;
      expect(api.unlikeArticleCalls, 1);
      expect(state.article.likedByMe, isFalse);
      expect(state.article.likeCount, 1);
    });

    test('toggleLike rolls back optimistic state when API fails', () async {
      final api = _FakeEducationApi(
        likeHandler: (articleId) async {
          throw Exception('Like gagal');
        },
      );
      final controller = EducationArticleDetailController(
        api: api,
        slug: 'healthy-heart',
      );
      addTearDown(controller.dispose);
      final initial = await _waitForData(controller);

      await expectLater(controller.toggleLike(), throwsA(isA<Exception>()));

      final state = controller.state.valueOrNull!;
      expect(state.article.likedByMe, initial.article.likedByMe);
      expect(state.article.likeCount, initial.article.likeCount);
    });

    test('comment mutations update comment tree and counters', () async {
      final api = _FakeEducationApi();
      final controller = EducationArticleDetailController(
        api: api,
        slug: 'healthy-heart',
      );
      addTearDown(controller.dispose);
      await _waitForData(controller);

      await controller.addComment('New comment');
      var state = controller.state.valueOrNull!;
      expect(api.createArticleCommentCalls, 1);
      expect(state.commentsPage!.items.first.commentId, 'created-comment');
      expect(state.article.commentCount, 2);

      await controller.replyToComment(
        parentCommentId: 'comment-1',
        content: 'Reply',
      );
      state = controller.state.valueOrNull!;
      final parent = state.commentsPage!.items
          .singleWhere((comment) => comment.commentId == 'comment-1');
      expect(api.replyToCommentCalls, 1);
      expect(parent.replies.single.commentId, 'created-reply');
      expect(state.article.commentCount, 3);

      await controller.editComment(
        commentId: 'created-reply',
        content: 'Edited reply',
      );
      state = controller.state.valueOrNull!;
      final editedParent = state.commentsPage!.items
          .singleWhere((comment) => comment.commentId == 'comment-1');
      expect(api.updateCommentCalls, 1);
      expect(editedParent.replies.single.content, 'Edited reply');

      await controller.deleteComment('comment-1');
      state = controller.state.valueOrNull!;
      expect(api.deleteCommentCalls, 1);
      expect(
        state.commentsPage!.items
            .where((comment) => comment.commentId == 'comment-1'),
        isEmpty,
      );
      expect(state.article.commentCount, 1);
    });

    test('deleteComment does nothing when comment id is absent', () async {
      final api = _FakeEducationApi();
      final controller = EducationArticleDetailController(
        api: api,
        slug: 'healthy-heart',
      );
      addTearDown(controller.dispose);
      await _waitForData(controller);

      await controller.deleteComment('missing-comment');

      expect(api.deleteCommentCalls, 0);
      expect(controller.state.valueOrNull!.commentsPage!.items, hasLength(1));
    });
  });
}

Future<EducationArticleDetailState> _waitForData(
  EducationArticleDetailController controller,
) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    final state = controller.state.valueOrNull;
    if (state != null) return state;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Education controller did not emit data state.');
}

typedef _CommentsHandler = Future<EducationCommentsPage> Function(
  String articleId,
);
typedef _LikeHandler = Future<bool> Function(String articleId);

class _FakeEducationApi extends EducationApi {
  _FakeEducationApi({
    this.fetchCommentsHandler,
    this.likeHandler,
  }) : super(Dio());

  final _CommentsHandler? fetchCommentsHandler;
  final _LikeHandler? likeHandler;

  int fetchArticleDetailCalls = 0;
  int fetchArticleCommentsCalls = 0;
  int likeArticleCalls = 0;
  int unlikeArticleCalls = 0;
  int createArticleCommentCalls = 0;
  int replyToCommentCalls = 0;
  int updateCommentCalls = 0;
  int deleteCommentCalls = 0;

  @override
  Future<EducationArticle> fetchArticleDetail(String slug) async {
    fetchArticleDetailCalls++;
    return _article(slug: slug, likeCount: 1, commentCount: 1);
  }

  @override
  Future<EducationCommentsPage> fetchArticleComments(
    String articleId, {
    int limit = 20,
  }) async {
    fetchArticleCommentsCalls++;
    final handler = fetchCommentsHandler;
    if (handler != null) return handler(articleId);
    return _commentsPage([_comment('comment-1')]);
  }

  @override
  Future<bool> likeArticle(String articleId) async {
    likeArticleCalls++;
    final handler = likeHandler;
    if (handler != null) return handler(articleId);
    return true;
  }

  @override
  Future<bool> unlikeArticle(String articleId) async {
    unlikeArticleCalls++;
    return false;
  }

  @override
  Future<EducationComment> createArticleComment(
    String articleId, {
    required String content,
  }) async {
    createArticleCommentCalls++;
    return _comment('created-comment', content: content);
  }

  @override
  Future<EducationComment> replyToComment(
    String commentId, {
    required String content,
  }) async {
    replyToCommentCalls++;
    return _comment(
      'created-reply',
      parentCommentId: commentId,
      content: content,
    );
  }

  @override
  Future<void> updateComment(
    String commentId, {
    required String content,
  }) async {
    updateCommentCalls++;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    deleteCommentCalls++;
  }
}

EducationArticle _article({
  String slug = 'healthy-heart',
  int likeCount = 0,
  int commentCount = 0,
  bool likedByMe = false,
}) {
  return EducationArticle(
    articleId: 'article-1',
    authorUserId: 'doctor-1',
    slug: slug,
    title: 'Healthy Heart',
    excerpt: 'Short summary',
    contentMarkdown: '# Content',
    coverImageUrl: 'cover.png',
    status: 'published',
    visibility: 'public',
    category: null,
    author: null,
    tags: const [],
    likeCount: likeCount,
    commentCount: commentCount,
    viewCount: 10,
    likedByMe: likedByMe,
    publishedAt: null,
    createdAt: null,
    updatedAt: null,
  );
}

EducationCommentsPage _commentsPage(List<EducationComment> items) {
  return EducationCommentsPage(
    items: items,
    pagination: const EducationFeedPagination(
      limit: 20,
      hasMore: false,
      nextCursor: null,
    ),
  );
}

EducationComment _comment(
  String commentId, {
  String? parentCommentId,
  String? content,
  List<EducationComment> replies = const [],
}) {
  return EducationComment(
    commentId: commentId,
    articleId: 'article-1',
    userId: 'user-1',
    parentCommentId: parentCommentId,
    content: content ?? 'Comment $commentId',
    status: 'active',
    createdAt: null,
    updatedAt: null,
    author: null,
    canEdit: true,
    canDelete: true,
    replies: replies,
  );
}
