import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class FaceBoxPainter extends CustomPainter {
  final Rect box;
  final Size imageSize;
  final CameraLensDirection cameraLensDirection;

  FaceBoxPainter({
    required this.box,
    required this.imageSize,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.lightGreenAccent;

    final scaleX = size.width / imageSize.height;
    final scaleY = size.height / imageSize.width;

    final flippedX = (cameraLensDirection == CameraLensDirection.front)
        ? imageSize.width - box.left - box.width
        : box.left;

    final rect = Rect.fromLTRB(
      flippedX * scaleX,
      box.top * scaleY,
      (flippedX + box.width) * scaleX,
      (box.top + box.height) * scaleY,
    );

    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant FaceBoxPainter oldDelegate) {
    return oldDelegate.box != box || oldDelegate.imageSize != imageSize;
  }
}
