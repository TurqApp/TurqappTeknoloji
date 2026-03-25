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
  static const double _captureButtonSize = 84;
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
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.24),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.44),
                            ],
                            stops: const [0.0, 0.18, 0.64, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _topControlButton(
                      icon: CupertinoIcons.xmark,
                      onPressed: () => Get.back(),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _topControlButton(
                      icon: CupertinoIcons.refresh,
                      onPressed: _toggleLens,
                    ),
                  ),
                  Positioned(
                    bottom: 164,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Text(
                          _mode == ChatCameraMode.photo
                              ? 'chat.camera.capture'.tr
                              : (_isRecording
                                  ? 'chat.camera.recording'
                                      .trParams({'seconds': '$_recordSec'})
                                  : 'chat.camera.video_max'.tr),
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
                    bottom: 38,
                    left: 18,
                    right: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _modeButton(
                              icon: CupertinoIcons.photo,
                              text: 'Fotoğraf',
                              value: ChatCameraMode.photo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () async {
                              if (_mode == ChatCameraMode.photo) {
                                await _takePhoto();
                              } else if (_isRecording) {
                                await _stopVideo();
                              } else {
                                await _startVideo();
                              }
                            },
                            child: Container(
                              width: _captureButtonSize,
                              height: _captureButtonSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  width: 3.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: _isRecording ? 30 : 58,
                                  height: _isRecording ? 30 : 58,
                                  decoration: BoxDecoration(
                                    color: _isRecording
                                        ? const Color(0xFFE63A3A)
                                        : Colors.white,
                                    shape: _isRecording
                                        ? BoxShape.rectangle
                                        : BoxShape.circle,
                                    borderRadius: _isRecording
                                        ? BorderRadius.circular(10)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _modeButton(
                              icon: CupertinoIcons.video_camera_solid,
                              text: 'Video',
                              value: ChatCameraMode.video,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : const Center(
                child: CupertinoActivityIndicator(color: Colors.white)),
      ),
    );
  }

  Widget _topControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _modeButton({
    required IconData icon,
    required String text,
    required ChatCameraMode value,
  }) {
    final selected = _mode == value;
    return GestureDetector(
      onTap: () {
        if (_isRecording) return;
        setState(() => _mode = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: "MontserratBold",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
