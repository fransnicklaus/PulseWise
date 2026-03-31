import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_provider.dart';
import 'tabs/beranda_tab.dart';
import 'tabs/diari_tab.dart';
import 'tabs/edukasi_tab.dart';
import 'tabs/pengingat_tab.dart';
import 'tabs/profil_tab.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(dashboardNavIndexProvider);
    final prevIndex = ref.watch(previousNavIndexProvider);

    // Update previous index when current changes
    ref.listen<int>(dashboardNavIndexProvider, (previous, next) {
      ref.read(previousNavIndexProvider.notifier).state = previous ?? 0;
    });

    // List of tab widgets
    final tabs = [
      const BerandaTab(),
      const EdukasiTab(),
      const DiariTab(),
      const PengingatTab(),
      const ProfilTab(),
    ];

    // Determine swipe direction: if moving to higher index, swipe right-to-left (from right)
    // if moving to lower index, swipe left-to-right (from left)
    final isMovingRight = navIndex > prevIndex;
    final beginOffset =
        isMovingRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: beginOffset * 0.5,
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                      parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            );
          },
          child: SizedBox(
            key: ValueKey<int>(navIndex),
            child: tabs[navIndex],
          ),
        ),
      ),

      // Custom Bottom Navigation Bar matching design
      bottomNavigationBar: Container(
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
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          selectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(FluentIcons.home_24_regular),
              activeIcon: Icon(FluentIcons.home_24_filled),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(FluentIcons.book_open_24_regular),
              label: 'Edukasi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: 'Diari',
            ),
            BottomNavigationBarItem(
              icon: Icon(FluentIcons.alert_24_regular),
              label: 'Pengingat',
            ),
            BottomNavigationBarItem(
              icon: Icon(FluentIcons.person_24_regular),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
