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

class AdminDoctorDetailPage extends ConsumerWidget {
  const AdminDoctorDetailPage({
    super.key,
    required this.doctorId,
  });

  final String doctorId;

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(adminDoctorDetailProvider(doctorId).notifier).fetchInitial();
  }

  bool _isNetworkError(Object error) {
    return isNetworkRequestError(error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(adminDoctorDetailProvider(doctorId));
    final doctor = detailState.doctor;
    final errorCause = detailState.errorCause;
    final shouldShowInitialLoading =
        !detailState.hasDoctor &&
        detailState.error == null &&
        errorCause == null;
    final hasInitialNetworkFailure =
        errorCause != null &&
        _isNetworkError(errorCause) &&
        !detailState.hasDoctor;
    final hasInitialNonNetworkFailure =
        errorCause != null &&
        !_isNetworkError(errorCause) &&
        !detailState.hasDoctor;

    return Scaffold(
      backgroundColor: AdminPalette.background,
      appBar: CustomAppBar(
        title: 'Detail Dokter',
        subtitle: 'Review akun dokter secara lengkap',
        onBackPressed: () => context.pop(),
      ),
      body: RefreshIndicator(
        color: AdminPalette.accent,
        backgroundColor: Colors.white,
        onRefresh: () => _refresh(ref),
        child: shouldShowInitialLoading || (detailState.isLoading && !detailState.hasDoctor)
            ? const _AdminDoctorDetailLoadingView()
            : hasInitialNetworkFailure
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.68,
                        child: NoConnectionState.page(
                          title: 'Detail dokter belum bisa dimuat',
                          message:
                              'Kami belum bisa mengambil detail dokter karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                          onRetry: () => ref
                              .read(adminDoctorDetailProvider(doctorId).notifier)
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
                            icon: Icons.local_hospital_outlined,
                            title: 'Detail dokter belum tersedia',
                            description:
                                detailState.error ?? 'Terjadi kesalahan.',
                            actionLabel: 'Muat Ulang',
                            onActionTap: () => ref
                                .read(adminDoctorDetailProvider(doctorId).notifier)
                                .fetchInitial(),
                          ),
                        ],
                      )
                    : doctor == null
                        ? const _AdminDoctorDetailLoadingView()
                        : _AdminDoctorDetailContent(
                            doctor: doctor,
                            isRefreshing: detailState.isRefreshing,
                            hasRefreshNetworkFailure:
                                errorCause != null &&
                                _isNetworkError(errorCause) &&
                                detailState.hasDoctor,
                            onRetryRefresh: () => ref
                                .read(adminDoctorDetailProvider(doctorId).notifier)
                                .fetchInitial(),
                          ),
      ),
    );
  }
}

class _AdminDoctorDetailContent extends ConsumerWidget {
  const _AdminDoctorDetailContent({
    required this.doctor,
    required this.isRefreshing,
    required this.hasRefreshNetworkFailure,
    required this.onRetryRefresh,
  });

