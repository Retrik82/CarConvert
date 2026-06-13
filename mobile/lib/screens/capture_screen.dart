import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/design_tokens.dart';
import '../models/background.dart';
import '../models/hint_response.dart';
import '../repositories/auth_repository.dart';
import '../repositories/background_repository.dart';
import '../repositories/camera_repository.dart';
import '../repositories/photo_repository.dart';
import '../repositories/settings_repository.dart';
import '../utils/error_utils.dart';
import '../utils/frame_crop.dart';
import '../utils/money_format.dart';
import '../widgets/background_scene_preview.dart';
import '../widgets/capture_hint_overlay.dart';
import '../widgets/design_system/app_button.dart';
import 'backgrounds_screen.dart';
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
  final _camera = CameraRepository();
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
    if (_mode == CaptureMode.camera) _initCamera();
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
    await _camera.disconnect();
  }

  Future<void> _resumeCapture() async {
    if (_mode != CaptureMode.camera) return;
    final token = AuthRepository.instance.accessToken;
    if (token != null && _sessionId != null) {
      try {
        await _camera.connect(sessionId: _sessionId!, token: token);
      } catch (_) {}
    }
    _startFrameLoop();
  }

  Future<void> _loadBilling() async {
    try {
      await AuthRepository.instance.refreshCurrentUser();
      _generationPrice = await SettingsRepository.instance.getGenerationPrice();
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
      _sessionId = await PhotoRepository.instance.startSession();
      final token = AuthRepository.instance.accessToken;
      if (token == null) {
        setState(() => _status = 'Authentication required');
        return;
      }
      await _camera.connect(sessionId: _sessionId!, token: token);
      _hintSub = _camera.hints.listen((h) {
        if (mounted) setState(() => _hint = h);
      });
      _statusSub = _camera.status.listen((s) {
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
      _camera.sendFrame(base64Encode(compressed));
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
    final user = AuthRepository.instance.currentUser;
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
    final selectedBackground = BackgroundRepository.instance.selected;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          imageBytes: bytes,
          sessionId: _sessionId,
          carId: widget.carId,
          onCharged: _loadBilling,
          selectedBackground: selectedBackground,
        ),
      ),
    ).then((_) => _loadBilling());
  }

  Future<void> _openBackgrounds() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BackgroundsScreen()),
    );
    if (mounted) setState(() {});
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
    _camera.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final ready = _controller?.value.isInitialized ?? false;
    final user = AuthRepository.instance.currentUser;
    final canPop = Navigator.canPop(context);
    final selectedBackground = BackgroundRepository.instance.selected;
    final isPerfect = _hint?.isPerfect == true;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_mode == CaptureMode.camera)
            (ready
                ? CameraPreview(_controller!)
                : const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
          else if (_galleryPreview != null)
            Image.memory(_galleryPreview!, fit: BoxFit.cover)
          else
            Container(
              color: const Color(0xFF121216),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 56, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(height: DesignTokens.spacing12),
                    Text(
                      s.selectGalleryPhoto,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

          if (_mode == CaptureMode.camera)
            CaptureHintOverlay(hint: _hint, status: _status),

          _GlassBar(
            top: MediaQuery.of(context).padding.top + 8,
            child: Row(
              children: [
                if (canPop)
                  _GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
                if (canPop) const SizedBox(width: DesignTokens.spacing8),
                Expanded(
                  child: _ModePill(
                    mode: _mode,
                    onChanged: _switchMode,
                    cameraLabel: s.captureCamera,
                    galleryLabel: s.captureGallery,
                  ),
                ),
              ],
            ),
          ),

          if (user != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: DesignTokens.screenPaddingH,
              child: _GlassChip(
                icon: Icons.account_balance_wallet_outlined,
                label: MoneyFormat.usd(user.balance),
                trailing: MoneyFormat.pricePerGeneration(_generationPrice),
              ),
            ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            right: DesignTokens.screenPaddingH,
            child: GestureDetector(
              onTap: _openBackgrounds,
              child: _BackgroundChip(selectedBackground: selectedBackground, s: s),
            ),
          ),

          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 24,
            left: 0,
            right: 0,
            child: _mode == CaptureMode.camera
                ? _ShutterButton(
                    enabled: !_capturing && ready,
                    isPerfect: isPerfect,
                    loading: _capturing,
                    label: s.takePhoto,
                    onTap: _takePhoto,
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
                    child: AppButton(
                      label: s.uploadFromGallery,
                      icon: Icons.upload_rounded,
                      onPressed: _pickFromGallery,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GlassBar extends StatelessWidget {
  final double top;
  final Widget child;

  const _GlassBar({required this.top, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: DesignTokens.screenPaddingH,
      right: DesignTokens.screenPaddingH,
      child: child,
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  final CaptureMode mode;
  final ValueChanged<CaptureMode> onChanged;
  final String cameraLabel;
  final String galleryLabel;

  const _ModePill({
    required this.mode,
    required this.onChanged,
    required this.cameraLabel,
    required this.galleryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          _pillItem(CaptureMode.camera, Icons.camera_alt_outlined, cameraLabel),
          _pillItem(CaptureMode.gallery, Icons.photo_library_outlined, galleryLabel),
        ],
      ),
    );
  }

  Widget _pillItem(CaptureMode value, IconData icon, String label) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: DesignTokens.durationNormal,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white.withValues(alpha: selected ? 1 : 0.65)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: Colors.white.withValues(alpha: selected ? 1 : 0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailing;

  const _GlassChip({required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(trailing, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }
}

class _BackgroundChip extends StatelessWidget {
  final SelectedBackground? selectedBackground;
  final AppStrings s;

  const _BackgroundChip({required this.selectedBackground, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedBackground != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 36,
                height: 36,
                child: BackgroundScenePreview(
                  preset: selectedBackground!.preset,
                  showCar: false,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.wallpaper_outlined, color: Colors.white.withValues(alpha: 0.7), size: 18),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              selectedBackground?.displayName ?? s.chooseBackground,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.5), size: 18),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool enabled;
  final bool isPerfect;
  final bool loading;
  final String label;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.enabled,
    required this.isPerfect,
    required this.loading,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isPerfect ? const Color(0xFF66BB6A) : Colors.white.withValues(alpha: 0.75),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: DesignTokens.spacing12),
        GestureDetector(
          onTap: enabled && !loading ? onTap : null,
          child: AnimatedContainer(
            duration: DesignTokens.durationNormal,
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isPerfect ? const Color(0xFF66BB6A) : Colors.white,
                width: 3,
              ),
              boxShadow: isPerfect
                  ? [
                      BoxShadow(
                        color: const Color(0xFF66BB6A).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPerfect ? const Color(0xFF66BB6A) : Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
