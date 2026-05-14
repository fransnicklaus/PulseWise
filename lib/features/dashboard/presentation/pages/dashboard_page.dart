import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/notifications/reminder_notification_coordinator.dart';

import '../providers/current_diary_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../services/health_connect_sync_service.dart';
import 'tabs/beranda_tab.dart';
import 'tabs/diari_tab.dart';
import 'tabs/edukasi_tab.dart';
import 'tabs/pengingat_tab.dart';
import 'tabs/profil_tab.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ReminderNotificationCoordinator.instance
        .addListener(_handleReminderNotification);
    // Sync on first open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleReminderNotification();
      _triggerHealthConnectSync();
    });
  }

  @override
  void dispose() {
    ReminderNotificationCoordinator.instance
        .removeListener(_handleReminderNotification);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[DashboardPage] App resumed — triggering HC sync');
      _triggerHealthConnectSync();
    }
  }

  Future<void> _triggerHealthConnectSync() async {
    try {
      final diaryNotifier = ref.read(currentDiaryProvider.notifier);
      final service = HealthConnectSyncService(diaryNotifier: diaryNotifier);
      await service.syncAll();
    } catch (e) {
      debugPrint('[DashboardPage] HC sync error: $e');
    }
  }

  void _handleReminderNotification() {
    final pending = ReminderNotificationCoordinator.instance.pendingPayload;
    if (pending == null) return;

    final navNotifier = ref.read(dashboardNavIndexProvider.notifier);
    debugPrint(
      '[ReminderNotification][Dashboard] currentIndex=${navNotifier.state} '
      'pending=${pending.debugSummary}',
    );
    if (navNotifier.state != 3) {
      debugPrint(
        '[ReminderNotification][Dashboard] Switching to Pengingat tab.',
      );
      navNotifier.state = 3;
      return;
    }

    debugPrint(
      '[ReminderNotification][Dashboard] Pengingat tab already active.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(dashboardNavIndexProvider);

    // List of tab widgets
    final tabs = [
      const BerandaTab(),
      const EdukasiTab(),
      const DiariTab(),
      const PengingatTab(),
      const ProfilTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: IndexedStack(
          index: navIndex,
          children: tabs,
        ),
      ),

      // Custom Bottom Navigation Bar matching design
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: BottomNavigationBar(
            currentIndex: navIndex,
            onTap: (index) {
              ref.read(dashboardNavIndexProvider.notifier).state = index;
            },
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFE64060),
            unselectedItemColor: const Color(0xFF62748E),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            selectedLabelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(FluentIcons.home_24_regular),
                activeIcon: Icon(FluentIcons.home_24_filled),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(FluentIcons.book_open_24_regular),
                activeIcon: Icon(FluentIcons.book_open_24_filled),
                label: 'Edukasi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Diari',
              ),
              BottomNavigationBarItem(
                icon: Icon(FluentIcons.alert_24_regular),
                activeIcon: Icon(FluentIcons.alert_24_filled),
                label: 'Pengingat',
              ),
              BottomNavigationBarItem(
                icon: Icon(FluentIcons.person_24_regular),
                activeIcon: Icon(FluentIcons.person_24_filled),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
