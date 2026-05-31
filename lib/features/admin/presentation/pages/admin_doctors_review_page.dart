import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';
import 'package:pulsewise/features/admin/presentation/providers/admin_providers.dart';
import 'package:pulsewise/features/admin/presentation/widgets/admin_widgets.dart';

class AdminDoctorsReviewPage extends ConsumerStatefulWidget {
  const AdminDoctorsReviewPage({super.key});

  @override
  ConsumerState<AdminDoctorsReviewPage> createState() =>
      _AdminDoctorsReviewPageState();
}

class _AdminDoctorsReviewPageState
    extends ConsumerState<AdminDoctorsReviewPage> {
  bool _isNetworkError(Object? error) {
    return error != null && isNetworkRequestError(error);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(adminDoctorsReviewNotifierProvider);
      if (state.items.isEmpty && !state.isLoading) {
        ref.read(adminDoctorsReviewNotifierProvider.notifier).loadDoctors();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDoctorsReviewNotifierProvider);
    final showOfflinePage =
        _isNetworkError(state.errorCause) && state.items.isEmpty && !state.isLoading;
    final showOfflineBanner =
        _isNetworkError(state.errorCause) && state.items.isNotEmpty;
    final showInitialNonNetworkError =
        state.error != null &&
        !_isNetworkError(state.errorCause) &&
        state.items.isEmpty &&
        !state.isLoading;

    return Scaffold(
      backgroundColor: AdminPalette.background,
      appBar: CustomAppBar(
        title: 'Review Dokter',
        subtitle: '${state.items.length} akun pada filter aktif',
        onBackPressed: () => context.pop(),
      ),
      body: RefreshIndicator(
        color: AdminPalette.accent,
        backgroundColor: Colors.white,
        onRefresh: () => ref
            .read(adminDoctorsReviewNotifierProvider.notifier)
            .refreshDoctors(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: state.status,
              items: AdminAccountStatuses.doctorReviewOptions
                  .map(
                    (status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        adminStatusStyle(status).label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                ref
                    .read(adminDoctorsReviewNotifierProvider.notifier)
                    .loadDoctors(status: value);
              },
              decoration: InputDecoration(
                labelText: 'Status dokter',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AdminPalette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AdminPalette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      const BorderSide(color: AdminPalette.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (state.isRefreshing) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(
                  color: AdminPalette.accent,
                  backgroundColor: Color(0xFFF8FAFC),
                ),
              ),
            ] else if (showOfflineBanner) ...[
              NoConnectionState.compact(
                title: 'Koneksi terputus',
                message:
                    'Daftar dokter terakhir tetap ditampilkan. Sambungkan internet lalu coba lagi.',
                onRetry: () => ref
                    .read(adminDoctorsReviewNotifierProvider.notifier)
                    .refreshDoctors(),
              ),
              const SizedBox(height: 16),
            ],
            if (state.isLoading && state.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 100),
                child: Center(
                  child: CircularProgressIndicator(color: AdminPalette.accent),
                ),
              )
            else if (showOfflinePage)
              NoConnectionState.card(
                title: 'Daftar dokter belum bisa dimuat',
                message:
                    'Kami belum bisa mengambil daftar dokter karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                onRetry: () => ref
                    .read(adminDoctorsReviewNotifierProvider.notifier)
                    .loadDoctors(status: state.status),
              )
            else if (showInitialNonNetworkError)
              AdminMessageCard(
                icon: Icons.error_outline_rounded,
                title: 'Daftar dokter gagal dimuat',
                description: state.error ?? 'Terjadi kesalahan.',
                actionLabel: 'Coba Lagi',
                onActionTap: () => ref
                    .read(adminDoctorsReviewNotifierProvider.notifier)
                    .loadDoctors(status: state.status),
              )
            else if (state.items.isEmpty)
              const AdminMessageCard(
                icon: Icons.verified_outlined,
                title: 'Tidak ada dokter pada status ini',
                description:
                    'Coba ganti filter untuk melihat akun dokter pada status review yang lain.',
              )
            else
              ...state.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AdminDoctorReviewCard(item: item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdminDoctorReviewCard extends StatelessWidget {
  const _AdminDoctorReviewCard({
    required this.item,
  });

  final AdminDoctorReviewItem item;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      item.doctorProfile.specialization,
      item.doctorProfile.hospitalName,
      item.doctorProfile.licenseNo,
    ].where((part) => (part ?? '').trim().isNotEmpty).cast<String>().toList();

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push('/admin/home/doctors/${item.doctorId}'),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AdminPalette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminAvatar(
              name: item.fullName,
              photoUrl: item.avatarPhoto,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fullName,
                    style: const TextStyle(
                      color: AdminPalette.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.email,
                    style: const TextStyle(
                      color: AdminPalette.subtext,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitleParts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitleParts.join(' | '),
                      style: const TextStyle(
                        color: AdminPalette.subtext,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AdminRoleChip(role: item.role),
                      AdminStatusChip(status: item.accountStatus),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Masuk antrian ${formatAdminDateTime(item.createdAt)}',
                    style: const TextStyle(
                      color: AdminPalette.subtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Terakhir diperbarui ${formatAdminDateTime(item.updatedAt)}',
                    style: const TextStyle(
                      color: AdminPalette.subtext,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
