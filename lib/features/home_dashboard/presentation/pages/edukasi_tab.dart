import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/platform/health_connect_visibility.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/education/data/models/education_models.dart';
import 'package:pulsewise/features/education/presentation/providers/education_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class EdukasiTab extends ConsumerStatefulWidget {
  const EdukasiTab({super.key});

  @override
  ConsumerState<EdukasiTab> createState() => _EdukasiTabState();
}

class _EdukasiTabState extends ConsumerState<EdukasiTab> {
  static final Uri _educationCmsUri = Uri.parse(
    'https://pulsewise-cms.vercel.app/',
  );
  final TextEditingController _searchController = TextEditingController();

  String _searchKeyword = '';
  String _selectedSort = 'latest';
  String? _selectedCategorySlug;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchKeyword = _searchController.text.trim();
    });
  }

  Future<void> _openEducationCms() async {
    final opened = await launchUrl(_educationCmsUri);
    if (opened || !mounted) return;

    AppToast.warning(
      context,
      'CMS PulseWise belum bisa dibuka saat ini.',
    );
  }

  Future<void> _openFilterSheet(List<EducationCategory> categories) async {
    var draftSort = _selectedSort;
    String? draftCategorySlug = _selectedCategorySlug;

    final applied = await showModalBottomSheet<_EducationFilterSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filter Artikel',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              draftSort = 'latest';
                              draftCategorySlug = null;
                            });
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: Color(0xFFE64060),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Urutkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _FilterChip(
                          label: 'Terbaru',
                          selected: draftSort == 'latest',
                          onTap: () {
                            setModalState(() {
                              draftSort = 'latest';
                            });
                          },
                        ),
                        _FilterChip(
                          label: 'Populer',
                          selected: draftSort == 'popular',
                          onTap: () {
                            setModalState(() {
                              draftSort = 'popular';
                            });
                          },
                        ),
                      ],
                    ),
                    if (categories.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _FilterChip(
                            label: 'Semua',
                            selected: (draftCategorySlug ?? '').trim().isEmpty,
                            onTap: () {
                              setModalState(() {
                                draftCategorySlug = null;
                              });
                            },
                          ),
                          ...categories.map(
                            (category) => _FilterChip(
                              label: category.name,
                              selected: draftCategorySlug == category.slug,
                              onTap: () {
                                setModalState(() {
                                  draftCategorySlug = category.slug;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                _EducationFilterSelection(
                                  sort: draftSort,
                                  categorySlug: draftCategorySlug,
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE64060),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Terapkan',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
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
          },
        );
      },
    );

    if (applied == null || !mounted) return;

    setState(() {
      _selectedSort = applied.sort;
      _selectedCategorySlug = applied.categorySlug;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    const categoryQuery = EducationFeedQuery(sort: 'latest', limit: 20);
    final query = EducationFeedQuery(
      sort: _selectedSort,
      limit: 10,
      categorySlug: _selectedCategorySlug,
      keyword: _searchKeyword,
    );
    final feedAsync = ref.watch(educationFeedProvider(query));
    final categoryFeedAsync = ref.watch(educationFeedProvider(categoryQuery));
    final availableCategories = categoryFeedAsync.maybeWhen(
      data: (feed) => _deriveCategories(feed.items),
      orElse: () => const <EducationCategory>[],
    );

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.refresh(educationFeedProvider(query).future),
          ref.refresh(educationFeedProvider(categoryQuery).future),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          SizedBox(height: topPadding),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edukasi',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF525252),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    onPressed: _openEducationCms,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE64060),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      'Tambah',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (shouldExposeHealthConnectUi)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: _WearableConnectionCard(
                initiallyExpanded: false,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: SizedBox(
              height: 48,
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _applySearch(),
                decoration: InputDecoration(
                  hintText: 'Cari Artikel',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF94A3B8),
                  ),
                  suffixIcon: _searchController.text.trim().isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchKeyword = '';
                            });
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFE64060),
                      width: 1.7,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _applySearch,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE64060),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.search_rounded, size: 22),
                    label: const Text(
                      'Cari',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openFilterSheet(availableCategories),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 22),
                    label: const Text(
                      'Filter',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          feedAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (error, _) {
              final isNetwork = isNetworkRequestError(error);
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: isNetwork
                    ? NoConnectionState.card(
                        title: 'Artikel belum bisa dimuat',
                        message:
                            'Kami belum bisa mengambil artikel edukasi karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                        onRetry: () =>
                            ref.refresh(educationFeedProvider(query).future),
                      )
                    : _EducationInlineError(
                        message: error.toString(),
                        onRetry: () =>
                            ref.refresh(educationFeedProvider(query).future),
                      ),
              );
            },
            data: (feed) {
              final hasActiveFilter =
                  (_selectedCategorySlug ?? '').trim().isNotEmpty ||
                      _searchKeyword.isNotEmpty;
              final sectionTitle = _selectedSort == 'popular'
                  ? 'Artikel Populer'
                  : 'Artikel Terbaru';

              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasActiveCriteria) ...[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (_searchKeyword.isNotEmpty)
                            _ActiveFilterPill(
                              text: 'Cari: $_searchKeyword',
                              onClear: () {
                                _searchController.clear();
                                setState(() {
                                  _searchKeyword = '';
                                });
                              },
                            ),
                          if (_selectedSort == 'popular')
                            _ActiveFilterPill(
                              text: 'Urut: Populer',
                              onClear: () {
                                setState(() {
                                  _selectedSort = 'latest';
                                });
                              },
                            ),
                          if ((_selectedCategorySlug ?? '').trim().isNotEmpty)
                            _ActiveFilterPill(
                              text:
                                  'Kategori: ${_categoryNameForSlug(availableCategories, _selectedCategorySlug!)}',
                              onClear: () {
                                setState(() {
                                  _selectedCategorySlug = null;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sectionTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        // Text(
                        //   '${feed.items.length} artikel',
                        //   style: const TextStyle(
                        //     fontSize: 14,
                        //     fontWeight: FontWeight.w600,
                        //     color: Color(0xFF94A3B8),
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (feed.items.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          hasActiveFilter
                              ? 'Belum ada artikel yang cocok dengan pencarian atau kategori yang dipilih.'
                              : 'Belum ada artikel edukasi yang tersedia saat ini.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: feed.items
                            .map(
                              (article) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ArticleCard(
                                  article: article,
                                  onTap: () => context.push(
                                    '/home/education/articles/${Uri.encodeComponent(article.slug)}',
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<EducationCategory> _deriveCategories(List<EducationArticle> items) {
    final bySlug = <String, EducationCategory>{};
    for (final item in items) {
      final category = item.category;
      if (category == null || category.slug.trim().isEmpty) continue;
      bySlug[category.slug] = category;
    }

    final categories = bySlug.values.toList(growable: false);
    categories.sort((a, b) {
      final sortOrderComparison = a.sortOrder.compareTo(b.sortOrder);
      if (sortOrderComparison != 0) return sortOrderComparison;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return categories;
  }

  bool get _hasActiveCriteria {
    return _searchKeyword.isNotEmpty ||
        _selectedSort != 'latest' ||
        (_selectedCategorySlug ?? '').trim().isNotEmpty;
  }

  String _categoryNameForSlug(
    List<EducationCategory> categories,
    String slug,
  ) {
    for (final category in categories) {
      if (category.slug == slug) return category.name;
    }
    return slug;
  }
}

class _WearableConnectionCard extends StatefulWidget {
  const _WearableConnectionCard({
    this.initiallyExpanded = false,
  });

  final bool initiallyExpanded;

  @override
  State<_WearableConnectionCard> createState() =>
      _WearableConnectionCardState();
}

class _WearableConnectionCardState extends State<_WearableConnectionCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFBCDD6)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE7E7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.watch_outlined,
                      color: Color(0xFFE64060),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Koneksi Wearable',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE64060),
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Hubungkan PulseWise dengan smartwatch Anda',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFBCDD6)),
                    ),
                    child: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFFE64060),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Buka bagian ini untuk melihat panduan integrasi Health Connect dan data apa saja yang bisa disinkronkan.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 14),
              const Text(
                'Sambungkan PulseWise ke Health Connect agar aplikasi bisa membaca data langkah, detak jantung, tidur, dan aktivitas dari wearable Anda.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: 'Langkah'),
                  _InfoChip(label: 'Detak Jantung'),
                  _InfoChip(label: 'Tidur'),
                  _InfoChip(label: 'Aktivitas'),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/home/health-connect'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE64060),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    'Lihat Panduan Health Connect',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFBCDD6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
    required this.onTap,
  });

  final EducationArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = article.category;
    final categoryColor = _categoryColor(category?.slug ?? '');
    final readTime = _estimateReadTime(article.contentMarkdown);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.coverImageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    article.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: const Color(0xFFFFF1F2),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFFE64060),
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                if (category != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      category.name,
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (category != null) const SizedBox(width: 8),
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: Color(0xFF62748E),
                ),
                const SizedBox(width: 4),
                Text(
                  readTime,
                  style: const TextStyle(
                    color: Color(0xFF62748E),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              article.title,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.excerpt.trim().isEmpty
                  ? 'Buka artikel untuk membaca isi lengkapnya.'
                  : article.excerpt,
              style: const TextStyle(
                color: Color(0xFF62748E),
                fontSize: 16,
                height: 1.55,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFFFFE7E7),
                  backgroundImage:
                      (article.author?.avatarPhoto ?? '').trim().isNotEmpty
                          ? NetworkImage(article.author!.avatarPhoto)
                          : null,
                  child: (article.author?.avatarPhoto ?? '').trim().isEmpty
                      ? Text(
                          _initials(article.author?.displayName ?? 'PW'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE64060),
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (article.author?.displayName ?? '').trim().isEmpty
                            ? 'Penulis PulseWise'
                            : article.author!.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (article.publishedAt != null)
                        Text(
                          (article.author?.badge ?? '').trim().isNotEmpty
                              ? article.author!.badge
                              : DateFormat('dd MMM yyyy', 'id_ID').format(
                                  article.publishedAt!.toLocal(),
                                ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${article.likeCount}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.mode_comment_outlined,
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${article.commentCount}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE64060) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFE64060) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF475569),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EducationInlineError extends StatelessWidget {
  const _EducationInlineError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Artikel gagal dimuat',
            style: TextStyle(
              color: Color(0xFF991B1B),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF7F1D1D),
              fontSize: 14,
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

class _ActiveFilterPill extends StatelessWidget {
  const _ActiveFilterPill({
    required this.text,
    required this.onClear,
  });

  final String text;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFBCDD6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9F1239),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: Color(0xFF9F1239),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationFilterSelection {
  const _EducationFilterSelection({
    required this.sort,
    required this.categorySlug,
  });

  final String sort;
  final String? categorySlug;
}

String _estimateReadTime(String markdown) {
  final words = markdown
      .replaceAll(RegExp(r'!\[\]\(.+?\)'), ' ')
      .replaceAll(RegExp(r'[#>*`_\-\n]'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;

  if (words <= 0) return '1 Menit';
  final minutes = (words / 180).ceil().clamp(1, 60);
  return '$minutes Menit';
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
