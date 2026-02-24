import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ChatCameraMode { photo, video }

class ChatCameraCaptureResult {
  final File file;
  final ChatCameraMode mode;

  ChatCameraCaptureResult({
    required this.file,
    required this.mode,
  });
}

class ChatCameraCaptureView extends StatefulWidget {
  const ChatCameraCaptureView({super.key});

  @override
  State<ChatCameraCaptureView> createState() => _ChatCameraCaptureViewState();
}

class _ChatCameraCaptureViewState extends State<ChatCameraCaptureView> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _selectedCameraIndex = 0;
  ChatCameraMode _mode = ChatCameraMode.photo;
  bool _isRecording = false;
  int _recordSec = 0;
  Timer? _recordTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) Get.back();
        return;
      }

      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex < 0) _selectedCameraIndex = 0;

      await _createController();
    } catch (_) {
      if (mounted) Get.back();
    }
  }

  Future<void> _createController() async {
    final old = _controller;
    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _controller!.initialize();
    await old?.dispose();
    if (mounted) setState(() {});
  }

  Future<void> _toggleLens() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _createController();
  }

  Future<void> _takePhoto() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    final file = await c.takePicture();
    if (!mounted) return;
    Get.back(
      result: ChatCameraCaptureResult(
        file: File(file.path),
        mode: ChatCameraMode.photo,
      ),
    );
  }

  Future<void> _startVideo() async {
    final c = _controller;
    if (c == null ||
        !c.value.isInitialized ||
        c.value.isRecordingVideo ||
        _isRecording) {
      return;
    }
    await c.startVideoRecording();
    _isRecording = true;
    _recordSec = 0;
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _recordSec++;
      if (mounted) setState(() {});
      if (_recordSec >= 60) {
        await _stopVideo();
      }
    });
    if (mounted) setState(() {});
  }

  Future<void> _stopVideo() async {
    final c = _controller;
    if (c == null || !c.value.isRecordingVideo) return;
    final file = await c.stopVideoRecording();
    _recordTimer?.cancel();
    _recordTimer = null;
    _isRecording = false;
    _recordSec = 0;
    if (!mounted) return;
    Get.back(
      result: ChatCameraCaptureResult(
        file: File(file.path),
        mode: ChatCameraMode.video,
      ),
    );
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ready
            ? Stack(
                children: [
                  Positioned.fill(
                    child: CameraPreview(c),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      onPressed: _toggleLens,
                      icon: const Icon(
                        CupertinoIcons.refresh_circled_solid,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 130,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _mode == ChatCameraMode.photo
                              ? "Yakala"
                              : (_isRecording
                                  ? "Kayıt: ${_recordSec}s / 60s"
                                  : "Video (Maks. 1 dk)"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _modeButton("YAKALA", ChatCameraMode.photo),
                        const SizedBox(width: 18),
                        GestureDetector(
                          onTap: () async {
                            if (_mode == ChatCameraMode.photo) {
                              await _takePhoto();
                            } else {
                              if (_isRecording) {
                                await _stopVideo();
                              } else {
                                await _startVideo();
                              }
                            }
                          },
                          child: Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording
                                  ? Colors.red
                                  : Colors.white.withValues(alpha: 0.9),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        _modeButton("VIDEO", ChatCameraMode.video),
                      ],
                    ),
                  ),
                ],
              )
            : const Center(child: CupertinoActivityIndicator(color: Colors.white)),
      ),
    );
  }

  Widget _modeButton(String text, ChatCameraMode value) {
    final selected = _mode == value;
    return GestureDetector(
      onTap: () {
        if (_isRecording) return;
        setState(() => _mode = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: "MontserratBold",
          ),
        ),
      ),
    );
  }
}

