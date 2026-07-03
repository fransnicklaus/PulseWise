import 'package:flutter/foundation.dart';

class AppSessionScopeController extends ChangeNotifier {
  AppSessionScopeController._();

  static final AppSessionScopeController instance =
      AppSessionScopeController._();

  int _revision = 0;

  int get revision => _revision;

  void reset() {
    _revision += 1;
    notifyListeners();
  }
}
