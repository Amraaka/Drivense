import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../views/pages/camera/camera_controller_service.dart';
import 'face_detection_service.dart';
import '../../../views/pages/camera/image_converter.dart';
import 'face_box_painter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _cameraService = CameraControllerService();
  final _faceDetectionService = FaceDetectionService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    final frontIndex = _cameras.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    if (frontIndex != -1) {
      _selectedCameraIndex = frontIndex;
    }
    await _cameraService.initializeController(
      _cameras[_selectedCameraIndex],
      onImage: _processCameraImage,
    );
    if (mounted) setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;
    final inputImage = convertToInputImage(
      image,
      _cameras[_selectedCameraIndex],
      defaultTargetPlatform,
    );
    if (inputImage != null) {
      await _faceDetectionService.processImage(inputImage);
      if (_faceDetectionService.isEyeClosedTooLong) {
        await _audioPlayer.play(AssetSource('assets/audio/warning.mp3'));
      }
      setState(() {});
    }
    _isDetecting = false;
  }

  void _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _cameraService.initializeController(
      _cameras[_selectedCameraIndex],
      onImage: _processCameraImage,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _faceDetectionService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio:
                  controller.value.previewSize!.height /
                  controller.value.previewSize!.width,
              child: CameraPreview(controller),
            ),
          ),
          if (_faceDetectionService.detectedFaceBox != null)
            CustomPaint(
              painter: FaceBoxPainter(
                box: _faceDetectionService.detectedFaceBox!,
                imageSize: controller.value.previewSize!,
                cameraLensDirection: controller.description.lensDirection,
              ),
            ),
          _buildMessageOverlay(),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF000000),
                size: 30,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              // child: ElevatedButton.icon(
              //   onPressed: _switchCamera,
              //   icon: const Icon(Icons.switch_camera),
              //   label: const Text('Switch Camera'),
              // ),
              child: ElevatedButton(
                onPressed: () async {
                  await _audioPlayer.play(
                    AssetSource('assets/audio/warning.mp3'),
                  );
                  debugPrint('Sound should be playing now');
                },
                child: const Text("Test Sound"),
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
          if (_faceDetectionService.isEyeClosedTooLong)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Drowsiness Alert: Eyes closed for too long!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (_faceDetectionService.detectionMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Notice: ${_faceDetectionService.detectionMessage!}',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.black.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
