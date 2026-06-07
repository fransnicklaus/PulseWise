import 'package:flutter/material.dart';
import 'package:pulsewise/core/constants/wellness_disclaimer.dart';

class WellnessDisclaimerCard extends StatefulWidget {
  const WellnessDisclaimerCard({
    super.key,
    required this.title,
    this.caption,
    this.margin,
    this.icon = Icons.info_outline_rounded,
    this.badgeLabel,
    this.bodyText,
    this.isExpandable = false,
    this.initiallyExpanded = true,
    this.compact = false,
    this.expandLabel = 'Lihat detail',
    this.collapseLabel = 'Sembunyikan',
  });

  final String title;
  final String? caption;
  final EdgeInsetsGeometry? margin;
  final IconData icon;
  final String? badgeLabel;
  final String? bodyText;
  final bool isExpandable;
  final bool initiallyExpanded;
  final bool compact;
  final String expandLabel;
  final String collapseLabel;

  @override
  State<WellnessDisclaimerCard> createState() => _WellnessDisclaimerCardState();
}

class _WellnessDisclaimerCardState extends State<WellnessDisclaimerCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpandable ? widget.initiallyExpanded : true;
  }

  @override
  void didUpdateWidget(covariant WellnessDisclaimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isExpandable && !_isExpanded) {
      _isExpanded = true;
    }
  }

  void _toggleExpanded() {
    if (!widget.isExpandable) return;
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final bodyText = (widget.bodyText ?? wellnessDisclaimerText).trim();
    final hasCaption =
        widget.caption != null && widget.caption!.trim().isNotEmpty;
    final hasBadge =
        widget.badgeLabel != null && widget.badgeLabel!.trim().isNotEmpty;
    final showBody = !widget.isExpandable || _isExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: widget.margin,
      padding: EdgeInsets.all(compact ? 16 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFCF0),
            Color(0xFFFFF6DB),
            Color(0xFFFFF1CC),
          ],
        ),
        border: Border.all(color: const Color(0xFFF7D774)),
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14B45309),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasBadge) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 6 : 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFB45309),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.badgeLabel!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
          ],
          InkWell(
            onTap: widget.isExpandable ? _toggleExpanded : null,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: compact ? 40 : 54,
                  height: compact ? 40 : 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(compact ? 14 : 18),
                    border: Border.all(color: const Color(0xFFF4D47A)),
                  ),
                  child: Icon(
                    widget.icon,
                    color: const Color(0xFFB45309),
                    size: compact ? 22 : 28,
                  ),
                ),
                SizedBox(width: compact ? 12 : 14),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: const Color(0xFF7C2D12),
                      fontSize: compact ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
                Center(
                  child: AnimatedRotation(
                    turns: showBody ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF9A3412),
                      size: compact ? 25 : 29,
                    ),
                  ),
                ),
                // InkWell(
                //   onTap: _toggleExpanded,
                //   borderRadius: BorderRadius.circular(16),
                //   child: Padding(
                //     padding: const EdgeInsets.symmetric(vertical: 4),
                //     child:
                //   ),
                // ),
                // Expanded(
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [

                //       if (hasCaption) ...[
                //         SizedBox(height: compact ? 6 : 14),
                //         Text(
                //           widget.caption!,
                //           style: TextStyle(
                //             color: const Color(0xFF8A4B12),
                //             fontSize: compact ? 13 : 15,
                //             fontWeight: FontWeight.w500,
                //             height: 1.5,
                //           ),
                //         ),
                //       ],
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
          // if (widget.isExpandable) ...[
          //   // SizedBox(height: compact ? 8 : 12),
          //   // InkWell(
          //   //   onTap: _toggleExpanded,
          //   //   borderRadius: BorderRadius.circular(16),
          //   //   child: Padding(
          //   //     padding: const EdgeInsets.symmetric(vertical: 4),
          //   //     child: Row(
          //   //       children: [
          //   //         Text(
          //   //           _isExpanded ? widget.collapseLabel : widget.expandLabel,
          //   //           style: TextStyle(
          //   //             color: const Color(0xFF9A3412),
          //   //             fontSize: compact ? 13 : 14,
          //   //             fontWeight: FontWeight.w700,
          //   //           ),
          //   //         ),
          //   //         const Spacer(),
          //   //         Icon(
          //   //           _isExpanded
          //   //               ? Icons.keyboard_arrow_up_rounded
          //   //               : Icons.keyboard_arrow_down_rounded,
          //   //           color: const Color(0xFF9A3412),
          //   //           size: compact ? 20 : 22,
          //   //         ),
          //   //       ],
          //   //     ),
          //   //   ),
          //   // ),
          // ],
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            // crossFadeState:
            //     showBody ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            // firstChild: const SizedBox.shrink(),
            curve: Curves.easeInOut,
            child: showBody
                ? Padding(
                    padding: EdgeInsets.only(top: compact ? 10 : 16),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(compact ? 14 : 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(compact ? 16 : 20),
                        border: Border.all(color: const Color(0xFFF2DF9E)),
                      ),
                      child: Text(
                        bodyText,
                        style: TextStyle(
                          color: const Color(0xFF6B3E0B),
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          height: 1.65,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
