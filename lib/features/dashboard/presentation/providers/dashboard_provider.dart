import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to manage the selected index of the bottom navigation bar
final dashboardNavIndexProvider = StateProvider<int>((ref) => 0);

// Provider to track the previous index for determining swipe direction
final previousNavIndexProvider = StateProvider<int>((ref) => 0);
