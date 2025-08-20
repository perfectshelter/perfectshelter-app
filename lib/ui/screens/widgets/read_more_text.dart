import 'package:ebroker/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class ReadMoreText extends StatefulWidget {
  const ReadMoreText({
    required this.text,
    super.key,
    this.style,
    this.readMoreButtonStyle,
  });
  final String text;

  final TextStyle? style;
  final TextStyle? readMoreButtonStyle;

  @override
  State<ReadMoreText> createState() => _ReadMoreTextState();
}

class _ReadMoreTextState extends State<ReadMoreText> {
  bool showingFullText = false;

  Widget buildReadMore(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: widget.style,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width);

    final numLines = textPainter.computeLineMetrics().length;

    if (numLines > 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            showingFullText ? text : _truncateText(text),
            style: widget.style,
          ),
          TextButton(
            style: const ButtonStyle(
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
              splashFactory: NoSplash.splashFactory,
            ),
            onPressed: () {
              setState(() {
                showingFullText = !showingFullText;
              });
            },
            child: Text(
              showingFullText
                  ? UiUtils.translate(context, 'readLessLbl')
                  : UiUtils.translate(context, 'readMoreLbl'),
              style: widget.readMoreButtonStyle,
            ),
          ),
        ],
      );
    }

    return Text(text, style: widget.style);
  }

  String _truncateText(String text) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: DefaultTextStyle.of(context).style),
      maxLines: 4,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width);

    final endIndex = textPainter
        .getPositionForOffset(
          Offset(MediaQuery.of(context).size.width, double.infinity),
        )
        .offset;

    final truncatedText = text.substring(0, endIndex).trim();
    return truncatedText.length < text.length
        ? '$truncatedText...'
        : truncatedText;
  }

  @override
  Widget build(BuildContext context) {
    return buildReadMore(widget.text);
  }
}
