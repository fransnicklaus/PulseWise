import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/admin/presentation/pages/admin_doctor_detail_page.dart';
import 'package:pulsewise/features/admin/presentation/providers/admin_providers.dart';
import 'package:pulsewise/features/admin/presentation/widgets/admin_widgets.dart';

class AdminDoctorDetailResolverPage extends ConsumerWidget {
  const AdminDoctorDetailResolverPage({
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
    final doctorId = user?.doctorProfile?.doctorId.trim() ?? '';
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

    if (doctorId.isNotEmpty) {
      return AdminDoctorDetailPage(doctorId: doctorId);
    }

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
        child: shouldShowInitialLoading || (detailState.isLoading && !detailState.hasUser)
            ? const _AdminDoctorResolverLoadingView()
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
                              'Kami belum bisa membuka detail dokter karena koneksi internet tidak tersedia atau sedang tidak stabil.',
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
                            icon: Icons.local_hospital_outlined,
                            title: 'Detail dokter belum tersedia',
                            description:
                                detailState.error ?? 'Terjadi kesalahan.',
                            actionLabel: 'Muat Ulang',
                            onActionTap: () => ref
                                .read(adminUserDetailProvider(userId).notifier)
                                .fetchInitial(),
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                        children: [
                          AdminMessageCard(
                            icon: Icons.local_hospital_outlined,
                            title: 'Profil dokter belum tersedia',
                            description:
                                'Akun ini terdeteksi sebagai dokter dari role pengguna, tetapi doctorId belum tersedia untuk membuka halaman review dokter.',
                            actionLabel: 'Buka Detail Pengguna',
                            onActionTap: () =>
                                context.push('/admin/home/users/$userId'),
                          ),
                        ],
                      ),
      ),
    );
  }
}

class _AdminDoctorResolverLoadingView extends StatelessWidget {
  const _AdminDoctorResolverLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: const [
        SizedBox(height: 220),
        Center(
          child: CircularProgressIndicator(
            color: AdminPalette.accent,
          ),
        ),
      ],
    );
  }
}
