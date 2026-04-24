import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/custom_app_bar.dart';
import '../providers/current_diary_provider.dart';
import '../providers/diary_history_provider.dart';
import '../providers/profile_provider.dart';

class RiwayatDiariPage extends ConsumerStatefulWidget {
  const RiwayatDiariPage({super.key});

  @override
  ConsumerState<RiwayatDiariPage> createState() => _RiwayatDiariPageState();
}

class _RiwayatDiariPageState extends ConsumerState<RiwayatDiariPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};
  String? _expandedDiaryId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThisMonth();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 220;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(diaryHistoryProvider.notifier).loadNextPage();
    }
  }

  Future<void> _loadThisMonth() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    await ref.read(diaryHistoryProvider.notifier).loadDiaryHistory(
          page: 1,
          limit: 10,
          startDate: startDate,
          endDate: endDate,
        );
  }

  Future<void> _refreshHistory() async {
    final state = ref.read(diaryHistoryProvider);
    final now = DateTime.now();
    final startDate = state.startDate ?? DateTime(now.year, now.month, 1);
    final endDate = state.endDate ?? DateTime(now.year, now.month + 1, 0);

    setState(() {
      _expandedDiaryId = null;
    });

    await ref.read(diaryHistoryProvider.notifier).refreshHistory(
          startDate: startDate,
          endDate: endDate,
        );
  }

  Future<void> _toggleEntry(DiaryHistoryItem item) async {
    final isExpanded = _expandedDiaryId == item.diaryId;

    setState(() {
      _expandedDiaryId = isExpanded ? null : item.diaryId;
    });

    if (isExpanded) return;

    await ref.read(diaryHistoryProvider.notifier).loadDiaryDetail(item.diaryId);

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[item.diaryId];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  DateTime _asDateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final state = ref.read(diaryHistoryProvider);
    final currentStart = state.startDate ?? DateTime(now.year, now.month, 1);
    final currentEnd = state.endDate ?? DateTime(now.year, now.month + 1, 0);

    final picked = await showDatePicker(
      context: context,
      initialDate: currentStart,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );

    if (picked == null || !mounted) return;

    var startDate = _asDateOnly(picked);
    var endDate = _asDateOnly(currentEnd);

    if (startDate.isAfter(endDate)) {
      endDate = startDate;
    }

    setState(() {
      _expandedDiaryId = null;
    });

    await ref.read(diaryHistoryProvider.notifier).loadDiaryHistory(
          page: 1,
          limit: 10,
          startDate: startDate,
          endDate: endDate,
        );
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final state = ref.read(diaryHistoryProvider);
    final currentStart = state.startDate ?? DateTime(now.year, now.month, 1);
    final currentEnd = state.endDate ?? DateTime(now.year, now.month + 1, 0);

    final picked = await showDatePicker(
      context: context,
      initialDate: currentEnd,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );

    if (picked == null || !mounted) return;

    var startDate = _asDateOnly(currentStart);
    var endDate = _asDateOnly(picked);

    if (endDate.isBefore(startDate)) {
      startDate = endDate;
    }

    setState(() {
      _expandedDiaryId = null;
    });

    await ref.read(diaryHistoryProvider.notifier).loadDiaryHistory(
          page: 1,
          limit: 10,
          startDate: startDate,
          endDate: endDate,
        );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:--';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryHistoryProvider);
    final startLabel =
        state.startDate != null ? _formatDate(state.startDate) : 'Start date';
    final endLabel =
        state.endDate != null ? _formatDate(state.endDate) : 'End date';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBody: true,
      appBar: CustomAppBar(
        title: 'Riwayat Diari',
        subtitle: 'Semua catatan kesehatan Anda',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        color: const Color(0xFFE64060),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Ensures the scrollable area is at least as tall as the screen
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.event_available, size: 18),
                              label: Text(
                                startLabel,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 16),
                              ),
                              onPressed:
                                  state.isLoading ? null : _pickStartDate,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side:
                                    const BorderSide(color: Color(0xFFD9E2EC)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '-',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.event, size: 18),
                              label: Text(endLabel),
                              onPressed: state.isLoading ? null : _pickEndDate,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side:
                                    const BorderSide(color: Color(0xFFD9E2EC)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${state.totalItems} item',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // if (state.isLoading) ...[
                          //   const SizedBox(width: 10),
                          //   const SizedBox(
                          //     width: 16,
                          //     height: 16,
                          //     child: CircularProgressIndicator(
                          //       strokeWidth: 2.2,
                          //       color: Color(0xFFE64060),
                          //     ),
                          //   ),
                          //   const SizedBox(width: 6),
                          //   const Text(
                          //     'Memuat filter...',
                          //     style: TextStyle(
                          //       color: Color(0xFF64748B),
                          //       fontSize: 12,
                          //       fontWeight: FontWeight.w500,
                          //     ),
                          //   ),
                          // ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFE64060)),
                    ),
                  )
                else if (state.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                    child: Center(
                      child: Text(
                        'Belum ada riwayat diari pada periode ini',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  ...state.items.map((item) {
                    final isExpanded = _expandedDiaryId == item.diaryId;
                    final isDetailLoading =
                        state.loadingDetailDiaryIds.contains(item.diaryId);
                    final detail = state.detailsByDiaryId[item.diaryId];
                    final detailError =
                        state.detailErrorsByDiaryId[item.diaryId];

                    _itemKeys[item.diaryId] ??= GlobalKey();

                    return Padding(
                      key: _itemKeys[item.diaryId],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _toggleEntry(item),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatDate(item.diaryDate),
                                          style: const TextStyle(
                                            color: Color(0xFF1E293B),
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Dibuat ${_formatTime(item.createdAt)}',
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.25 : 0,
                                    duration: const Duration(milliseconds: 220),
                                    child: const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              ClipRect(
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    child: isExpanded
                                        ? Padding(
                                            key: ValueKey<String>(
                                              'expanded-${item.diaryId}',
                                            ),
                                            padding:
                                                const EdgeInsets.only(top: 12),
                                            child: _ExpandedArea(
                                              isLoading: isDetailLoading,
                                              error: detailError,
                                              detail: detail,
                                              onRetry: () => ref
                                                  .read(diaryHistoryProvider
                                                      .notifier)
                                                  .loadDiaryDetail(
                                                      item.diaryId),
                                              formatTime: _formatTime,
                                            ),
                                          )
                                        : const SizedBox(
                                            key: ValueKey<String>('collapsed'),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                if (state.error != null && state.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Text(
                      state.error!,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (state.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 18),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Color(0xFFE64060),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedArea extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final DiaryDetail? detail;
  final VoidCallback onRetry;
  final String Function(DateTime?) formatTime;

  const _ExpandedArea({
    required this.isLoading,
    required this.error,
    required this.detail,
    required this.onRetry,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFFE64060),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                foregroundColor: const Color(0xFFB91C1C),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (detail == null) {
      return const SizedBox.shrink();
    }

    return _ExpandedDiaryContent(
      detail: detail!,
      formatTime: formatTime,
    );
  }
}

class _ExpandedDiaryContent extends StatelessWidget {
  final DiaryDetail detail;
  final String Function(DateTime?) formatTime;

  const _ExpandedDiaryContent({
    required this.detail,
    required this.formatTime,
  });

  String _v(num? value, [String unit = '']) {
    if (value == null) return '-';
    return unit.isEmpty ? '$value' : '$value $unit';
  }

  @override
  Widget build(BuildContext context) {
    final bodyMetrics = [...detail.bodyMetrics]..sort((a, b) =>
        (b.timeStamp ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.timeStamp ?? DateTime.fromMillisecondsSinceEpoch(0)));
    final symptoms = [...detail.symptoms]..sort((a, b) =>
        (b.timeStamp ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.timeStamp ?? DateTime.fromMillisecondsSinceEpoch(0)));
    final activities = [...detail.activities]..sort((a, b) =>
        (b.timeStamp ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.timeStamp ?? DateTime.fromMillisecondsSinceEpoch(0)));
    final consumptions = [...detail.consumptions]..sort((a, b) =>
        (b.timeStamp ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.timeStamp ?? DateTime.fromMillisecondsSinceEpoch(0)));

    final latestMetric = bodyMetrics.isNotEmpty ? bodyMetrics.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 12),
        const Text(
          'Ringkasan Metriks',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Berat ${_v(latestMetric?.bodyWeight, 'kg')} • Tekanan ${_v(latestMetric?.systolicPressure)}/${_v(latestMetric?.diastolicPressure)} mmHg • Nadi ${_v(latestMetric?.heartRate, 'BPM')}',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SimpleSection(
          title: 'Gejala',
          isEmpty: symptoms.isEmpty,
          emptyLabel: 'Tidak ada gejala',
          children: symptoms
              .map(
                (symptom) => _SimpleRow(
                  leading: formatTime(symptom.timeStamp),
                  title: symptom.symptomName,
                  subtitle:
                      'Intensitas ${symptom.intensity?.toString() ?? '-'}${(symptom.note ?? '').isEmpty ? '' : ' • ${symptom.note}'}',
                ),
              )
              .toList(),
        ),
        _SimpleSection(
          title: 'Aktivitas',
          isEmpty: activities.isEmpty,
          emptyLabel: 'Tidak ada aktivitas',
          children: activities
              .map(
                (activity) => _SimpleRow(
                  leading: formatTime(activity.timeStamp),
                  title: activity.name,
                  subtitle:
                      '${activity.duration?.toString() ?? '-'} menit • ${activity.heartRate?.toString() ?? '-'} BPM • ${(activity.userFeeling ?? '').isEmpty ? '-' : activity.userFeeling}',
                ),
              )
              .toList(),
        ),
        _SimpleSection(
          title: 'Konsumsi',
          isEmpty: consumptions.isEmpty,
          emptyLabel: 'Tidak ada konsumsi',
          children: consumptions
              .map(
                (item) => _SimpleRow(
                  leading: formatTime(item.timeStamp),
                  title: item.name,
                  subtitle:
                      '${item.type} • ${(item.portion ?? '').isEmpty ? '-' : item.portion}${(item.note ?? '').isEmpty ? '' : ' • ${item.note}'}',
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SimpleSection extends StatelessWidget {
  final String title;
  final bool isEmpty;
  final String emptyLabel;
  final List<Widget> children;

  const _SimpleSection({
    required this.title,
    required this.isEmpty,
    required this.emptyLabel,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          if (isEmpty)
            Text(
              emptyLabel,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _SimpleRow extends StatelessWidget {
  final String leading;
  final String title;
  final String subtitle;

  const _SimpleRow({
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              leading,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
