import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
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
    return ref.refresh(adminDoctorDetailProvider(doctorId).future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(adminDoctorDetailProvider(doctorId));

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
        child: detailAsync.when(
          data: (doctor) => _AdminDoctorDetailContent(doctor: doctor),
          loading: () => const _AdminDoctorDetailLoadingView(),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              AdminMessageCard(
                icon: Icons.local_hospital_outlined,
                title: 'Detail dokter belum tersedia',
                description: error.toString().replaceFirst('Exception: ', ''),
                actionLabel: 'Muat Ulang',
                onActionTap: () =>
                    ref.invalidate(adminDoctorDetailProvider(doctorId)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminDoctorDetailContent extends StatelessWidget {
  const _AdminDoctorDetailContent({
    required this.doctor,
  });

  final AdminDoctorDetail doctor;

  @override
  Widget build(BuildContext context) {
    final profile = doctor.doctorProfile;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        _AdminDoctorHeroCard(doctor: doctor),
        const SizedBox(height: 16),
        const AdminCalloutCard(
          icon: Icons.visibility_outlined,
          title: 'Termin ini masih read-only',
          description:
              'Halaman ini baru menampilkan status review dan catatan admin. Tombol approve, reject, suspend, dan reactivate akan ditambahkan di termin berikutnya.',
          foregroundColor: Color(0xFF1D4ED8),
          backgroundColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFBFDBFE),
        ),
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
                label: 'User ID', value: adminValueOrDash(doctor.userId)),
            AdminInfoRow(
              label: 'Username',
              value: adminValueOrDash(doctor.username),
            ),
            AdminInfoRow(label: 'Email', value: adminValueOrDash(doctor.email)),
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
