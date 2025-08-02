import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _startCamera(_selectedCameraIndex);
    }
  }

  void _startCamera(int cameraIndex) {
    final camera = _cameras[cameraIndex];
    _controller = CameraController(camera, ResolutionPreset.medium);
    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {}); // Refresh UI
      }
    }).catchError((e) {
      debugPrint('Error initializing camera: $e');
    });
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _controller?.dispose();
    _startCamera(_selectedCameraIndex);
  }

  @override
  void dispose() {
    _controller?.dispose();
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
          CameraPreview(_controller!),
          Positioned(
            bottom: 0,
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
}
