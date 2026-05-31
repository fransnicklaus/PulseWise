import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';
import 'package:pulsewise/features/admin/presentation/providers/admin_providers.dart';
import 'package:pulsewise/features/admin/presentation/widgets/admin_widgets.dart';

class AdminUserDetailPage extends ConsumerWidget {
  const AdminUserDetailPage({
    super.key,
    required this.userId,
  });

  final String userId;

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(adminUserDetailProvider(userId).notifier).fetchInitial();
  }

  bool _isNetworkError(Object error) {
    return isNetworkRequestError(error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(adminUserDetailProvider(userId));
    final user = detailState.user;
    final errorCause = detailState.errorCause;
    final shouldShowInitialLoading =
        !detailState.hasUser &&
        detailState.error == null &&
        errorCause == null;
    final hasInitialNetworkFailure =
        errorCause != null &&
        _isNetworkError(errorCause) &&
        !detailState.hasUser;
    final hasInitialNonNetworkFailure =
        errorCause != null &&
        !_isNetworkError(errorCause) &&
        !detailState.hasUser;

    return Scaffold(
      backgroundColor: AdminPalette.background,
      appBar: CustomAppBar(
        title: 'Detail Pengguna',
        subtitle: 'Lihat metadata akun secara lengkap',
        onBackPressed: () => context.pop(),
      ),
      body: RefreshIndicator(
        color: AdminPalette.accent,
        backgroundColor: Colors.white,
        onRefresh: () => _refresh(ref),
        child: shouldShowInitialLoading || (detailState.isLoading && !detailState.hasUser)
            ? const _AdminDetailLoadingView()
            : hasInitialNetworkFailure
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.68,
                        child: NoConnectionState.page(
                          title: 'Detail pengguna belum bisa dimuat',
                          message:
                              'Kami belum bisa mengambil detail pengguna karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                          onRetry: () => ref
                              .read(adminUserDetailProvider(userId).notifier)
                              .fetchInitial(),
                        ),
                      ),
                    ],
                  )
                : hasInitialNonNetworkFailure
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                        children: [
                          AdminMessageCard(
                            icon: Icons.person_search_outlined,
                            title: 'Detail pengguna belum tersedia',
                            description:
                                detailState.error ?? 'Terjadi kesalahan.',
                            actionLabel: 'Muat Ulang',
                            onActionTap: () => ref
                                .read(adminUserDetailProvider(userId).notifier)
                                .fetchInitial(),
                          ),
                        ],
                      )
                    : user == null
                        ? const _AdminDetailLoadingView()
                    : _AdminUserDetailContent(
                        user: user,
                        isRefreshing: detailState.isRefreshing,
                        hasRefreshNetworkFailure:
                            errorCause != null &&
                            _isNetworkError(errorCause) &&
                            detailState.hasUser,
                        onRetryRefresh: () => ref
                            .read(adminUserDetailProvider(userId).notifier)
                            .fetchInitial(),
                      ),
      ),
    );
  }
}

class _AdminUserDetailContent extends ConsumerWidget {
  const _AdminUserDetailContent({
    required this.user,
    required this.isRefreshing,
    required this.hasRefreshNetworkFailure,
    required this.onRetryRefresh,
  });

