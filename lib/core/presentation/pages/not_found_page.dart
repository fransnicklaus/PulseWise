import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({
    super.key,
    this.requestedLocation,
  });

  final String? requestedLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withOpacity(0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: SvgPicture.asset(
                        'assets/svgs/pulsewise_logo.svg',
                      ),
                    ),
                    const SizedBox(height: 22),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3F3F46),
                          fontSize: 46,
                        ),
                        children: const [
                          TextSpan(text: 'Pulse'),
                          TextSpan(
                            text: 'Wise',
                            style: TextStyle(color: Color(0xFFE64060)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Halaman tidak ditemukan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: const Text(
                        'Rute yang kamu buka tidak tersedia, mungkin link-nya berubah atau halaman itu belum ada. Tenang, kita bisa balik ke area yang benar tanpa nyasar lama-lama.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          height: 1.55,
                        ),
                      ),
                    ),
                    if ((requestedLocation ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SelectableText(
                          requestedLocation!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    FutureBuilder<_NotFoundAction>(
                      future: _resolvePrimaryAction(),
                      builder: (context, snapshot) {
                        final action =
                            snapshot.data ?? const _NotFoundAction.login();

                        return SizedBox(
                          width: 280,
                          child: ElevatedButton(
                            onPressed: () => context.go(action.route),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE64060),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              action.label,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<_NotFoundAction> _resolvePrimaryAction() async {
    final session = await AppSessionStore.readSession(allowEnvFallback: false);
    if (!session.hasValidSession) {
      return const _NotFoundAction.login();
    }

    return _NotFoundAction(
      label: 'Kembali ke Home',
      route: routeForRoleSession(
        role: session.role,
        nextStep: session.nextStep,
        accountStatus: session.accountStatus,
      ),
    );
  }
}

class _NotFoundAction {
  const _NotFoundAction({
    required this.label,
    required this.route,
  });

  const _NotFoundAction.login()
      : label = 'Kembali ke Login',
        route = '/login';

  final String label;
  final String route;
}
