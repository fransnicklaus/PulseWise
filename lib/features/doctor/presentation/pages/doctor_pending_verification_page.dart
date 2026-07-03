import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/session/account_scoped_state.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_profile_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_profile_provider.dart';

class DoctorPendingVerificationPage extends ConsumerWidget {
  const DoctorPendingVerificationPage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).logout();
    await prepareAppForUnauthenticatedSession(ref);
    if (!context.mounted) return;
    AppToast.success(context, 'Berhasil keluar dari akun dokter');
    context.go('/login');
    scheduleAppSessionScopeReset();
  }

  Future<void> _refreshProfile(WidgetRef ref) async {
    await ref.read(doctorProfileNotifierProvider.notifier).refreshProfile();
  }

  Future<void> _retryProfile(WidgetRef ref) async {
    await ref.read(doctorProfileNotifierProvider.notifier).reloadProfile();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(doctorProfileNotifierProvider);
    final profile = profileState.profile;
    final showOfflineCard = profile == null &&
        profileState.errorCause != null &&
        isNetworkRequestError(profileState.errorCause!);
    final showOfflineBanner = profile != null &&
        profileState.errorCause != null &&
        isNetworkRequestError(profileState.errorCause!);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFE64060),
          onRefresh: () => _refreshProfile(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              const Text(
                'Verifikasi Dokter',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Akun dokter Anda sudah terdaftar, tapi masih menunggu verifikasi dari admin PulseWise.',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF6C37A)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFFB45309),
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Menunggu Verifikasi Admin',
                            style: TextStyle(
                              color: Color(0xFF9A3412),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Sambil menunggu, lengkapi data profesi dokter Anda agar admin bisa meninjau akun lebih cepat.',
                      style: TextStyle(
                        color: Color(0xFF7C2D12),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (profileState.isRefreshing && profile != null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: Color(0xFFE64060),
                    backgroundColor: Color(0xFFFBCFD7),
                  ),
                ),
              if (showOfflineBanner)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NoConnectionState.compact(
                    title: 'Profil dokter belum tersinkron',
                    message:
                        'Data terakhir tetap ditampilkan. Sambungkan internet lalu tarik untuk memuat ulang.',
                    onRetry: () => _refreshProfile(ref),
                  ),
                ),
              if (profileState.isLoading && profile == null)
                const _DoctorProfileLoadingCard()
              else if (showOfflineCard)
                NoConnectionState.card(
                  title: 'Profil dokter belum bisa dimuat',
                  message:
                      'Kami belum bisa mengambil data profil dokter Anda saat ini. Cek koneksi internet lalu coba lagi.',
                  onRetry: () => _retryProfile(ref),
                )
              else if (profile == null && profileState.error != null)
                _DoctorProfileErrorCard(
                  message: profileState.error!,
                  onRetry: () => _retryProfile(ref),
                )
              else if (profile != null)
                _DoctorProfilePreviewCard(profile: profile),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context
                      .push('$doctorPendingVerificationRoute/update-profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE64060),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 24),
                  label: const Text(
                    'Lengkapi Profil Dokter',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _refreshProfile(ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  label: const Text(
                    'Muat Ulang Halaman',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _logout(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorProfilePreviewCard extends StatelessWidget {
  const _DoctorProfilePreviewCard({required this.profile});

  final DoctorProfile profile;

  String _valueOrFallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Profil Dokter',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _ProfileRow(
            label: 'Nama',
            value: _valueOrFallback(profile.fullName, 'Belum diisi'),
          ),
          _ProfileRow(
            label: 'Email',
            value: _valueOrFallback(profile.email, 'Belum diisi'),
          ),
          _ProfileRow(
            label: 'Spesialisasi',
            value: _valueOrFallback(profile.specialization, 'Belum diisi'),
          ),
          _ProfileRow(
            label: 'Nomor Izin',
            value: _valueOrFallback(profile.licenseNo, 'Belum diisi'),
          ),
          _ProfileRow(
            label: 'Rumah Sakit',
            value: _valueOrFallback(profile.hospitalName, 'Belum diisi'),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _DoctorProfileLoadingCard extends StatelessWidget {
  const _DoctorProfileLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFFE64060)),
      ),
    );
  }
}

class _DoctorProfileErrorCard extends StatelessWidget {
  const _DoctorProfileErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profil belum bisa dimuat',
            style: TextStyle(
              color: Color(0xFF991B1B),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF7F1D1D),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
