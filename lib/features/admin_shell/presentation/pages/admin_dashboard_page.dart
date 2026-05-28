import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/admin/presentation/pages/tabs/admin_tabs.dart';
import 'package:pulsewise/features/admin_shell/presentation/providers/admin_dashboard_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(adminDashboardNavIndexProvider);

    const tabs = [
      AdminHomeTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: IndexedStack(
          index: navIndex,
          children: tabs,
        ),
      ),
    );
  }
}
