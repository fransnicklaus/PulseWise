import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/medication/data/models/medication_models.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_api_provider.dart';
import 'package:pulsewise/features/medication/presentation/utils/medication_status_ui.dart';

class MedicationConsumptionTrackingCard extends ConsumerStatefulWidget {
  const MedicationConsumptionTrackingCard({
    super.key,
    required this.patientId,
    required this.medicationId,
  });

  final String patientId;
  final String medicationId;

  @override
  ConsumerState<MedicationConsumptionTrackingCard> createState() =>
      _MedicationConsumptionTrackingCardState();
}

class _MedicationConsumptionTrackingCardState
    extends ConsumerState<MedicationConsumptionTrackingCard> {
  static const int _pageSize = 20;
  static const List<_RangeOption> _rangeOptions = [
    _RangeOption(label: '7 Hari', days: 7),
    _RangeOption(label: '14 Hari', days: 14),
    _RangeOption(label: '21 Hari', days: 21),
    _RangeOption(label: '1 Bulan', months: 1),
    _RangeOption(label: '2 Bulan', months: 2),
    _RangeOption(label: '3 Bulan', months: 3),
  ];

  final ScrollController _scrollController = ScrollController();
  int _selectedRangeIndex = 3;
  int _requestSerial = 0;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  Object? _errorCause;
  bool _hasLoadedOnce = false;
  int _page = 1;
  int _totalPages = 1;
  List<MedicationLogItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLogs(reset: true);
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
    if (_isLoading || _isLoadingMore || _isRefreshing || !_hasMore) return;

    final threshold = _scrollController.position.maxScrollExtent - 180;
    if (_scrollController.position.pixels >= threshold) {
      _loadLogs();
    }
  }

  Future<void> _loadLogs({
    bool reset = false,
    bool preserveVisibleData = false,
  }) async {
    final requestId = ++_requestSerial;
    final range = _rangeOptions[_selectedRangeIndex];
    final now = DateTime.now();
    final endDate = _dateOnly(now);
    final startDate = _resolveStartDate(now, range);
    final nextPage = reset ? 1 : _page + 1;
    final keepVisibleData = reset && preserveVisibleData && _hasLoadedOnce;

    if (reset) {
      if (mounted) {
        setState(() {
          _isLoading = !keepVisibleData;
          _isRefreshing = keepVisibleData;
          _isLoadingMore = false;
          _errorMessage = null;
          _errorCause = null;
          _page = 1;
          _totalPages = 1;
          _hasMore = true;
          if (!keepVisibleData) {
            _items = const [];
            _hasLoadedOnce = false;
          }
        });
      }
    } else {
      if (_isLoading || _isLoadingMore || _isRefreshing || !_hasMore) return;
      if (mounted) {
        setState(() {
          _isLoadingMore = true;
          _errorMessage = null;
          _errorCause = null;
        });
      }
    }

    try {
      final response =
          await ref.read(medicationApiProvider).fetchMedicationLogs(
                patientId: widget.patientId,
                medicationId: widget.medicationId,
                page: nextPage,
                limit: _pageSize,
                startDate: startDate,
                endDate: endDate,
              );

      if (!mounted || requestId != _requestSerial) return;

      final nextItems = reset ? response.items : [..._items, ...response.items];
      setState(() {
        _items = nextItems;
        _page = response.pagination.page;
        _totalPages = response.pagination.totalPages;
        _hasMore = _page < _totalPages;
        _isLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;
        _errorMessage = null;
        _errorCause = null;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      if (!mounted || requestId != _requestSerial) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _errorCause = e;
        if (!keepVisibleData) {
          _hasLoadedOnce = false;
        }
      });
    }
  }

  Future<void> _refresh() async {
    await _loadLogs(
      reset: true,
      preserveVisibleData: _hasLoadedOnce,
    );
  }

  Future<void> _changeRange(int index) async {
    if (_selectedRangeIndex == index) return;
    setState(() {
      _selectedRangeIndex = index;
    });
    await _loadLogs(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final takenCount = _countByStatus('taken');
    final skippedCount = _countByStatus('skipped');
    final missedCount = _countByStatus('missed');
    final hasNetworkError =
        _errorCause != null && isNetworkRequestError(_errorCause!);
    final showInitialNoConnection = hasNetworkError && !_hasLoadedOnce;
    final showRefreshNoConnection = hasNetworkError && _hasLoadedOnce;
    final showInitialError =
        _errorMessage != null && !_hasLoadedOnce && !showInitialNoConnection;
    final showInlineError =
        _errorMessage != null && _hasLoadedOnce && !showRefreshNoConnection;
    final Widget trackingBody;

    if (_isLoading && !_hasLoadedOnce) {
      trackingBody = const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE64060),
        ),
      );
    } else if (showInitialNoConnection) {
      trackingBody = NoConnectionState.card(
        title: 'Riwayat konsumsi belum bisa dimuat',
        message:
            'Kami belum bisa mengambil log konsumsi obat karena koneksi internet tidak tersedia atau sedang tidak stabil.',
        onRetry: () {
          _loadLogs(reset: true);
        },
      );
    } else if (showInitialError) {
      trackingBody = _TrackingErrorState(
        message: _errorMessage!,
        onRetry: () {
          _loadLogs(reset: true);
        },
      );
    } else {
      trackingBody = RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFFE64060),
        backgroundColor: Colors.white,
        child: _items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(
                    child: Text(
                      'Belum ada log konsumsi pada periode ini.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFFE64060),
                          ),
                        ),
                      ),
                    );
                  }

                  final item = _items[index];
                  return _MedicationLogListTile(item: item);
                },
              ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tracking Konsumsi',
            style: TextStyle(
              color: Color(0xFF4F5F7B),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // const Text(
          //   'Lacak status taken, skipped, dan missed pada rentang waktu yang dipilih.',
          //   style: TextStyle(
          //     color: Color(0xFF64748B),
          //     fontSize: 14,
          //     height: 1.35,
          //   ),
          // ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedRangeIndex,
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              labelText: 'Periode',
              labelStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 22,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            items: List.generate(_rangeOptions.length, (index) {
              final option = _rangeOptions[index];
              return DropdownMenuItem<int>(
                value: index,
                child: Text(
                  option.label,
                  style: TextStyle(fontSize: 18),
                ),
              );
            }),
            onChanged: _isLoading ? null : (value) => _changeRange(value ?? 3),
          ),
          const SizedBox(height: 12),
          // LayoutBuilder(
          //   builder: (context, constraints) {
          //     final useCompact = constraints.maxWidth < 420;
          //     return Wrap(
          //       spacing: 8,
          //       runSpacing: 8,
          //       children: [

          //       ],
          //     );
          //   },
          // ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: _SummaryStatCard(
                  label: 'Diminum',
                  value: takenCount,
                  color: const Color(0xFF15803D),
                  compact: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStatCard(
                  label: 'Dilewati',
                  value: skippedCount,
                  color: const Color(0xFFB45309),
                  compact: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStatCard(
                  label: 'Terlewat',
                  value: missedCount,
                  color: const Color(0xFFB91C1C),
                  compact: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isRefreshing) ...[
            const LinearProgressIndicator(
              minHeight: 3,
              color: Color(0xFFE64060),
              backgroundColor: Color(0xFFFFE1E7),
            ),
            const SizedBox(height: 12),
          ],
          if (showRefreshNoConnection) ...[
            NoConnectionState.compact(
              title: 'Koneksi terputus',
              message:
                  'Menampilkan log konsumsi terakhir yang berhasil dimuat. Sambungkan internet untuk memperbarui riwayat terbaru.',
              onRetry: () {
                _refresh();
              },
            ),
            const SizedBox(height: 12),
          ] else if (showInlineError) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Gagal memuat log konsumsi.',
                      style: TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 300,
            child: trackingBody,
          ),
        ],
      ),
    );
  }

  int _countByStatus(String status) {
    return _items.where((item) => item.status.toLowerCase() == status).length;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _resolveStartDate(DateTime now, _RangeOption option) {
    if (option.months != null) {
      return _dateOnly(DateTime(now.year, now.month - option.months!, now.day));
    }
    final days = option.days ?? 7;
    return _dateOnly(now.subtract(Duration(days: days - 1)));
  }
}

