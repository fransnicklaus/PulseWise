import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_dashboard_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_patients_provider.dart';
import 'package:pulsewise/features/home_dashboard/data/models/dashboard_overview_models.dart';

class DoctorHomeTab extends StatelessWidget {
  const DoctorHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DoctorPlaceholderTab(
      title: 'Beranda Dokter',
      subtitle:
          'Ringkasan cepat pasien, aktivitas pairing, dan insight dokter akan muncul di sini.',
      icon: Icons.medical_services_rounded,
      accent: Color(0xFF0F766E),
      cardTitle: 'Home',
      bullets: [
        'Statistik pairing dokter dan pasien.',
        'Ringkasan aktivitas pasien terbaru.',
        'Shortcut ke daftar pasien dan monitoring harian.',
      ],
    );
  }
}

class DoctorPatientsTab extends ConsumerStatefulWidget {
  const DoctorPatientsTab({super.key});

  @override
  ConsumerState<DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends ConsumerState<DoctorPatientsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(doctorPatientsNotifierProvider.notifier).loadPatients();
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
      ref.read(doctorPatientsNotifierProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doctorPatientsNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: _buildHeader(state.totalItems),
            ),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFE64060),
                backgroundColor: Colors.white,
                onRefresh: () => ref
                    .read(doctorPatientsNotifierProvider.notifier)
                    .refreshPatients(),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    if (state.isLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      )
                    else if (state.error != null && state.items.isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        sliver: SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: _PatientsInlineState(
                              icon: Icons.error_outline_rounded,
                              iconColor: const Color(0xFFEF4444),
                              title: 'Gagal memuat daftar pasien',
                              description: state.error!,
                              actionLabel: 'Coba Lagi',
                              onActionTap: () => ref
                                  .read(doctorPatientsNotifierProvider.notifier)
                                  .loadPatients(),
                            ),
                          ),
                        ),
                      )
                    else if (state.items.isEmpty)
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                        sliver: SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: _PatientsInlineState(
                              icon: Icons.group_off_rounded,
                              iconColor: Color(0xFF94A3B8),
                              title: 'Belum ada pasien',
                              description:
                                  'Pasien yang sudah terhubung ke dashboard dokter akan muncul di sini.',
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == state.items.length) {
                                if (state.isLoadingMore) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.only(top: 12, bottom: 24),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox(height: 24);
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _DoctorPatientListCard(
                                  item: state.items[index],
                                ),
                              );
                            },
                            childCount: state.items.length +
                                (state.isLoadingMore ? 1 : 0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int totalItems) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Pasien',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        // const SizedBox(height: 8),
        // Text(
        //   totalItems > 0
        //       ? '$totalItems pasien terhubung. Pilih salah satu untuk membuka dashboard dokter.'
        //       : 'Pilih pasien yang sudah terhubung untuk membuka dashboard dokter.',
        //   style: const TextStyle(
        //     color: Color(0xFF64748B),
        //     fontSize: 15,
        //     fontWeight: FontWeight.w600,
        //     height: 1.5,
        //   ),
        // ),
      ],
    );
  }
}

class DoctorDiaryTab extends StatelessWidget {
  const DoctorDiaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DoctorPlaceholderTab(
      title: 'Diari Pasien',
      subtitle:
          'Tab ini akan menjadi tempat dokter membaca diary pasien yang sudah terhubung.',
      icon: Icons.menu_book_rounded,
      accent: Color(0xFF7C3AED),
      cardTitle: 'Monitoring Diari',
      bullets: [
        'Lihat konsumsi, aktivitas, tidur, dan gejala pasien.',
        'Filter berdasarkan pasien atau tanggal.',
        'Buka detail harian untuk evaluasi dokter.',
      ],
    );
  }
}

class _DoctorPatientListCard extends StatelessWidget {
  const _DoctorPatientListCard({required this.item});

  final DoctorDashboardPatientListItem item;

  @override
  Widget build(BuildContext context) {
    final patient = item.patient;
    final properGender = _genderLabel(patient.sex);
    final name =
        patient.fullName.isEmpty ? 'Pasien Tanpa Nama' : patient.fullName;
    final ageLabel =
        patient.age == null ? 'Usia tidak diketahui' : '${patient.age} Tahun';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/doctor/home/patients/${patient.patientId}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCE3EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Color.fromRGBO(15, 23, 42, 1),
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$properGender, $ageLabel',
                        style: const TextStyle(
                          color: Color(0xFF7C4A36),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F1F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFE64060),
                    size: 24,
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 18),
            // const Center(
            //   child: Text(
            //     'LIHAT DETAIL LENGKAP',
            //     style: TextStyle(
            //       color: Color(0xFFC21D4A),
            //       fontSize: 14,
            //       fontWeight: FontWeight.w800,
            //       letterSpacing: 0.2,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class _PatientsInlineState extends StatelessWidget {
  const _PatientsInlineState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: iconColor),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onActionTap != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onActionTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DoctorPlaceholderTab extends StatelessWidget {
  const _DoctorPlaceholderTab({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.cardTitle,
    required this.bullets,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String cardTitle;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      Color.lerp(accent, Colors.white, 0.22) ?? accent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x110F172A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardTitle,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...bullets.map(
                      (text) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _genderLabel(String? text) {
  final value = text?.trim();
  if (value == null || value.isEmpty) return '-';
  if (value.toLowerCase() == 'male') return 'Pria';
  if (value.toLowerCase() == 'female') return 'Wanita';
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

extension on DashboardPatient {
  String get fullName => '$firstName $lastName'.trim();
}
