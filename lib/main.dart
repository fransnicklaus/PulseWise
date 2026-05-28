import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:pulsewise/core/notifications/fcm_service.dart';
import 'package:pulsewise/core/notifications/reminder_notification_coordinator.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/core/widgets/connectivity_status_banner.dart';
import 'core/config/routes.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Storage
  await Hive.initFlutter();

  // Initialize environment variables (uncomment when .env exists)
  await dotenv.load(fileName: '.env');

  // Initialize DI / Services
  await di.init();
  await AppFcmService.instance.initialize();
  await initializeDateFormatting('id_ID');

  final initialLocation = await _resolveInitialLocation();
  if (initialLocation != '/login') {
    await AppFcmService.instance.registerTokenForCurrentSession(
      trigger: 'app_launch',
    );
  }

  runApp(
    ProviderScope(
      child: MyApp(initialLocation: initialLocation),
    ),
  );
}

Future<String> _resolveInitialLocation() async {
  final session = await AppSessionStore.readSession(allowEnvFallback: false);
  final token = session.token ?? '';
  final userId = session.userId ?? '';
  final role = session.role;
  final nextStep = session.nextStep;
  final accountStatus = session.accountStatus;

  if (token.isEmpty || userId.isEmpty) {
    return '/login';
  }

  try {
    final isExpired = JwtDecoder.isExpired(token);
    if (isExpired) {
      await AppSessionStore.clearSession();
      return '/login';
    }
    return routeForRoleSession(
      role: role,
      nextStep: nextStep,
      accountStatus: accountStatus,
    );
  } catch (_) {
    await AppSessionStore.clearSession();
    return '/login';
  }
}

class MyApp extends StatefulWidget {
  final String initialLocation;

  const MyApp({super.key, required this.initialLocation});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final router =
      buildRouterConfig(initialLocation: widget.initialLocation);

  @override
  void initState() {
    super.initState();
    ReminderNotificationCoordinator.instance
        .addListener(_handleReminderNotificationNavigation);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleReminderNotificationNavigation();
      _requestNotificationPermissionOnFirstLaunch();
    });
  }

  @override
  void dispose() {
    ReminderNotificationCoordinator.instance
        .removeListener(_handleReminderNotificationNavigation);
    router.dispose();
    super.dispose();
  }

  void _handleReminderNotificationNavigation() {
    final pending = ReminderNotificationCoordinator.instance.pendingPayload;
    if (pending == null) return;
    final currentPath =
        router.routeInformationProvider.value.uri.toString().trim();
    debugPrint(
      '[ReminderNotification][Router] currentPath=$currentPath '
      'pending=${pending.debugSummary}',
    );
    if (currentPath.startsWith('/login')) {
      debugPrint(
        '[ReminderNotification][Router] Still on login flow, keeping payload queued.',
      );
      return;
    }

    if (currentPath.startsWith('/doctor') || currentPath.startsWith('/admin')) {
      debugPrint(
        '[ReminderNotification][Router] Non-patient flow active, keeping patient reminder payload queued.',
      );
      return;
    }

    if (currentPath != '/home') {
      debugPrint('[ReminderNotification][Router] Navigating to /home');
      router.go('/home');
      return;
    }

    debugPrint('[ReminderNotification][Router] Already at /home');
  }

  Future<void> _requestNotificationPermissionOnFirstLaunch() async {
    await AppFcmService.instance
        .maybePromptNotificationPermissionOnFirstLaunch();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PulseWise',
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ConnectivityStatusBanner(),
            ),
          ],
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Outfit',
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
