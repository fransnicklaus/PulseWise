// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

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
  PwaInstallPromptController() {
    _installed = _detectInstalled();
    _platform = _detectPlatform();
    _bindListeners();
  }

  Object? _deferredPromptEvent;
  bool _installed = false;
  late final PwaInstallPlatform _platform;
  StreamSubscription<html.Event>? _beforeInstallSubscription;
  StreamSubscription<html.Event>? _appInstalledSubscription;

  bool get isInstalled => _installed;

  bool get canPromptInstall => _deferredPromptEvent != null && !_installed;

  PwaInstallPlatform get platform => _platform;

  Future<PwaInstallOutcome> promptInstall() async {
    if (_installed) {
      return PwaInstallOutcome.alreadyInstalled;
    }

    final deferredPromptEvent = _deferredPromptEvent;
    if (deferredPromptEvent == null) {
      return platform == PwaInstallPlatform.chromium
          ? PwaInstallOutcome.unavailable
          : PwaInstallOutcome.unsupported;
    }

    try {
      final promptPromise =
          js_util.callMethod<Object?>(deferredPromptEvent, 'prompt', const []);

      Object? choiceResult;
      if (promptPromise != null) {
        choiceResult = await js_util.promiseToFuture<Object?>(promptPromise);
      }

      choiceResult ??= await js_util.promiseToFuture<Object?>(
        js_util.getProperty<Object>(deferredPromptEvent, 'userChoice'),
      );

      _deferredPromptEvent = null;
      notifyListeners();

      final outcome =
          js_util.getProperty<Object?>(choiceResult as Object, 'outcome');
      return outcome?.toString() == 'accepted'
          ? PwaInstallOutcome.accepted
          : PwaInstallOutcome.dismissed;
    } catch (_) {
      return PwaInstallOutcome.error;
    }
  }

  void _bindListeners() {
    _beforeInstallSubscription = html.window.on['beforeinstallprompt'].listen(
      (event) {
        event.preventDefault();
        _deferredPromptEvent = event;
        notifyListeners();
      },
    );

    _appInstalledSubscription = html.window.on['appinstalled'].listen((_) {
      _installed = true;
      _deferredPromptEvent = null;
      notifyListeners();
    });
  }

  bool _detectInstalled() {
    final standalone =
        html.window.matchMedia('(display-mode: standalone)').matches;
    final fullscreen =
        html.window.matchMedia('(display-mode: fullscreen)').matches;
    final navigator = html.window.navigator;
    final iosStandalone = js_util.hasProperty(navigator, 'standalone') &&
        js_util.getProperty<Object?>(navigator, 'standalone') == true;

    return standalone || fullscreen || iosStandalone;
  }

  PwaInstallPlatform _detectPlatform() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    final isIos = userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');
    final isSafari = userAgent.contains('safari') &&
        !userAgent.contains('chrome') &&
        !userAgent.contains('crios') &&
        !userAgent.contains('edg');

    if (isIos && isSafari) {
      return PwaInstallPlatform.iosSafari;
    }

    if (userAgent.contains('chrome') ||
        userAgent.contains('crios') ||
        userAgent.contains('edg') ||
        userAgent.contains('edge')) {
      return PwaInstallPlatform.chromium;
    }

    return PwaInstallPlatform.other;
  }

  @override
  void dispose() {
    _beforeInstallSubscription?.cancel();
    _appInstalledSubscription?.cancel();
    super.dispose();
  }
}

final pwaInstallPromptController = PwaInstallPromptController();
