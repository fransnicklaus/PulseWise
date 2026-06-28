import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/education/data/models/education_models.dart';

void main() {
  group('EducationFeedQuery', () {
    test('compares all query fields by value', () {
      const first = EducationFeedQuery(
        sort: 'popular',
        limit: 5,
        categorySlug: 'heart',
        keyword: 'diet',
        cursor: 'cursor-1',
      );
      const same = EducationFeedQuery(
        sort: 'popular',
        limit: 5,
        categorySlug: 'heart',
        keyword: 'diet',
        cursor: 'cursor-1',
      );
      const different = EducationFeedQuery(sort: 'latest');

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(different));
    });
  });

  group('EducationArticle', () {
    test('parses nested category, author, tags, counters, and dates', () {
      final article = EducationArticle.fromJson({
        'articleId': 101,
        'authorUserId': 'doctor-1',
        'slug': 'healthy-heart',
        'title': 'Healthy Heart',
        'excerpt': 'Short summary',
        'contentMarkdown': '# Content',
        'coverImageUrl': 'cover.png',
        'status': 'published',
        'visibility': 'public',
        'category': {
          'categoryId': 'cat-1',
          'slug': 'heart',
          'name': 'Heart',
          'description': 'Heart health',
          'sortOrder': '2',
          'isActive': true,
        },
        'author': {
          'userId': 'doctor-1',
          'username': 'doc',
          'role': 'doctor',
          'displayName': 'Dr Pulse',
          'badge': 'cardiology',
          'avatarPhoto': 'avatar.png',
        },
        'tags': [
          {'tagId': 1, 'slug': 'diet', 'name': 'Diet'},
          'ignored',
        ],
        'likeCount': '7',
        'commentCount': 3.9,
        'viewCount': '100',
        'likedByMe': true,
        'publishedAt': '2026-06-29T08:00:00.000Z',
        'createdAt': 'bad-date',
        'updatedAt': '2026-06-29T09:00:00.000Z',
      });

      expect(article.articleId, '101');
      expect(article.category!.sortOrder, 2);
      expect(article.author!.displayName, 'Dr Pulse');
      expect(article.tags.single.slug, 'diet');
      expect(article.likeCount, 7);
      expect(article.commentCount, 3);
      expect(article.viewCount, 100);
      expect(article.likedByMe, isTrue);
      expect(article.publishedAt, DateTime.parse('2026-06-29T08:00:00.000Z'));
      expect(article.createdAt, isNull);
      expect(article.updatedAt, DateTime.parse('2026-06-29T09:00:00.000Z'));
    });

    test('copyWith replaces provided fields and preserves others', () {
      final original = _article();

      final updated = original.copyWith(
        title: 'Updated',
        likeCount: 2,
        likedByMe: true,
      );

      expect(updated.title, 'Updated');
      expect(updated.likeCount, 2);
      expect(updated.likedByMe, isTrue);
      expect(updated.articleId, original.articleId);
      expect(updated.tags, original.tags);
    });
  });

  group('EducationArticlesFeed', () {
    test('parses items and pagination defaults', () {
      final feed = EducationArticlesFeed.fromJson({
        'items': [_articleJson('article-1'), 'ignored'],
        'pagination': {
          'limit': '5',
          'hasMore': true,
          'nextCursor': ' cursor-2 ',
        },
      });
      final emptyFeed = EducationArticlesFeed.fromJson({});

      expect(feed.items, hasLength(1));
      expect(feed.items.single.articleId, 'article-1');
      expect(feed.pagination.limit, 5);
      expect(feed.pagination.hasMore, isTrue);
      expect(feed.pagination.nextCursor, 'cursor-2');
      expect(emptyFeed.items, isEmpty);
      expect(emptyFeed.pagination.limit, 10);
      expect(emptyFeed.pagination.nextCursor, isNull);
    });
  });

  group('EducationComment', () {
    test('parses nested replies and nullable parent id', () {
      final comment = EducationComment.fromJson({
        'commentId': 'comment-1',
        'articleId': 'article-1',
        'userId': 'user-1',
        'parentCommentId': '',
        'content': 'Great article',
        'status': 'active',
        'createdAt': '2026-06-29T08:00:00.000Z',
        'updatedAt': 'bad-date',
        'author': {
          'userId': 'user-1',
          'displayName': 'Ayu',
        },
        'canEdit': true,
        'canDelete': false,
        'replies': [
          {
            'commentId': 'reply-1',
            'parentCommentId': 'comment-1',
            'content': 'Thanks',
          },
        ],
      });

      expect(comment.commentId, 'comment-1');
      expect(comment.parentCommentId, isNull);
      expect(comment.createdAt, DateTime.parse('2026-06-29T08:00:00.000Z'));
      expect(comment.updatedAt, isNull);
      expect(comment.author!.displayName, 'Ayu');
      expect(comment.canEdit, isTrue);
      expect(comment.canDelete, isFalse);
      expect(comment.replies.single.commentId, 'reply-1');
      expect(comment.replies.single.parentCommentId, 'comment-1');
    });

    test('copyWith can replace reply list', () {
      final comment = _comment('comment-1');
      final reply = _comment('reply-1', parentCommentId: 'comment-1');

      final updated = comment.copyWith(
        content: 'Updated',
        replies: [reply],
      );

      expect(updated.content, 'Updated');
      expect(updated.replies.single.commentId, 'reply-1');
      expect(updated.commentId, 'comment-1');
    });
  });

  group('EducationCommentsPage', () {
    test('parses comments and supports copyWith', () {
      final page = EducationCommentsPage.fromJson({
        'items': [_commentJson('comment-1')],
        'pagination': {
          'limit': 20,
          'hasMore': false,
        },
      });

      final updated = page.copyWith(items: [_comment('comment-2')]);

      expect(page.items.single.commentId, 'comment-1');
      expect(page.pagination.limit, 20);
      expect(page.pagination.hasMore, isFalse);
      expect(updated.items.single.commentId, 'comment-2');
      expect(updated.pagination, page.pagination);
    });
  });
}

EducationArticle _article() {
  return EducationArticle.fromJson(_articleJson('article-1'));
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

EducationComment _comment(
  String commentId, {
  String? parentCommentId,
}) {
  return EducationComment.fromJson(
    _commentJson(commentId, parentCommentId: parentCommentId),
  );
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
