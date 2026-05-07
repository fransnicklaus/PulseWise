// import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/profile_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/recommendation_history_provider.dart';

import '../../../../core/widgets/custom_app_bar.dart';

// TODO: Update this when ML Recommendation History Endpoint is ready
// final mlHistoryProvider = StateNotifierProvider.autoDispose<
//     RecommendationHistoryNotifier, RecommendationHistoryState>(
//   (ref) {
//     return RecommendationHistoryNotifier(ref.watch(profileApiProvider));
//   },
// );

class MlRecommendationHistoryPage extends ConsumerStatefulWidget {
  const MlRecommendationHistoryPage({super.key});

  @override
  ConsumerState<MlRecommendationHistoryPage> createState() =>
      _MlRecommendationHistoryPageState();
}

class _MlRecommendationHistoryPageState
    extends ConsumerState<MlRecommendationHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};
  String? _expandedId;

  MlRecommendationResponse? _mlRecommendation;
  MlRecommendationResponse? _mlPredictionResult;

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
      ref.read(recommendationhistoryNotifier.notifier).loadNextPage();
    }
  }

  void _loadThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    ref.read(recommendationhistoryNotifier.notifier).loadRecommendationHistory(
          page: 1,
          limit: 10,
          startDate: startOfMonth,
          endDate: endOfMonth,
        );
  }

  void _toggleEntry(String id) async {
    final isExpanded = _expandedId == id;
    setState(() {
      _expandedId = _expandedId == id ? null : id;
    });

    if (isExpanded) return;

    await ref.read(profileApiProvider).fetchMlRecommendationHistoryDetail(id);
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[id];
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

  String formatToCustomDate(String isoString) {
    // 1. Parse the string to a DateTime object
    DateTime dateTime = DateTime.parse(isoString);

    // 2. Define the month names
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Des'
    ];

    // 3. Extract parts
    String day = dateTime.day.toString();
    String month = months[dateTime.month - 1]; // -1 because months are 1-12
    int year = dateTime.year;

    // 4. Return the combined string
    return "$day $month $year";
  }

  String formatWithTime(String isoString) {
    DateTime dateTime = DateTime.parse(isoString);

    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    // Date parts
    String day = dateTime.day.toString();
    String month = months[dateTime.month - 1];
    int year = dateTime.year;

    // Time parts (padded to 2 digits)
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');

    return "$day $month $year, $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationhistoryNotifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBody: true,
      appBar: CustomAppBar(
        title: 'Riwayat Prediksi ML',
        subtitle: 'Hasil Prediksi & Rekomendasi',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(recommendationhistoryNotifier.notifier).refreshHistory(),
        color: const Color(0xFFE64060),
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE64060)),
                ),
              )
            else if (state.items.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Belum ada riwayat prediksi ML',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = state.items[index];
                      final id = item.resultId as String;
                      final date = formatToCustomDate(item.generatedAt);
                      final dateTime = formatWithTime(item.generatedAt);
                      // final cleanDate = formatToCustomDate(
                      //     date.toIso8601String().split('T')[0]);

                      final isExpanded = _expandedId == id;

                      return Padding(
                        key: _itemKeys[id],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 7),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _toggleEntry(id),
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
                                            date,
                                            style: const TextStyle(
                                              color: Color(0xFF1E293B),
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'Dibuat $dateTime',
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
                                      duration:
                                          const Duration(milliseconds: 220),
                                      child: const Icon(
                                        Icons.chevron_right,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                                // ...state.items.map((item) {
                                //   final id = item.resultId;
                                //   final detail = state.detailsByDiaryId[id];
                                //   final isDetailLoading =
                                //       state.loadingDetailDiaryIds.contains(id);
                                //   final detailError =
                                //       state.detailErrorsByDiaryId[id];
                                //   return

                                // _itemKeys[id] ??= GlobalKey();

                                // return Padding(
                                //   key: _itemKeys[id],
                                //   padding: const EdgeInsets.symmetric(
                                //     horizontal: 16,
                                //     vertical: 7,
                                //   ),
                                //   child: InkWell(
                                //     borderRadius: BorderRadius.circular(16),
                                //     onTap: () => _toggleEntry(id),
                                //     child: Container(
                                //       padding: const EdgeInsets.all(16),
                                //       decoration: BoxDecoration(
                                //         color: Colors.white,
                                //         borderRadius:
                                //             BorderRadius.circular(16),
                                //         boxShadow: [
                                //           BoxShadow(
                                //             color: Colors.black
                                //                 .withOpacity(0.03),
                                //             blurRadius: 10,
                                //             offset: const Offset(0, 4),
                                //           ),
                                //         ],
                                //       ),
                                //       child: Column(
                                //         crossAxisAlignment:
                                //             CrossAxisAlignment.start,
                                //         children: [
                                //           Row(
                                //             children: [
                                //               Expanded(
                                //                 child: Column(
                                //                   crossAxisAlignment:
                                //                       CrossAxisAlignment
                                //                           .start,
                                //                   children: [
                                //                     Text(
                                //                       date,
                                //                       style: const TextStyle(
                                //                         color:
                                //                             Color(0xFF1E293B),
                                //                         fontSize: 17,
                                //                         fontWeight:
                                //                             FontWeight.w700,
                                //                       ),
                                //                     ),
                                //                     const SizedBox(height: 3),
                                //                     Text(
                                //                       'Dibuat $dateTime',
                                //                       style: const TextStyle(
                                //                         color:
                                //                             Color(0xFF64748B),
                                //                         fontSize: 13,
                                //                         fontWeight:
                                //                             FontWeight.w500,
                                //                       ),
                                //                     ),
                                //                   ],
                                //                 ),
                                //               ),
                                //               AnimatedRotation(
                                //                 turns: isExpanded ? 0.25 : 0,
                                //                 duration: const Duration(
                                //                     milliseconds: 220),
                                //                 child: const Icon(
                                //                   Icons.chevron_right,
                                //                   color: Color(0xFF94A3B8),
                                //                 ),
                                //               ),
                                //             ],
                                //           ),
                                //           ClipRect(
                                //             child: AnimatedSize(
                                //               duration: const Duration(
                                //                   milliseconds: 220),
                                //               curve: Curves.easeInOutCubic,
                                //               alignment: Alignment.topCenter,
                                //               child: AnimatedSwitcher(
                                //                 duration: const Duration(
                                //                     milliseconds: 180),
                                //                 switchInCurve: Curves.easeOut,
                                //                 switchOutCurve: Curves.easeIn,
                                //                 transitionBuilder:
                                //                     (child, animation) {
                                //                   return FadeTransition(
                                //                     opacity: animation,
                                //                     child: child,
                                //                   );
                                //                 },
                                //                 child: isExpanded
                                //                     ? Padding(
                                //                         key: ValueKey<String>(
                                //                           'expanded-$id',
                                //                         ),
                                //                         padding:
                                //                             const EdgeInsets
                                //                                 .only(
                                //                                 top: 12),
                                //                         child: Text(
                                //                             'this works'),
                                //                         // child: _ExpandedArea(
                                //                         //   isLoading: isDetailLoading,
                                //                         //   error: detailError,
                                //                         //   detail: detail,
                                //                         //   onRetry: () => ref
                                //                         //       .read(diaryHistoryProvider
                                //                         //           .notifier)
                                //                         //       .loadDiaryDetail(item.diaryDate!),
                                //                         //   formatTime: _formatTime,
                                //                         // ),
                                //                       )
                                //                     : const SizedBox(
                                //                         key: ValueKey<String>(
                                //                             'collapsed'),
                                //                       ),
                                //               ),
                                //             ),
                                //           ),
                                //         ],
                                //       ),
                                //     ),
                                // ),
                                // );
                                // }
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: state.items.length,
                  ),
                ),
              ),
            if (state.error != null && state.items.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  state.error!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 13,
                  ),
                ),
              ),
            if (state.error != null && state.items.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          ],
        ),
      ),
    );
  }
}
// Widget _buildRecommendationSection() {
//   final state = ref.watch(recommendationhistoryNotifier);
//   return SingleChildScrollView(
//                           padding: const EdgeInsets.all(24),
//                           child: state.isLoading
//                               ? const Center(
//                                   child: Padding(
//                                     padding: EdgeInsets.all(40),
//                                     child: CircularProgressIndicator(
//                                       color: Color(0xFFE13D5A),
//                                     ),
//                                   ),
//                                 )
//                               : Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             // SizedBox(
//                                             //   width: double.infinity,
//                                             //   child: ElevatedButton.icon(
//                                             //     style:
//                                             //         ElevatedButton.styleFrom(
//                                             //       backgroundColor:
//                                             //           const Color(0xFFE13D5A),
//                                             //       foregroundColor:
//                                             //           Colors.white,
//                                             //       padding: const EdgeInsets
//                                             //           .symmetric(
//                                             //           vertical: 12),
//                                             //       shape:
//                                             //           RoundedRectangleBorder(
//                                             //         borderRadius:
//                                             //             BorderRadius.circular(
//                                             //                 12),
//                                             //       ),
//                                             //     ),
//                                             //     onPressed:
//                                             //         _checkMlReadinessAndPredict,
//                                             //     icon: const Icon(
//                                             //         Icons.refresh,
//                                             //         size: 28),
//                                             //     label: const Text(
//                                             //         'Jalankan Prediksi Lagi',
//                                             //         style: TextStyle(
//                                             //             fontSize: 18)),
//                                             //   ),
//                                             // ),
//                                             // const SizedBox(height: 12),
//                                             // Row(
//                                             //   children: [
//                                             //     Expanded(
//                                             //       child: OutlinedButton.icon(
//                                             //         style: OutlinedButton
//                                             //             .styleFrom(
//                                             //           foregroundColor:
//                                             //               const Color(
//                                             //                   0xFFE13D5A),
//                                             //           side: const BorderSide(
//                                             //               color: Color(
//                                             //                   0xFFE13D5A)),
//                                             //           padding:
//                                             //               const EdgeInsets
//                                             //                   .symmetric(
//                                             //                   vertical: 12),
//                                             //           shape:
//                                             //               RoundedRectangleBorder(
//                                             //             borderRadius:
//                                             //                 BorderRadius
//                                             //                     .circular(12),
//                                             //           ),
//                                             //         ),
//                                             //         onPressed: () => context.push(
//                                             //             '/home/patient-dashboard/ml-assessment'),
//                                             //         icon: const Icon(
//                                             //             Icons.edit_document,
//                                             //             size: 28),
//                                             //         label: const Text(
//                                             //             'Isi Form',
//                                             //             style: TextStyle(
//                                             //                 fontSize: 18)),
//                                             //       ),
//                                             //     ),
//                                             //     const SizedBox(width: 12),
//                                             //     Expanded(
//                                             //       child: OutlinedButton.icon(
//                                             //         style: OutlinedButton
//                                             //             .styleFrom(
//                                             //           foregroundColor:
//                                             //               const Color(
//                                             //                   0xFFE13D5A),
//                                             //           side: const BorderSide(
//                                             //               color: Color(
//                                             //                   0xFFE13D5A)),
//                                             //           padding:
//                                             //               const EdgeInsets
//                                             //                   .symmetric(
//                                             //                   vertical: 12),
//                                             //           shape:
//                                             //               RoundedRectangleBorder(
//                                             //             borderRadius:
//                                             //                 BorderRadius
//                                             //                     .circular(12),
//                                             //           ),
//                                             //         ),
//                                             //         onPressed: () => context.push(
//                                             //             '/home/patient-dashboard/ml-recommendation-history'),
//                                             //         icon: const Icon(
//                                             //             Icons.history,
//                                             //             size: 28),
//                                             //         label: const Text(
//                                             //             'Cek History',
//                                             //             style: TextStyle(
//                                             //                 fontSize: 18)),
//                                             //       ),
//                                             //     ),
//                                             //   ],
//                                             // ),
//                                             const SizedBox(height: 24),
//                                             if (_mlPredictionResult !=
//                                                 null) ...[
//                                               SizedBox(
//                                                 width: fullWidth,
//                                                 child: PredictionMetricCard(
//                                                   title: 'Prediksi',
//                                                   icon:
//                                                       Icons.insights_rounded,
//                                                   iconColor:
//                                                       const Color(0xFFE13D5A),
//                                                   description:
//                                                       'Dihasilkan pada: ${_getGeneratedDateStr()}',
//                                                   score: _getProbability(),
//                                                 ),
//                                               ),
//                                               const SizedBox(height: 24),
//                                             ],
//                                             _buildRekomendasiSection(
//                                                 _mlRecommendation),
//                                           ],
//                                         )
//                                       : _missingFields.isNotEmpty
//                                           ? _buildNotReadySection(fullWidth)
//                                           : Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 const SizedBox(height: 24),
//                                                 Center(
//                                                   child: ElevatedButton.icon(
//                                                     style: ElevatedButton
//                                                         .styleFrom(
//                                                       backgroundColor:
//                                                           const Color(
//                                                               0xFFE13D5A),
//                                                       foregroundColor:
//                                                           Colors.white,
//                                                       padding:
//                                                           const EdgeInsets
//                                                               .symmetric(
//                                                         horizontal: 24,
//                                                         vertical: 16,
//                                                       ),
//                                                       shape:
//                                                           RoundedRectangleBorder(
//                                                         borderRadius:
//                                                             BorderRadius
//                                                                 .circular(16),
//                                                       ),
//                                                     ),
//                                                     onPressed:
//                                                         _checkMlReadinessAndPredict,
//                                                     icon: const Icon(
//                                                         Icons.analytics),
//                                                     label: const Text(
//                                                       'Cek Prediksi ML Hari Ini',
//                                                       style: TextStyle(
//                                                         fontSize: 16,
//                                                         fontWeight:
//                                                             FontWeight.bold,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 SizedBox(height: 16),
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   child: FilledButton.icon(
//                                                     onPressed: () => context.push(
//                                                         '/home/patient-dashboard/ml-assessment'),
//                                                     style: FilledButton
//                                                         .styleFrom(
//                                                       backgroundColor:
//                                                           const Color(
//                                                               0xFFE64060),
//                                                       foregroundColor:
//                                                           Colors.white,
//                                                       padding:
//                                                           const EdgeInsets
//                                                               .symmetric(
//                                                               vertical: 14),
//                                                       shape:
//                                                           RoundedRectangleBorder(
//                                                         borderRadius:
//                                                             BorderRadius
//                                                                 .circular(14),
//                                                       ),
//                                                     ),
//                                                     icon: const Icon(
//                                                         Icons
//                                                             .assignment_turned_in_rounded,
//                                                         size: 18),
//                                                     label: const Text(
//                                                       'Isi Form Asesmen',
//                                                       style: TextStyle(
//                                                           fontSize: 15,
//                                                           fontWeight:
//                                                               FontWeight
//                                                                   .w700),
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                         ),
// }

