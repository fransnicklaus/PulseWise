import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pulsewise/core/notifications/reminder_notification_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[FCM BG] Firebase init failed: $e');
    return;
  }

  debugPrint(
    '[FCM BG] messageId=${message.messageId} '
    'title=${message.notification?.title} '
    'body=${message.notification?.body} '
    'data=${jsonEncode(message.data)}',
  );
}

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(
  NotificationResponse response,
) {
  debugPrint(
    '[FCM LOCAL BG TAP] payload=${response.payload} '
    'actionId=${response.actionId} '
    'input=${response.input}',
  );
  ReminderNotificationCoordinator.instance.queueFromEncodedPayload(
    response.payload,
    source: 'local_notification_background',
  );
}

class AppFcmService {
  AppFcmService._();

  static final AppFcmService instance = AppFcmService._();

  static const String tokenPrefsKey = 'fcm_device_token';
  static const String androidChannelId = 'pulsewise_reminders';
  static const String androidChannelName = 'PulseWise Reminders';
  static const String androidChannelDescription =
      'Reminder and health notifications from PulseWise';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _firebaseReady = false;
  bool _handlersRegistered = false;
  bool _localNotificationsReady = false;
  String? _lastError;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  bool get isReady => _firebaseReady;
  String? get lastError => _lastError;

  Future<void> initialize({bool requestPermission = false}) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    if (_initialized) {
      if (requestPermission && _firebaseReady) {
        await requestNotificationPermission();
      }
      return;
    }

    try {
      await _ensureFirebaseInitialized();
      _firebaseReady = true;
      _lastError = null;
    } on FirebaseException catch (e) {
      _firebaseReady = false;
      _lastError =
          'Firebase belum siap: ${e.message ?? e.code}. Tambahkan file konfigurasi Firebase terlebih dahulu.';
      debugPrint('[FCM] $_lastError');
      _initialized = true;
      return;
    } catch (e) {
      _firebaseReady = false;
      _lastError =
          'Firebase belum siap: $e. Tambahkan file konfigurasi Firebase terlebih dahulu.';
      debugPrint('[FCM] $_lastError');
      _initialized = true;
      return;
    }

    await _setupLocalNotifications();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _registerHandlers();
    await _handleInitialMessage();

    if (requestPermission) {
      await requestNotificationPermission();
    }

    final token = await getToken(printToDebugger: true);
    if (token != null && token.isNotEmpty) {
      await _persistToken(token);
    }

    _initialized = true;
  }

  Future<NotificationSettings?> getNotificationSettings() async {
    if (!_firebaseReady) return null;
    try {
      return await _messaging.getNotificationSettings();
    } catch (e) {
      debugPrint('[FCM] Failed to read notification settings: $e');
      return null;
    }
  }

  Future<NotificationSettings?> requestNotificationPermission() async {
    if (!_firebaseReady) return null;
    try {
      return await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('[FCM] Failed to request notification permission: $e');
      return null;
    }
  }

  Future<String?> getToken({bool printToDebugger = false}) async {
    if (!_firebaseReady) {
      final saved = await getSavedToken();
      if (printToDebugger) {
        debugPrint('[FCM_TOKEN] ${saved ?? '<empty>'}');
      }
      return saved;
    }

    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _persistToken(token);
      }
      if (printToDebugger) {
        debugPrint('[FCM_TOKEN] ${token ?? '<empty>'}');
      }
      return token;
    } catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
      final saved = await getSavedToken();
      if (printToDebugger) {
        debugPrint('[FCM_TOKEN] ${saved ?? '<empty>'}');
      }
      return saved;
    }
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenPrefsKey);
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  Future<String?> getBestAvailableToken({bool printToDebugger = false}) async {
    final live = await getToken(printToDebugger: printToDebugger);
    if (live != null && live.trim().isNotEmpty) {
      return live;
    }
    return getSavedToken();
  }

  Future<void> printTokenToDebugger() async {
    await getBestAvailableToken(printToDebugger: true);
  }

  void _registerHandlers() {
    if (_handlersRegistered || !_firebaseReady) return;

    _messaging.onTokenRefresh.listen((token) async {
      await _persistToken(token);
      debugPrint('[FCM_TOKEN_REFRESH] $token');
    });

    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint(
        '[FCM FG] messageId=${message.messageId} '
        'title=${message.notification?.title} '
        'body=${message.notification?.body} '
        'data=${jsonEncode(message.data)}',
      );
      await _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
        '[FCM OPEN] messageId=${message.messageId} '
        'data=${jsonEncode(message.data)}',
      );
      _queueReminderNavigation(
        message.data,
        source: 'fcm_opened_app',
      );
    });

    _handlersRegistered = true;
  }

  Future<void> _setupLocalNotifications() async {
    if (_localNotificationsReady) return;

    const androidChannel = AndroidNotificationChannel(
      androidChannelId,
      androidChannelName,
      description: androidChannelDescription,
      importance: Importance.max,
    );

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _localNotificationsReady = true;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!_localNotificationsReady) return;

    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    await _localNotifications.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title ?? 'PulseWise',
      body ?? 'Anda memiliki notifikasi baru.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          channelDescription: androidChannelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenPrefsKey, token);
  }

  Future<void> _handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) {
      debugPrint('[FCM INITIAL] No initial message found.');
      return;
    }

    debugPrint(
      '[FCM INITIAL] messageId=${message.messageId} '
      'data=${jsonEncode(message.data)}',
    );
    _queueReminderNavigation(
      message.data,
      source: 'fcm_initial_message',
    );
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint(
      '[FCM LOCAL TAP] payload=${response.payload} '
      'actionId=${response.actionId} '
      'input=${response.input}',
    );
    ReminderNotificationCoordinator.instance.queueFromEncodedPayload(
      response.payload,
      source: 'local_notification_tap',
    );
  }

  void _queueReminderNavigation(
    Map<String, dynamic> data, {
    required String source,
  }) {
    ReminderNotificationCoordinator.instance.queueFromData(
      data,
      source: source,
    );
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      Firebase.app();
      return;
    }

    await Firebase.initializeApp();
  }
}
