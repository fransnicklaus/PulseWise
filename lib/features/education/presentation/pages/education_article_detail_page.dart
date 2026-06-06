import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/education/data/models/education_models.dart';
import 'package:pulsewise/features/education/presentation/providers/education_provider.dart';

class EducationArticleDetailPage extends ConsumerStatefulWidget {
  const EducationArticleDetailPage({
    super.key,
    required this.slug,
  });

  final String slug;

  @override
  ConsumerState<EducationArticleDetailPage> createState() =>
      _EducationArticleDetailPageState();
}

class _EducationArticleDetailPageState
    extends ConsumerState<EducationArticleDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _busyCommentIds = <String>{};

  bool _isSubmittingComment = false;
  bool _isTogglingLike = false;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() {
    return ref
        .read(educationArticleDetailControllerProvider(widget.slug).notifier)
        .refreshData();
  }

  Future<void> _handleToggleLike() async {
    if (_isTogglingLike) return;

    setState(() => _isTogglingLike = true);

    try {
      await ref
          .read(educationArticleDetailControllerProvider(widget.slug).notifier)
          .toggleLike();
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, _extractErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isTogglingLike = false);
      }
    }
  }

  Future<void> _handleSubmitComment() async {
    if (_isSubmittingComment) return;

    final content = _commentController.text.trim();
    if (content.isEmpty) {
      AppToast.warning(context, 'Komentar tidak boleh kosong.');
      return;
    }

    setState(() => _isSubmittingComment = true);

    try {
      await ref
          .read(educationArticleDetailControllerProvider(widget.slug).notifier)
          .addComment(content);

      _commentController.clear();
      _commentFocusNode.unfocus();

      if (!mounted) return;
      AppToast.success(context, 'Komentar berhasil dikirim.');
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, _extractErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  Future<void> _handleReplyComment(EducationComment comment) async {
    final content = await _openCommentSheet(
      title: 'Balas Komentar',
      hintText: 'Tulis balasan Anda',
      actionLabel: 'Kirim Balasan',
    );
    if (!mounted || content == null) return;

    await _runCommentAction(
      commentId: comment.commentId,
      action: () {
        return ref
            .read(
                educationArticleDetailControllerProvider(widget.slug).notifier)
            .replyToComment(
              parentCommentId: comment.commentId,
              content: content,
            );
      },
      successMessage: 'Balasan berhasil dikirim.',
    );
  }

  Future<void> _handleEditComment(EducationComment comment) async {
    final content = await _openCommentSheet(
      title: 'Ubah Komentar',
      hintText: 'Perbarui komentar Anda',
      actionLabel: 'Simpan Perubahan',
      initialValue: comment.content,
    );
    if (!mounted || content == null) return;

    await _runCommentAction(
      commentId: comment.commentId,
      action: () {
        return ref
            .read(
                educationArticleDetailControllerProvider(widget.slug).notifier)
            .editComment(
              commentId: comment.commentId,
              content: content,
            );
      },
      successMessage: 'Komentar berhasil diperbarui.',
    );
  }

  Future<void> _handleDeleteComment(EducationComment comment) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Hapus komentar?'),
              content: const Text(
                'Komentar yang dihapus tidak bisa dikembalikan lagi.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE64060),
                  ),
                  child: const Text('Hapus'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) return;

    await _runCommentAction(
      commentId: comment.commentId,
      action: () {
        return ref
            .read(
                educationArticleDetailControllerProvider(widget.slug).notifier)
            .deleteComment(comment.commentId);
      },
      successMessage: 'Komentar berhasil dihapus.',
    );
  }

  Future<void> _runCommentAction({
    required String commentId,
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_busyCommentIds.contains(commentId)) return;

    setState(() => _busyCommentIds.add(commentId));

    try {
      await action();

      if (!mounted) return;
      AppToast.success(context, successMessage);
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, _extractErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busyCommentIds.remove(commentId));
      }
    }
  }

  Future<String?> _openCommentSheet({
    required String title,
    required String hintText,
    required String actionLabel,
    String initialValue = '',
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => _CommentActionBottomSheet(
        title: title,
        hintText: hintText,
        actionLabel: actionLabel,
        initialValue: initialValue,
      ),
    );
  }

  void _focusCommentComposer() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _commentFocusNode.requestFocus();
      }
    });
  }

  bool _isCommentBusy(String commentId) => _busyCommentIds.contains(commentId);

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(educationArticleDetailControllerProvider(widget.slug));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        title: 'Detail Artikel',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFE64060)),
        ),
        error: (error, _) {
          final isNetwork = isNetworkRequestError(error);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: isNetwork
                ? NoConnectionState.page(
                    title: 'Artikel belum bisa dibuka',
                    message:
                        'Kami belum bisa mengambil detail artikel karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                    onRetry: _handleRefresh,
                  )
                : _EducationErrorState(
                    title: 'Artikel gagal dimuat',
                    message: _extractErrorMessage(error),
                    onRetry: _handleRefresh,
                  ),
          );
        },
        data: (detail) {
          final article = detail.article;
          final commentsPage = detail.commentsPage;
          final commentsError = detail.commentsError;

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(35, 20, 35, 32),
              children: [
                if (article.coverImageUrl.isNotEmpty)
                  _ArticleCoverImage(imageUrl: article.coverImageUrl),
                if (article.coverImageUrl.isNotEmpty)
                  const SizedBox(height: 20),
                if (article.category != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _MetaPill(
                      text: article.category!.name,
                      backgroundColor: _categoryTint(article.category!.slug),
                      foregroundColor: _categoryColor(article.category!.slug),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                if (article.author != null)
                  _AuthorRow(
                    author: article.author!,
                    publishedAt: article.publishedAt,
                  ),
                if (article.author != null) const SizedBox(height: 20),
                _MarkdownArticleContent(markdown: article.contentMarkdown),
                if (article.tags.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Tags:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: article.tags
                              .map(
                                (tag) => _MetaPill(
                                  text: '#${tag.name}',
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  foregroundColor: const Color(0xFF475569),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      _InteractiveMetric(
                        icon: article.likedByMe
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        value: article.likeCount,
                        color: article.likedByMe
                            ? const Color(0xFFE64060)
                            : const Color(0xFF64748B),
                        label: 'Suka',
                        onTap: _isTogglingLike ? null : _handleToggleLike,
                      ),
                      const SizedBox(width: 36),
                      _InteractiveMetric(
                        icon: Icons.mode_comment_outlined,
                        value: article.commentCount,
                        color: const Color(0xFF64748B),
                        label: 'Komentar',
                        onTap: _focusCommentComposer,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Komentar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 14),
                _CommentComposerCard(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  isSubmitting: _isSubmittingComment,
                  onSubmit: _handleSubmitComment,
                ),
                const SizedBox(height: 18),
                if (commentsPage != null && commentsPage.items.isNotEmpty)
                  Column(
                    children: commentsPage.items
                        .map(
                          (comment) => _CommentCard(
                            comment: comment,
                            isBusy: _isCommentBusy(comment.commentId),
                            onReply: comment.parentCommentId == null
                                ? () => _handleReplyComment(comment)
                                : null,
                            onEdit: comment.canEdit
                                ? () => _handleEditComment(comment)
                                : null,
                            onDelete: comment.canDelete
                                ? () => _handleDeleteComment(comment)
                                : null,
                            isReplyBusy: _isCommentBusy,
                            onReplyEdit: _handleEditComment,
                            onReplyDelete: _handleDeleteComment,
                          ),
                        )
                        .toList(growable: false),
                  )
                else if (commentsPage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'Belum ada komentar pada artikel ini.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  )
                else if (commentsError != null)
                  isNetworkRequestError(commentsError)
                      ? NoConnectionState.card(
                          title: 'Komentar belum bisa dimuat',
                          message:
                              'Kami belum bisa mengambil komentar artikel saat ini.',
                          onRetry: _handleRefresh,
                        )
                      : _EducationErrorState(
                          title: 'Komentar gagal dimuat',
                          message: _extractErrorMessage(commentsError),
                          onRetry: _handleRefresh,
                        )
                else
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ArticleCoverImage extends StatelessWidget {
  const _ArticleCoverImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: const Color(0xFFFFF1F2),
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: Color(0xFFE64060),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.author,
    required this.publishedAt,
  });

  final EducationAuthor author;
  final DateTime? publishedAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFFFE7E7),
          backgroundImage: author.avatarPhoto.isNotEmpty
              ? NetworkImage(author.avatarPhoto)
              : null,
          child: author.avatarPhoto.isEmpty
              ? Text(
                  _initials(author.displayName),
                  style: const TextStyle(
                    color: Color(0xFFE64060),
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (author.badge.trim().isNotEmpty) author.badge,
                  if (publishedAt != null)
                    DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(
                      publishedAt!.toLocal(),
                    ),
                ].join(' • '),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentComposerCard extends StatelessWidget {
  const _CommentComposerCard({
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tulis komentar Anda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Bagikan pemikiran atau pertanyaan Anda di sini',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(18),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(isSubmitting ? 'Mengirim...' : 'Kirim Komentar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentActionBottomSheet extends StatefulWidget {
  const _CommentActionBottomSheet({
    required this.title,
    required this.hintText,
    required this.actionLabel,
    this.initialValue = '',
  });

  final String title;
  final String hintText;
  final String actionLabel;
  final String initialValue;

  @override
  State<_CommentActionBottomSheet> createState() =>
      _CommentActionBottomSheetState();
}

class _CommentActionBottomSheetState extends State<_CommentActionBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      AppToast.warning(context, 'Komentar tidak boleh kosong.');
      return;
    }

    Navigator.of(context).pop(content);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        top: 16,
        right: 18,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tulis pesan Anda dengan jelas agar lebih mudah dibaca pengguna lain.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              minLines: 5,
              maxLines: 7,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFFE64060),
                    width: 1.7,
                  ),
                ),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE64060),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      widget.actionLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkdownArticleContent extends StatelessWidget {
  const _MarkdownArticleContent({required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    if (markdown.trim().isEmpty) {
      return const Text(
        'Isi artikel belum tersedia.',
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFF64748B),
        ),
      );
    }

    return Html(
      data: _toHtml(markdown),
      extensions: [
        TagWrapExtension(
          tagsToWrap: {'blockquote'},
          builder: (child) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(18),
                border: const Border(
                  left: BorderSide(
                    color: Color(0xFFE64060),
                    width: 4,
                  ),
                ),
              ),
              child: child,
            );
          },
        ),
      ],
      style: {
        'html': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          backgroundColor: Colors.transparent,
        ),
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(16),
          lineHeight: const LineHeight(1.75),
          color: const Color(0xFF334155),
          backgroundColor: Colors.transparent,
        ),
        'p': Style(
          margin: Margins.only(bottom: 14),
          fontSize: FontSize(18),
          lineHeight: const LineHeight(1.75),
          color: const Color(0xFF334155),
        ),
        'h1': Style(
          margin: Margins.only(bottom: 16, top: 6),
          fontSize: FontSize(30),
          fontWeight: FontWeight.w900,
          lineHeight: const LineHeight(1.15),
          color: const Color(0xFF1E293B),
        ),
        'h2': Style(
          margin: Margins.only(bottom: 14, top: 6),
          fontSize: FontSize(26),
          fontWeight: FontWeight.w800,
          lineHeight: const LineHeight(1.2),
          color: const Color(0xFF1E293B),
        ),
        'h3': Style(
          margin: Margins.only(bottom: 12, top: 6),
          fontSize: FontSize(22),
          fontWeight: FontWeight.w800,
          lineHeight: const LineHeight(1.25),
          color: const Color(0xFF334155),
        ),
        'h4': Style(
          margin: Margins.only(bottom: 12, top: 6),
          fontSize: FontSize(20),
          fontWeight: FontWeight.w800,
          lineHeight: const LineHeight(1.3),
          color: const Color(0xFF334155),
        ),
        'h5': Style(
          margin: Margins.only(bottom: 10, top: 4),
          fontSize: FontSize(18),
          fontWeight: FontWeight.w800,
          lineHeight: const LineHeight(1.3),
          color: const Color(0xFF334155),
        ),
        'h6': Style(
          margin: Margins.only(bottom: 10, top: 4),
          fontSize: FontSize(16),
          fontWeight: FontWeight.w800,
          lineHeight: const LineHeight(1.35),
          color: const Color(0xFF475569),
        ),
        'blockquote': Style(
          color: const Color(0xFFBE123C),
          fontStyle: FontStyle.italic,
          fontSize: FontSize(18),
          lineHeight: const LineHeight(1.65),
          margin: Margins.zero,
          padding: HtmlPaddings.only(
            left: 18,
            top: 14,
            right: 16,
            bottom: 14,
          ),
        ),
        'ul': Style(
          margin: Margins.only(bottom: 16),
          padding: HtmlPaddings.only(left: 10),
        ),
        'ol': Style(
          margin: Margins.only(bottom: 16),
          padding: HtmlPaddings.only(left: 14),
        ),
        'li': Style(
          margin: Margins.only(bottom: 8),
          fontSize: FontSize(18),
          lineHeight: const LineHeight(1.7),
          color: const Color(0xFF334155),
        ),
        'strong': Style(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1E293B),
        ),
        'em': Style(
          fontStyle: FontStyle.italic,
          color: const Color(0xFF475569),
        ),
        'u': Style(
          textDecoration: TextDecoration.underline,
          textDecorationColor: const Color(0xFF334155),
          textDecorationThickness: 2,
        ),
        'img': Style(
          margin: Margins.only(bottom: 16),
        ),
      },
    );
  }

  String _toHtml(String rawMarkdown) {
    final normalized =
        rawMarkdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    return md.markdownToHtml(
      normalized,
      extensionSet: md.ExtensionSet.gitHubWeb,
      inlineSyntaxes: [
        md.InlineHtmlSyntax(),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.isBusy,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.isReplyBusy,
    required this.onReplyEdit,
    required this.onReplyDelete,
  });

  final EducationComment comment;
  final bool isBusy;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool Function(String commentId) isReplyBusy;
  final ValueChanged<EducationComment> onReplyEdit;
  final ValueChanged<EducationComment> onReplyDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentHeader(
            author: comment.author,
            createdAt: comment.createdAt,
            trailing: _buildActionMenu(
              isBusy: isBusy,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            comment.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF334155),
            ),
          ),
          if (onReply != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: isBusy ? null : onReply,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE64060),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                icon: const Icon(Icons.reply_rounded, size: 18),
                label: const Text(
                  'Balas',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: comment.replies
                    .map(
                      (reply) => _ReplyCard(
                        reply: reply,
                        isBusy: isReplyBusy(reply.commentId),
                        onEdit: reply.canEdit ? () => onReplyEdit(reply) : null,
                        onDelete:
                            reply.canDelete ? () => onReplyDelete(reply) : null,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildActionMenu({
    required bool isBusy,
    required VoidCallback? onEdit,
    required VoidCallback? onDelete,
  }) {
    if (isBusy) {
      return const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFE64060),
        ),
      );
    }

    final hasEdit = onEdit != null;
    final hasDelete = onDelete != null;
    if (!hasEdit && !hasDelete) return null;

    return PopupMenuButton<_CommentMenuAction>(
      icon: const Icon(
        Icons.more_horiz_rounded,
        color: Color(0xFF94A3B8),
      ),
      onSelected: (action) {
        switch (action) {
          case _CommentMenuAction.edit:
            onEdit?.call();
            break;
          case _CommentMenuAction.delete:
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) {
        return [
          if (hasEdit)
            const PopupMenuItem(
              value: _CommentMenuAction.edit,
              child: Text('Ubah komentar'),
            ),
          if (hasDelete)
            const PopupMenuItem(
              value: _CommentMenuAction.delete,
              child: Text('Hapus komentar'),
            ),
        ];
      },
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({
    required this.reply,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final EducationComment reply;
  final bool isBusy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentHeader(
            author: reply.author,
            createdAt: reply.createdAt,
            compact: true,
            trailing: _buildActionMenu(),
          ),
          const SizedBox(height: 8),
          Text(
            reply.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildActionMenu() {
    if (isBusy) {
      return const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFE64060),
        ),
      );
    }

    final hasEdit = onEdit != null;
    final hasDelete = onDelete != null;
    if (!hasEdit && !hasDelete) return null;

    return PopupMenuButton<_CommentMenuAction>(
      icon: const Icon(
        Icons.more_horiz_rounded,
        size: 18,
        color: Color(0xFF94A3B8),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.08),
      elevation: 4,
      onSelected: (action) {
        switch (action) {
          case _CommentMenuAction.edit:
            onEdit?.call();
            break;
          case _CommentMenuAction.delete:
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) {
        return [
          if (hasEdit)
            const PopupMenuItem(
              value: _CommentMenuAction.edit,
              child: Text('Ubah komentar'),
            ),
          if (hasDelete)
            const PopupMenuItem(
              value: _CommentMenuAction.delete,
              child: Text('Hapus komentar'),
            ),
        ];
      },
    );
  }
}

class _CommentHeader extends StatelessWidget {
  const _CommentHeader({
    required this.author,
    required this.createdAt,
    this.compact = false,
    this.trailing,
  });

  final EducationAuthor? author;
  final DateTime? createdAt;
  final bool compact;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final displayName = (author?.displayName ?? '').trim().isEmpty
        ? 'Pengguna'
        : author!.displayName;

    return Row(
      children: [
        CircleAvatar(
          radius: compact ? 16 : 18,
          backgroundColor: const Color(0xFFFFE7E7),
          backgroundImage: (author?.avatarPhoto ?? '').trim().isNotEmpty
              ? NetworkImage(author!.avatarPhoto)
              : null,
          child: (author?.avatarPhoto ?? '').trim().isEmpty
              ? Text(
                  _initials(displayName),
                  style: TextStyle(
                    color: const Color(0xFFE64060),
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF334155),
                ),
              ),
              if (createdAt != null)
                Text(
                  DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(
                    createdAt!.toLocal(),
                  ),
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InteractiveMetric extends StatelessWidget {
  const _InteractiveMetric({
    required this.icon,
    required this.value,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              '$value $label',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EducationErrorState extends StatelessWidget {
  const _EducationErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF991B1B),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF7F1D1D),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE64060),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

enum _CommentMenuAction {
  edit,
  delete,
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList(growable: false);
  if (words.isEmpty) return 'PW';
  return words.map((word) => word[0].toUpperCase()).join();
}

String _extractErrorMessage(Object error) {
  final message = error.toString().replaceFirst('Exception: ', '').trim();
  if (message.isEmpty) {
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
  return message;
}

Color _categoryColor(String slug) {
  final normalized = slug.toLowerCase();
  if (normalized.contains('jantung')) return const Color(0xFFE64060);
  if (normalized.contains('gejala')) return const Color(0xFFE08B3D);
  if (normalized.contains('nutrisi') || normalized.contains('makan')) {
    return const Color(0xFF2D9744);
  }
  if (normalized.contains('aktivitas')) return const Color(0xFF285DBE);
  return const Color(0xFF7C3AED);
}

Color _categoryTint(String slug) {
  final color = _categoryColor(slug);
  return color.withOpacity(0.12);
}
