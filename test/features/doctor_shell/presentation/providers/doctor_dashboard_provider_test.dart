import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/doctor_shell/presentation/providers/doctor_dashboard_provider.dart';

void main() {
  group('doctor dashboard providers', () {
    test('doctorDashboardNavIndexProvider defaults to first tab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(doctorDashboardNavIndexProvider), 0);
    });

    test('doctorDashboardNavIndexProvider stores selected tab', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(doctorDashboardNavIndexProvider.notifier).state = 2;

      expect(container.read(doctorDashboardNavIndexProvider), 2);
    });
  });
}
