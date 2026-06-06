import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/ml_questionnaire/presentation/pages/ml_questionnaire_page.dart';

class MlQuestionnaireRouteResolverPage extends StatelessWidget {
  const MlQuestionnaireRouteResolverPage({
    super.key,
    this.tokenOverride,
    this.patientIdOverride,
  });

  final String? tokenOverride;
  final String? patientIdOverride;

  Future<_MlQuestionnaireRouteArgs> _resolveArgs() async {
    final token = (tokenOverride ?? '').trim();
    final patientId = (patientIdOverride ?? '').trim();
    if (token.isNotEmpty && patientId.isNotEmpty) {
      return _MlQuestionnaireRouteArgs(
        token: token,
        patientId: patientId,
      );
    }

    final session = await AppSessionStore.readSession(allowEnvFallback: false);
    final sessionToken = (session.token ?? '').trim();
    final sessionUserId = (session.userId ?? '').trim();
    if (sessionToken.isEmpty || sessionUserId.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login ulang.');
    }

    return _MlQuestionnaireRouteArgs(
      token: sessionToken,
      patientId: sessionUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MlQuestionnaireRouteArgs>(
      future: _resolveArgs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: CustomAppBar(
              title: 'Kuisioner Pasien',
              subtitle: 'Menyiapkan data kuisioner',
              showBackButton: true,
              onBackPressed: () => context.go('/home'),
            ),
            body: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE64060),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            appBar: CustomAppBar(
              title: 'Kuisioner Pasien',
              subtitle: 'Data kuisioner belum tersedia',
              showBackButton: true,
              onBackPressed: () => context.go('/home'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (snapshot.error ?? 'Gagal membuka kuisioner.')
                          .toString()
                          .replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF7F1D1D),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE64060),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Kembali ke Beranda'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final args = snapshot.data!;
        return MlQuestionnairePage(
          token: args.token,
          patientId: args.patientId,
        );
      },
    );
  }
}

class _MlQuestionnaireRouteArgs {
  const _MlQuestionnaireRouteArgs({
    required this.token,
    required this.patientId,
  });

  final String token;
  final String patientId;
}
