import 'package:flutter/foundation.dart';

bool get shouldExposeHealthConnectUi =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
