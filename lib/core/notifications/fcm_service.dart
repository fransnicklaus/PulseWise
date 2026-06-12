import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pulsewise/core/config/firebase_app_options.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/core/notifications/browser_push_notification.dart';
import 'package:pulsewise/core/notifications/reminder_notification_coordinator.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
  static const String appIdPrefsKey = 'fcm_app_installation_id';
  static const String authTokenPrefsKey = AppSessionStore.tokenPrefsKey;
  static const String authUserIdPrefsKey = AppSessionStore.userIdPrefsKey;
  static const String notificationPromptedPrefsKey =
      'notification_permission_prompted';
  static const String androidChannelId = 'pulsewise_reminders';
  static const String androidChannelName = 'PulseWise Reminders';
  static const String androidChannelDescription =
      'Reminder and health notifications from PulseWise';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final Uuid _uuid = const Uuid();

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
    await getOrCreateAppId(printToDebugger: true);

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

    if (!kIsWeb) {
      await _setupLocalNotifications();
    }
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

  Future<NotificationSettings?> requestNotificationPermissionAndSync({
    String trigger = 'permission_request',
  }) async {
    final settings = await requestNotificationPermission();
    await _syncTokenRegistrationAfterPermission(
      settings,
      trigger: trigger,
    );
    return settings;
  }

  Future<void> maybePromptNotificationPermissionOnFirstLaunch() async {
    if (!_initialized) {
      await initialize();
    }
    if (!_firebaseReady) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyPrompted =
        prefs.getBool(notificationPromptedPrefsKey) ?? false;
    final settings = await getNotificationSettings();
    final status = settings?.authorizationStatus;

    if (status != null && status != AuthorizationStatus.notDetermined) {
      await prefs.setBool(notificationPromptedPrefsKey, true);
      debugPrint(
        '[FCM] Notification permission already decided: $status',
      );
      return;
    }

    if (alreadyPrompted) {
      debugPrint(
        '[FCM] Notification permission prompt already requested on this install.',
      );
      return;
    }

    final requestedSettings = await requestNotificationPermissionAndSync(
      trigger: 'first_launch_permission_prompt',
    );
    await prefs.setBool(notificationPromptedPrefsKey, true);
    debugPrint(
      '[FCM] Notification permission request completed with status='
      '${requestedSettings?.authorizationStatus}',
    );
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
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? pulseWiseWebVapidKey : null,
      );
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

  Future<String> getOrCreateAppId({bool printToDebugger = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(appIdPrefsKey);
    if (existing != null && existing.trim().isNotEmpty) {
      if (printToDebugger) {
        debugPrint('[FCM_APP_ID] $existing');
      }
      return existing;
    }

    final generated = _uuid.v4();
    await prefs.setString(appIdPrefsKey, generated);
    debugPrint('[FCM_APP_ID_CREATED] $generated');
    if (printToDebugger) {
      debugPrint('[FCM_APP_ID] $generated');
    }
    return generated;
  }

  Future<String?> getSavedAppId() async {
    final prefs = await SharedPreferences.getInstance();
    final appId = prefs.getString(appIdPrefsKey);
    if (appId == null || appId.trim().isEmpty) return null;
    return appId;
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

  Future<FcmTokenRegistrationResult?> registerTokenForCurrentSession({
    String trigger = 'manual',
    String? tokenOverride,
  }) async {
    final session = await _getCurrentSession();
    if (session == null) {
      debugPrint('[FCM_BACKEND][$trigger] Skip register: no active session.');
      return null;
    }

    final fcmToken = tokenOverride ?? await getBestAvailableToken();
    if (fcmToken == null || fcmToken.trim().isEmpty) {
      debugPrint('[FCM_BACKEND][$trigger] Skip register: no FCM token.');
      return null;
    }

    final payload = await _buildRegistrationPayload(fcmToken);
    final dio = _buildDio();

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/users/${session.userId}/fcm-tokens',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.token}',
          },
        ),
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw Exception(
          (body['message'] ?? 'Gagal menyimpan FCM token').toString(),
        );
      }

      final result = FcmTokenRegistrationResult.fromJson(body);
      debugPrint(
        '[FCM_BACKEND][$trigger] Registered appId=${payload['deviceId']} '
        'tokenId=${result.data?.fcmTokenId ?? '-'}',
      );
      return result;
    } catch (e) {
      debugPrint('[FCM_BACKEND][$trigger] Register failed: $e');
      return null;
    }
  }

  Future<FcmTokenListResult?> fetchRegisteredTokensForCurrentSession() async {
    final session = await _getCurrentSession();
    if (session == null) {
      debugPrint('[FCM_BACKEND] Skip fetch: no active session.');
      return null;
    }

    final dio = _buildDio();
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/users/${session.userId}/fcm-tokens',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.token}',
          },
        ),
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw Exception(
          (body['message'] ?? 'Gagal mengambil daftar FCM token').toString(),
        );
      }

      return FcmTokenListResult.fromJson(body);
    } catch (e) {
      debugPrint('[FCM_BACKEND] Fetch tokens failed: $e');
      return null;
    }
  }

  Future<FcmTokenRevocationResult?> revokeCurrentTokenForCurrentSession({
    String trigger = 'logout',
  }) async {
    final session = await _getCurrentSession();
    if (session == null) {
      debugPrint('[FCM_BACKEND][$trigger] Skip revoke: no active session.');
      return null;
    }

    final fcmToken = await getSavedToken();
    if (fcmToken == null || fcmToken.trim().isEmpty) {
      debugPrint('[FCM_BACKEND][$trigger] Skip revoke: no saved FCM token.');
      return null;
    }

    final dio = _buildDio();
    try {
      final response = await dio.delete<Map<String, dynamic>>(
        '/users/${session.userId}/fcm-tokens',
        data: {
          'fcmToken': fcmToken,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${session.token}',
          },
        ),
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw Exception(
          (body['message'] ?? 'Gagal menonaktifkan FCM token').toString(),
        );
      }

      final result = FcmTokenRevocationResult.fromJson(body);
      debugPrint(
        '[FCM_BACKEND][$trigger] Revoked appId=${await getSavedAppId() ?? '-'} '
        'count=${result.data?.revokedCount ?? 0}',
      );
      return result;
    } catch (e) {
      debugPrint('[FCM_BACKEND][$trigger] Revoke failed: $e');
      return null;
    }
  }

  void _registerHandlers() {
    if (_handlersRegistered || !_firebaseReady) return;

    _messaging.onTokenRefresh.listen((token) async {
      await _persistToken(token);
      debugPrint('[FCM_TOKEN_REFRESH] $token');
      await registerTokenForCurrentSession(
        trigger: 'token_refresh',
        tokenOverride: token,
      );
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
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
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
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    if (kIsWeb) {
      if (!supportsBrowserForegroundNotifications) {
        return;
      }

      await showBrowserForegroundNotification(
        title: title ?? 'PulseWise',
        body: body ?? 'Anda memiliki notifikasi baru.',
        tag: message.messageId,
        link: _resolveNotificationLink(message),
      );
      return;
    }

    if (!_localNotificationsReady) return;

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

  Future<void> _syncTokenRegistrationAfterPermission(
    NotificationSettings? settings, {
    required String trigger,
  }) async {
    final status = settings?.authorizationStatus;
    if (status != AuthorizationStatus.authorized &&
        status != AuthorizationStatus.provisional) {
      debugPrint(
        '[FCM] Skip token sync after permission request. status=$status',
      );
      return;
    }

    final token = await getToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint(
        '[FCM] Permission granted but no token available yet for trigger=$trigger',
      );
      return;
    }

    await registerTokenForCurrentSession(
      trigger: trigger,
      tokenOverride: token,
    );
  }

  Future<_FcmAuthSession?> _getCurrentSession() async {
    final session = await AppSessionStore.readSession(allowEnvFallback: false);
    final token = session.token ?? '';
    final userId = session.userId ?? '';

    if (token.trim().isEmpty || userId.trim().isEmpty) {
      return null;
    }

    return _FcmAuthSession(token: token, userId: userId);
  }

  Future<Map<String, dynamic>> _buildRegistrationPayload(
      String fcmToken) async {
    final appId = await getOrCreateAppId();
    final appMetadata = await _resolveAppMetadata();
    final locale = PlatformDispatcher.instance.locale.toLanguageTag();
    final timezone = DateTime.now().timeZoneName;

    return <String, dynamic>{
      'fcmToken': fcmToken,
      'platform': _platformName(),
      'deviceId': appId,
      'deviceName': await _deviceName(),
      'appVersion': appMetadata.version,
      'appBuild': appMetadata.buildNumber,
      'locale': locale.isNotEmpty ? locale : 'und',
      'timezone': timezone.isNotEmpty ? timezone : 'UTC',
    };
  }

  Future<_AppMetadata> _resolveAppMetadata() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version.trim();
      final buildNumber = packageInfo.buildNumber.trim();

      return _AppMetadata(
        version: version.isNotEmpty ? version : _fallbackAppVersion(),
        buildNumber:
            buildNumber.isNotEmpty ? buildNumber : _fallbackAppBuildNumber(),
      );
    } on MissingPluginException catch (e) {
      debugPrint('[FCM_BACKEND] PackageInfo plugin unavailable: $e');
      return _AppMetadata(
        version: _fallbackAppVersion(),
        buildNumber: _fallbackAppBuildNumber(),
      );
    } catch (e) {
      debugPrint('[FCM_BACKEND] Failed to resolve app metadata: $e');
      return _AppMetadata(
        version: _fallbackAppVersion(),
        buildNumber: _fallbackAppBuildNumber(),
      );
    }
  }

  String _fallbackAppVersion() {
    const buildName = String.fromEnvironment('FLUTTER_BUILD_NAME');
    return buildName.isNotEmpty ? buildName : '1.0.0';
  }

  String _fallbackAppBuildNumber() {
    const buildNumber = String.fromEnvironment('FLUTTER_BUILD_NUMBER');
    return buildNumber.isNotEmpty ? buildNumber : '1';
  }

  Dio _buildDio() {
    return createApiDio(resolveApiBaseUrl());
  }

  String _platformName() {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  Future<String> _deviceName() async {
    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) {
        final webInfo = await info.webBrowserInfo;
        return webInfo.userAgent?.trim().isNotEmpty == true
            ? webInfo.userAgent!.trim()
            : 'Web Browser';
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final android = await info.androidInfo;
          final manufacturer = android.manufacturer.trim();
          final model = android.model.trim();
          return '$manufacturer $model'.trim();
        case TargetPlatform.iOS:
          final ios = await info.iosInfo;
          final name = ios.name.trim();
          final model = ios.model.trim();
          return name.isNotEmpty ? name : model;
        case TargetPlatform.macOS:
          final mac = await info.macOsInfo;
          final model = mac.model.trim();
          return model.isNotEmpty ? model : 'macOS Device';
        case TargetPlatform.windows:
          final windows = await info.windowsInfo;
          final computerName = windows.computerName.trim();
          return computerName.isNotEmpty ? computerName : 'Windows Device';
        case TargetPlatform.linux:
          final linux = await info.linuxInfo;
          final name = linux.prettyName.trim();
          return name.isNotEmpty ? name : 'Linux Device';
        case TargetPlatform.fuchsia:
          return 'Fuchsia Device';
      }
    } catch (e) {
      debugPrint('[FCM_BACKEND] Failed to resolve device name: $e');
      return 'Unknown Device';
    }
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

    final options = firebaseInitializationOptionsForCurrentPlatform();
    if (options != null) {
      await Firebase.initializeApp(options: options);
      return;
    }

    await Firebase.initializeApp();
  }

  String? _resolveNotificationLink(RemoteMessage message) {
    final directLink = (message.data['link'] ?? '').toString().trim();
    if (directLink.isNotEmpty) {
      return directLink;
    }

    final clickAction = (message.data['click_action'] ?? '').toString().trim();
    if (clickAction.isNotEmpty) {
      return clickAction;
    }

    final route = (message.data['route'] ?? '').toString().trim();
    if (route.isEmpty) {
      return null;
    }

    return Uri.base.resolve(route).toString();
  }
}

