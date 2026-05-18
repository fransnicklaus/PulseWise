import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double _toolbarHeight = 64;
  static const double _toolbarHeightWithSubtitle = 80;
  static const double _titleFontSize = 24;
  static const double _subtitleFontSize = 16;

  final String title;
  final String? subtitle;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final Color backgroundColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final Widget? action;

  const CustomAppBar(
      {super.key,
      required this.title,
      this.subtitle,
      this.onBackPressed,
      this.showBackButton = true,
      this.backgroundColor = const Color(0xFFE64060),
      this.titleColor = Colors.white,
      this.subtitleColor,
      this.action});

  @override
  Widget build(BuildContext context) {
    final toolbarHeight = _resolveToolbarHeight();

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: Container(
        color: backgroundColor,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: toolbarHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showBackButton)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: onBackPressed ?? () => Navigator.pop(context),
                    ),
                  )
                else
                  const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: showBackButton ? 16 : 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: _titleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          softWrap: true,
                        ),
                        if (_hasSubtitle) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: subtitleColor ?? Colors.white,
                              fontSize: _subtitleFontSize,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (action != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: action!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(_resolveToolbarHeight());

  bool get _hasSubtitle => subtitle != null && subtitle!.trim().isNotEmpty;

  double _resolveToolbarHeight() {
    if (!_hasSubtitle) return _toolbarHeight;

    final textWidth = _estimateTextWidth();
    final titleHeight = _measureTextHeight(
      text: title,
      maxWidth: textWidth,
      style: const TextStyle(
        fontSize: _titleFontSize,
        fontWeight: FontWeight.bold,
      ),
    );
    final subtitleHeight = _measureTextHeight(
      text: subtitle!,
      maxWidth: textWidth,
      style: const TextStyle(
        fontSize: _subtitleFontSize,
      ),
    );

    final contentHeight = titleHeight + 4 + subtitleHeight;
    return contentHeight > _toolbarHeightWithSubtitle - 24
        ? contentHeight + 24
        : _toolbarHeightWithSubtitle;
  }

  double _estimateTextWidth() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    final view = views.isNotEmpty ? views.first : null;
    final logicalWidth =
        view == null ? 360.0 : view.physicalSize.width / view.devicePixelRatio;

    const double leadingWidth = 72;
    const double trailingWidthWithAction = 88;
    const double trailingWidthWithoutAction = 24;
    final reservedWidth = leadingWidth +
        (action != null ? trailingWidthWithAction : trailingWidthWithoutAction);
    final availableWidth = logicalWidth - reservedWidth;

    return availableWidth < 160 ? 160 : availableWidth;
  }

  double _measureTextHeight({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: maxWidth);

    return textPainter.size.height;
  }
}
