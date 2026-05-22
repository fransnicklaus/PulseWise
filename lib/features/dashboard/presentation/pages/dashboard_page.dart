import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/notifications/reminder_notification_coordinator.dart';
import 'package:pulsewise/core/utils/app_toast.dart';

import '../providers/current_diary_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/profile_provider.dart';
import '../../services/health_connect_sync_service.dart';
import 'tabs/beranda_tab.dart';
import 'tabs/diari_tab.dart';
import 'tabs/edukasi_tab.dart';
import 'tabs/pengingat_tab.dart';
import 'tabs/profil_tab.dart';

enum _HealthConnectPromptChoice {
  connectNow,
  remindLater,
  noDevice,
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with WidgetsBindingObserver {
  bool _isHandlingHealthConnectPrompt = false;

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
      final profile = await _resolvePatientProfileForHealthConnect();
      if (profile == null) {
        debugPrint('[DashboardPage] HC sync skipped: profile not available');
        return;
      }

      if (!profile.shouldActivateHealthConnectSync) {
        debugPrint(
          '[DashboardPage] HC sync skipped: waiting for connect_now/connected '
          '(preference=${profile.healthConnectPreference ?? '-'} '
          'status=${profile.healthConnectStatus ?? '-'})',
        );
        return;
      }

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

  Future<PatientProfile?> _resolvePatientProfileForHealthConnect() async {
    final cachedProfile = ref.read(patientProfileProvider).valueOrNull;
    if (cachedProfile != null) {
      return cachedProfile;
    }

    try {
      return await ref.read(patientProfileProvider.future);
    } catch (e) {
      debugPrint('[DashboardPage] Failed to resolve patient profile: $e');
      return null;
    }
  }

  Future<void> _maybeHandleHealthConnectPrompt(
    PatientProfile profile,
  ) async {
    if (_isHandlingHealthConnectPrompt) return;

    final promptArmed = ref.read(healthConnectLoginPromptArmedProvider);
    if (!promptArmed) return;

    _isHandlingHealthConnectPrompt = true;

    try {
      if (!profile.shouldPromptForHealthConnectOnLogin) {
        debugPrint(
          '[DashboardPage] HC prompt skipped: preference=${profile.healthConnectPreference ?? '-'} '
          'status=${profile.healthConnectStatus ?? '-'}',
        );
        ref.read(healthConnectLoginPromptArmedProvider.notifier).state = false;
        return;
      }

      final choice = await _showHealthConnectPrompt(profile);
      ref.read(healthConnectLoginPromptArmedProvider.notifier).state = false;

      if (!mounted || choice == null) {
        debugPrint('[DashboardPage] HC prompt dismissed without selection.');
        return;
      }

      await _applyHealthConnectPromptChoice(choice);
    } finally {
      _isHandlingHealthConnectPrompt = false;
    }
  }

  Future<void> _applyHealthConnectPromptChoice(
    _HealthConnectPromptChoice choice,
  ) async {
    try {
      switch (choice) {
        case _HealthConnectPromptChoice.connectNow:
          await ref.read(profileApiProvider).updateHealthConnectSetup(
                healthConnectPreference: 'connect_now',
                healthConnectStatus: 'not_started',
              );
          break;
        case _HealthConnectPromptChoice.remindLater:
          await ref.read(profileApiProvider).updateHealthConnectSetup(
                healthConnectPreference: 'remind_later',
                healthConnectStatus: 'not_started',
              );
          break;
        case _HealthConnectPromptChoice.noDevice:
          await ref.read(profileApiProvider).updateHealthConnectSetup(
                healthConnectPreference: 'no_device',
                healthConnectStatus: null,
              );
          break;
      }

      ref.invalidate(patientProfileProvider);
      await ref.read(patientProfileProvider.future);

      if (!mounted) return;

      switch (choice) {
        case _HealthConnectPromptChoice.connectNow:
          AppToast.info(
            context,
            'Membuka panduan Health Connect untuk melanjutkan setup.',
          );
          context.push('/home/health-connect');
          break;
        case _HealthConnectPromptChoice.remindLater:
          AppToast.info(
            context,
            'Baik, kami akan mengingatkan Anda lagi lain kali login.',
          );
          break;
        case _HealthConnectPromptChoice.noDevice:
          AppToast.info(
            context,
            'Baik, popup Health Connect tidak akan ditampilkan lagi.',
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<_HealthConnectPromptChoice?> _showHealthConnectPrompt(
    PatientProfile profile,
  ) {
    final isResumePrompt = profile.healthConnectPreference == 'connect_now' &&
        profile.healthConnectStatus != 'connected';

    final title = isResumePrompt
        ? 'Lanjutkan Setup Health Connect?'
        : 'Hubungkan Smartwatch Anda?';
    final description = isResumePrompt
        ? 'Anda sebelumnya sudah memilih untuk menghubungkan wearable, tetapi setup Health Connect belum selesai.'
        : 'PulseWise dapat membaca langkah, detak jantung, tidur, dan aktivitas dari smartwatch atau wearable Anda lewat Health Connect.';

    return showModalBottomSheet<_HealthConnectPromptChoice>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // const Text(
                //   'Health Connect',
                //   style: TextStyle(
                //     color: Color(0xFFE64060),
                //     fontSize: 14,
                //     fontWeight: FontWeight.w800,
                //     letterSpacing: 0.4,
                //   ),
                // ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Anda bisa memilih untuk hubungkan sekarang, ingatkan nanti, atau lewati jika memang tidak memakai perangkat wearable.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetContext)
                        .pop(_HealthConnectPromptChoice.connectNow),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE64060),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isResumePrompt
                          ? 'Lanjutkan Hubungkan Sekarang'
                          : 'Hubungkan Sekarang',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext)
                        .pop(_HealthConnectPromptChoice.remindLater),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Ingatkan Nanti',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext)
                        .pop(_HealthConnectPromptChoice.noDevice),
                    child: const Text(
                      'Saya Tidak Pakai Smartwatch',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(dashboardNavIndexProvider);
    final promptArmed = ref.watch(healthConnectLoginPromptArmedProvider);
    final profileAsync = ref.watch(patientProfileProvider);

    if (promptArmed && profileAsync.hasValue) {
      final profile = profileAsync.value;
      if (profile != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _maybeHandleHealthConnectPrompt(profile);
        });
      }
    }

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
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
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
                iconSize: 27,
                unselectedLabelStyle: const TextStyle(fontSize: 15),
                selectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
        ),
      ),
    );
  }
}
