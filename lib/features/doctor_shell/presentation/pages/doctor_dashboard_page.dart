import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/doctor/presentation/pages/tabs/doctor_qr_tab.dart';
import 'package:pulsewise/features/doctor/presentation/pages/tabs/doctor_profile_tab.dart';
import 'package:pulsewise/features/doctor/presentation/pages/tabs/doctor_tabs.dart';
import 'package:pulsewise/features/doctor_shell/presentation/providers/doctor_dashboard_provider.dart';

class DoctorDashboardPage extends ConsumerWidget {
  const DoctorDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(doctorDashboardNavIndexProvider);

    const tabs = [
      DoctorHomeTab(),
      DoctorPredictionTab(),
      DoctorQrTab(),
      DoctorDiaryTab(),
      DoctorProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SizedBox.expand(
        child: IndexedStack(
          index: navIndex,
          children: tabs,
        ),
      ),
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
                  ref.read(doctorDashboardNavIndexProvider.notifier).state =
                      index;
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
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FluentIcons.data_pie_24_regular),
                    activeIcon: Icon(FluentIcons.data_pie_24_filled),
                    label: 'Prediksi',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.qr_code_2_outlined),
                    activeIcon: Icon(Icons.qr_code_2_rounded),
                    label: 'QR',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite_border),
                    activeIcon: Icon(Icons.favorite),
                    label: 'Diari',
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
