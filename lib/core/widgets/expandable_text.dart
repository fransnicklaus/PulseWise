import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  const ExpandableText({
    super.key,
    required this.content,
    this.collapsedMaxLines = 3,
    this.expandLabel = 'Lihat detail',
    this.collapseLabel = 'Sembunyikan',
    this.textAlign = TextAlign.start,
    this.toggleStyle,
  });

  final InlineSpan content;
  final int collapsedMaxLines;
  final String expandLabel;
  final String collapseLabel;
  final TextAlign textAlign;
  final TextStyle? toggleStyle;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant ExpandableText oldWidget) {
    super.didUpdateWidget(oldWidget);

    final previousContent = oldWidget.content.toPlainText();
    final nextContent = widget.content.toPlainText();
    if (previousContent != nextContent && _isExpanded) {
      _isExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultToggleStyle = widget.toggleStyle ??
        const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE64060),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: widget.content,
          textAlign: widget.textAlign,
          textDirection: Directionality.of(context),
          maxLines: widget.collapsedMaxLines,
        )..layout(maxWidth: constraints.maxWidth);

        final hasOverflow = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              widget.content,
              textAlign: widget.textAlign,
              maxLines: _isExpanded ? null : widget.collapsedMaxLines,
              softWrap: true,
              overflow:
                  _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (hasOverflow || _isExpanded)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(top: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _isExpanded ? widget.collapseLabel : widget.expandLabel,
                    style: defaultToggleStyle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
