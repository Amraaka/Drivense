import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

InputImage? convertToInputImage(
    CameraImage image,
    CameraDescription camera,
    TargetPlatform platform,
    ) {
  final rotation = InputImageRotationValue.fromRawValue(
    platform == TargetPlatform.iOS
        ? camera.sensorOrientation
        : (camera.sensorOrientation + 0) % 360,
  );

  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null ||
      (platform == TargetPlatform.android && format != InputImageFormat.nv21) ||
      (platform == TargetPlatform.iOS && format != InputImageFormat.bgra8888)) {
    return null;
  }

  return InputImage.fromBytes(
    bytes: image.planes[0].bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    ),
  );
}
