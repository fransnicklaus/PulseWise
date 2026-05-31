import 'package:flutter/material.dart';

enum NoConnectionStateVariant {
  compact,
  card,
  page,
}

class NoConnectionState extends StatelessWidget {
  const NoConnectionState({
    super.key,
    this.variant = NoConnectionStateVariant.card,
    this.title = 'Tidak ada koneksi internet',
    this.message =
        'Kami belum bisa memuat data. Pastikan Wi-Fi atau data seluler Anda aktif, lalu coba lagi.',
    this.retryLabel = 'Coba Lagi',
    this.onRetry,
  });

  const NoConnectionState.compact({
    super.key,
    this.title = 'Koneksi terputus',
    this.message =
        'Data belum bisa dimuat. Sambungkan internet lalu coba lagi.',
    this.retryLabel = 'Coba Lagi',
    this.onRetry,
  }) : variant = NoConnectionStateVariant.compact;

  const NoConnectionState.card({
    super.key,
    this.title = 'Tidak ada koneksi internet',
    this.message =
        'Kami belum bisa memuat data. Periksa jaringan Anda lalu coba lagi.',
    this.retryLabel = 'Coba Lagi',
    this.onRetry,
  }) : variant = NoConnectionStateVariant.card;

  const NoConnectionState.page({
    super.key,
    this.title = 'Tidak ada koneksi internet',
    this.message =
        'Kami belum bisa terhubung ke server. Periksa Wi-Fi atau data seluler Anda, lalu coba lagi.',
    this.retryLabel = 'Coba Lagi',
    this.onRetry,
  }) : variant = NoConnectionStateVariant.page;

  final NoConnectionStateVariant variant;
  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  static const _accent = Color(0xFFE64060);
  static const _accentSoft = Color(0xFFFFEDF1);
  static const _border = Color(0xFFE2E8F0);
  static const _text = Color(0xFF0F172A);
  static const _subtext = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case NoConnectionStateVariant.compact:
        return _CompactNoConnectionState(
          title: title,
          message: message,
          retryLabel: retryLabel,
          onRetry: onRetry,
        );
      case NoConnectionStateVariant.card:
        return _CardNoConnectionState(
          title: title,
          message: message,
          retryLabel: retryLabel,
          onRetry: onRetry,
        );
      case NoConnectionStateVariant.page:
        return _PageNoConnectionState(
          title: title,
          message: message,
          retryLabel: retryLabel,
          onRetry: onRetry,
        );
    }
  }
}

class _CompactNoConnectionState extends StatelessWidget {
  const _CompactNoConnectionState({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackAction = constraints.maxWidth < 350;
        final content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _NoConnectionIconBadge(size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: NoConnectionState._text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: NoConnectionState._subtext,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final action = onRetry == null
            ? null
            : OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: NoConnectionState._accent,
                  side: const BorderSide(color: NoConnectionState._accent),
                  minimumSize: const Size(0, 42),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  retryLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _stateDecoration(),
          child: stackAction
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                    if (action != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(width: double.infinity, child: action),
                    ],
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: content),
                    if (action != null) ...[
                      const SizedBox(width: 12),
                      action,
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _CardNoConnectionState extends StatelessWidget {
  const _CardNoConnectionState({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _stateDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _NoConnectionIconBadge(size: 72, showOfflinePill: true),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: NoConnectionState._text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          // Text(
          //   message,
          //   textAlign: TextAlign.center,
          //   style: const TextStyle(
          //     color: NoConnectionState._subtext,
          //     fontSize: 14,
          //     fontWeight: FontWeight.w600,
          //     height: 1.5,
          //   ),
          // ),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: NoConnectionState._accent,
                  side: const BorderSide(color: NoConnectionState._accent),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  retryLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PageNoConnectionState extends StatelessWidget {
  const _PageNoConnectionState({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen =
            constraints.maxWidth < 360 || constraints.maxHeight < 540;
        final padding = isSmallScreen ? 22.0 : 28.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(padding),
              decoration: _stateDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NoConnectionIconBadge(
                    size: isSmallScreen ? 82 : 92,
                    showOfflinePill: true,
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: NoConnectionState._text,
                      fontSize: isSmallScreen ? 22 : 24,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: NoConnectionState._subtext,
                      fontSize: isSmallScreen ? 15 : 16,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: NoConnectionState._border),
                    ),
                    child: const Text(
                      'Tips: pastikan mode pesawat mati, lalu cek Wi-Fi atau data seluler sebelum mencoba lagi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: NoConnectionState._subtext,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NoConnectionState._accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: Text(
                          retryLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoConnectionIconBadge extends StatelessWidget {
  const _NoConnectionIconBadge({
    required this.size,
    this.showOfflinePill = false,
  });

  final double size;
  final bool showOfflinePill;

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = size * 0.58;
    final iconSize = size * 0.3;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: NoConnectionState._accentSoft,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.22),
            border: Border.all(color: const Color(0xFFFBCFE8)),
          ),
          child: Icon(
            Icons.wifi_off_rounded,
            color: NoConnectionState._accent,
            size: iconSize,
          ),
        ),
        if (showOfflinePill)
          Positioned(
            bottom: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Offline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

BoxDecoration _stateDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: NoConnectionState._border),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.05),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
