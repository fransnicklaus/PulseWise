import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
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
    final toolbarHeight = subtitle != null ? 80.0 : 64.0;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: subtitleColor ?? Colors.white,
                              fontSize: 16,
                            ),
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
  Size get preferredSize => Size.fromHeight(subtitle != null ? 80 : 64);
}