  final AdminUserDetail user;
  final bool isRefreshing;
  final bool hasRefreshNetworkFailure;
  final VoidCallback onRetryRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorProfile = user.doctorProfile;
    final canOpenDoctorDetail =
        doctorProfile != null && doctorProfile.doctorId.trim().isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        if (isRefreshing) ...[
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(999)),
            child: LinearProgressIndicator(
              minHeight: 4,
              color: AdminPalette.accent,
              backgroundColor: Color(0x1F0F766E),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (hasRefreshNetworkFailure) ...[
          NoConnectionState.compact(
            title: 'Detail pengguna gagal diperbarui',
            message:
                'Kami belum bisa memuat data terbaru karena koneksi internet tidak tersedia atau sedang tidak stabil.',
            onRetry: onRetryRefresh,
          ),
          const SizedBox(height: 12),
        ],
        _AdminUserHeroCard(user: user),
        const SizedBox(height: 16),
        AdminSectionCard(
          title: 'Informasi Akun',
          subtitle: 'Data dasar akun yang dipakai admin untuk identifikasi.',
          children: [
            AdminInfoRow(
              label: 'User ID',
              value: adminValueOrDash(user.userId),
            ),
            AdminInfoRow(
              label: 'Username',
              value: adminValueOrDash(user.username),
            ),
            AdminInfoRow(
              label: 'Email',
              value: adminValueOrDash(user.email),
            ),
            AdminInfoRow(
              label: 'Role utama',
              value: adminRoleLabel(user.role),
            ),
            AdminInfoRow(
              label: 'Semua role',
              value: user.roles.isEmpty
                  ? '-'
                  : user.roles.map(adminRoleLabel).join(', '),
            ),
            AdminInfoRow(
              label: 'Status akun',
              value: adminStatusStyle(user.accountStatus).label,
            ),
            AdminInfoRow(
              label: 'Akun aktif',
              value: adminBoolLabel(user.isActive),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdminSectionCard(
          title: 'Timeline Akun',
          subtitle: 'Membantu memeriksa progres verifikasi dan perubahan akun.',
          children: [
            AdminInfoRow(
              label: 'Email diverifikasi pada',
              value: formatAdminDateTime(user.emailVerifiedAt),
            ),
            AdminInfoRow(
              label: 'Akun dibuat pada',
              value: formatAdminDateTime(user.createdAt),
            ),
            AdminInfoRow(
              label: 'Terakhir diperbarui',
              value: formatAdminDateTime(user.updatedAt),
            ),
          ],
        ),
        if (!user.isDoctorUser) ...[
          const SizedBox(height: 16),
          _AdminUserActionSection(user: user),
        ],
        if (user.isDoctorUser) ...[
          const SizedBox(height: 16),
          AdminCalloutCard(
            icon: Icons.rule_folder_outlined,
            title: 'Akun dokter dikelola lewat review dokter',
            description:
                'Perubahan status untuk akun dokter tidak dilakukan dari detail pengguna. Gunakan detail review dokter agar alur verifikasi tetap konsisten.',
            actionLabel:
                canOpenDoctorDetail ? 'Buka Detail Review Dokter' : null,
            onActionTap: canOpenDoctorDetail
                ? () => context.push(
                      '/admin/home/doctors/${doctorProfile.doctorId}',
                    )
                : null,
          ),
        ],
        if (doctorProfile != null) ...[
          const SizedBox(height: 16),
          AdminSectionCard(
            title: 'Profil Dokter',
            subtitle:
                'Ringkasan profil dokter yang ikut terbawa di detail pengguna.',
            children: [
              AdminInfoRow(
                label: 'Doctor ID',
                value: adminValueOrDash(doctorProfile.doctorId),
              ),
              AdminInfoRow(
                label: 'Spesialisasi',
                value: adminValueOrDash(doctorProfile.specialization),
              ),
              AdminInfoRow(
                label: 'Nomor izin',
                value: adminValueOrDash(doctorProfile.licenseNo),
              ),
              AdminInfoRow(
                label: 'Rumah sakit',
                value: adminValueOrDash(doctorProfile.hospitalName),
              ),
              AdminInfoRow(
                label: 'Status verifikasi',
                value: adminVerificationLabel(doctorProfile.isVerified),
              ),
              AdminInfoRow(
                label: 'Profil dibuat pada',
                value: formatAdminDateTime(doctorProfile.createdAt),
              ),
              AdminInfoRow(
                label: 'Diverifikasi pada',
                value: formatAdminDateTime(doctorProfile.verifiedAt),
              ),
              AdminInfoRow(
                label: 'Diverifikasi oleh',
                value: adminValueOrDash(doctorProfile.verifiedBy),
              ),
              AdminInfoRow(
                label: 'Catatan verifikasi',
                value: adminValueOrDash(doctorProfile.verificationNote),
              ),
              AdminInfoRow(
                label: 'Alasan penolakan',
                value: adminValueOrDash(doctorProfile.rejectionReason),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AdminUserActionSection extends ConsumerWidget {
  const _AdminUserActionSection({
    required this.user,
  });

  final AdminUserDetail user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(adminUserStatusActionProvider);
    final shouldActivate = user.accountStatus != AdminAccountStatuses.active;

    return AdminSectionCard(
      title: 'Aksi Akun',
      subtitle:
          'Gunakan endpoint status pengguna umum hanya untuk akun non-dokter.',
      children: [
        Text(
          shouldActivate
              ? 'Akun ini bisa diaktifkan kembali dengan status `active`.'
              : 'Akun ini sedang aktif dan bisa ditangguhkan sementara dengan status `suspended`.',
          style: const TextStyle(
            color: AdminPalette.subtext,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        AdminActionButton(
          label: shouldActivate ? 'Aktifkan Akun' : 'Tangguhkan Akun',
          icon: shouldActivate
              ? Icons.check_circle_outline_rounded
              : Icons.pause_circle_outline_rounded,
          isPrimary: shouldActivate,
          backgroundColor: shouldActivate ? const Color(0xFF15803D) : null,
          foregroundColor:
              shouldActivate ? Colors.white : const Color(0xFFB91C1C),
          borderColor: shouldActivate
              ? const Color(0xFF15803D)
              : const Color(0xFFFCA5A5),
          isLoading: actionState.isLoading,
          onPressed: () => _confirmUserStatusChange(
            context: context,
            ref: ref,
            user: user,
            nextStatus: shouldActivate
                ? AdminAccountStatuses.active
                : AdminAccountStatuses.suspended,
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmUserStatusChange({
  required BuildContext context,
  required WidgetRef ref,
  required AdminUserDetail user,
  required String nextStatus,
}) async {
  final isActivation = nextStatus == AdminAccountStatuses.active;
  final confirmed = await _showAdminConfirmationSheet(
    context: context,
    title: isActivation ? 'Aktifkan akun ini?' : 'Tangguhkan akun ini?',
    description: isActivation
        ? 'Akun ${user.fullName} akan diubah menjadi aktif kembali.'
        : 'Akun ${user.fullName} akan ditangguhkan sementara sampai admin mengaktifkannya lagi.',
    confirmLabel: isActivation ? 'Ya, Aktifkan' : 'Ya, Tangguhkan',
    confirmColor:
        isActivation ? const Color(0xFF15803D) : const Color(0xFFE11D48),
  );

  if (confirmed != true) return;
  if (!context.mounted) return;

  final result = await ref
      .read(adminUserStatusActionProvider.notifier)
      .updateStatus(user.userId, nextStatus);

  if (!context.mounted) return;
  if (result != null) {
    AppToast.success(
      context,
      result.message.isEmpty
          ? 'Status pengguna berhasil diperbarui'
          : result.message,
    );
    return;
  }

  final error = ref.read(adminUserStatusActionProvider).error ??
      'Status pengguna gagal diperbarui';
  AppToast.error(context, error);
}

Future<bool?> _showAdminConfirmationSheet({
  required BuildContext context,
  required String title,
  required String description,
  required String confirmLabel,
  required Color confirmColor,
}) {
  return showModalBottomSheet<bool>(
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
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
      );
    },
  );
}

class _AdminUserHeroCard extends StatelessWidget {
  const _AdminUserHeroCard({
    required this.user,
  });

  final AdminUserDetail user;

  @override
  Widget build(BuildContext context) {
    final hasUsername = user.username.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminPalette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AdminPalette.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminAvatar(
                name: user.fullName,
                photoUrl: user.avatarPhoto,
                size: 76,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: AdminPalette.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: AdminPalette.subtext,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    if (hasUsername) ...[
                      const SizedBox(height: 6),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in user.roles) AdminRoleChip(role: role),
              AdminStatusChip(status: user.accountStatus),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'User ID: ${adminValueOrDash(user.userId)}',
            style: const TextStyle(
              color: AdminPalette.subtext,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDetailLoadingView extends StatelessWidget {
  const _AdminDetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            height: index == 0 ? 220 : 190,
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
