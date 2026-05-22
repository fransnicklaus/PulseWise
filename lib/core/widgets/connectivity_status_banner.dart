import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/app_connectivity_provider.dart';

class ConnectivityStatusBanner extends ConsumerWidget {
  const ConnectivityStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appConnectivityProvider);
    final shouldShow = state.hasInitialized && state.isOffline;

    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: shouldShow
              ? Padding(
                  key: const ValueKey('offline_banner'),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _OfflineBannerCard(
                    hasNetworkTransport: state.hasNetworkTransport,
                    message: state.message,
                  ),
                )
              : const SizedBox.shrink(
                  key: ValueKey('offline_banner_hidden'),
                ),
        ),
      ),
    );
  }
}

class _OfflineBannerCard extends StatelessWidget {
  const _OfflineBannerCard({
    required this.hasNetworkTransport,
    required this.message,
  });

  final bool hasNetworkTransport;
  final String message;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        hasNetworkTransport ? const Color(0xFFB45309) : const Color(0xFFB91C1C);
    final icon =
        hasNetworkTransport ? Icons.cloud_off_rounded : Icons.wifi_off_rounded;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
