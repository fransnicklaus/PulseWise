bool get supportsBrowserForegroundNotifications => false;

Future<void> showBrowserForegroundNotification({
  required String title,
  String? body,
  String? tag,
  String? link,
}) async {}

Future<void> logBrowserPushDiagnostics({String source = 'manual'}) async {}
