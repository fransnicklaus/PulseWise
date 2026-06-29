import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';

void main() {
  group('dashboard shell providers', () {
    test('use expected initial navigation and pending action values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(dashboardNavIndexProvider), 0);
      expect(container.read(previousNavIndexProvider), 0);
      expect(container.read(pendingDiarySectionProvider), isNull);
      expect(container.read(pendingDiaryToastMessageProvider), isNull);
      expect(container.read(healthConnectLoginPromptArmedProvider), isFalse);
    });

    test('store independent navigation and pending action state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(dashboardNavIndexProvider.notifier).state = 2;
      container.read(previousNavIndexProvider.notifier).state = 1;
      container.read(pendingDiarySectionProvider.notifier).state = 'sleep';
      container.read(pendingDiaryToastMessageProvider.notifier).state =
          'Sleep saved';
      container.read(healthConnectLoginPromptArmedProvider.notifier).state =
          true;

      expect(container.read(dashboardNavIndexProvider), 2);
      expect(container.read(previousNavIndexProvider), 1);
      expect(container.read(pendingDiarySectionProvider), 'sleep');
      expect(container.read(pendingDiaryToastMessageProvider), 'Sleep saved');
      expect(container.read(healthConnectLoginPromptArmedProvider), isTrue);
    });
  });
}
