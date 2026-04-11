import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final initialLocation = await _resolveInitialLocation();

  runApp(
    ProviderScope(
      child: MyApp(initialLocation: initialLocation),
    ),
  );
}

Future<String> _resolveInitialLocation() async {
  const tokenKey = 'auth_token';
  const userIdKey = 'auth_user_id';

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(tokenKey) ?? '';
  final userId = prefs.getString(userIdKey) ?? '';

  if (token.isEmpty || userId.isEmpty) {
    return '/login';
  }

  try {
    final isExpired = JwtDecoder.isExpired(token);
    if (isExpired) {
      await prefs.remove(tokenKey);
      await prefs.remove(userIdKey);
      return '/login';
    }

    return '/home';
  } catch (_) {
    await prefs.remove(tokenKey);
    await prefs.remove(userIdKey);
    return '/login';
  }
}

class MyApp extends StatelessWidget {
  final String initialLocation;

  const MyApp({super.key, required this.initialLocation});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PulseWise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Outfit',
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: buildRouterConfig(initialLocation: initialLocation),
    );
  }
}
