import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_dio_provider.dart';
import 'api_logger.dart';

enum AppConnectivityStatus {
  checking,
  online,
  offline,
}

class AppConnectivityState {
  final AppConnectivityStatus status;
  final bool hasInitialized;
  final bool hasNetworkTransport;
  final List<ConnectivityResult> transports;
  final String message;
  final DateTime? checkedAt;

  const AppConnectivityState({
    required this.status,
    required this.hasInitialized,
    required this.hasNetworkTransport,
    required this.transports,
    required this.message,
    required this.checkedAt,
  });

  const AppConnectivityState.initial()
      : status = AppConnectivityStatus.checking,
        hasInitialized = false,
        hasNetworkTransport = false,
        transports = const [],
        message = 'Memeriksa koneksi internet...',
        checkedAt = null;

  bool get isChecking => status == AppConnectivityStatus.checking;
  bool get isOnline => status == AppConnectivityStatus.online;
  bool get isOffline => status == AppConnectivityStatus.offline;

  AppConnectivityState copyWith({
    AppConnectivityStatus? status,
    bool? hasInitialized,
    bool? hasNetworkTransport,
    List<ConnectivityResult>? transports,
    String? message,
    DateTime? checkedAt,
  }) {
    return AppConnectivityState(
      status: status ?? this.status,
      hasInitialized: hasInitialized ?? this.hasInitialized,
      hasNetworkTransport: hasNetworkTransport ?? this.hasNetworkTransport,
      transports: transports ?? this.transports,
      message: message ?? this.message,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }
}

final appConnectivityProvider =
    StateNotifierProvider<AppConnectivityNotifier, AppConnectivityState>((ref) {
  return AppConnectivityNotifier(
    connectivity: Connectivity(),
    baseUrl: ref.watch(apiBaseUrlProvider),
  );
});

final isAppOnlineProvider = Provider<bool>((ref) {
  return ref.watch(appConnectivityProvider).isOnline;
});

class AppConnectivityNotifier extends StateNotifier<AppConnectivityState> {
  AppConnectivityNotifier({
    required Connectivity connectivity,
    required String baseUrl,
  })  : _connectivity = connectivity,
        _baseUrl = baseUrl,
        _healthDio = Dio(
          BaseOptions(
            headers: const {
              'Accept': 'application/json',
            },
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            sendTimeout: const Duration(seconds: 5),
            validateStatus: (status) =>
                status != null && status >= 200 && status < 300,
          ),
        ),
        super(const AppConnectivityState.initial()) {
    ApiLogger.attach(_healthDio);
    _initialize();
  }

  static const _probeInterval = Duration(seconds: 30);

  final Connectivity _connectivity;
  final Dio _healthDio;
  final String _baseUrl;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicProbeTimer;
  int _activeProbeId = 0;

