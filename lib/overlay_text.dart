import 'dart:ui';

class OverlayText {
  String text;
  Offset position;
  double fontSize;

  OverlayText({
    required this.text,
    this.position = const Offset(50, 50),
    this.fontSize = 24,
  });
}
