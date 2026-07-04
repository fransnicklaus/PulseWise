import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/session/account_scoped_state.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';
import 'package:pulsewise/features/admin/presentation/providers/admin_providers.dart';
import 'package:pulsewise/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';

class AdminOverviewPage extends ConsumerWidget {
  const AdminOverviewPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      _refreshProviderSilently(() => ref.refresh(adminOverviewProvider.future)),
      _refreshProviderSilently(
        () => ref.refresh(adminPendingDoctorsProvider.future),
      ),
    ]);
  }

  Future<void> _refreshProviderSilently(
    Future<Object?> Function() refresh,
  ) async {
    try {
      await refresh();
    } catch (_) {
      // Let each section render its own fallback state.
    }
  }

  bool _isNetworkAsyncError<T>(AsyncValue<T> asyncValue) {
    final error = asyncValue.asError?.error;
    return error != null && isNetworkRequestError(error);
  }

  bool _hasInitialNetworkFailure<T>(AsyncValue<T> asyncValue) {
    return _isNetworkAsyncError(asyncValue) && !asyncValue.hasValue;
  }

  bool _hasRefreshNetworkFailure<T>(AsyncValue<T> asyncValue) {
    return _isNetworkAsyncError(asyncValue) && asyncValue.hasValue;
  }

  bool _hasInitialNonNetworkFailure<T>(AsyncValue<T> asyncValue) {
    final error = asyncValue.asError?.error;
    return error != null &&
        !isNetworkRequestError(error) &&
        !asyncValue.hasValue;
  }

  String _errorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _onLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();
    await prepareAppForUnauthenticatedSession(ref);
    if (!context.mounted) return;
    AppToast.success(context, 'Berhasil keluar dari akun admin');
    context.go('/login');
    scheduleAppSessionScopeReset();
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Konfirmasi Keluar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Apakah Anda yakin ingin keluar dari akun admin ini?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE64060),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Ya, Keluar',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldLogout == true) {
      if (!context.mounted) return;
      await _onLogout(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(adminOverviewProvider);
    final pendingDoctorsAsync = ref.watch(adminPendingDoctorsProvider);
    final showOverviewLoadingState = overviewAsync.isLoading;
    final showPendingDoctorsLoadingState = pendingDoctorsAsync.isLoading;
    final showOverviewRefreshNotice = _hasRefreshNetworkFailure(overviewAsync);
    final showPendingDoctorsRefreshNotice =
        _hasRefreshNetworkFailure(pendingDoctorsAsync);

    return AdminShellScaffold(
      title: 'Panel Admin',
      subtitle: 'Pantau pengguna dan review dokter',
      currentSection: AdminShellSection.home,
      onBackPressed: () => context.pop(),
      onHomeTap: () {},
      onUsersTap: () => context.pushReplacement('/admin/home/users'),
      onLogoutTap: () => _confirmLogout(context, ref),
      body: RefreshIndicator(
        color: AdminPalette.accent,
        backgroundColor: Colors.white,
        onRefresh: () => _refresh(ref),
        child: ListView(
          key: const Key('admin_overview_content'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            if (showOverviewLoadingState && overviewAsync.hasValue) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(
                  color: AdminPalette.accent,
                  backgroundColor: Color(0xFFF8FAFC),
                ),
              ),
            ] else if (showOverviewRefreshNotice) ...[
              NoConnectionState.compact(
                title: 'Koneksi terputus',
                message:
                    'Ringkasan admin terakhir tetap ditampilkan. Sambungkan internet lalu coba lagi.',
                onRetry: () => ref.invalidate(adminOverviewProvider),
              ),
              const SizedBox(height: 16),
            ],
            if (overviewAsync.isLoading && !overviewAsync.hasValue)
              const _OverviewLoadingSection()
            else if (_hasInitialNetworkFailure(overviewAsync))
              NoConnectionState.card(
                title: 'Ringkasan admin belum bisa dimuat',
                message:
                    'Kami belum bisa mengambil ringkasan admin karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                onRetry: () => ref.invalidate(adminOverviewProvider),
              )
            else if (_hasInitialNonNetworkFailure(overviewAsync))
              AdminMessageCard(
                icon: Icons.monitor_heart_outlined,
                title: 'Ringkasan admin belum tersedia',
                description: _errorMessage(overviewAsync.asError!.error),
                actionLabel: 'Muat Ulang',
                onActionTap: () => ref.invalidate(adminOverviewProvider),
              )
            else if (overviewAsync.valueOrNull case final overview?)
              _OverviewStatsSection(overview: overview),
            const SizedBox(height: 28),
            const Text(
              'Dokter yang Butuh Review',
              style: TextStyle(
                color: AdminPalette.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Daftar ini menampilkan semua dokter yang masih menunggu verifikasi admin.',
              style: TextStyle(
                color: AdminPalette.subtext,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            if (showPendingDoctorsLoadingState &&
                pendingDoctorsAsync.hasValue) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(
                  color: AdminPalette.accent,
                  backgroundColor: Color(0xFFF8FAFC),
                ),
              ),
            ] else if (showPendingDoctorsRefreshNotice) ...[
              NoConnectionState.compact(
                title: 'Koneksi terputus',
                message:
                    'Daftar dokter terakhir tetap ditampilkan. Sambungkan internet lalu coba lagi.',
                onRetry: () => ref.invalidate(adminPendingDoctorsProvider),
              ),
              const SizedBox(height: 16),
            ],
            if (pendingDoctorsAsync.isLoading && !pendingDoctorsAsync.hasValue)
              const _PendingDoctorsLoadingSection()
            else if (_hasInitialNetworkFailure(pendingDoctorsAsync))
              NoConnectionState.card(
                title: 'Daftar dokter belum bisa dimuat',
                message:
                    'Kami belum bisa mengambil daftar dokter yang butuh review karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                onRetry: () => ref.invalidate(adminPendingDoctorsProvider),
              )
            else if (_hasInitialNonNetworkFailure(pendingDoctorsAsync))
              AdminMessageCard(
                icon: Icons.person_search_outlined,
                title: 'Daftar dokter belum tersedia',
                description: _errorMessage(pendingDoctorsAsync.asError!.error),
                actionLabel: 'Muat Ulang',
                onActionTap: () => ref.invalidate(adminPendingDoctorsProvider),
              )
            else if (pendingDoctorsAsync.valueOrNull case final items?)
              if (items.isEmpty)
                const AdminMessageCard(
                  icon: Icons.verified_user_outlined,
                  title: 'Tidak ada dokter yang menunggu review',
                  description:
                      'Semua akun dokter yang masuk ke antrian admin sudah tertangani.',
                )
              else
                Column(
                  children: [
                    for (final item in items) ...[
                      _PendingDoctorPreviewCard(item: item),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

class _OverviewStatsSection extends StatelessWidget {
  const _OverviewStatsSection({
    required this.overview,
  });

  final AdminOverview overview;

  @override
  Widget build(BuildContext context) {
    const spacing = 10.0;
    final tiles = [
      AdminSummaryTile(
        title: 'Total Pengguna',
        value: overview.totalUsers.toString(),
        icon: Icons.groups_2_outlined,
        iconColor: const Color(0xFF2563EB),
        backgroundColor: const Color(0xFFDBEAFE),
      ),
      AdminSummaryTile(
        title: 'Total Dokter',
        value: overview.totalDoctors.toString(),
        icon: Icons.medical_services_outlined,
        iconColor: const Color(0xFF0F766E),
        backgroundColor: const Color(0xFFCCFBF1),
      ),
      AdminSummaryTile(
        title: 'Total Pasien',
        value: overview.totalPatients.toString(),
        icon: Icons.favorite_border_rounded,
        iconColor: const Color(0xFFE11D48),
        backgroundColor: const Color(0xFFFFE4E6),
      ),
      AdminSummaryTile(
        title: 'Total Admin',
        value: overview.totalAdmins.toString(),
        icon: Icons.admin_panel_settings_outlined,
        iconColor: const Color(0xFF7C3AED),
        backgroundColor: const Color(0xFFEDE9FE),
      ),
      AdminSummaryTile(
        title: 'Dokter Pending',
        value: overview.pendingDoctors.toString(),
        icon: Icons.pending_actions_outlined,
        iconColor: const Color(0xFFD97706),
        backgroundColor: const Color(0xFFFFEDD5),
      ),
      AdminSummaryTile(
        title: 'Pengguna Suspended',
        value: overview.suspendedUsers.toString(),
        icon: Icons.pause_circle_outline_rounded,
        iconColor: const Color(0xFF475569),
        backgroundColor: const Color(0xFFE2E8F0),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = (maxWidth / 150).floor().clamp(1, 4);
        final tileWidth = (maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: tileWidth,
                child: tile,
              ),
          ],
        );
      },
    );
  }
}

class _OverviewLoadingSection extends StatelessWidget {
  const _OverviewLoadingSection();

  @override
  Widget build(BuildContext context) {
    const spacing = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = (maxWidth / 150).floor().clamp(1, 4);
        final tileWidth = (maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(
            6,
            (index) => SizedBox(
              width: tileWidth,
              child: Container(
                height: 152,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AdminPalette.border),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AdminPalette.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PendingDoctorPreviewCard extends StatelessWidget {
  const _PendingDoctorPreviewCard({
    required this.item,
  });

  final AdminDoctorReviewItem item;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      item.doctorProfile.specialization,
      item.doctorProfile.hospitalName,
    ].where((part) => (part ?? '').trim().isNotEmpty).cast<String>().toList();

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push('/admin/home/doctors/${item.doctorId}'),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AdminPalette.surface,
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
                ],
              ),
            ),
            const SizedBox(width: 10),
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

class _PendingDoctorsLoadingSection extends StatelessWidget {
  const _PendingDoctorsLoadingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AdminPalette.border),
            ),
          ),
        ),
      ),
    );
  }
}