  Future<void> _initialize() async {
    final initialResults = await _safeCheckConnectivity();
    if (!mounted) return;

    await _refreshFromConnectivity(
      initialResults,
      reason: 'initial_check',
    );

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      unawaited(
        _refreshFromConnectivity(
          results,
          reason: 'connectivity_changed',
        ),
      );
    });
  }

  Future<List<ConnectivityResult>> _safeCheckConnectivity() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('[Connectivity] Failed to read current transport: $e');
      return const [ConnectivityResult.none];
    }
  }

  Future<void> _refreshFromConnectivity(
    List<ConnectivityResult> results, {
    required String reason,
  }) async {
    final hasTransport = _hasNetworkTransport(results);

    if (!hasTransport) {
      _stopPeriodicProbe();
      _emitState(
        state.copyWith(
          status: AppConnectivityStatus.offline,
          hasInitialized: true,
          hasNetworkTransport: false,
          transports: results,
          message:
              'Tidak ada koneksi internet. Periksa Wi-Fi atau data seluler Anda.',
          checkedAt: DateTime.now(),
        ),
        reason: reason,
      );
      return;
    }

    _startPeriodicProbe();

    if (!state.hasInitialized) {
      _emitState(
        state.copyWith(
          status: AppConnectivityStatus.checking,
          hasInitialized: false,
          hasNetworkTransport: true,
          transports: results,
          message: 'Memeriksa koneksi internet...',
        ),
        reason: '$reason:checking',
      );
    } else {
      state = state.copyWith(
        hasNetworkTransport: true,
        transports: results,
      );
    }

    await _probeBackendHealth(reason: reason, transports: results);
  }

  void _startPeriodicProbe() {
    _periodicProbeTimer ??= Timer.periodic(_probeInterval, (_) {
      unawaited(
        _probeBackendHealth(
          reason: 'periodic_probe',
          transports: state.transports,
        ),
      );
    });
  }

  void _stopPeriodicProbe() {
    _periodicProbeTimer?.cancel();
    _periodicProbeTimer = null;
  }

  bool _hasNetworkTransport(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> _probeBackendHealth({
    required String reason,
    required List<ConnectivityResult> transports,
  }) async {
    final probeId = ++_activeProbeId;

    try {
      final reachable = await _isBackendReachable();
      if (!mounted || probeId != _activeProbeId) return;

      if (reachable) {
        _emitState(
          state.copyWith(
            status: AppConnectivityStatus.online,
            hasInitialized: true,
            hasNetworkTransport: true,
            transports: transports,
            message: 'Koneksi internet aktif.',
            checkedAt: DateTime.now(),
          ),
          reason: '$reason:online',
        );
        return;
      }

      _emitState(
        state.copyWith(
          status: AppConnectivityStatus.offline,
          hasInitialized: true,
          hasNetworkTransport: true,
          transports: transports,
          message:
              'Koneksi terdeteksi, tetapi server tidak bisa dijangkau saat ini.',
          checkedAt: DateTime.now(),
        ),
        reason: '$reason:health_failed',
      );
    } catch (e) {
      if (!mounted || probeId != _activeProbeId) return;

      _emitState(
        state.copyWith(
          status: AppConnectivityStatus.offline,
          hasInitialized: true,
          hasNetworkTransport: true,
          transports: transports,
          message:
              'Koneksi terdeteksi, tetapi pemeriksaan internet gagal dilakukan.',
          checkedAt: DateTime.now(),
        ),
        reason: '$reason:error',
      );
      debugPrint('[Connectivity] Health probe failed: $e');
    }
  }

  Future<bool> _isBackendReachable() async {
    for (final uri in _buildHealthCheckUris()) {
      try {
        final response = await _healthDio.getUri(uri);
        final statusCode = response.statusCode ?? 0;
        if (statusCode >= 200 && statusCode < 300) {
          return true;
        }
      } on DioException catch (e) {
        debugPrint(
          '[Connectivity] Health probe failed for ${uri.toString()}: '
          '${e.type}',
        );
      } catch (e) {
        debugPrint(
          '[Connectivity] Unexpected health probe error for ${uri.toString()}: '
          '$e',
        );
      }
    }

    return false;
  }

  List<Uri> _buildHealthCheckUris() {
    final baseUri = Uri.parse(_baseUrl);
    final basePath = _trimTrailingSlash(baseUri.path);
    final candidates = <Uri>[
      baseUri.replace(
        path: '/health',
        query: null,
        fragment: null,
      ),
      if (basePath.isNotEmpty)
        baseUri.replace(
          path: _joinUrlPath(basePath, 'health'),
          query: null,
          fragment: null,
        ),
    ];

    final seen = <String>{};
    return candidates.where((uri) => seen.add(uri.toString())).toList();
  }

  String _trimTrailingSlash(String value) {
    if (value.length <= 1) return value;
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  String _joinUrlPath(String basePath, String segment) {
    if (basePath.isEmpty || basePath == '/') {
      return '/$segment';
    }
    final normalizedBase = basePath.startsWith('/') ? basePath : '/$basePath';
    return '$normalizedBase/$segment';
  }

  void _emitState(AppConnectivityState nextState, {required String reason}) {
    final previousState = state;
    state = nextState;

    if (previousState.status != nextState.status ||
        previousState.message != nextState.message ||
        previousState.hasNetworkTransport != nextState.hasNetworkTransport) {
      debugPrint(
        '[Connectivity] status=${nextState.status.name} '
        'transport=${nextState.hasNetworkTransport} reason=$reason '
        'message="${nextState.message}"',
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _stopPeriodicProbe();
    _healthDio.close(force: true);
    super.dispose();
  }
}
