import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/medication/data/models/medication_models.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_api_provider.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_history_provider.dart';
import 'package:pulsewise/features/medication/presentation/widgets/medication_consumption_tracking_card.dart';

class DetailPengingatPage extends ConsumerStatefulWidget {
  const DetailPengingatPage({
    super.key,
    required this.medicationId,
  });

  final String medicationId;

  @override
  ConsumerState<DetailPengingatPage> createState() =>
      _DetailPengingatPageState();
}

class _DetailPengingatPageState extends ConsumerState<DetailPengingatPage> {
  bool _isDeleting = false;

  Future<bool> _showDeleteConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Rutinitas?'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus rutinitas ini?',
          ),
          actions: [
            TextButton(
              onPressed: _isDeleting
                  ? null
                  : () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: _isDeleting
                  ? null
                  : () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF435D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Hapus'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _deleteMedication(String medicationId) async {
    if (_isDeleting) return;

    final shouldDelete = await _showDeleteConfirmationDialog();
    if (!shouldDelete) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(medicationApiProvider).deleteMedication(medicationId);
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      AppToast.warning(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(medicationDetailProvider(widget.medicationId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Detail Rutinitas',
        // subtitle: 'Tambahkan kontak dukungan baru',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFE64060)),
          ),
          error: (error, _) => isNetworkRequestError(error)
              ? NoConnectionState.page(
                  title: 'Detail rutinitas belum bisa dimuat',
                  message:
                      'Kami belum bisa mengambil detail rutinitas karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                  onRetry: () {
                    ref.invalidate(
                        medicationDetailProvider(widget.medicationId));
                  },
                )
              : _ErrorState(
                  message: error.toString().replaceFirst('Exception: ', ''),
                  onRetry: () {
                    ref.invalidate(
                        medicationDetailProvider(widget.medicationId));
                  },
                ),
          data: (item) => SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _buildHeader(context),
                const SizedBox(height: 16),
                _buildMainCard(item),
                const SizedBox(height: 16),
                _buildTrackingCard(item),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await context.push(
                              '/home/reminder/edit/${item.medicationId}',
                            );
                            if (!context.mounted) return;
                            if (result == true) {
                              ref.invalidate(
                                medicationDetailProvider(widget.medicationId),
                              );
                              AppToast.success(
                                context,
                                'Rutinitas berhasil diperbarui',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE64060),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isDeleting
                              ? null
                              : () => _deleteMedication(item.medicationId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF435D),
                            side: const BorderSide(color: Color(0xFFFF435D)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isDeleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFFFF435D),
                                  ),
                                )
                              : const Text(
                                  'Hapus',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(MedicationItem item) {
    final iconColor = _resolveColor(item.color);
    final hasWeeklyDays =
        item.frequency.toLowerCase() == 'weekly' && item.daysOfWeek.isNotEmpty;
    final note = item.note?.trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: iconColor.withOpacity(0.16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -34,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE64060).withOpacity(0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              iconColor.withOpacity(0.25),
                              iconColor.withOpacity(0.12),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border:
                              Border.all(color: iconColor.withOpacity(0.18)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _MedicationFormIcon(
                            form: item.form,
                            color: iconColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Wrap(
                            //   spacing: 8,
                            //   runSpacing: 8,
                            //   children: [
                            //     // const _GreyChip(label: 'Obat'),
                            //     if (conditionTag != null &&
                            //         conditionTag.isNotEmpty)
                            //       _ColorChip(
                            //         label: conditionTag,
                            //         background: iconColor.withOpacity(0.12),
                            //         foreground: iconColor,
                            //       ),
                            //   ],
                            // ),
                            // const SizedBox(height: 10),
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_doseText(item)} ${item.singleDoseUnit}',
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _frequencyText(item),
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: _InfoStatCard(
                  //         label: 'Dosis',
                  //         value: '${_doseText(item)} ${item.singleDoseUnit}',
                  //         // accentColor: Colors.white,
                  //         compact: false,
                  //       ),
                  //     ),
                  //     const SizedBox(width: 10),
                  //     Expanded(
                  //       child: _InfoStatCard(
                  //         label: 'Reminder',
                  //         value: '${item.reminders.length} aktif',
                  //         // accentColor: const Color(0xFF0F766E),
                  //         // accentColor: Colors.white,
                  //         compact: false,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 10),
                  // _InfoStatCard(
                  //   label: 'Jadwal',
                  //   value: _frequencyText(item),
                  //   // accentColor: const Color(0xFFE64060),
                  //   compact: false,
                  //   fullWidth: true,
                  // ),
                  // const SizedBox(height: 18),
                  if (hasWeeklyDays) ...[
                    const Text(
                      'Hari Rutin',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: item.daysOfWeek
                          .map(
                            (day) => _ColorChip(
                              label: _dayLabel(day),
                              background: const Color(0xFFFFE7EE),
                              foreground: const Color(0xFFE64060),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Waktu Pengingat',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: item.intakeTimes
                        .map(
                          (time) => _ColorChip(
                            label: time,
                            background: const Color(0xFFF1F5F9),
                            foreground: const Color(0xFF334155),
                          ),
                        )
                        .toList(),
                  ),
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.sticky_note_2_outlined,
                              size: 18,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              note,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 20,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard(MedicationItem item) {
    return MedicationConsumptionTrackingCard(
      patientId: item.userId,
      medicationId: item.medicationId,
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoStatCard extends StatelessWidget {
  const _InfoStatCard({
    required this.label,
    required this.value,
    // required this.accentColor,
    required this.compact,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  // final Color accentColor;
  final bool compact;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      constraints: BoxConstraints(minWidth: compact ? 0 : 124),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
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
                fontSize: 15,
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

class _GreyChip extends StatelessWidget {
  const _GreyChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MedicationFormIcon extends StatelessWidget {
  const _MedicationFormIcon({
    required this.form,
    required this.color,
  });

  final String form;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final svg = _formIcons[form.toLowerCase().trim()];
    if (svg == null) {
      return Icon(Icons.medication_rounded, color: color, size: 30);
    }

    return Center(
      child: SvgPicture.string(
        svg,
        width: 40,
        height: 40,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}

const Map<String, String> _formIcons = {
  'pill':
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m10.5 20.5 10-10a4.95 4.95 0 1 0-7-7l-10 10a4.95 4.95 0 1 0 7 7Z"/><path d="m8.5 8.5 7 7"/></svg>''',
  'tablet':
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="7" cy="7" r="5"/><circle cx="17" cy="17" r="5"/><path d="M12 17h10"/><path d="m3.46 10.54 7.08-7.08"/></svg>''',
  'kapsul':
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 11h-4a1 1 0 0 0-1 1v5a1 1 0 0 0 1 1h4"/><path d="M6 7v13a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V7"/><rect width="16" height="5" x="4" y="2" rx="1"/></svg>''',
  'capsule':
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 11h-4a1 1 0 0 0-1 1v5a1 1 0 0 0 1 1h4"/><path d="M6 7v13a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V7"/><rect width="16" height="5" x="4" y="2" rx="1"/></svg>''',
  'tetes':
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5s-3.5-4-4-6.5c-.5 2.5-2 4.9-4 6.5C6 11.1 5 13 5 15a7 7 0 0 0 7 7z"/></svg>''',
  'drops':
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22a7 7 0 0 0 7-7c0-2-1-3.9-3-5.5s-3.5-4-4-6.5c-.5 2.5-2 4.9-4 6.5C6 11.1 5 13 5 15a7 7 0 0 0 7 7z"/></svg>''',
  'sirup':
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2h8"/><path d="M9 2v2.789a4 4 0 0 1-.672 2.219l-.656.984A4 4 0 0 0 7 10.212V20a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2v-9.789a4 4 0 0 0-.672-2.219l-.656-.984A4 4 0 0 1 15 4.788V2"/><path d="M7 15a6.472 6.472 0 0 1 5 0 6.47 6.47 0 0 0 5 0"/></svg>''',
  'syrup':
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 2h8"/><path d="M9 2v2.789a4 4 0 0 1-.672 2.219l-.656.984A4 4 0 0 0 7 10.212V20a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2v-9.789a4 4 0 0 0-.672-2.219l-.656-.984A4 4 0 0 1 15 4.788V2"/><path d="M7 15a6.472 6.472 0 0 1 5 0 6.47 6.47 0 0 0 5 0"/></svg>''',
  'cairan':
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5.116 4.104A1 1 0 0 1 6.11 3h11.78a1 1 0 0 1 .994 1.105L17.19 20.21A2 2 0 0 1 15.2 22H8.8a2 2 0 0 1-2-1.79z"/><path d="M6 12a5 5 0 0 1 6 0 5 5 0 0 0 6 0"/></svg>''',
  'liquid':
      '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5.116 4.104A1 1 0 0 1 6.11 3h11.78a1 1 0 0 1 .994 1.105L17.19 20.21A2 2 0 0 1 15.2 22H8.8a2 2 0 0 1-2-1.79z"/><path d="M6 12a5 5 0 0 1 6 0 5 5 0 0 0 6 0"/></svg>''',
};

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

String _doseText(MedicationItem item) {
  final dose = item.singleDose;
  return dose % 1 == 0 ? dose.toInt().toString() : dose.toString();
}

String _frequencyText(MedicationItem item) {
  final frequency = item.frequency.toLowerCase();
  if (frequency == 'weekly') {
    return 'Mingguan';
  }

  final every = item.numOfDays;
  if (every != null && every > 0) {
    return 'Harian • setiap $every hari';
  }
  return 'Harian';
}

String _dayLabel(int value) {
  switch (value) {
    case 1:
      return 'Sen';
    case 2:
      return 'Sel';
    case 3:
      return 'Rab';
    case 4:
      return 'Kam';
    case 5:
      return 'Jum';
    case 6:
      return 'Sab';
    case 7:
      return 'Min';
    // Backward compatibility for older payloads that still used Sunday=0.
    case 0:
      return 'Min';
    default:
      return 'Hari $value';
  }
}
