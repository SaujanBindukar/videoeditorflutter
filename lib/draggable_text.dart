import 'package:flutter/material.dart';
import 'package:video_editing_app/overlay_text.dart';

class DraggableText extends StatefulWidget {
  final OverlayText overlay;
  final VoidCallback onUpdate;
  final Size parentSize;

  const DraggableText({
    super.key,
    required this.overlay,
    required this.onUpdate,
    required this.parentSize,
  });

  @override
  State<DraggableText> createState() => _DraggableTextState();
}

class _DraggableTextState extends State<DraggableText> {
  final GlobalKey _textKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final renderBox =
            _textKey.currentContext?.findRenderObject() as RenderBox?;
        final textSize = renderBox?.size ?? Size.zero;

        double newX = widget.overlay.position.dx + details.delta.dx;
        double newY = widget.overlay.position.dy + details.delta.dy;

        newX = newX.clamp(0.0, widget.parentSize.width - textSize.width);
        newY = newY.clamp(0.0, widget.parentSize.height - textSize.height);

        setState(() {
          widget.overlay.position = Offset(newX, newY);
          widget.onUpdate();
        });
      },
      child: Text(
        key: _textKey,
        widget.overlay.text,
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.overlay.fontSize,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
          ],
        ),
      ),
    );
  }
}
