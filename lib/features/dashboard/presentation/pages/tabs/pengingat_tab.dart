import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:pulsewise/features/dashboard/presentation/providers/medication_calendar_provider.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/profile_provider.dart';

class PengingatTab extends ConsumerStatefulWidget {
  const PengingatTab({super.key});

  @override
  ConsumerState<PengingatTab> createState() => _PengingatTabState();
}

class _PengingatTabState extends ConsumerState<PengingatTab>
    with AutomaticKeepAliveClientMixin {
  late DateTime _selectedDate;
  late DateTime _focusedDate;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = _dateOnly(now);
    _focusedDate = _dateOnly(now);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final now = DateTime.now();
    final fromDate = _dateOnly(now);
    final toDate = _dateOnly(DateTime(now.year, now.month + 1, 0));

    final query = MedicationCalendarRangeQuery(
      from: fromDate,
      to: toDate,
    );

    final calendarAsync = ref.watch(medicationCalendarRangeProvider(query));

    return SafeArea(
      child: calendarAsync.when(
        loading: () => const SizedBox.expand(
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFE64060)),
          ),
        ),
        error: (error, _) => _ErrorView(
          message: error.toString().replaceFirst('Exception: ', ''),
          onRetry: () {
            ref.invalidate(medicationCalendarRangeProvider(query));
          },
        ),
        data: (calendarData) {
          final events = [...calendarData.items]..sort((a, b) {
              final dateA = a.scheduledDate ?? DateTime(1970);
              final dateB = b.scheduledDate ?? DateTime(1970);
              final dateCompare = dateA.compareTo(dateB);
              if (dateCompare != 0) return dateCompare;
              return a.scheduledTime.compareTo(b.scheduledTime);
            });

          final selectedEvents = events
              .where((item) => _isSameDay(item.scheduledDate, _selectedDate))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(medicationCalendarRangeProvider(query));
              await ref.read(medicationCalendarRangeProvider(query).future);
            },
            color: const Color(0xFFE64060),
            backgroundColor: Colors.white,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
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
                  child: TableCalendar<MedicationCalendarItem>(
                    firstDay: fromDate,
                    lastDay: toDate,
                    focusedDay: _focusedDate,
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
                      setState(() {
                        _focusedDate = _dateOnly(focusedDay);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Jadwal ${_formatDateLong(_selectedDate)}',
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (selectedEvents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _EmptyDayCard(),
                  )
                else
                  ...selectedEvents.map(
                    (item) => _MedicationCalendarCard(
                      item: item,
                      onTap: () => _showMedicationBottomSheet(context, item),
                    ),
                  ),
              ],
            ),
          );
        },
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
                  'Pengingat',
                  style: TextStyle(
                    color: Color(0xFF525252),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Kalender Obat',
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
            onTap: () => context.push('/home/reminder/manage'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMedicationBottomSheet(
    BuildContext context,
    MedicationCalendarItem item,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                item.name,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_doseText(item.singleDose)} ${item.singleDoseUnit}',
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatDateLong(item.scheduledDate)} • ${item.scheduledTime}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              _StatusChip(status: item.status),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/home/reminder/detail/${item.medicationId}');
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text(
                    'Kelola Obat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE64060),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
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

  String _doseText(num dose) {
    return dose % 1 == 0 ? dose.toInt().toString() : dose.toString();
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Color(0xFFE64060), size: 24),
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
        label = 'Taken';
        textColor = const Color(0xFF15803D);
        bgColor = const Color(0xFFDCFCE7);
        break;
      case 'missed':
        label = 'Missed';
        textColor = const Color(0xFFB91C1C);
        bgColor = const Color(0xFFFEE2E2);
        break;
      case 'skipped':
        label = 'Skipped';
        textColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        break;
      default:
        label = 'Open';
        textColor = const Color(0xFFE64060);
        bgColor = const Color(0xFFFFE7EE);
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
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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
        'Tidak ada jadwal obat pada tanggal ini.',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
