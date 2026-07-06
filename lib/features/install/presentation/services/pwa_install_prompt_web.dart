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
    _syncFromWindow(notify: false);
  }

  bool _installed = false;
  late final PwaInstallPlatform _platform;
  StreamSubscription<html.Event>? _availabilitySubscription;
  StreamSubscription<html.Event>? _appInstalledSubscription;

  bool get isInstalled => _installed;

  bool get canPromptInstall => !_installed && _jsCanPromptInstall();

  PwaInstallPlatform get platform => _platform;

  Future<PwaInstallOutcome> promptInstall() async {
    _syncFromWindow(notify: false);

    if (_installed) {
      return PwaInstallOutcome.alreadyInstalled;
    }

    if (!_jsCanPromptInstall()) {
      return platform == PwaInstallPlatform.chromium
          ? PwaInstallOutcome.unavailable
          : PwaInstallOutcome.unsupported;
    }

    try {
      final result = await js_util.promiseToFuture<Object?>(
        js_util.callMethod<Object>(
          html.window as Object,
          'pulsewisePromptInstall',
          const [],
        ),
      );

      _syncFromWindow();

      switch ((result ?? _jsInstallStatus()).toString()) {
        case 'accepted':
          return PwaInstallOutcome.accepted;
        case 'dismissed':
          return PwaInstallOutcome.dismissed;
        case 'installed':
          return PwaInstallOutcome.alreadyInstalled;
        case 'unavailable':
          return PwaInstallOutcome.unavailable;
        default:
          return PwaInstallOutcome.error;
      }
    } catch (_) {
      _syncFromWindow();
      return PwaInstallOutcome.error;
    }
  }

  void _bindListeners() {
    _availabilitySubscription = html.window
        .on['pulsewise-install-availability-changed']
        .listen((_) => _syncFromWindow());

    _appInstalledSubscription = html.window.on['appinstalled'].listen((_) {
      _installed = true;
      notifyListeners();
    });
  }

  void _syncFromWindow({bool notify = true}) {
    final status = _jsInstallStatus();
    final installed = _detectInstalled() || status == 'installed';
    final changed = installed != _installed;

    _installed = installed;

    if (notify && changed) {
      notifyListeners();
      return;
    }

    if (notify) {
      notifyListeners();
    }
  }

  bool _jsCanPromptInstall() {
    try {
      return js_util.callMethod<bool>(
        html.window as Object,
        'pulsewiseCanPromptInstall',
        const [],
      );
    } catch (_) {
      return false;
    }
  }

  String _jsInstallStatus() {
    try {
      final result = js_util.callMethod<Object>(
        html.window as Object,
        'pulsewiseGetInstallStatus',
        const [],
      );
      return (result ?? 'idle').toString();
    } catch (_) {
      return 'idle';
    }
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
    _availabilitySubscription?.cancel();
    _appInstalledSubscription?.cancel();
    super.dispose();
  }
}

final pwaInstallPromptController = PwaInstallPromptController();
