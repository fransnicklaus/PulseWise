// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

bool get supportsBrowserForegroundNotifications => true;

Future<void> showBrowserForegroundNotification({
  required String title,
  String? body,
  String? tag,
  String? link,
}) async {
  if (html.Notification.permission != 'granted') {
    return;
  }

  final notification = html.Notification(
    title,
    body: (body ?? '').trim(),
    icon: Uri.base.resolve('icons/Icon-192.png').toString(),
    tag: (tag ?? '').trim().isEmpty ? null : tag!.trim(),
  );

  notification.onClick.listen((_) {
    notification.close();

    final destination = (link ?? '').trim();
    if (destination.isNotEmpty) {
      html.window.location.assign(destination);
    }
  });
}
