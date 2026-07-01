import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/medication/data/models/medication_models.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_history_provider.dart';

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

class ManagePengingatPage extends ConsumerStatefulWidget {
  const ManagePengingatPage({super.key});

  @override
  ConsumerState<ManagePengingatPage> createState() =>
      _ManagePengingatPageState();
}

class _ManagePengingatPageState extends ConsumerState<ManagePengingatPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(medicationHistoryProvider.notifier);
      final state = ref.read(medicationHistoryProvider);
      if (state.items.isEmpty && !state.isLoading) {
        notifier.loadMedications(page: 1, limit: 10);
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 220;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(medicationHistoryProvider.notifier).loadNextPage();
    }
  }

  Future<void> _openAddMedication(BuildContext context) async {
    final result = await context.push('/home/reminder/add');
    if (!context.mounted) return;
    if (result == true) {
      AppToast.success(context, 'Pengingat obat berhasil ditambahkan');
      await ref.read(medicationHistoryProvider.notifier).refreshMedications();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(medicationHistoryProvider.notifier).refreshMedications();
  }

  Future<void> _retryLoad() async {
    await ref.read(medicationHistoryProvider.notifier).loadMedications(
          page: 1,
          limit: 10,
        );
  }

  Future<void> _openMedicationDetail(String medicationId) async {
    final result = await context.push('/home/reminder/detail/$medicationId');
    if (!mounted) return;
    if (result == true) {
      AppToast.success(context, 'Pengingat berhasil dihapus');
      ref.read(medicationHistoryProvider.notifier).refreshMedications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicationHistoryProvider);
    final hasNetworkError =
        state.errorCause != null && isNetworkRequestError(state.errorCause!);

    final showInitialLoader = state.isLoading && state.items.isEmpty;
    final showInitialError =
        state.error != null && state.error!.isNotEmpty && state.items.isEmpty;
    final showInitialNoConnection = showInitialError && hasNetworkError;
    final showEmptyState =
        !state.isLoading && !showInitialError && state.items.isEmpty;
    final showRefreshing = state.isLoading && state.items.isNotEmpty;
    final showRefreshNoConnection =
        hasNetworkError && state.error != null && state.items.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
          title: 'Pengingat',
          subtitle: 'Kelola pengingat obat Anda',
          showBackButton: true,
          onBackPressed: () => context.pop(),
          action: GestureDetector(
            key: const Key('patient_medication_manage_add_button'),
            onTap: () => _openAddMedication(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          )),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFE64060),
          backgroundColor: Colors.white,
          onRefresh: _onRefresh,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: 1 +
                (showInitialLoader || showInitialError || showEmptyState
                    ? 1
                    : state.items.length +
                        (showRefreshNoConnection ? 1 : 0) +
                        (showRefreshing ? 1 : 0) +
                        (state.isLoadingMore ? 1 : 0)),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 14),
                  ],
                );
              }

              if (showInitialLoader) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE64060),
                    ),
                  ),
                );
              }

              if (showInitialError) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: showInitialNoConnection
                      ? NoConnectionState.page(
                          title: 'Daftar pengingat belum bisa dimuat',
                          message:
                              'Kami belum bisa mengambil daftar pengingat obat karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                          onRetry: () {
                            _retryLoad();
                          },
                        )
                      : _StateCard(
                          message: state.error!,
                          actionLabel: 'Coba Lagi',
                          onTap: _retryLoad,
                        ),
                );
              }

              if (showRefreshNoConnection && index == 1) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: NoConnectionState.compact(
                    title: 'Koneksi terputus',
                    message:
                        'Menampilkan daftar pengingat terakhir yang berhasil dimuat. Sambungkan internet untuk memperbarui daftar terbaru.',
                    onRetry: () {
                      _retryLoad();
                    },
                  ),
                );
              }

              if (showEmptyState) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _StateCard(
                    message:
                        'Belum ada pengingat obat. Tekan tombol + untuk menambah.',
                  ),
                );
              }

              if (showRefreshing && index == 1) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE64060),
                    ),
                  ),
                );
              }

              final dataIndex = index -
                  1 -
                  (showRefreshing ? 1 : 0) -
                  (showRefreshNoConnection ? 1 : 0);
              if (dataIndex >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFFE64060),
                      ),
                    ),
                  ),
                );
              }

              final item = state.items[dataIndex];
              return _MedicationCard(
                item: item,
                onTap: () => _openMedicationDetail(item.medicationId),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const SizedBox();
  }

  // Widget _buildHeader(BuildContext context) {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
  //     decoration: const BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [Color(0xFFE64060), Color(0xFFFF6C86)],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.only(
  //         bottomLeft: Radius.circular(28),
  //         bottomRight: Radius.circular(28),
  //       ),
  //     ),
  //     child: Row(
  //       children: [
  //         _HeaderIcon(
  //           icon: Icons.arrow_back,
  //           onTap: () => context.pop(),
  //         ),
  //         const SizedBox(width: 10),
  //         const Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Pengingat',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 36,
  //                   fontWeight: FontWeight.w700,
  //                 ),
  //               ),
  //               SizedBox(height: 2),
  //               Text(
  //                 'Medication list',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         _HeaderIcon(
  //           icon: Icons.add,
  //           onTap: () => _openAddMedication(context),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

class _MedicationCard extends StatelessWidget {
  final MedicationItem item;
  final VoidCallback onTap;

  const _MedicationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: InkWell(
        key: Key('patient_medication_manage_card_${item.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _resolveColor(item.color).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _MedicationFormIcon(
                  form: item.form,
                  color: _resolveColor(item.color),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Color(0xFF0B1742),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _detailText(item),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6B7280),
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.message,
    this.actionLabel,
    this.onTap,
  });

  final String message;
  final String? actionLabel;
  final Future<void> Function()? onTap;

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
        crossAxisAlignment: CrossAxisAlignment.center,
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
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => onTap!.call(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel!),
            ),
          ],
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

IconData _resolveIcon(String form) {
  return Icons.medication_rounded;
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
    final key = form.toLowerCase().trim();
    final svg = _formIcons[key];
    if (svg == null) {
      return Icon(_resolveIcon(form), color: color, size: 30);
    }

    return Center(
      child: SvgPicture.string(
        svg,
        width: 28,
        height: 28,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}

String _detailText(MedicationItem item) {
  final unit = item.singleDoseUnit.trim();
  final dose = item.singleDose;
  final doseText = dose % 1 == 0 ? dose.toInt().toString() : dose.toString();
  final timesPerDay = item.intakeTimes.length;
  return '$doseText $unit • $timesPerDay kali per hari';
}

// class _AddMedicationCard extends StatelessWidget {
//   final VoidCallback onTap;

//   const _AddMedicationCard({required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(24),
//         child: Container(
//           padding: const EdgeInsets.all(18),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(color: const Color(0xFFE5E7EB)),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 56,
//                 height: 56,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border:
//                       Border.all(color: const Color(0xFF2F64D3), width: 2.5),
//                 ),
//                 child: const Icon(
//                   Icons.add,
//                   color: Color(0xFF2F64D3),
//                   size: 36,
//                 ),
//               ),
//               const SizedBox(width: 14),
//               const Text(
//                 'Add Medication halo',
//                 style: TextStyle(
//                   color: Color(0xFF2F64D3),
//                   fontSize: 24,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
