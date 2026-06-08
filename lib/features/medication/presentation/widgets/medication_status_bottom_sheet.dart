import 'package:flutter/material.dart';
import 'package:pulsewise/features/medication/data/models/medication_models.dart';
import 'package:pulsewise/features/medication/presentation/utils/medication_status_ui.dart';

Future<bool?> showMedicationStatusBottomSheet({
  required BuildContext context,
  required MedicationCalendarItem item,
  required Future<void> Function(String status, MedicationCalendarItem item)
      onSave,
  VoidCallback? onManage,
  String initialStatus = 'Taken',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      return MedicationStatusBottomSheet(
        item: item,
        initialStatus: initialStatus,
        onSave: onSave,
        onManage: onManage,
      );
    },
  );
}

class MedicationStatusBottomSheet extends StatefulWidget {
  const MedicationStatusBottomSheet({
    super.key,
    required this.item,
    required this.onSave,
    this.onManage,
    this.initialStatus = 'Taken',
  });

  final MedicationCalendarItem item;
  final String initialStatus;
  final Future<void> Function(String status, MedicationCalendarItem item)
      onSave;
  final VoidCallback? onManage;

  @override
  State<MedicationStatusBottomSheet> createState() =>
      _MedicationStatusBottomSheetState();
}

class _MedicationStatusBottomSheetState
    extends State<MedicationStatusBottomSheet> {
  static const List<_MedicationStatusOption> _statusOptions = [
    _MedicationStatusOption(
      value: 'Taken',
      label: 'Selesai',
      icon: Icons.check_circle_outline_sharp,
    ),
    _MedicationStatusOption(
      value: 'Skipped',
      label: 'Dilewati',
      icon: Icons.directions_walk_rounded,
    ),
    _MedicationStatusOption(
      value: 'Missed',
      label: 'Terlewat',
      icon: Icons.directions_run_rounded,
    ),
  ];

  late String _selectedLevel;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedLevel = _normalizeStatusValue(widget.item.status) ??
        _normalizeStatusValue(widget.initialStatus) ??
        _statusOptions.first.value;
  }

  Future<void> _submit() async {
    final scheduledDate = widget.item.scheduledDate;
    if (scheduledDate == null) {
      setState(() {
        _errorMessage = 'Tanggal jadwal rutinitas tidak tersedia.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.onSave(_selectedLevel.toLowerCase(), widget.item);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _handleManage() {
    Navigator.of(context).pop(false);
    widget.onManage?.call();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.item.status;
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
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        top: 16,
        right: 16,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_doseText(widget.item.singleDose)} ${widget.item.singleDoseUnit}',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatDateLong(widget.item.scheduledDate)} • ${widget.item.scheduledTime}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              (widget.item.status != null)
                  ? Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        value: _selectedLevel,
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: _isSaving ? Colors.white : Colors.grey[50],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color(0xFFE64060),
                              width: 2,
                            ),
                          ),
                        ),
                        items: _statusOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option.value,
                            child: Row(
                              children: [
                                // Icon(option.icon,
                                //     size: 18, color: const Color(0xFF475569)),
                                const SizedBox(width: 10),
                                Text(
                                  option.label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _isSaving
                            ? null
                            : (val) {
                                if (val == null) return;
                                setState(() {
                                  _selectedLevel = val;
                                });
                              },
                      ),
                    ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              widget.item.status != null
                  ? const SizedBox.shrink()
                  : Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: _isSaving
                            ? const SizedBox.shrink()
                            : const Icon(Icons.check_circle_outline_sharp),
                        label: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFFE13D5A),
                                ),
                              )
                            : const Text(
                                'Simpan',
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
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleManage,
                  icon: const Icon(Icons.settings),
                  label: const Text(
                    'Kelola Rutinitas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE64060),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE64060)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  String? _normalizeStatusValue(String? rawStatus) {
    if (rawStatus == null || rawStatus.trim().isEmpty) return null;

    for (final option in _statusOptions) {
      if (option.value.toLowerCase() == rawStatus.toLowerCase()) {
        return option.value;
      }
    }

    return null;
  }
}

class _MedicationStatusOption {
  const _MedicationStatusOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}