  final AdminDoctorDetail doctor;
  final bool isRefreshing;
  final bool hasRefreshNetworkFailure;
  final VoidCallback onRetryRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = doctor.doctorProfile;

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
            title: 'Detail dokter gagal diperbarui',
            message:
                'Kami belum bisa memuat data dokter terbaru karena koneksi internet tidak tersedia atau sedang tidak stabil.',
            onRetry: onRetryRefresh,
          ),
          const SizedBox(height: 12),
        ],
        _AdminDoctorHeroCard(doctor: doctor),
        const SizedBox(height: 16),
        _AdminDoctorActionSection(doctor: doctor),
        const SizedBox(height: 16),
        AdminSectionCard(
          title: 'Status Review',
          subtitle: 'Ringkasan status akun dokter saat ini.',
          children: [
            AdminInfoRow(
              label: 'Status akun',
              value: adminStatusStyle(doctor.accountStatus).label,
            ),
            AdminInfoRow(
              label: 'Status verifikasi',
              value: adminVerificationLabel(profile.isVerified),
            ),
            AdminInfoRow(
              label: 'Diverifikasi pada',
              value: formatAdminDateTime(profile.verifiedAt),
            ),
            AdminInfoRow(
              label: 'Diverifikasi oleh',
              value: adminValueOrDash(profile.verifiedBy),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdminSectionCard(
          title: 'Informasi Praktik',
          subtitle: 'Data profesi dan dokumen inti milik dokter.',
          children: [
            AdminInfoRow(
              label: 'Doctor ID',
              value: adminValueOrDash(profile.doctorId),
            ),
            AdminInfoRow(
              label: 'Spesialisasi',
              value: adminValueOrDash(profile.specialization),
            ),
            AdminInfoRow(
              label: 'Nomor izin',
              value: adminValueOrDash(profile.licenseNo),
            ),
            AdminInfoRow(
              label: 'Rumah sakit',
              value: adminValueOrDash(profile.hospitalName),
            ),
            AdminInfoRow(
              label: 'Profil dokter dibuat pada',
              value: formatAdminDateTime(profile.createdAt),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdminSectionCard(
          title: 'Informasi Akun',
          subtitle: 'Metadata akun user yang terkait dengan profil dokter ini.',
          children: [
            AdminInfoRow(
              label: 'User ID',
              value: adminValueOrDash(doctor.userId),
            ),
            AdminInfoRow(
              label: 'Username',
              value: adminValueOrDash(doctor.username),
            ),
            AdminInfoRow(
              label: 'Email',
              value: adminValueOrDash(doctor.email),
            ),
            AdminInfoRow(
              label: 'Semua role',
              value: doctor.roles.isEmpty
                  ? '-'
                  : doctor.roles.map(adminRoleLabel).join(', '),
            ),
            AdminInfoRow(
              label: 'Email diverifikasi pada',
              value: formatAdminDateTime(doctor.emailVerifiedAt),
            ),
            AdminInfoRow(
              label: 'Akun dibuat pada',
              value: formatAdminDateTime(doctor.createdAt),
            ),
            AdminInfoRow(
              label: 'Terakhir diperbarui',
              value: formatAdminDateTime(doctor.updatedAt),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdminSectionCard(
          title: 'Catatan Admin',
          subtitle: 'Menampilkan keputusan review terakhir yang tersimpan.',
          children: [
            AdminInfoRow(
              label: 'Catatan verifikasi',
              value: adminValueOrDash(profile.verificationNote),
            ),
            AdminInfoRow(
              label: 'Alasan penolakan',
              value: adminValueOrDash(profile.rejectionReason),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminDoctorActionSection extends ConsumerWidget {
  const _AdminDoctorActionSection({
    required this.doctor,
  });

  final AdminDoctorDetail doctor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(adminDoctorReviewActionProvider);

    switch (doctor.accountStatus) {
      case AdminAccountStatuses.pendingAdminVerification:
        return AdminSectionCard(
          title: 'Aksi Review',
          subtitle:
              'Akun dokter ini sedang menunggu verifikasi admin. Pilih approve atau reject dengan catatan yang sesuai.',
          children: [
            AdminActionButton(
              label: 'Setujui Dokter',
              icon: Icons.verified_rounded,
              isPrimary: true,
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              isLoading: actionState.isLoading,
              onPressed: () => _promptAndApproveDoctor(
                context: context,
                ref: ref,
                doctor: doctor,
              ),
            ),
            const SizedBox(height: 12),
            AdminActionButton(
              label: 'Tolak Dokter',
              icon: Icons.cancel_outlined,
              foregroundColor: const Color(0xFFB91C1C),
              borderColor: const Color(0xFFFCA5A5),
              isLoading: actionState.isLoading,
              onPressed: () => _promptAndRejectDoctor(
                context: context,
                ref: ref,
                doctor: doctor,
              ),
            ),
          ],
        );
      case AdminAccountStatuses.active:
        return AdminSectionCard(
          title: 'Aksi Review',
          subtitle:
              'Dokter ini sudah aktif. Anda bisa menangguhkan akun bila perlu untuk review lanjutan.',
          children: [
            AdminActionButton(
              label: 'Tangguhkan Dokter',
              icon: Icons.pause_circle_outline_rounded,
              foregroundColor: const Color(0xFFB45309),
              borderColor: const Color(0xFFFCD34D),
              isLoading: actionState.isLoading,
              onPressed: () => _promptAndSuspendDoctor(
                context: context,
                ref: ref,
                doctor: doctor,
              ),
            ),
          ],
        );
      case AdminAccountStatuses.rejected:
      case AdminAccountStatuses.suspended:
        return AdminSectionCard(
          title: 'Aksi Review',
          subtitle:
              'Dokter ini bisa diaktifkan kembali. Backend akan menentukan apakah hasilnya kembali ke `active` atau `pending_admin_verification` sesuai status verifikasi.',
          children: [
            AdminActionButton(
              label: 'Aktifkan Kembali Dokter',
              icon: Icons.refresh_rounded,
              isPrimary: true,
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              isLoading: actionState.isLoading,
              onPressed: () => _confirmReactivateDoctor(
                context: context,
                ref: ref,
                doctor: doctor,
              ),
            ),
          ],
        );
      default:
        return const AdminCalloutCard(
          icon: Icons.info_outline_rounded,
          title: 'Belum ada aksi untuk status ini',
          description:
              'Status dokter saat ini belum memiliki tombol tindakan khusus di panel admin.',
          foregroundColor: Color(0xFF1D4ED8),
          backgroundColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFBFDBFE),
        );
    }
  }
}

Future<void> _promptAndApproveDoctor({
  required BuildContext context,
  required WidgetRef ref,
  required AdminDoctorDetail doctor,
}) async {
  final note = await _showAdminTextPromptSheet(
    context: context,
    title: 'Setujui dokter ini?',
    description:
        'Masukkan catatan verifikasi untuk menyetujui akun ${doctor.fullName}.',
    fieldLabel: 'Catatan verifikasi',
    confirmLabel: 'Setujui Dokter',
    confirmColor: const Color(0xFF15803D),
  );

  if (note == null || !context.mounted) return;
  final result = await ref
      .read(adminDoctorReviewActionProvider.notifier)
      .approveDoctor(doctor.doctorId, note);

  if (!context.mounted) return;
  if (result != null) {
    AppToast.success(
      context,
      result.message.isEmpty ? 'Dokter berhasil disetujui' : result.message,
    );
    return;
  }

  final error = ref.read(adminDoctorReviewActionProvider).error ??
      'Dokter gagal disetujui';
  AppToast.error(context, error);
}

Future<void> _promptAndRejectDoctor({
  required BuildContext context,
  required WidgetRef ref,
  required AdminDoctorDetail doctor,
}) async {
  final reason = await _showAdminTextPromptSheet(
    context: context,
    title: 'Tolak dokter ini?',
    description: 'Masukkan alasan penolakan untuk akun ${doctor.fullName}.',
    fieldLabel: 'Alasan penolakan',
    confirmLabel: 'Tolak Dokter',
    confirmColor: const Color(0xFFB91C1C),
  );

  if (reason == null || !context.mounted) return;
  final result = await ref
      .read(adminDoctorReviewActionProvider.notifier)
      .rejectDoctor(doctor.doctorId, reason);

  if (!context.mounted) return;
  if (result != null) {
    AppToast.success(
      context,
      result.message.isEmpty ? 'Dokter berhasil ditolak' : result.message,
    );
    return;
  }

  final error =
      ref.read(adminDoctorReviewActionProvider).error ?? 'Dokter gagal ditolak';
  AppToast.error(context, error);
}

Future<void> _promptAndSuspendDoctor({
  required BuildContext context,
  required WidgetRef ref,
  required AdminDoctorDetail doctor,
}) async {
  final note = await _showAdminTextPromptSheet(
    context: context,
    title: 'Tangguhkan dokter ini?',
    description:
        'Masukkan catatan review sebelum menangguhkan akun ${doctor.fullName}.',
    fieldLabel: 'Catatan penangguhan',
    confirmLabel: 'Tangguhkan Dokter',
    confirmColor: const Color(0xFFB45309),
  );

  if (note == null || !context.mounted) return;
  final result = await ref
      .read(adminDoctorReviewActionProvider.notifier)
      .suspendDoctor(doctor.doctorId, note);

  if (!context.mounted) return;
  if (result != null) {
    AppToast.success(
      context,
      result.message.isEmpty ? 'Dokter berhasil ditangguhkan' : result.message,
    );
    return;
  }

  final error = ref.read(adminDoctorReviewActionProvider).error ??
      'Dokter gagal ditangguhkan';
  AppToast.error(context, error);
}

Future<void> _confirmReactivateDoctor({
  required BuildContext context,
  required WidgetRef ref,
  required AdminDoctorDetail doctor,
}) async {
  final confirmed = await _showAdminConfirmationSheet(
    context: context,
    title: 'Aktifkan kembali dokter ini?',
    description:
        'Akun ${doctor.fullName} akan diaktifkan kembali. Backend akan menentukan apakah status akhirnya kembali aktif atau kembali ke antrian review admin.',
    confirmLabel: 'Ya, Aktifkan Kembali',
    confirmColor: const Color(0xFF15803D),
  );

  if (confirmed != true || !context.mounted) return;
  final result = await ref
      .read(adminDoctorReviewActionProvider.notifier)
      .reactivateDoctor(doctor.doctorId);

  if (!context.mounted) return;
  if (result != null) {
    AppToast.success(
      context,
      result.message.isEmpty
          ? 'Dokter berhasil diaktifkan kembali'
          : result.message,
    );
    return;
  }

  final error = ref.read(adminDoctorReviewActionProvider).error ??
      'Dokter gagal diaktifkan kembali';
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

Future<String?> _showAdminTextPromptSheet({
  required BuildContext context,
  required String title,
  required String description,
  required String fieldLabel,
  required String confirmLabel,
  required Color confirmColor,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return _AdminTextPromptSheet(
        title: title,
        description: description,
        fieldLabel: fieldLabel,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
      );
    },
  );
}

class _AdminTextPromptSheet extends StatefulWidget {
  const _AdminTextPromptSheet({
    required this.title,
    required this.description,
    required this.fieldLabel,
    required this.confirmLabel,
    required this.confirmColor,
  });

  final String title;
  final String description;
  final String fieldLabel;
  final String confirmLabel;
  final Color confirmColor;

  @override
  State<_AdminTextPromptSheet> createState() => _AdminTextPromptSheetState();
}

class _AdminTextPromptSheetState extends State<_AdminTextPromptSheet> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _errorText = '${widget.fieldLabel} wajib diisi';
      });
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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
              widget.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: widget.fieldLabel,
                errorText: _errorText,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AdminPalette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AdminPalette.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: widget.confirmColor, width: 1.3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.confirmColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  widget.confirmLabel,
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
                onPressed: () => Navigator.of(context).pop(),
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
  }
}

class _AdminDoctorHeroCard extends StatelessWidget {
  const _AdminDoctorHeroCard({
    required this.doctor,
  });

  final AdminDoctorDetail doctor;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      doctor.doctorProfile.specialization,
      doctor.doctorProfile.hospitalName,
      doctor.doctorProfile.licenseNo,
    ].where((part) => (part ?? '').trim().isNotEmpty).cast<String>().toList();

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
                name: doctor.fullName,
                photoUrl: doctor.avatarPhoto,
                size: 76,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.fullName,
                      style: const TextStyle(
                        color: AdminPalette.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctor.email,
                      style: const TextStyle(
                        color: AdminPalette.subtext,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    if (doctor.username.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '@${doctor.username}',
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
          if (subtitleParts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              subtitleParts.join(' | '),
              style: const TextStyle(
                color: AdminPalette.subtext,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in doctor.roles) AdminRoleChip(role: role),
              AdminStatusChip(status: doctor.accountStatus),
              _AdminVerificationChip(
                isVerified: doctor.doctorProfile.isVerified,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Doctor ID: ${adminValueOrDash(doctor.doctorProfile.doctorId)}',
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

class _AdminVerificationChip extends StatelessWidget {
  const _AdminVerificationChip({
    required this.isVerified,
  });

  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED);
    final foregroundColor =
        isVerified ? const Color(0xFF166534) : const Color(0xFFC2410C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        adminVerificationLabel(isVerified),
        style: TextStyle(
          color: foregroundColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdminDoctorDetailLoadingView extends StatelessWidget {
  const _AdminDoctorDetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            height: index == 0 ? 240 : 180,
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