//   Widget _buildRekomendasiSection(MlRecommendationResponse? mlRec) {
//     final lifestyle =
//         mlRec?.data?.upstream?.body?.recommendationResult.lifestyle ?? [];

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(color: const Color(0xFFF1F5F9)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFFF0F2),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(Icons.recommend, color: Color(0xFFE13D5A)),
//               ),
//               const SizedBox(width: 16),
//               const Text(
//                 'Rekomendasi',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1A202C),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           if (lifestyle.isEmpty)
//             const Text(
//               'Tidak ada rekomendasi spesifik saat ini.',
//               style: TextStyle(color: Color(0xFF4A5568)),
//             ),
//           ...lifestyle.map((item) {
//             final title =
//                 item.comparison.isNotEmpty ? item.comparison : item.description;
//             // final rec = item.recommendedValueInterval;
//             final changeStatus = item.changeStatus;

//             if (changeStatus == 'False') {
//               return const SizedBox.shrink();
//             }

//             return Padding(
//               padding: const EdgeInsets.only(bottom: 16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Padding(
//                         padding: EdgeInsets.only(top: 4, right: 8),
//                         child: Icon(Icons.check_circle,
//                             size: 16, color: Colors.green),
//                       ),
//                       Expanded(
//                         child: Text(
//                           title,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF1A202C),
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   // if (rec.isNotEmpty) ...[
//                   //   const SizedBox(height: 6),
//                   //   Padding(
//                   //     padding: const EdgeInsets.only(left: 24.0),
//                   //     child: Text(
//                   //       rec,
//                   //       style: const TextStyle(
//                   //         color: Color(0xFF4A5568),
//                   //         height: 1.5,
//                   //       ),
//                   //     ),
//                   //   ),
//                   // ],
//                 ],
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }
// }
