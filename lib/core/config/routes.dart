import 'package:go_router/go_router.dart';
import 'package:pulsewise/features/auth/presentation/pages/login_page.dart';
import 'package:pulsewise/features/auth/presentation/pages/register_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/home_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/contacts_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/add_diary_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/riwayat_diari_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/detail_diari_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/detail_pengingat_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/add_pengingat_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/diary_qr_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/qr_scanner_page.dart';

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
      routes: [
        GoRoute(
          path: 'contacts',
          builder: (context, state) => const ContactsPage(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddContactPage(),
            ),
          ],
        ),
        GoRoute(
          path: 'add-diary',
          builder: (context, state) => const AddDiaryPage(),
        ),
        GoRoute(
          path: 'diary-qr',
          builder: (context, state) => const DiaryQrPage(),
        ),
        GoRoute(
          path: 'diary-qr/scan',
          builder: (context, state) => const QrScannerPage(),
        ),
        GoRoute(
          path: 'diary',
          builder: (context, state) => const RiwayatDiariPage(),
          routes: [
            GoRoute(
              path: 'detail/:index',
              builder: (context, state) {
                final index = int.parse(state.pathParameters['index'] ?? '0');
                return DetailDiariPage(entryIndex: index);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'reminder/detail/:index',
          builder: (context, state) => const DetailPengingatPage(),
        ),
        GoRoute(
          path: 'reminder/add',
          builder: (context, state) => const AddPengingatPage(),
        ),
      ],
    ),
  ],
);