class _FcmAuthSession {
  final String token;
  final String userId;

  const _FcmAuthSession({
    required this.token,
    required this.userId,
  });
}

class _AppMetadata {
  final String version;
  final String buildNumber;

  const _AppMetadata({
    required this.version,
    required this.buildNumber,
  });
}

class FcmTokenRegistrationResult {
  final bool success;
  final String message;
  final FcmTokenRegistrationData? data;

  const FcmTokenRegistrationResult({
    required this.success,
    required this.message,
    required this.data,
  });

  factory FcmTokenRegistrationResult.fromJson(Map<String, dynamic> json) {
    return FcmTokenRegistrationResult(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? FcmTokenRegistrationData.fromJson(json['data'])
          : null,
    );
  }
}

class FcmTokenRegistrationData {
  final String fcmTokenId;
  final String userId;
  final String platform;
  final String deviceId;
  final String deviceName;
  final String appVersion;
  final String appBuild;
  final String locale;
  final String timezone;
  final bool isActive;

  const FcmTokenRegistrationData({
    required this.fcmTokenId,
    required this.userId,
    required this.platform,
    required this.deviceId,
    required this.deviceName,
    required this.appVersion,
    required this.appBuild,
    required this.locale,
    required this.timezone,
    required this.isActive,
  });