class _TrackingErrorState extends StatelessWidget {
  const _TrackingErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.compact,
  });

  final String label;
  final int value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationLogListTile extends StatelessWidget {
  const _MedicationLogListTile({required this.item});

  final MedicationLogItem item;

  @override
  Widget build(BuildContext context) {
    final statusColor = _resolveStatusColor(item.status);
    final statusLabel = _statusLabel(item.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Container(
          //   width: 44,
          //   height: 44,
          //   decoration: BoxDecoration(
          //     color: statusColor.withOpacity(0.12),
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Icon(
          //     _statusIcon(item.status),
          //     color: statusColor,
          //     size: 22,
          //   ),
          // ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatDate(item.medicationDate)} • ${item.medicationTime}',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // const SizedBox(height: 3),
                // Text(
                //   'Created ${_formatDateTime(item.createdAt)}',
                //   style: const TextStyle(
                //     color: Color(0xFF64748B),
                //     fontSize: 12,
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusPill(label: statusLabel, color: statusColor),
        ],
      ),
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

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return _formatDate(date);
  }

  String _statusLabel(String status) {
    return medicationStatusUiLabel(status);
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'taken':
        return Icons.check_circle_outline;
      case 'skipped':
        return Icons.fast_forward_rounded;
      case 'missed':
        return Icons.close_rounded;
      default:
        return Icons.medication_rounded;
    }
  }

  Color _resolveStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'taken':
        return const Color(0xFF15803D);
      case 'skipped':
        return const Color(0xFFB45309);
      case 'missed':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFFE64060);
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RangeOption {
  const _RangeOption({
    required this.label,
    this.days,
    this.months,
  }) : assert(days != null || months != null);

  final String label;
  final int? days;
  final int? months;
}
