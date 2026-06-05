import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/hint_response.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_utils.dart';
import '../utils/frame_crop.dart';
import '../utils/money_format.dart';
import '../widgets/capture_hint_overlay.dart';
import 'processing_screen.dart';

enum CaptureMode { camera, gallery }

class CaptureScreen extends StatefulWidget {
  final VoidCallback? onBalanceChanged;
  final String? carId;
  final bool isActive;
  final CaptureMode initialMode;

  const CaptureScreen({
    super.key,
    this.onBalanceChanged,
    this.carId,
    this.isActive = true,
    this.initialMode = CaptureMode.camera,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _controller;
  final _ws = WebSocketService();
  final _picker = ImagePicker();
  HintResponse? _hint;
  String _status = 'Initializing...';
  String? _sessionId;
  bool _capturing = false;
  Timer? _frameTimer;
  StreamSubscription? _hintSub;
  StreamSubscription? _statusSub;
  bool _streaming = false;
  double _generationPrice = 0.10;
  CaptureMode _mode = CaptureMode.camera;
  Uint8List? _galleryPreview;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (_mode == CaptureMode.camera) {
      _initCamera();
    }
    _loadBilling();
  }

  @override
  void didUpdateWidget(CaptureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _resumeCapture();
      } else {
        _pauseCapture();
      }
    }
  }

  Future<void> _pauseCapture() async {
    _stopFrameLoop();
    await _ws.disconnect();
  }

  Future<void> _resumeCapture() async {
    if (_mode != CaptureMode.camera) return;
    final token = AuthService.instance.accessToken;
    if (token != null && _sessionId != null) {
      try {
        await _ws.connect(sessionId: _sessionId!, token: token);
      } catch (_) {}
    }
    _startFrameLoop();
  }

  Future<void> _loadBilling() async {
    try {
      await AuthService.instance.refreshCurrentUser();
      _generationPrice = await ApiService.instance.getGenerationPrice();
      widget.onBalanceChanged?.call();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      setState(() => _status = 'Camera permission denied');
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _status = 'No camera found');
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
      final token = AuthService.instance.accessToken;
      if (token == null) {
        setState(() => _status = 'Authentication required');
        return;
      }
      await _ws.connect(
        sessionId: _sessionId!,
        token: token,
      );
      _hintSub = _ws.hints.listen((h) {
        if (mounted) setState(() => _hint = h);
      });
      _statusSub = _ws.status.listen((s) {
        if (mounted) setState(() => _status = s);
      });
      if (widget.isActive) _startFrameLoop();
    } catch (e) {
      setState(() => _status = userFacingError(e));
    }

    if (mounted) setState(() {});
  }

  void _startFrameLoop() {
    if (_mode != CaptureMode.camera || !widget.isActive) return;
    _frameTimer?.cancel();
    _streaming = true;
    _frameTimer = Timer.periodic(const Duration(milliseconds: 450), (_) => _sendPreviewFrame());
  }

  void _stopFrameLoop() {
    _streaming = false;
    _frameTimer?.cancel();
  }

  Future<void> _sendPreviewFrame() async {
    if (!_streaming || _controller == null || !_controller!.value.isInitialized) return;
    XFile? file;
    try {
      file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      final compressed = _compressFrame(bytes);
      _ws.sendFrame(base64Encode(compressed));
    } catch (_) {} finally {
      if (file != null) {
        try {
          await File(file.path).delete();
        } catch (_) {}
      }
    }
  }

  Uint8List _compressFrame(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final resized = img.copyResize(decoded, width: 640);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 65));
  }

  bool _checkBalance() {
    final user = AuthService.instance.currentUser;
    if (user != null && user.balance < _generationPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance. Need ${MoneyFormat.usd(_generationPrice)}, '
            'available ${MoneyFormat.usd(user.balance)}',
          ),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _processBytes(Uint8List bytes) async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          imageBytes: bytes,
          sessionId: _sessionId,
          carId: widget.carId,
          onCharged: _loadBilling,
        ),
      ),
    ).then((_) => _loadBilling());
  }

  Future<void> _takePhoto() async {
    if (_controller == null || _capturing) return;
    if (!_checkBalance()) return;

    setState(() => _capturing = true);
    _stopFrameLoop();

    try {
      final file = await _controller!.takePicture();
      try {
        final rawBytes = await file.readAsBytes();
        final bytes = cropToFrameGuide(rawBytes);
        await _processBytes(bytes);
      } finally {
        try {
          await File(file.path).delete();
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: ${userFacingError(e)}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
        if (_mode == CaptureMode.camera) _startFrameLoop();
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (!_checkBalance()) return;
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;
      final rawBytes = await picked.readAsBytes();
      final bytes = cropToFrameGuide(rawBytes);
      setState(() => _galleryPreview = bytes);
      await _processBytes(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery upload failed: ${userFacingError(e)}')),
        );
      }
    }
  }

  Future<void> _ensureCamera() async {
    if (_controller != null) return;
    await _initCamera();
  }

  void _switchMode(CaptureMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _galleryPreview = null;
      if (mode == CaptureMode.camera) {
        _ensureCamera().then((_) {
          if (mounted) _startFrameLoop();
        });
      } else {
        _stopFrameLoop();
      }
    });
  }

  @override
  void dispose() {
    _stopFrameLoop();
    _hintSub?.cancel();
    _statusSub?.cancel();
    _ws.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller?.value.isInitialized ?? false;
    final user = AuthService.instance.currentUser;

    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_mode == CaptureMode.camera)
            (ready
                ? CameraPreview(_controller!)
                : const Center(child: CircularProgressIndicator(color: AppTheme.white)))
          else if (_galleryPreview != null)
            Image.memory(_galleryPreview!, fit: BoxFit.cover)
          else
            Container(
              color: AppTheme.surface,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 64, color: AppTheme.textSecondary),
                    SizedBox(height: 12),
                    Text('Select a photo from gallery', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
          if (_mode == CaptureMode.camera)
            CaptureHintOverlay(hint: _hint, status: _status),
          if (user != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withValues(alpha: 0.9), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      MoneyFormat.usd(user.balance),
                      style: AppTheme.textStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.white),
                    ),
                    const Spacer(),
                    Text(
                      MoneyFormat.pricePerGeneration(_generationPrice),
                      style: AppTheme.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          if (canPop)
            Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              left: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: SegmentedButton<CaptureMode>(
              segments: const [
                ButtonSegment(value: CaptureMode.camera, label: Text('Camera'), icon: Icon(Icons.camera_alt)),
                ButtonSegment(value: CaptureMode.gallery, label: Text('Gallery'), icon: Icon(Icons.photo_library)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => _switchMode(s.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return Colors.white.withValues(alpha: 0.22);
                  return Colors.black.withValues(alpha: 0.4);
                }),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                side: WidgetStateProperty.all(BorderSide(color: Colors.white.withValues(alpha: 0.15))),
              ),
            ),
          ),
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: _mode == CaptureMode.camera
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ShutterButton(
                        enabled: !_capturing,
                        isPerfect: _hint?.isPerfect == true,
                        onTap: _takePhoto,
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FilledButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload from Gallery'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool enabled;
  final bool isPerfect;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.enabled,
    required this.isPerfect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Take Photo', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: enabled ? onTap : null,
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
                  color: isPerfect ? AppTheme.success : AppTheme.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
