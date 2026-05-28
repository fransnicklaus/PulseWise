import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';
import 'package:pulsewise/features/admin/presentation/providers/admin_providers.dart';
import 'package:pulsewise/features/admin/presentation/widgets/admin_widgets.dart';

class AdminOverviewPage extends ConsumerWidget {
  const AdminOverviewPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.refresh(adminOverviewProvider.future),
      ref.refresh(adminPendingDoctorsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(adminOverviewProvider);
    final pendingDoctorsAsync = ref.watch(adminPendingDoctorsProvider);

    return Scaffold(
      backgroundColor: AdminPalette.background,
      appBar: const CustomAppBar(
        title: 'Panel Admin',
        subtitle: 'Pantau pengguna dan review dokter',
        showBackButton: false,
      ),
      body: RefreshIndicator(
        color: AdminPalette.accent,
        backgroundColor: Colors.white,
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            const Text(
              'Ringkasan Hari Ini',
              style: TextStyle(
                color: AdminPalette.text,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan halaman ini untuk membuka daftar pengguna, memeriksa dokter yang menunggu review, dan melihat status platform secara cepat.',
              style: TextStyle(
                color: AdminPalette.subtext,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 18),
            overviewAsync.when(
              data: (overview) => _OverviewStatsSection(overview: overview),
              loading: () => const _OverviewLoadingSection(),
              error: (error, _) => AdminMessageCard(
                icon: Icons.monitor_heart_outlined,
                title: 'Ringkasan admin belum tersedia',
                description: error.toString().replaceFirst('Exception: ', ''),
                actionLabel: 'Muat Ulang',
                onActionTap: () => ref.invalidate(adminOverviewProvider),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Akses Cepat',
              style: TextStyle(
                color: AdminPalette.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            AdminShortcutCard(
              title: 'Kelola Pengguna',
              description:
                  'Cari pengguna, filter per role/status, dan lihat data akun secara read-only.',
              icon: Icons.people_alt_outlined,
              onTap: () => context.push('/admin/home/users'),
            ),
            const SizedBox(height: 12),
            AdminShortcutCard(
              title: 'Review Dokter',
              description:
                  'Buka daftar dokter untuk melihat akun yang menunggu verifikasi admin.',
              icon: Icons.medical_services_outlined,
              onTap: () => context.push('/admin/home/doctors'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Dokter Menunggu Review',
                    style: TextStyle(
                      color: AdminPalette.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/admin/home/doctors'),
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            pendingDoctorsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const AdminMessageCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Tidak ada dokter yang menunggu review',
                    description:
                        'Semua akun dokter yang masuk ke antrian admin sudah tertangani.',
                  );
                }

                final previewItems = items.take(3).toList();
                return Column(
                  children: [
                    for (final item in previewItems) ...[
                      _PendingDoctorPreviewCard(item: item),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
              loading: () => const _PendingDoctorsLoadingSection(),
              error: (error, _) => AdminMessageCard(
                icon: Icons.person_search_outlined,
                title: 'Preview dokter belum tersedia',
                description: error.toString().replaceFirst('Exception: ', ''),
                actionLabel: 'Muat Ulang',
                onActionTap: () => ref.invalidate(adminPendingDoctorsProvider),
              ),
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
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
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
      ],
    );
  }
}

class _OverviewLoadingSection extends StatelessWidget {
  const _OverviewLoadingSection();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: List.generate(
        6,
        (index) => Container(
          width: 160,
          height: 152,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AdminPalette.border),
          ),
        ),
      ),
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
      onTap: () => context.push('/admin/home/doctors'),
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
