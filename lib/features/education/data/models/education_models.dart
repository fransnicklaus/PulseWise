class EducationFeedQuery {
  const EducationFeedQuery({
    this.sort = 'latest',
    this.limit = 10,
    this.categorySlug,
    this.keyword,
    this.cursor,
  });

  final String sort;
  final int limit;
  final String? categorySlug;
  final String? keyword;
  final String? cursor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EducationFeedQuery &&
        other.sort == sort &&
        other.limit == limit &&
        other.categorySlug == categorySlug &&
        other.keyword == keyword &&
        other.cursor == cursor;
  }

  @override
  int get hashCode => Object.hash(sort, limit, categorySlug, keyword, cursor);
}

class EducationCategory {
  const EducationCategory({
    required this.categoryId,
    required this.slug,
    required this.name,
    required this.description,
    required this.sortOrder,
    required this.isActive,
  });

  final String categoryId;
  final String slug;
  final String name;
  final String description;
  final int sortOrder;
  final bool isActive;

  factory EducationCategory.fromJson(Map<String, dynamic> json) {
    return EducationCategory(
      categoryId: (json['categoryId'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      sortOrder: _readInt(json['sortOrder']),
      isActive: json['isActive'] == true,
    );
  }
}

class EducationAuthor {
  const EducationAuthor({
    required this.userId,
    required this.username,
    required this.role,
    required this.displayName,
    required this.badge,
    required this.avatarPhoto,
  });

  final String userId;
  final String username;
  final String role;
  final String displayName;
  final String badge;
  final String avatarPhoto;

  factory EducationAuthor.fromJson(Map<String, dynamic> json) {
    return EducationAuthor(
      userId: (json['userId'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      badge: (json['badge'] ?? '').toString(),
      avatarPhoto: (json['avatarPhoto'] ?? '').toString(),
    );
  }

  EducationAuthor copyWith({
    String? userId,
    String? username,
    String? role,
    String? displayName,
    String? badge,
    String? avatarPhoto,
  }) {
    return EducationAuthor(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      badge: badge ?? this.badge,
      avatarPhoto: avatarPhoto ?? this.avatarPhoto,
    );
  }
}

class EducationTag {
  const EducationTag({
    required this.tagId,
    required this.slug,
    required this.name,
  });

  final String tagId;
  final String slug;
  final String name;

  factory EducationTag.fromJson(Map<String, dynamic> json) {
    return EducationTag(
      tagId: (json['tagId'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }

  EducationTag copyWith({
    String? tagId,
    String? slug,
    String? name,
  }) {
    return EducationTag(
      tagId: tagId ?? this.tagId,
      slug: slug ?? this.slug,
      name: name ?? this.name,
    );
  }
}

class EducationArticle {
  const EducationArticle({
    required this.articleId,
    required this.authorUserId,
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.contentMarkdown,
    required this.coverImageUrl,
    required this.status,
    required this.visibility,
    required this.category,
    required this.author,
    required this.tags,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.likedByMe,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String articleId;
  final String authorUserId;
  final String slug;
  final String title;
  final String excerpt;
  final String contentMarkdown;
  final String coverImageUrl;
  final String status;
  final String visibility;
  final EducationCategory? category;
  final EducationAuthor? author;
  final List<EducationTag> tags;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final bool likedByMe;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EducationArticle.fromJson(Map<String, dynamic> json) {
    return EducationArticle(
      articleId: (json['articleId'] ?? '').toString(),
      authorUserId: (json['authorUserId'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      excerpt: (json['excerpt'] ?? '').toString(),
      contentMarkdown: (json['contentMarkdown'] ?? '').toString(),
      coverImageUrl: (json['coverImageUrl'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      visibility: (json['visibility'] ?? '').toString(),
      category: _mapOrNull(json['category'], EducationCategory.fromJson),
      author: _mapOrNull(json['author'], EducationAuthor.fromJson),
      tags: _mapList(json['tags'], EducationTag.fromJson),
      likeCount: _readInt(json['likeCount']),
      commentCount: _readInt(json['commentCount']),
      viewCount: _readInt(json['viewCount']),
      likedByMe: json['likedByMe'] == true,
      publishedAt: _readDateTime(json['publishedAt']),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }

  EducationArticle copyWith({
    String? articleId,
    String? authorUserId,
    String? slug,
    String? title,
    String? excerpt,
    String? contentMarkdown,
    String? coverImageUrl,
    String? status,
    String? visibility,
    EducationCategory? category,
    EducationAuthor? author,
    List<EducationTag>? tags,
    int? likeCount,
    int? commentCount,
    int? viewCount,
    bool? likedByMe,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EducationArticle(
      articleId: articleId ?? this.articleId,
      authorUserId: authorUserId ?? this.authorUserId,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      category: category ?? this.category,
      author: author ?? this.author,
      tags: tags ?? this.tags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      likedByMe: likedByMe ?? this.likedByMe,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EducationFeedPagination {
  const EducationFeedPagination({
    required this.limit,
    required this.hasMore,
    required this.nextCursor,
  });

  final int limit;
  final bool hasMore;
  final String? nextCursor;

  factory EducationFeedPagination.fromJson(Map<String, dynamic> json) {
    final nextCursorRaw = (json['nextCursor'] ?? '').toString().trim();
    return EducationFeedPagination(
      limit: _readInt(json['limit'], fallback: 10),
      hasMore: json['hasMore'] == true,
      nextCursor: nextCursorRaw.isEmpty ? null : nextCursorRaw,
    );
  }
}

class EducationArticlesFeed {
  const EducationArticlesFeed({
    required this.items,
    required this.pagination,
  });

  final List<EducationArticle> items;
  final EducationFeedPagination pagination;

  factory EducationArticlesFeed.fromJson(Map<String, dynamic> json) {
    return EducationArticlesFeed(
      items: _mapList(json['items'], EducationArticle.fromJson),
      pagination: EducationFeedPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class EducationComment {
  const EducationComment({
    required this.commentId,
    required this.articleId,
    required this.userId,
    required this.parentCommentId,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    required this.canEdit,
    required this.canDelete,
    required this.replies,
  });

  final String commentId;
  final String articleId;
  final String userId;
  final String? parentCommentId;
  final String content;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final EducationAuthor? author;
  final bool canEdit;
  final bool canDelete;
  final List<EducationComment> replies;

  factory EducationComment.fromJson(Map<String, dynamic> json) {
    final parentId = (json['parentCommentId'] ?? '').toString().trim();
    return EducationComment(
      commentId: (json['commentId'] ?? '').toString(),
      articleId: (json['articleId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      parentCommentId: parentId.isEmpty ? null : parentId,
      content: (json['content'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: _readDateTime(json['createdAt']),
      updatedAt: _readDateTime(json['updatedAt']),
      author: _mapOrNull(json['author'], EducationAuthor.fromJson),
      canEdit: json['canEdit'] == true,
      canDelete: json['canDelete'] == true,
      replies: _mapList(json['replies'], EducationComment.fromJson),
    );
  }

  EducationComment copyWith({
    String? commentId,
    String? articleId,
    String? userId,
    String? parentCommentId,
    String? content,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    EducationAuthor? author,
    bool? canEdit,
    bool? canDelete,
    List<EducationComment>? replies,
  }) {
    return EducationComment(
      commentId: commentId ?? this.commentId,
      articleId: articleId ?? this.articleId,
      userId: userId ?? this.userId,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      replies: replies ?? this.replies,
    );
  }
}

class EducationCommentsPage {
  const EducationCommentsPage({
    required this.items,
    required this.pagination,
  });

  final List<EducationComment> items;
  final EducationFeedPagination pagination;

  factory EducationCommentsPage.fromJson(Map<String, dynamic> json) {
    return EducationCommentsPage(
      items: _mapList(json['items'], EducationComment.fromJson),
      pagination: EducationFeedPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  EducationCommentsPage copyWith({
    List<EducationComment>? items,
    EducationFeedPagination? pagination,
  }) {
    return EducationCommentsPage(
      items: items ?? this.items,
      pagination: pagination ?? this.pagination,
    );
  }
}

List<T> _mapList<T>(
  Object? value,
  T Function(Map<String, dynamic>) mapper,
) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map((entry) => mapper(Map<String, dynamic>.from(entry)))
      .toList(growable: false);
}

T? _mapOrNull<T>(
  Object? value,
  T Function(Map<String, dynamic>) mapper,
) {
  if (value is! Map) return null;
  return mapper(Map<String, dynamic>.from(value));
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? fallback;
}

DateTime? _readDateTime(Object? value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
