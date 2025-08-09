import 'package:camera/camera.dart';

class CameraControllerService {
  CameraController? _controller;

  CameraController? get controller => _controller;

  Future<void> initializeController(
      CameraDescription camera, {
        required Function(CameraImage) onImage,
      }) async {
    _controller?.dispose();

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _controller!.initialize();
    await _controller!.startImageStream(onImage);
  }

  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
  }
}
