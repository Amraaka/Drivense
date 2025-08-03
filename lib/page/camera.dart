import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isDetecting = false;
  String? _detectionMessage;

  // Face Detector
  late final FaceDetector _faceDetector;

  // Timer for eye closure
  Timer? _eyeClosureTimer;
  bool _isEyeClosureWarningActive = false;
  final int _eyeClosureDurationThreshold = 3;

  // Detected face data
  Rect? _faceBoundingBox;

  @override
  void initState() {
    super.initState();
    // Initialize the FaceDetector
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true, // To detect eye closure
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    // Use the front camera if available
    final frontCameraIndex = _cameras.indexWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front);
    if (frontCameraIndex != -1) {
      _selectedCameraIndex = frontCameraIndex;
    }

    if (_cameras.isNotEmpty) {
      _startCamera(_selectedCameraIndex);
    }
  }

  void _startCamera(int cameraIndex) {
    if (_controller != null) {
      _controller!.dispose();
    }

    final camera = _cameras[cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    _controller!.initialize().then((_) {
      if (mounted) {
        // Start streaming images for face detection
        _controller!.startImageStream(_processCameraImage);
        setState(() {});
      }
    }).catchError((e) {
      debugPrint('Error initializing camera: $e');
    });
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _startCamera(_selectedCameraIndex);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _clearDetectionData();
      } else {
        // We are interested in the first detected face
        final face = faces.first;
        _faceBoundingBox = face.boundingBox;

        // --- Head Movement Detection ---
        _handleHeadMovement(face);

        // --- Eye Closure Detection ---
        _handleEyeClosure(face);
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    }

    _isDetecting = false;
  }

  void _handleHeadMovement(Face face) {
    const double headTurnThreshold = 10.0; // degrees
    final double? rotY = face.headEulerAngleY; // Head is rotated to the right (positive) or left (negative)
    final double? rotX = face.headEulerAngleX; // Head is tilted up (negative) or down (positive)

    String message = "";
    if (rotY != null && rotX != null) {
      if (rotY > headTurnThreshold) {
        message = "Looking Right";
      } else if (rotY < -headTurnThreshold) {
        message = "Looking Left";
      } else if (rotX > headTurnThreshold) {
        message = "Looking Up";
      } else if (rotX < -headTurnThreshold) {
        message = "Looking Down";
      }
    }
    _detectionMessage = message.isNotEmpty ? message : null;
  }


  void _handleEyeClosure(Face face) {
    const double eyeOpenProbabilityThreshold = 0.4;
    final double? leftEyeOpenProb = face.leftEyeOpenProbability;
    final double? rightEyeOpenProb = face.rightEyeOpenProbability;

    if (leftEyeOpenProb != null &&
        leftEyeOpenProb < eyeOpenProbabilityThreshold &&
        rightEyeOpenProb != null &&
        rightEyeOpenProb < eyeOpenProbabilityThreshold) {
      // Both eyes are closed
      if (_eyeClosureTimer == null || !_eyeClosureTimer!.isActive) {
        _eyeClosureTimer = Timer(Duration(seconds: _eyeClosureDurationThreshold), () {
          setState(() {
            _isEyeClosureWarningActive = true;
          });
        });
      }
    } else {
      // At least one eye is open, cancel timer
      _eyeClosureTimer?.cancel();
      if (_isEyeClosureWarningActive) {
        setState(() {
          _isEyeClosureWarningActive = false;
        });
      }
    }
  }

  void _clearDetectionData() {
    if (mounted && (_faceBoundingBox != null || _detectionMessage != null)) {
      setState(() {
        _faceBoundingBox = null;
        _detectionMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _faceDetector.close();
    _eyeClosureTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.previewSize!.height / _controller!.value.previewSize!.width,
              child: CameraPreview(_controller!),
            ),
          ),
          if (_faceBoundingBox != null)
            CustomPaint(
              painter: FaceBoxPainter(
                box: _faceBoundingBox!,
                imageSize: _controller!.value.previewSize!,
                cameraLensDirection: _controller!.description.lensDirection,
              ),
            ),
          _buildMessageOverlay(),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _switchCamera,
                icon: const Icon(Icons.switch_camera),
                label: const Text('Switch Camera'),
              ),
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildMessageOverlay() {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Column(
        children: [
          if (_isEyeClosureWarningActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Drowsiness Alert: Eyes closed for too long!',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          if (_detectionMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Notice: $_detectionMessage',
                style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    backgroundColor: Colors.black.withOpacity(0.5)
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // Helper function to convert CameraImage to InputImage
// Helper function to convert CameraImage to InputImage
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameras[_selectedCameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // For iOS, the rotation is the same as the sensor orientation
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // For Android, the rotation is relative to the device's natural orientation
      var rotationCompensation = 0; // This may need to be adjusted based on device orientation
      rotation = InputImageRotationValue.fromRawValue((sensorOrientation + rotationCompensation) % 360);
    }

    if (rotation == null) {
      debugPrint('Could not determine image rotation.');
      return null;
    }

    // Get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    // Validate format
    if (format == null ||
        (defaultTargetPlatform == TargetPlatform.android && format != InputImageFormat.nv21) ||
        (defaultTargetPlatform == TargetPlatform.iOS && format != InputImageFormat.bgra8888)) {
      debugPrint('Unsupported image format: ${image.format.group}');
      return null;
    }

    // Create InputImage from bytes
    return InputImage.fromBytes(
      bytes: image.planes[0].bytes, // For both NV21 and BGRA8888, the data is in the first plane
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }
}

// Custom Painter to draw the bounding box on the screen
class FaceBoxPainter extends CustomPainter {
  final Rect box;
  final Size imageSize;
  final CameraLensDirection cameraLensDirection;

  FaceBoxPainter({
    required this.box,
    required this.imageSize,
    this.cameraLensDirection = CameraLensDirection.back,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreenAccent;

    // Scale coordinates from image size to screen size
    final double scaleX = size.width / imageSize.height;
    final double scaleY = size.height / imageSize.width;

    // Invert the x-coordinate for front camera
    final double flippedX = (cameraLensDirection == CameraLensDirection.front)
        ? imageSize.width - box.left - box.width
        : box.left;

    final Rect scaledBox = Rect.fromLTRB(
      flippedX * scaleX,
      box.top * scaleY,
      (flippedX + box.width) * scaleX,
      (box.top + box.height) * scaleY,
    );

    canvas.drawRect(scaledBox, paint);
  }

  @override
  bool shouldRepaint(FaceBoxPainter oldDelegate) {
    return oldDelegate.box != box || oldDelegate.imageSize != imageSize;
  }
}