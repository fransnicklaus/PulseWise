import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/admin_shell/presentation/providers/admin_dashboard_provider.dart';

void main() {
  group('admin dashboard providers', () {
    test('adminDashboardNavIndexProvider defaults to first tab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(adminDashboardNavIndexProvider), 0);
    });

    test('adminDashboardNavIndexProvider stores selected tab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(adminDashboardNavIndexProvider.notifier).state = 3;

      expect(container.read(adminDashboardNavIndexProvider), 3);
    });
  });
}
