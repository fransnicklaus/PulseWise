import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/notifications/reminder_notification_coordinator.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';
import 'package:pulsewise/features/medication/data/models/medication_models.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_api_provider.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_calendar_provider.dart';
import 'package:pulsewise/features/medication/presentation/utils/medication_status_ui.dart';
import 'package:pulsewise/features/medication/presentation/widgets/medication_status_bottom_sheet.dart';
import 'package:table_calendar/table_calendar.dart';

class PengingatTab extends ConsumerStatefulWidget {
  const PengingatTab({super.key});

  @override
  ConsumerState<PengingatTab> createState() => _PengingatTabState();
}

class _PengingatTabState extends ConsumerState<PengingatTab>
    with AutomaticKeepAliveClientMixin {
  late DateTime _selectedDate;
  late DateTime _focusedDate;
  bool _isOpeningPendingReminder = false;
  int _pendingLookupAttempts = 0;
  String? _lastPendingLookupKey;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = _dateOnly(now);
    _focusedDate = _dateOnly(now);
    ReminderNotificationCoordinator.instance
        .addListener(_handlePendingReminderSignal);
  }

  bool _isNoConnectionErrorWithoutValue<T>(AsyncValue<T> asyncValue) {
    final error = asyncValue.asError?.error;
    return error != null &&
        isNetworkRequestError(error) &&
        !asyncValue.hasValue;
  }

  bool _isNoConnectionErrorWithValue<T>(AsyncValue<T> asyncValue) {
    final error = asyncValue.asError?.error;
    return error != null && isNetworkRequestError(error) && asyncValue.hasValue;
  }

  bool _hasNonNetworkErrorWithoutValue<T>(AsyncValue<T> asyncValue) {
    final error = asyncValue.asError?.error;
    return error != null &&
        !isNetworkRequestError(error) &&
        !asyncValue.hasValue;
  }

  void _retryCalendarSection(MedicationCalendarRangeQuery query) {
    ref.invalidate(medicationCalendarRangeProvider(query));
  }

  Future<void> _refreshCalendarSilently(
    MedicationCalendarRangeQuery query,
  ) async {
    try {
      ref.invalidate(medicationCalendarRangeProvider(query));
      await ref.read(medicationCalendarRangeProvider(query).future);
    } catch (_) {
      // Let the UI reflect the provider's AsyncValue state.
    }
  }

  @override
  void dispose() {
    ReminderNotificationCoordinator.instance
        .removeListener(_handlePendingReminderSignal);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final calendarFirstDay = DateTime(_focusedDate.year - 5, 1, 1);
    final calendarLastDay = DateTime(_focusedDate.year + 5, 12, 31);
    final monthAnchor = _dateOnly(_focusedDate);
    final fromDate = DateTime(monthAnchor.year, monthAnchor.month, 1);
    final toDate = DateTime(monthAnchor.year, monthAnchor.month + 1, 0);

    final query = MedicationCalendarRangeQuery(
      from: fromDate,
      to: toDate,
    );

    final calendarAsync = ref.watch(medicationCalendarRangeProvider(query));
    final calendarData = calendarAsync.valueOrNull;
    final calendarError = calendarAsync.asError?.error;
    final events = calendarData == null
        ? <MedicationCalendarItem>[]
        : [...calendarData.items]
      ..sort((a, b) {
        final dateA = a.scheduledDate ?? DateTime(1970);
        final dateB = b.scheduledDate ?? DateTime(1970);
        final dateCompare = dateA.compareTo(dateB);
        if (dateCompare != 0) return dateCompare;
        return a.scheduledTime.compareTo(b.scheduledTime);
      });
    final selectedEvents = events
        .where((item) => _isSameDay(item.scheduledDate, _selectedDate))
        .toList();
    final errorMessage =
        calendarError?.toString().replaceFirst('Exception: ', '');
    final showInitialNoConnection =
        _isNoConnectionErrorWithoutValue(calendarAsync);
    final showRefreshNoConnection =
        _isNoConnectionErrorWithValue(calendarAsync);
    final showInitialNonNetworkError =
        _hasNonNetworkErrorWithoutValue(calendarAsync);

    if (calendarData != null) {
      _maybeHandlePendingReminder(events, query);
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _refreshCalendarSilently(query),
        color: const Color(0xFFE64060),
        backgroundColor: Colors.white,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildHeader(context),
            const SizedBox(height: 14),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  TableCalendar<MedicationCalendarItem>(
                    firstDay: calendarFirstDay,
                    lastDay: calendarLastDay,
                    focusedDay: _focusedDate,
                    locale: 'id_ID',
                    selectedDayPredicate: (day) =>
                        _isSameDay(day, _selectedDate),
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Bulan',
                    },
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFFE64060),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Color(0xFFFFCBD7),
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 1,
                    ),
                    eventLoader: (day) {
                      return events
                          .where((item) => _isSameDay(item.scheduledDate, day))
                          .toList();
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = _dateOnly(selectedDay);
                        _focusedDate = _dateOnly(focusedDay);
                      });
                    },
                    onPageChanged: (focusedDay) {
                      final nextFocusedDate = _dateOnly(focusedDay);
                      setState(() {
                        _focusedDate = nextFocusedDate;
                        _selectedDate =
                            _defaultSelectedDateForMonth(nextFocusedDate);
                      });
                    },
                  ),
                  if (calendarAsync.isLoading) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(
                      minHeight: 3,
                      color: Color(0xFFE64060),
                      backgroundColor: Color(0xFFFFE1E7),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _formatDateLong(_selectedDate),
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (showRefreshNoConnection) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: NoConnectionState.compact(
                  title: 'Koneksi terputus',
                  message:
                      'Menampilkan kalender rutinitas terakhir yang berhasil dimuat. Sambungkan internet untuk memperbarui jadwal terbaru.',
                  onRetry: () => _retryCalendarSection(query),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (calendarAsync.isLoading && calendarData == null)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _LoadingDayCard(),
              )
            else if (showInitialNoConnection)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: NoConnectionState.card(
                  title: 'Kalender rutinitas belum bisa dimuat',
                  message:
                      'Kami belum bisa mengambil kalender rutinitas bulan ini karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                  onRetry: () => _retryCalendarSection(query),
                ),
              )
            else if (showInitialNonNetworkError && errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _InlineErrorCard(
                  message: errorMessage,
                  onRetry: () => _retryCalendarSection(query),
                ),
              )
            else if (selectedEvents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _EmptyDayCard(),
              )
            else
              ...selectedEvents.map(
                (item) => _MedicationCalendarCard(
                  item: item,
                  onTap: () => _showMedicationBottomSheet(
                    context,
                    item,
                    query,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
      // decoration: const BoxDecoration(
      //   gradient: LinearGradient(
      //     colors: [Color(0xFFE64060), Color(0xFFFF6C86)],
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //   ),
      //   borderRadius: BorderRadius.only(
      //     bottomLeft: Radius.circular(28),
      //     bottomRight: Radius.circular(28),
      //   ),
      // ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rutinitas',
                  style: TextStyle(
                    color: Color(0xFF525252),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Kalender Rutinitas',
                  style: TextStyle(
                    color: Color(0xFF525252),
                    fontSize: 18,
                    // fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _HeaderAction(
            icon: Icons.medication_rounded,
            label: 'Kelola',
            onTap: () => context.push('/home/reminder/manage'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMedicationBottomSheet(
    BuildContext context,
    MedicationCalendarItem item,
    MedicationCalendarRangeQuery query,
  ) async {
    debugPrint(
      '[ReminderNotification][PengingatTab] Opening bottom sheet for '
      'Item ID: ${item.medicationId}, Status: ${item.status}, '
      'Scheduled Date: ${item.scheduledDate}, Scheduled Time: ${item.scheduledTime}',
    );
    final saved = await showMedicationStatusBottomSheet(
      context: context,
      item: item,
      onSave: (status, currentItem) {
        final scheduledDate = currentItem.scheduledDate;
        if (scheduledDate == null) {
          throw Exception('Tanggal jadwal rutinitas tidak tersedia.');
        }

        return ref.read(medicationApiProvider).takeMedication(
              status,
              currentItem.medicationId,
              scheduledDate,
              currentItem.scheduledTime,
            );
      },
      onManage: () {
        context.push('/home/reminder/detail/${item.medicationId}');
      },
      initialStatus: item.status ?? 'Taken',
    );

    debugPrint(
      '[ReminderNotification][PengingatTab] Bottom sheet closed. saved=$saved '
      'medicationId=${item.medicationId}',
    );

    if (saved == true) {
      ref.invalidate(medicationCalendarRangeProvider(query));
      try {
        await ref.read(medicationCalendarRangeProvider(query).future);
        if (mounted) {
          AppToast.success(
              this.context, 'Status rutinitas berhasil diperbarui.');
        }
      } catch (e) {
        if (!mounted) return;
        if (isNetworkRequestError(e)) {
          AppToast.info(
            this.context,
            'Status rutinitas berhasil diperbarui, tetapi kalender terbaru belum bisa dimuat.',
          );
          return;
        }
        rethrow;
      }
    }
  }

  void _maybeHandlePendingReminder(
    List<MedicationCalendarItem> events,
    MedicationCalendarRangeQuery query,
  ) {
    final pending = ReminderNotificationCoordinator.instance.pendingPayload;
    if (pending == null) return;

    final currentNavIndex = ref.read(dashboardNavIndexProvider);
    if (currentNavIndex != 3) {
      debugPrint(
        '[ReminderNotification][PengingatTab] Waiting for Pengingat tab to become active. '
        'currentNavIndex=$currentNavIndex pending=${pending.debugSummary}',
      );
      return;
    }

    if (_isOpeningPendingReminder) {
      debugPrint(
        '[ReminderNotification][PengingatTab] Already opening reminder sheet, skipping duplicate attempt.',
      );
      return;
    }

    final pendingKey = _pendingKey(pending);
    if (_lastPendingLookupKey != pendingKey) {
      _lastPendingLookupKey = pendingKey;
      _pendingLookupAttempts = 0;
    }

    final targetDate = _dateOnly(pending.targetDate);
    final isOnTargetDate = _isSameDay(_selectedDate, targetDate);
    final isOnTargetMonth = _focusedDate.year == targetDate.year &&
        _focusedDate.month == targetDate.month;

    debugPrint(
      '[ReminderNotification][PengingatTab] Processing pending reminder. '
      'pending=${pending.debugSummary} '
      'selectedDate=$_selectedDate focusedDate=$_focusedDate '
      'queryRange=${query.from}..${query.to} events=${events.length}',
    );

    if (!isOnTargetDate || !isOnTargetMonth) {
      debugPrint(
        '[ReminderNotification][PengingatTab] Moving calendar to target date $targetDate '
        '(isOnTargetDate=$isOnTargetDate, isOnTargetMonth=$isOnTargetMonth).',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedDate = targetDate;
          _focusedDate = targetDate;
        });
      });
      return;
    }

    final matchedItem = _findPendingReminderItem(events, pending);
    if (matchedItem == null) {
      _pendingLookupAttempts += 1;
      debugPrint(
        '[ReminderNotification][PengingatTab] Medication item not found on attempt '
        '$_pendingLookupAttempts for ${pending.debugSummary}. '
        'Available events: ${_debugEventSummaries(events)}',
      );
      if (_pendingLookupAttempts >= 5) {
        debugPrint(
          '[ReminderNotification][PengingatTab] Giving up after $_pendingLookupAttempts attempts. '
          'Clearing pending payload.',
        );
        ReminderNotificationCoordinator.instance.consumePendingPayload();
        _pendingLookupAttempts = 0;
        _lastPendingLookupKey = null;
      }
      return;
    }

    debugPrint(
      '[ReminderNotification][PengingatTab] Matched item found: '
      'medicationId=${matchedItem.medicationId} '
      'date=${matchedItem.scheduledDate} '
      'time=${matchedItem.scheduledTime}',
    );

    _isOpeningPendingReminder = true;
    _pendingLookupAttempts = 0;
    _lastPendingLookupKey = null;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _isOpeningPendingReminder = false;
        return;
      }

      try {
        debugPrint(
          '[ReminderNotification][PengingatTab] Triggering bottom sheet open now.',
        );
        await _showMedicationBottomSheet(context, matchedItem, query);
      } finally {
        ReminderNotificationCoordinator.instance.consumePendingPayload();
        _isOpeningPendingReminder = false;
      }
    });
  }

  MedicationCalendarItem? _findPendingReminderItem(
    List<MedicationCalendarItem> events,
    MedicationReminderNotificationPayload pending,
  ) {
    debugPrint(
      '[ReminderNotification][PengingatTab] Finding item for pending=${pending.debugSummary}',
    );

    for (final item in events) {
      if (pending.matches(item)) {
        debugPrint(
          '[ReminderNotification][PengingatTab] Exact match success for '
          '${item.medicationId} at ${item.scheduledDate} ${item.scheduledTime}',
        );
        return item;
      }
    }

    for (final item in events) {
      if (item.medicationId == pending.medicationId &&
          _isSameDay(item.scheduledDate, pending.targetDate)) {
        debugPrint(
          '[ReminderNotification][PengingatTab] Fallback match by medicationId + date for '
          '${item.medicationId} at ${item.scheduledDate} ${item.scheduledTime}',
        );
        return item;
      }
    }

    for (final item in events) {
      if (item.medicationId == pending.medicationId) {
        debugPrint(
          '[ReminderNotification][PengingatTab] Fallback match by medicationId only for '
          '${item.medicationId} at ${item.scheduledDate} ${item.scheduledTime}',
        );
        return item;
      }
    }

    return null;
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _defaultSelectedDateForMonth(DateTime monthDate) {
    final today = _dateOnly(DateTime.now());
    if (today.year == monthDate.year && today.month == monthDate.month) {
      return today;
    }
    return DateTime(monthDate.year, monthDate.month, 1);
  }

  String _formatDateLong(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _handlePendingReminderSignal() {
    final pending = ReminderNotificationCoordinator.instance.pendingPayload;
    debugPrint(
      '[ReminderNotification][PengingatTab] Coordinator listener fired. '
      'hasPending=${pending != null} pending=${pending?.debugSummary ?? '-'}',
    );

    if (!mounted || pending == null) return;

    setState(() {
      // Trigger a rebuild so _maybeHandlePendingReminder can process the queue.
    });
  }

  String _pendingKey(MedicationReminderNotificationPayload pending) {
    return [
      pending.medicationId,
      pending.scheduledDate?.toIso8601String() ?? '',
      pending.scheduledTime ?? '',
    ].join('|');
  }

  String _debugEventSummaries(List<MedicationCalendarItem> events) {
    if (events.isEmpty) return '<empty>';

    return events.take(8).map((item) {
      return '{id:${item.medicationId}, date:${item.scheduledDate}, '
          'time:${item.scheduledTime}, status:${item.status}}';
    }).join(', ');
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F6),
          border: Border.all(color: const Color(0xFFF5CDD6)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE64060).withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFFAD9E0)),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFE64060),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFE64060),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _MedicationCalendarCard extends StatelessWidget {
  const _MedicationCalendarCard({
    required this.item,
    required this.onTap,
  });

  final MedicationCalendarItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _resolveColor(item.color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: _resolveColor(item.color),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_doseText(item.singleDose)} ${item.singleDoseUnit} • ${item.scheduledTime}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: item.status),
            ],
          ),
        ),
      ),
    );
  }

  String _doseText(num dose) {
    return dose % 1 == 0 ? dose.toInt().toString() : dose.toString();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final value = (status ?? 'open').toLowerCase();
    Color textColor;
    Color bgColor;
    String label;

    switch (value) {
      case 'taken':
        label = medicationStatusUiLabel(value);
        textColor = const Color(0xFF15803D);
        bgColor = const Color(0xFFDCFCE7);
        break;
      case 'missed':
        label = medicationStatusUiLabel(value);
        textColor = const Color(0xFFB91C1C);
        bgColor = const Color(0xFFFEE2E2);
        break;
      case 'skipped':
        label = medicationStatusUiLabel(value);
        textColor = Colors.orange[800]!;
        bgColor = Colors.orange[200]!;
        break;
      default:
        label = medicationStatusUiLabel(value);
        textColor = Colors.grey[700]!;
        bgColor = Colors.grey[200]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadingDayCard extends StatelessWidget {
  const _LoadingDayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Color(0xFFE64060),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Memuat jadwal rutinitas untuk bulan ini...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  const _EmptyDayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'Tidak ada jadwal rutinitas pada tanggal ini.',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 16,
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
    );
  }
}

Color _resolveColor(String raw) {
  final cleaned = raw.replaceFirst('#', '').trim();
  if (cleaned.isEmpty) return const Color(0xFFE64060);

  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return const Color(0xFFE64060);

  if (cleaned.length <= 6) {
    return Color(0xFF000000 | value);
  }

  return Color(value);
}
