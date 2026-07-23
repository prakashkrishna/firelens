import 'package:flutter/material.dart';

/// A custom [TextEditingController] that highlights JSON syntax in real time
/// using GitHub Dark theme color tokens.
class JsonTextEditingController extends TextEditingController {
  JsonTextEditingController({super.text});

  static final _jsonRegex = RegExp(
    r'("(?:\\.|[^"\\])*")\s*:|("(?:\\.|[^"\\])*")|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)|(\btrue\b|\bfalse\b)|(\bnull\b)|([{}[\]:,])',
    multiLine: true,
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = <TextSpan>[];
    int start = 0;

    for (final match in _jsonRegex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: style,
        ));
      }

      final keyMatch = match.group(1);
      final stringMatch = match.group(2);
      final numberMatch = match.group(3);
      final boolMatch = match.group(4);
      final nullMatch = match.group(5);
      final punctuationMatch = match.group(6);

      if (keyMatch != null) {
        // Key match: e.g. "fieldName":
        spans.add(TextSpan(
          text: keyMatch,
          style: style?.copyWith(color: const Color(0xFF7EE787), fontWeight: FontWeight.bold) ??
              const TextStyle(color: Color(0xFF7EE787), fontWeight: FontWeight.bold),
        ));
        spans.add(TextSpan(
          text: ':',
          style: style?.copyWith(color: const Color(0xFF8B949E)) ??
              const TextStyle(color: Color(0xFF8B949E)),
        ));
      } else if (stringMatch != null) {
        // String value: e.g. "active"
        spans.add(TextSpan(
          text: stringMatch,
          style: style?.copyWith(color: const Color(0xFFA5D6FF)) ??
              const TextStyle(color: Color(0xFFA5D6FF)),
        ));
      } else if (numberMatch != null) {
        // Number value: e.g. 42, 99.99
        spans.add(TextSpan(
          text: numberMatch,
          style: style?.copyWith(color: const Color(0xFF79C0FF)) ??
              const TextStyle(color: Color(0xFF79C0FF)),
        ));
      } else if (boolMatch != null) {
        // Boolean value: e.g. true / false
        spans.add(TextSpan(
          text: boolMatch,
          style: style?.copyWith(color: const Color(0xFFFF7B72), fontWeight: FontWeight.bold) ??
              const TextStyle(color: Color(0xFFFF7B72), fontWeight: FontWeight.bold),
        ));
      } else if (nullMatch != null) {
        // Null value: e.g. null
        spans.add(TextSpan(
          text: nullMatch,
          style: style?.copyWith(color: const Color(0xFFFAA356), fontWeight: FontWeight.bold) ??
              const TextStyle(color: Color(0xFFFAA356), fontWeight: FontWeight.bold),
        ));
      } else if (punctuationMatch != null) {
        // Punctuation: { } [ ] , :
        spans.add(TextSpan(
          text: punctuationMatch,
          style: style?.copyWith(color: const Color(0xFF8B949E)) ??
              const TextStyle(color: Color(0xFF8B949E)),
        ));
      } else {
        spans.add(TextSpan(
          text: match.group(0),
          style: style,
        ));
      }

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }

    return TextSpan(children: spans, style: style);
  }
}
