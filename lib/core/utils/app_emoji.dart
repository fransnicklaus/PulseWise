import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';

final EmojiParser _emojiParser = EmojiParser();

const List<String> appEmojiFontFallback = [
  'Apple Color Emoji',
  'Segoe UI Emoji',
  'Noto Color Emoji',
];

String normalizeEmojiText(String value) {
  if (value.isEmpty) return value;
  return _emojiParser.emojify(value);
}

TextStyle withEmojiFallback(TextStyle style) {
  return style.copyWith(fontFamilyFallback: appEmojiFontFallback);
}
