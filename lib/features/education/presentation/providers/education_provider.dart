import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/education/data/datasources/education_api.dart';
import 'package:pulsewise/features/education/data/models/education_models.dart';

final educationApiProvider = Provider<EducationApi>((ref) {
  final dio = ref.watch(apiDioProvider);
  return EducationApi(dio);
});

final educationFeedProvider =
    FutureProvider.autoDispose.family<EducationArticlesFeed, EducationFeedQuery>(
  (ref, query) {
    return ref.watch(educationApiProvider).fetchArticles(query);
  },
);

final educationArticleDetailProvider =
    FutureProvider.autoDispose.family<EducationArticle, String>(
  (ref, slug) {
    return ref.watch(educationApiProvider).fetchArticleDetail(slug);
  },
);

final educationArticleCommentsProvider =
    FutureProvider.autoDispose.family<EducationCommentsPage, String>(
  (ref, articleId) {
    return ref.watch(educationApiProvider).fetchArticleComments(articleId);
  },
);

final educationArticleDetailControllerProvider = StateNotifierProvider
    .autoDispose
    .family<EducationArticleDetailController, AsyncValue<EducationArticleDetailState>, String>(
  (ref, slug) {
    final api = ref.watch(educationApiProvider);
    return EducationArticleDetailController(
      api: api,
      slug: slug,
    );
  },
);

class EducationArticleDetailState {
  const EducationArticleDetailState({
    required this.article,
    this.commentsPage,
    this.commentsError,
    this.commentsStackTrace,
  });

  final EducationArticle article;
  final EducationCommentsPage? commentsPage;
  final Object? commentsError;
  final StackTrace? commentsStackTrace;

  EducationArticleDetailState copyWith({
    EducationArticle? article,
    EducationCommentsPage? commentsPage,
  }) {
    return EducationArticleDetailState(
      article: article ?? this.article,
      commentsPage: commentsPage ?? this.commentsPage,
      commentsError: null,
      commentsStackTrace: null,
    );
  }

  EducationArticleDetailState withCommentsError(
    Object error,
    StackTrace? stackTrace,
  ) {
    return EducationArticleDetailState(
      article: article,
      commentsPage: commentsPage,
      commentsError: error,
      commentsStackTrace: stackTrace,
    );
  }
}

