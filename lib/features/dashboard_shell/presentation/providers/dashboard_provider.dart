import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to manage the selected index of the bottom navigation bar
final dashboardNavIndexProvider = StateProvider<int>((ref) => 0);

// Provider to track the previous index for determining swipe direction
final previousNavIndexProvider = StateProvider<int>((ref) => 0);

// Used to request opening a specific diary section after navigating to the Diary tab.
final pendingDiarySectionProvider = StateProvider<String?>((ref) => null);

// Used to show a one-time success toast after redirecting into the Diary tab.
final pendingDiaryToastMessageProvider = StateProvider<String?>((ref) => null);

// Armed only after an explicit login/auth flow transitions into /home.
final healthConnectLoginPromptArmedProvider =
    StateProvider<bool>((ref) => false);
