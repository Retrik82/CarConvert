import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

import '../models/hint_response.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import '../widgets/hint_overlay.dart';
import 'processing_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final _ws = WebSocketService();
  HintResponse? _hint;
  String _status = 'Инициализация...';
  String? _sessionId;
  bool _capturing = false;
  Timer? _frameTimer;
  StreamSubscription? _hintSub;
  StreamSubscription? _statusSub;
  bool _streaming = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      setState(() => _status = 'Нет доступа к камере');
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _status = 'Камера не найдена');
      return;
    }

    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(back, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (!mounted) return;

    try {
      _sessionId = await ApiService.instance.startSession();
      await _ws.connect(
        sessionId: _sessionId!,
        token: AuthService.instance.accessToken!,
      );
      _hintSub = _ws.hints.listen((h) {
        if (mounted) setState(() => _hint = h);
      });
      _statusSub = _ws.status.listen((s) {
        if (mounted) setState(() => _status = s);
      });
      _startFrameLoop();
    } catch (e) {
      setState(() => _status = 'Ошибка: $e');
    }

    if (mounted) setState(() {});
  }

  void _startFrameLoop() {
    _frameTimer?.cancel();
    _streaming = true;
    _frameTimer = Timer.periodic(const Duration(milliseconds: 450), (_) => _sendPreviewFrame());
  }

  Future<void> _sendPreviewFrame() async {
    if (!_streaming || _controller == null || !_controller!.value.isInitialized) return;
    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      final compressed = _compressFrame(bytes);
      _ws.sendFrame(base64Encode(compressed));
    } catch (_) {}
  }

  Uint8List _compressFrame(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final resized = img.copyResize(decoded, width: 640);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 65));
  }

  Future<void> _capture() async {
    if (_controller == null || _capturing) return;
    setState(() => _capturing = true);
    _streaming = false;
    _frameTimer?.cancel();

    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(
            imageBytes: bytes,
            sessionId: _sessionId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка съёмки: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
        _startFrameLoop();
      }
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _hintSub?.cancel();
    _statusSub?.cancel();
    _ws.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller?.value.isInitialized ?? false;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            CameraPreview(_controller!)
          else
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
          CameraHintOverlay(hint: _hint, status: _status),
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _capturing ? null : _capture,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hint?.isPerfect == true ? Colors.greenAccent : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