class EducationArticleDetailController
    extends StateNotifier<AsyncValue<EducationArticleDetailState>> {
  EducationArticleDetailController({
    required EducationApi api,
    required String slug,
  })  : _api = api,
        _slug = slug,
        super(const AsyncValue.loading()) {
    _loadInitial();
  }

  final EducationApi _api;
  final String _slug;

  Future<void> _loadInitial() async {
    try {
      state = AsyncValue.data(await _loadData());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<EducationArticleDetailState> _loadData() async {
    final article = await _api.fetchArticleDetail(_slug);

    try {
      final comments = await _api.fetchArticleComments(article.articleId);
      return EducationArticleDetailState(
        article: article,
        commentsPage: comments,
      );
    } catch (error, stackTrace) {
      return EducationArticleDetailState(
        article: article,
        commentsError: error,
        commentsStackTrace: stackTrace,
      );
    }
  }

  Future<void> refreshData() async {
    final previous = state.valueOrNull;

    try {
      state = AsyncValue.data(await _loadData());
    } catch (error, stackTrace) {
      if (previous == null) {
        state = AsyncValue.error(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> toggleLike() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final wasLiked = current.article.likedByMe;
    final previous = current;
    final optimisticArticle = current.article.copyWith(
      likedByMe: !wasLiked,
      likeCount: wasLiked
          ? _safeDecrement(current.article.likeCount)
          : current.article.likeCount + 1,
    );

    state = AsyncValue.data(current.copyWith(article: optimisticArticle));

    try {
      if (wasLiked) {
        await _api.unlikeArticle(current.article.articleId);
      } else {
        await _api.likeArticle(current.article.articleId);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.data(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> addComment(String content) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final created = await _api.createArticleComment(
      current.article.articleId,
      content: content,
    );

    final existingComments = current.commentsPage;
    final nextComments = (existingComments ?? _emptyCommentsPage()).copyWith(
      items: [created, ...(existingComments?.items ?? const <EducationComment>[])],
    );

    state = AsyncValue.data(
      current.copyWith(
        article: current.article.copyWith(
          commentCount: current.article.commentCount + 1,
        ),
        commentsPage: nextComments,
      ),
    );
  }

  Future<void> replyToComment({
    required String parentCommentId,
    required String content,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final commentsPage = current.commentsPage;
    if (commentsPage == null) return;

    final reply = await _api.replyToComment(
      parentCommentId,
      content: content,
    );

    state = AsyncValue.data(
      current.copyWith(
        article: current.article.copyWith(
          commentCount: current.article.commentCount + 1,
        ),
        commentsPage: commentsPage.copyWith(
          items: _appendReply(
            commentsPage.items,
            parentCommentId: parentCommentId,
            reply: reply,
          ),
        ),
      ),
    );
  }

  Future<void> editComment({
    required String commentId,
    required String content,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final commentsPage = current.commentsPage;
    if (commentsPage == null) return;

    await _api.updateComment(commentId, content: content);

    state = AsyncValue.data(
      current.copyWith(
        commentsPage: commentsPage.copyWith(
          items: _updateCommentContent(
            commentsPage.items,
            commentId: commentId,
            content: content,
          ),
        ),
      ),
    );
  }

  Future<void> deleteComment(String commentId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final commentsPage = current.commentsPage;
    if (commentsPage == null) return;

    final removedCount = _countRemovedComments(
      commentsPage.items,
      commentId: commentId,
    );

    if (removedCount <= 0) return;

    await _api.deleteComment(commentId);

    state = AsyncValue.data(
      current.copyWith(
        article: current.article.copyWith(
          commentCount: current.article.commentCount - removedCount < 0
              ? 0
              : current.article.commentCount - removedCount,
        ),
        commentsPage: commentsPage.copyWith(
          items: _removeCommentTree(
            commentsPage.items,
            commentId: commentId,
          ),
        ),
      ),
    );
  }
}

EducationCommentsPage _emptyCommentsPage() {
  return const EducationCommentsPage(
    items: [],
    pagination: EducationFeedPagination(
      limit: 20,
      hasMore: false,
      nextCursor: null,
    ),
  );
}

List<EducationComment> _appendReply(
  List<EducationComment> items, {
  required String parentCommentId,
  required EducationComment reply,
}) {
  return items.map((comment) {
    if (comment.commentId == parentCommentId) {
      return comment.copyWith(
        replies: [...comment.replies, reply],
      );
    }

    if (comment.replies.isEmpty) return comment;

    return comment.copyWith(
      replies: _appendReply(
        comment.replies,
        parentCommentId: parentCommentId,
        reply: reply,
      ),
    );
  }).toList(growable: false);
}

List<EducationComment> _updateCommentContent(
  List<EducationComment> items, {
  required String commentId,
  required String content,
}) {
  return items.map((comment) {
    if (comment.commentId == commentId) {
      return comment.copyWith(
        content: content,
        updatedAt: DateTime.now(),
      );
    }

    if (comment.replies.isEmpty) return comment;

    return comment.copyWith(
      replies: _updateCommentContent(
        comment.replies,
        commentId: commentId,
        content: content,
      ),
    );
  }).toList(growable: false);
}

List<EducationComment> _removeCommentTree(
  List<EducationComment> items, {
  required String commentId,
}) {
  return items
      .where((comment) => comment.commentId != commentId)
      .map((comment) {
        if (comment.replies.isEmpty) return comment;
        return comment.copyWith(
          replies: _removeCommentTree(
            comment.replies,
            commentId: commentId,
          ),
        );
      })
      .toList(growable: false);
}

int _countRemovedComments(
  List<EducationComment> items, {
  required String commentId,
}) {
  for (final comment in items) {
    if (comment.commentId == commentId) {
      return 1 + _countNestedReplies(comment.replies);
    }

    final nested = _countRemovedComments(
      comment.replies,
      commentId: commentId,
    );
    if (nested > 0) {
      return nested;
    }
  }

  return 0;
}

int _countNestedReplies(List<EducationComment> replies) {
  var total = 0;
  for (final reply in replies) {
    total += 1 + _countNestedReplies(reply.replies);
  }
  return total;
}

int _safeDecrement(int value) {
  if (value <= 0) return 0;
  return value - 1;
}
