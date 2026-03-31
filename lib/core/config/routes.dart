import 'package:go_router/go_router.dart';
import 'package:pulsewise/features/auth/presentation/pages/login_page.dart';
import 'package:pulsewise/features/auth/presentation/pages/register_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/home_page.dart';

final goRouterConfig = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
      routes: [
        GoRoute(
          path: 'register',
          builder: (context, state) => const RegisterPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
  ],
);
