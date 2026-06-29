import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/install/presentation/services/pwa_install_prompt_stub.dart';

void main() {
  group('PwaInstallPromptController stub', () {
    test('reports unsupported install prompt on non-web platforms', () async {
      final controller = PwaInstallPromptController();

      expect(controller.isInstalled, isFalse);
      expect(controller.canPromptInstall, isFalse);
      expect(controller.platform, PwaInstallPlatform.other);
      await expectLater(
        controller.promptInstall(),
        completion(PwaInstallOutcome.unsupported),
      );
    });

    test('exposes singleton stub controller', () {
      expect(pwaInstallPromptController, isA<PwaInstallPromptController>());
      expect(pwaInstallPromptController.platform, PwaInstallPlatform.other);
    });
  });
}
