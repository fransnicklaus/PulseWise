// Export the new DashboardPage as HomePage for backward compatibility
export 'dashboard_page.dart' show DashboardPage;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/profile_provider.dart';
import 'dashboard_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authMeAsync = ref.watch(authMeProvider);

    if (authMeAsync.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE64060)),
        ),
      );
    }

    return const DashboardPage();
  }
}