  factory FcmTokenRegistrationData.fromJson(Map<String, dynamic> json) {
    return FcmTokenRegistrationData(
      fcmTokenId: (json['fcmTokenId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      deviceId: (json['deviceId'] ?? '').toString(),
      deviceName: (json['deviceName'] ?? '').toString(),
      appVersion: (json['appVersion'] ?? '').toString(),
      appBuild: (json['appBuild'] ?? '').toString(),
      locale: (json['locale'] ?? '').toString(),
      timezone: (json['timezone'] ?? '').toString(),
      isActive: json['isActive'] == true,
    );
  }
}

class FcmTokenListResult {
  final bool success;
  final String message;
  final List<FcmTokenListItem> items;

  const FcmTokenListResult({
    required this.success,
    required this.message,
    required this.items,
  });

  factory FcmTokenListResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    final items = ((data['items'] as List?) ?? const [])
        .map((item) => FcmTokenListItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return FcmTokenListResult(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      items: items,
    );
  }
}

class FcmTokenListItem {
  final String fcmTokenId;
  final String platform;
  final String deviceId;
  final String deviceName;
  final String appVersion;
  final String appBuild;
  final bool isActive;
  final DateTime? lastSeenAt;
  final DateTime? lastSentAt;

  const FcmTokenListItem({
    required this.fcmTokenId,
    required this.platform,
    required this.deviceId,
    required this.deviceName,
    required this.appVersion,
    required this.appBuild,
    required this.isActive,
    required this.lastSeenAt,
    required this.lastSentAt,
  });

  factory FcmTokenListItem.fromJson(Map<String, dynamic> json) {
    return FcmTokenListItem(
      fcmTokenId: (json['fcmTokenId'] ?? '').toString(),
      platform: (json['platform'] ?? '').toString(),
      deviceId: (json['deviceId'] ?? '').toString(),
      deviceName: (json['deviceName'] ?? '').toString(),
      appVersion: (json['appVersion'] ?? '').toString(),
      appBuild: (json['appBuild'] ?? '').toString(),
      isActive: json['isActive'] == true,
      lastSeenAt: DateTime.tryParse((json['lastSeenAt'] ?? '').toString()),
      lastSentAt: DateTime.tryParse((json['lastSentAt'] ?? '').toString()),
    );
  }
}

class FcmTokenRevocationResult {
  final bool success;
  final String message;
  final FcmTokenRevocationData? data;

  const FcmTokenRevocationResult({
    required this.success,
    required this.message,
    required this.data,
  });

  factory FcmTokenRevocationResult.fromJson(Map<String, dynamic> json) {
    return FcmTokenRevocationResult(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? FcmTokenRevocationData.fromJson(json['data'])
          : null,
    );
  }
}

class FcmTokenRevocationData {
  final int revokedCount;
  final List<FcmTokenRevokedItem> items;

  const FcmTokenRevocationData({
    required this.revokedCount,
    required this.items,
  });

  factory FcmTokenRevocationData.fromJson(Map<String, dynamic> json) {
    return FcmTokenRevocationData(
      revokedCount: (json['revokedCount'] as num?)?.toInt() ?? 0,
      items: ((json['items'] as List?) ?? const [])
          .map((item) =>
              FcmTokenRevokedItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FcmTokenRevokedItem {
  final String fcmTokenId;
  final String fcmToken;
  final String deviceId;
  final bool isActive;
  final DateTime? revokedAt;

  const FcmTokenRevokedItem({
    required this.fcmTokenId,
    required this.fcmToken,
    required this.deviceId,
    required this.isActive,
    required this.revokedAt,
  });

  factory FcmTokenRevokedItem.fromJson(Map<String, dynamic> json) {
    return FcmTokenRevokedItem(
      fcmTokenId: (json['fcmTokenId'] ?? '').toString(),
      fcmToken: (json['fcmToken'] ?? '').toString(),
      deviceId: (json['deviceId'] ?? '').toString(),
      isActive: json['isActive'] == true,
      revokedAt: DateTime.tryParse((json['revokedAt'] ?? '').toString()),
    );
  }
}
