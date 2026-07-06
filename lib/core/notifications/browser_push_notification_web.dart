// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:flutter/foundation.dart';

const _fcmServiceWorkerScope = '/firebase-cloud-messaging-push-scope';
const _fcmServiceWorkerPath = '/firebase-messaging-sw.js';

bool get supportsBrowserForegroundNotifications =>
    js_util.hasProperty(html.window, 'Notification');

Future<void> logBrowserPushDiagnostics({String source = 'manual'}) async {
  final serviceWorker = _serviceWorkerContainer();
  final fcmRegistration = serviceWorker == null
      ? null
      : await _getFcmServiceWorkerRegistration(
          serviceWorker,
          logErrors: false,
        );

  debugPrint(
    '[BrowserPush][$source] '
    'secure=${_isSecureContext()} '
    'notificationApi=$supportsBrowserForegroundNotifications '
    'permission=${_notificationPermissionLabel()} '
    'serviceWorkerApi=${serviceWorker != null} '
    'standalone=${_isStandaloneMode()} '
    'fcmServiceWorker=${fcmRegistration != null}',
  );
}

Future<void> showBrowserForegroundNotification({
  required String title,
  String? body,
  String? tag,
  String? link,
}) async {
  if (!supportsBrowserForegroundNotifications) {
    debugPrint('[BrowserPush] Notification API is not available.');
    return;
  }

  if (html.Notification.permission != 'granted') {
    debugPrint(
      '[BrowserPush] Skip foreground notification. '
      'permission=${html.Notification.permission}',
    );
    return;
  }

  final destination = (link ?? '').trim();
  final iconUrl = Uri.base.resolve('icons/Icon-192.png').toString();
  final options = <String, Object?>{
    'body': (body ?? '').trim(),
    'icon': iconUrl,
    'badge': iconUrl,
    'data': <String, Object?>{
      'link': destination.isEmpty ? '/' : destination,
    },
  };
  final normalizedTag = (tag ?? '').trim();
  if (normalizedTag.isNotEmpty) {
    options['tag'] = normalizedTag;
  }

  final shownViaServiceWorker = await _showViaFcmServiceWorker(
    title: title,
    options: options,
  );
  if (shownViaServiceWorker) {
    return;
  }

  _showViaNotificationConstructor(
    title: title,
    body: body,
    iconUrl: iconUrl,
    tag: normalizedTag,
    link: destination,
  );
}

Future<bool> _showViaFcmServiceWorker({
  required String title,
  required Map<String, Object?> options,
}) async {
  final serviceWorker = _serviceWorkerContainer();
  if (serviceWorker == null) {
    debugPrint('[BrowserPush] Service Worker API is not available.');
    return false;
  }

  final registration = await _ensureFcmServiceWorkerRegistration(serviceWorker);
  if (registration == null) {
    debugPrint('[BrowserPush] FCM service worker registration is unavailable.');
    return false;
  }

  if (!js_util.hasProperty(registration, 'showNotification')) {
    debugPrint('[BrowserPush] Service worker cannot show notifications.');
    return false;
  }

  try {
    final promise = js_util.callMethod<Object?>(
      registration,
      'showNotification',
      [title, js_util.jsify(options)],
    );
    if (promise == null) {
      debugPrint(
        '[BrowserPush] Service worker returned no notification promise.',
      );
      return false;
    }
    await js_util.promiseToFuture<Object?>(promise);
    debugPrint(
        '[BrowserPush] Foreground notification shown via service worker.');
    return true;
  } catch (e) {
    debugPrint('[BrowserPush] Service worker showNotification failed: $e');
    return false;
  }
}

void _showViaNotificationConstructor({
  required String title,
  required String? body,
  required String iconUrl,
  required String tag,
  required String link,
}) {
  try {
    final notification = html.Notification(
      title,
      body: (body ?? '').trim(),
      icon: iconUrl,
      tag: tag.isEmpty ? null : tag,
    );

    notification.onClick.listen((_) {
      notification.close();

      if (link.isNotEmpty) {
        html.window.location.assign(link);
      }
    });
    debugPrint(
      '[BrowserPush] Foreground notification shown via Notification constructor.',
    );
  } catch (e) {
    debugPrint('[BrowserPush] Notification constructor failed: $e');
  }
}

Object? _serviceWorkerContainer() {
  final navigator = html.window.navigator;
  if (!js_util.hasProperty(navigator, 'serviceWorker')) {
    return null;
  }

  return js_util.getProperty<Object?>(navigator, 'serviceWorker');
}

Future<Object?> _ensureFcmServiceWorkerRegistration(
  Object serviceWorker,
) async {
  final existing = await _getFcmServiceWorkerRegistration(serviceWorker);
  if (existing != null) {
    return existing;
  }

  try {
    final promise = js_util.callMethod<Object?>(
      serviceWorker,
      'register',
      [
        _fcmServiceWorkerPath,
        js_util.jsify(<String, Object?>{'scope': _fcmServiceWorkerScope}),
      ],
    );
    if (promise == null) {
      debugPrint(
        '[BrowserPush] Service worker registration returned no promise.',
      );
      return null;
    }
    final registration = await js_util.promiseToFuture<Object?>(promise);
    if (registration == null ||
        !_isFcmServiceWorkerRegistration(registration)) {
      debugPrint(
          '[BrowserPush] Registered service worker has unexpected scope.');
      return null;
    }
    debugPrint(
        '[BrowserPush] Registered FCM service worker for notifications.');
    return registration;
  } catch (e) {
    debugPrint('[BrowserPush] Failed to register FCM service worker: $e');
    return null;
  }
}

Future<Object?> _getFcmServiceWorkerRegistration(
  Object serviceWorker, {
  bool logErrors = true,
}) async {
  try {
    final promise = js_util.callMethod<Object?>(
      serviceWorker,
      'getRegistration',
      [_fcmServiceWorkerScope],
    );
    if (promise == null) {
      return null;
    }
    final registration = await js_util.promiseToFuture<Object?>(promise);
    if (registration == null ||
        !_isFcmServiceWorkerRegistration(registration)) {
      return null;
    }
    return registration;
  } catch (e) {
    if (logErrors) {
      debugPrint('[BrowserPush] Failed to read FCM service worker: $e');
    }
    return null;
  }
}

String _notificationPermissionLabel() {
  if (!supportsBrowserForegroundNotifications) {
    return 'unsupported';
  }

  return html.Notification.permission ?? 'unknown';
}

bool _isSecureContext() {
  return js_util.getProperty<Object?>(html.window, 'isSecureContext') == true;
}

bool _isFcmServiceWorkerRegistration(Object registration) {
  final scope =
      js_util.getProperty<Object?>(registration, 'scope')?.toString() ?? '';
  if (scope.trim().isEmpty) {
    return false;
  }

  return _normalizeScope(scope) ==
      _normalizeScope(Uri.base.resolve(_fcmServiceWorkerScope).toString());
}

String _normalizeScope(String scope) {
  final trimmed = scope.trim();
  if (trimmed.endsWith('/')) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

bool _isStandaloneMode() {
  final standalone = _matchesDisplayMode('standalone');
  final fullscreen = _matchesDisplayMode('fullscreen');
  final navigator = html.window.navigator;
  final iosStandalone = js_util.hasProperty(navigator, 'standalone') &&
      js_util.getProperty<Object?>(navigator, 'standalone') == true;

  return standalone || fullscreen || iosStandalone;
}

bool _matchesDisplayMode(String mode) {
  try {
    return html.window.matchMedia('(display-mode: $mode)').matches;
  } catch (_) {
    return false;
  }
}
