import 'dart:async';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/material.dart';

class FaceDetectionService {
  final FaceDetector _faceDetector;
  Rect? detectedFaceBox;
  String? detectionMessage;
  bool isEyeClosedTooLong = false;
  Timer? _eyeClosureTimer;

  FaceDetectionService()
      : _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<void> processImage(InputImage inputImage) async {
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      _clear();
    } else {
      final face = faces.first;
      detectedFaceBox = face.boundingBox;
      _detectHeadMovement(face);
      _detectEyeClosure(face);
    }
  }

  void _detectHeadMovement(Face face) {
    const threshold = 10.0;
    final rotY = face.headEulerAngleY;
    final rotX = face.headEulerAngleX;

    String message = '';
    if (rotY != null && rotX != null) {
      if (rotY > threshold) {
        message = "Looking Right";
      } else if (rotY < -threshold) {
        message = "Looking Left";
      } else if (rotX > threshold) {
        message = "Looking Up";
      } else if (rotX < -threshold) {
        message = "Looking Down";
      }
    }

    detectionMessage = message.isNotEmpty ? message : null;
  }

  void _detectEyeClosure(Face face) {
    const threshold = 0.4;
    final leftProb = face.leftEyeOpenProbability;
    final rightProb = face.rightEyeOpenProbability;

    final bothClosed = leftProb != null &&
        leftProb < threshold &&
        rightProb != null &&
        rightProb < threshold;

    if (bothClosed) {
      if (_eyeClosureTimer == null || !_eyeClosureTimer!.isActive) {
        _eyeClosureTimer = Timer(const Duration(seconds: 3), () {
          isEyeClosedTooLong = true;
        });
      }
    } else {
      _eyeClosureTimer?.cancel();
      isEyeClosedTooLong = false;
    }
  }

  void _clear() {
    detectedFaceBox = null;
    detectionMessage = null;
  }

  void dispose() {
    _faceDetector.close();
    _eyeClosureTimer?.cancel();
  }
}
