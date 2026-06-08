import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart' as dntp;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:time_picker_spinner_pop_up/time_picker_spinner_pop_up.dart';

class DateTimePickerDemoPage extends StatefulWidget {
  const DateTimePickerDemoPage({super.key});

  @override
  State<DateTimePickerDemoPage> createState() => _DateTimePickerDemoPageState();
}

class _DateTimePickerDemoPageState extends State<DateTimePickerDemoPage> {
  DateTime? _materialDate;
  TimeOfDay? _materialTime;
  DateTimeRange? _materialRange;
  DateTime? _calendarDate;
  DateTime _spinnerDate = DateTime.now();
  DateTime _spinnerDateTime = DateTime.now();
  DateTime _inlineCalendarDate = DateTime.now();
  DateTime _cupertinoDialogDate = DateTime.now();
  DateTime _cupertinoSheetDate = DateTime.now();
  DateTime _cupertinoSheetDateTime = DateTime.now();
  dntp.Time _dayNightTime = dntp.Time(hour: 8, minute: 0);

  Future<void> _pickMaterialDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _materialDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: 'Pilih tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked == null || !mounted) return;
    setState(() => _materialDate = picked);
  }

  Future<void> _pickMaterialTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _materialTime ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Pilih waktu',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() => _materialTime = picked);
  }

  Future<void> _pickMaterialRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _materialRange,
      helpText: 'Pilih rentang tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked == null || !mounted) return;
    setState(() => _materialRange = picked);
  }

  Future<void> _pickCalendarDate() async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        calendarType: CalendarDatePicker2Type.single,
        selectedDayHighlightColor: const Color(0xFFE64060),
        centerAlignModePicker: true,
        selectedDayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        okButtonTextStyle: const TextStyle(
          color: Color(0xFFE64060),
          fontWeight: FontWeight.w700,
        ),
        cancelButtonTextStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w700,
        ),
      ),
      dialogSize: const Size(360, 420),
      value: [
        _calendarDate ?? DateTime.now(),
      ],
      borderRadius: BorderRadius.circular(24),
    );

    if (!mounted ||
        results == null ||
        results.isEmpty ||
        results.first == null) {
      return;
    }

    setState(() => _calendarDate = results.first);
  }

  Future<void> _pickCupertinoSheetDateTime() async {
    final initialValue = _cupertinoSheetDateTime;
    var draftValue = initialValue;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Cupertino Sheet',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(draftValue),
                        child: const Text(
                          'Pilih',
                          style: TextStyle(
                            color: Color(0xFFEA580C),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 240,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    use24hFormat: true,
                    initialDateTime: initialValue,
                    onDateTimeChanged: (value) => draftValue = value,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() => _cupertinoSheetDateTime = picked);
  }

  Future<void> _pickCupertinoSheetDate() async {
    final initialValue = _cupertinoSheetDate;
    var draftValue = initialValue;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Cupertino Date',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(draftValue),
                        child: const Text(
                          'Pilih',
                          style: TextStyle(
                            color: Color(0xFFEA580C),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 240,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialValue,
                    onDateTimeChanged: (value) => draftValue = value,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() => _cupertinoSheetDate = picked);
  }

  Future<void> _pickCupertinoDialogDate() async {
    final initialValue = _cupertinoDialogDate;
    var draftValue = initialValue;

    final picked = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Cupertino Popup',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(draftValue),
                      child: const Text(
                        'Pilih',
                        style: TextStyle(
                          color: Color(0xFFE64060),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialValue,
                    onDateTimeChanged: (value) => draftValue = value,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() => _cupertinoDialogDate = picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Belum dipilih';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} - $hour:$minute';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Belum dipilih';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDayNightTime(dntp.Time time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatRange(DateTimeRange? range) {
    if (range == null) return 'Belum dipilih';
    return '${_formatDate(range.start)} - ${_formatDate(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Demo Picker',
        subtitle: 'Bandingkan opsi tanggal & waktu',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const _IntroCard(
              title: 'Opsi yang worth dicoba',
              description:
                  'Aku pasang beberapa gaya picker di halaman ini supaya kamu bisa ngerasain mana yang paling enak dipakai pengguna, terutama untuk teks besar, tap target yang jelas, dan flow yang gampang dipahami.',
              bullets: [
                'Material bawaan Flutter',
                'Calendar Date Picker 2',
                'Spinner Pop Up ala Cupertino',
                'Day/Night Time Picker tanpa header asset',
                'Material Date Range Picker',
                'Inline Calendar dan Cupertino bottom sheet',
                'Cupertino date only',
                'Cupertino popup modal',
              ],
            ),
            const SizedBox(height: 14),
            _DemoCard(
              title: '1. Material Bawaan',
              subtitle:
                  'Paling aman dan paling native. Bagus kalau kita mau UI tetap familiar.',
              accent: const Color(0xFF2563EB),
              children: [
                _ResultRow(
                  label: 'Tanggal terpilih',
                  value: _formatDate(_materialDate),
                ),
                _ResultRow(
                  label: 'Waktu terpilih',
                  value: _formatTime(_materialTime),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Pilih Tanggal',
                        icon: Icons.calendar_month_outlined,
                        onTap: _pickMaterialDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: 'Pilih Waktu',
                        icon: Icons.schedule_outlined,
                        onTap: _pickMaterialTime,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DemoCard(
              title: '2. Calendar Date Picker 2',
              subtitle:
                  'Kalender besar yang lebih fleksibel. Enak kalau kita mau tampilan tanggal yang lebih jelas dan mudah di-tweak.',
              accent: const Color(0xFFE64060),
              children: [
                _ResultRow(
                  label: 'Tanggal terpilih',
                  value: _formatDate(_calendarDate),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Buka Kalender Besar',
                  icon: Icons.date_range_outlined,
                  onTap: _pickCalendarDate,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DemoCard(
              title: '3. Spinner Pop Up',
              subtitle:
                  'Gaya picker ala iOS/Cupertino. Cocok kalau kamu mau pilihan yang halus dan terasa lebih premium.',
              accent: const Color(0xFF0F766E),
              children: [
                _ResultRow(
                  label: 'Tanggal spinner',
                  value: _formatDate(_spinnerDate),
                ),
                _ResultRow(
                  label: 'Tanggal + waktu spinner',
                  value: _formatDateTime(_spinnerDateTime),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SpinnerPickerButton(
                        label: 'Tanggal Spinner',
                        icon: Icons.event_outlined,
                        initTime: _spinnerDate,
                        mode: CupertinoDatePickerMode.date,
                        timeFormat: 'dd/MM/yyyy',
                        onChange: (value) =>
                            setState(() => _spinnerDate = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SpinnerPickerButton(
                        label: 'Date & Time',
                        icon: Icons.more_time_outlined,
                        initTime: _spinnerDateTime,
                        mode: CupertinoDatePickerMode.dateAndTime,
                        timeFormat: 'dd/MM/yyyy HH:mm',
                        onChange: (value) =>
                            setState(() => _spinnerDateTime = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DemoCard(
              title: '4. Day / Night Time Picker',
              subtitle:
                  'Masih terasa beda dari picker biasa, tapi header asset-nya dimatikan supaya aman dan tidak error di demo.',
              accent: const Color(0xFF7C3AED),
              children: [
                _ResultRow(
                  label: 'Waktu terpilih',
                  value: _formatDayNightTime(_dayNightTime),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Buka Picker Animasi',
                  icon: Icons.dark_mode_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      dntp.showPicker(
                        context: context,
                        value: _dayNightTime,
                        onChange: (value) =>
                            setState(() => _dayNightTime = value),
                        is24HrFormat: true,
                        minuteInterval: dntp.TimePickerInterval.FIVE,
                        accentColor: const Color(0xFF7C3AED),
                        displayHeader: false,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DemoCard(
              title: '5. Material Date Range Picker',
              subtitle:
                  'Berguna kalau nanti ada kebutuhan pilih periode, misalnya filter riwayat atau jadwal mingguan.',
              accent: const Color(0xFF0891B2),
              children: [
                _ResultRow(
                  label: 'Rentang terpilih',
                  value: _formatRange(_materialRange),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Pilih Rentang',
                  icon: Icons.calendar_view_week_outlined,
                  onTap: _pickMaterialRange,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DemoCard(
              title: '6. Inline Calendar Material',
              subtitle:
                  'Kalender langsung tampil di halaman. Lebih gampang buat user lansia karena tidak terasa seperti pop-up tambahan.',
              accent: const Color(0xFF16A34A),
              children: [
                _ResultRow(
                  label: 'Tanggal terpilih',
                  value: _formatDate(_inlineCalendarDate),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CalendarDatePicker(
                    initialDate: _inlineCalendarDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365 * 2),
                    ),
                    lastDate: DateTime.now().add(
                      const Duration(days: 365 * 2),
                    ),
                    onDateChanged: (value) =>
                        setState(() => _inlineCalendarDate = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DemoCard(
              title: '7. Cupertino Bottom Sheet',
              subtitle:
                  'Wheel picker yang dibuka dari bawah layar. Terasa halus, fokus, dan cukup ramah buat jari yang lebih pelan.',
              accent: const Color(0xFFEA580C),
              children: [
                _ResultRow(
                  label: 'Tanggal terpilih',
                  value: _formatDate(_cupertinoSheetDate),
                ),
                _ResultRow(
                  label: 'Tanggal + waktu terpilih',
                  value: _formatDateTime(_cupertinoSheetDateTime),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Date Only',
                        icon: Icons.event_outlined,
                        onTap: _pickCupertinoSheetDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: 'Date & Time',
                        icon: Icons.expand_less_rounded,
                        onTap: _pickCupertinoSheetDateTime,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DemoCard(
              title: '8. Cupertino Pop-up Modal',
              subtitle:
                  'Versi tengah layar yang terasa seperti dialog. Ini paling dekat dengan popup modal tanpa turun dari bawah.',
              accent: const Color(0xFFDC2626),
              children: [
                _ResultRow(
                  label: 'Tanggal terpilih',
                  value: _formatDate(_cupertinoDialogDate),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Buka Pop-up Modal',
                  icon: Icons.open_in_new_rounded,
                  onTap: _pickCupertinoDialogDate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.title,
    required this.description,
    required this.bullets,
  });

  final String title;
  final String description;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Demo untuk dipilih',
            style: TextStyle(
              color: Color(0xFFB45309),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          ...bullets.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: Color(0xFFCA8A04),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.children,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE64060),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SpinnerPickerButton extends StatelessWidget {
  const _SpinnerPickerButton({
    required this.label,
    required this.icon,
    required this.initTime,
    required this.mode,
    required this.timeFormat,
    required this.onChange,
  });

  final String label;
  final IconData icon;
  final DateTime initTime;
  final CupertinoDatePickerMode mode;
  final String timeFormat;
  final ValueChanged<DateTime> onChange;

  @override
  Widget build(BuildContext context) {
    return TimePickerSpinnerPopUp(
      mode: mode,
      initTime: initTime,
      timeFormat: timeFormat,
      use24hFormat: true,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onChange: onChange,
      timeWidgetBuilder: (_) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
