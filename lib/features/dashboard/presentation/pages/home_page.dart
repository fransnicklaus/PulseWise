// Export the new DashboardPage as HomePage for backward compatibility
export 'dashboard_page.dart' show DashboardPage;

import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardPage();
  }
}
