import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
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
    return ref.refresh(adminUserDetailProvider(userId).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(adminUserDetailProvider(userId));

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
        child: detailAsync.when(
          data: (user) => _AdminUserDetailContent(user: user),
          loading: () => const _AdminDetailLoadingView(),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              AdminMessageCard(
                icon: Icons.person_search_outlined,
                title: 'Detail pengguna belum tersedia',
                description: error.toString().replaceFirst('Exception: ', ''),
                actionLabel: 'Muat Ulang',
                onActionTap: () =>
                    ref.invalidate(adminUserDetailProvider(userId)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminUserDetailContent extends StatelessWidget {
  const _AdminUserDetailContent({
    required this.user,
  });

  final AdminUserDetail user;

  @override
  Widget build(BuildContext context) {
    final doctorProfile = user.doctorProfile;
    final canOpenDoctorDetail =
        doctorProfile != null && doctorProfile.doctorId.trim().isNotEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        _AdminUserHeroCard(user: user),
        const SizedBox(height: 16),
        AdminSectionCard(
          title: 'Informasi Akun',
          subtitle: 'Data dasar akun yang dipakai admin untuk identifikasi.',
          children: [
            AdminInfoRow(
                label: 'User ID', value: adminValueOrDash(user.userId)),
            AdminInfoRow(
              label: 'Username',
              value: adminValueOrDash(user.username),
            ),
            AdminInfoRow(label: 'Email', value: adminValueOrDash(user.email)),
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
        const SizedBox(height: 16),
        const AdminCalloutCard(
          icon: Icons.visibility_outlined,
          title: 'Termin ini masih read-only',
          description:
              'Halaman detail ini baru menampilkan data. Tombol ubah status dan aksi review akan ditambahkan di termin berikutnya.',
          foregroundColor: Color(0xFF1D4ED8),
          backgroundColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFBFDBFE),
        ),
      ],
    );
  }
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
