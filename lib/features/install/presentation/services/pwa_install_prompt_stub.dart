import 'package:flutter/foundation.dart';

enum PwaInstallPlatform {
  chromium,
  iosSafari,
  other,
}

enum PwaInstallOutcome {
  accepted,
  dismissed,
  unavailable,
  unsupported,
  alreadyInstalled,
  error,
}

class PwaInstallPromptController extends ChangeNotifier {
  bool get isInstalled => false;

  bool get canPromptInstall => false;

  PwaInstallPlatform get platform => PwaInstallPlatform.other;

  Future<PwaInstallOutcome> promptInstall() async {
    return PwaInstallOutcome.unsupported;
  }
}

final pwaInstallPromptController = PwaInstallPromptController();
