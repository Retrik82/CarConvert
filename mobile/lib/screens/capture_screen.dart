import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/l10n/app_strings.dart';
import '../core/l10n/hint_localizer.dart';
import '../core/theme/capture_chrome.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/page_transitions.dart';
import '../models/background.dart';
import '../models/hint_response.dart';
import '../repositories/auth_repository.dart';
import '../repositories/background_repository.dart';
import '../repositories/camera_repository.dart';
import '../repositories/photo_repository.dart';
import '../repositories/settings_repository.dart';
import '../utils/camera_frame_encoder.dart';
import '../utils/error_utils.dart';
import '../utils/frame_crop.dart';
import '../utils/money_format.dart';
import '../widgets/background_scene_preview.dart';
import '../widgets/camera_preview_view.dart';
import '../widgets/capture_hint_bar.dart';
import '../widgets/capture_hint_overlay.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/framed_photo_preview.dart';
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

class _CaptureScreenState extends State<CaptureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  final _camera = CameraRepository();
  final _picker = ImagePicker();
  HintResponse? _hint;
  String _status = 'Initializing...';
  String? _sessionId;
  bool _capturing = false;
  StreamSubscription? _hintSub;
  StreamSubscription? _statusSub;
  bool _streaming = false;
  bool _encodingFrame = false;
  int _lastFrameSentMs = 0;
  double _generationPrice = 0.10;
  CaptureMode _mode = CaptureMode.camera;
  Uint8List? _galleryPreview;

  static const _frameIntervalMs = 500;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _unlockOrientations();
    _mode = widget.initialMode;
    if (_mode == CaptureMode.camera) _initCamera();
    _loadBilling();
    _ensureDefaultBackground();
  }

  Future<void> _ensureDefaultBackground() async {
    if (BackgroundRepository.instance.selected != null) return;
    try {
      final catalog = await BackgroundRepository.instance.fetchCatalog();
      if (catalog.presets.isNotEmpty) {
        BackgroundRepository.instance.select(catalog.presets.first);
        if (mounted) setState(() {});
      }
    } catch (_) {}
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

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (mounted) setState(() {});
  }

  Future<void> _unlockOrientations() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _lockPortraitOrientations() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _pauseCapture() async {
    await _stopImageStream();
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
    await _startImageStream();
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

    _controller = CameraController(back, ResolutionPreset.high, enableAudio: false);
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
      if (widget.isActive) await _startImageStream();
    } catch (e) {
      setState(() => _status = userFacingError(e));
    }

    if (mounted) setState(() {});
  }

  Future<void> _startImageStream() async {
    if (_mode != CaptureMode.camera || !widget.isActive || _streaming) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    _streaming = true;
    try {
      await controller.startImageStream(_onCameraImage);
    } catch (_) {
      _streaming = false;
    }
  }

  Future<void> _stopImageStream() async {
    _streaming = false;
    final controller = _controller;
    if (controller != null && controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
    }
  }

  /// Image stream and still capture share the same camera session — both must
  /// be fully idle before [CameraController.takePicture] is safe to call.
  Future<void> _prepareForStillCapture() async {
    _streaming = false;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
    }

    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (DateTime.now().isBefore(deadline)) {
      if (!controller.value.isStreamingImages && !_encodingFrame) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (!controller.value.isStreamingImages && !_encodingFrame) return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  void _onCameraImage(CameraImage image) {
    if (!_streaming || _encodingFrame) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastFrameSentMs < _frameIntervalMs) return;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    _encodingFrame = true;
    final sensorOrientation = controller.description.sensorOrientation;

    encodeCameraFrameJpeg(
      image,
      sensorOrientation: sensorOrientation,
    ).then((compressed) {
      if (!_streaming || compressed == null) return;
      _lastFrameSentMs = DateTime.now().millisecondsSinceEpoch;
      _camera.sendFrame(base64Encode(compressed));
    }).catchError((_) {}).whenComplete(() {
      _encodingFrame = false;
    });
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
      AppPageTransitions.fadeSlide(
        page: ProcessingScreen(
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
      AppPageTransitions.fadeSlide(page: const BackgroundsScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _takePhoto() async {
    if (_controller == null || _capturing) return;
    if (!_checkBalance()) return;

    _capturing = true;
    if (mounted) setState(() {});

    try {
      await _prepareForStillCapture();
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) {
        throw StateError('Camera not ready');
      }
      final file = await controller.takePicture();
      try {
        final rawBytes = await file.readAsBytes();
        final crop = _currentFrameCrop();
        final bytes = cropToFrameGuide(rawBytes, crop: crop);
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
      _capturing = false;
      if (mounted) {
        setState(() {});
        if (_mode == CaptureMode.camera && widget.isActive) await _startImageStream();
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_capturing) return;
    if (!_checkBalance()) return;
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked == null) return;
      final rawBytes = await picked.readAsBytes();
      final bytes = cropToFrameGuide(rawBytes, crop: _currentFrameCrop());
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
        _ensureCamera().then((_) async {
          if (mounted) await _startImageStream();
        });
      } else {
        _stopImageStream();
      }
    });
  }

  FrameCropSpec _currentFrameCrop() {
    return frameCropFor(MediaQuery.orientationOf(context));
  }

  String _hintMessage(AppStrings strings) {
    final localizer = HintLocalizer(strings);
    final isPerfect = _hint?.isPerfect ?? false;
    final lighting = _lightingScore(_hint);
    final lowLight = lighting < 0.5;

    if (lowLight && !isPerfect) return strings.advisorLowLight;
    return localizer.message(
      hint: _hint,
      status: localizer.statusOrConnecting(_status),
    );
  }

  double _lightingScore(HintResponse? hint) {
    if (hint == null) return 0.5;
    if (hint.confidence < 0.35) return 0.35;
    return (0.55 + hint.confidence * 0.35).clamp(0, 1);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopImageStream();
    _hintSub?.cancel();
    _statusSub?.cancel();
    _camera.dispose();
    _controller?.dispose();
    _lockPortraitOrientations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final ready = _controller?.value.isInitialized ?? false;
    final canPop = Navigator.canPop(context);
    final selectedBackground = BackgroundRepository.instance.selected;
    final isPerfect = _hint?.isPerfect == true;
    final hintMessage = _hintMessage(s);
    final arrowDirection = _hint?.overlay.arrow ?? 'none';
    final frameCrop = _currentFrameCrop();
    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildViewport(ready, s, frameCrop)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: _CaptureTopBar(
                  canPop: canPop,
                  title: s.captureTitle,
                  selectedBackground: selectedBackground,
                  chooseBackgroundLabel: s.chooseBackground,
                  onBack: () => Navigator.pop(context),
                  onBackgroundTap: _openBackgrounds,
                ),
              ),
            ),
          ),
          if (_mode == CaptureMode.camera)
            Positioned(
              left: DesignTokens.spacing16,
              right: DesignTokens.spacing16,
              top: isLandscape ? 64 : null,
              bottom: isLandscape ? null : 148,
              child: CaptureHintBar(
                message: hintMessage,
                isPerfect: isPerfect,
                arrowDirection: arrowDirection,
                floating: true,
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: isLandscape ? 0.85 : 0.92),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: _CaptureBottomControls(
                  mode: _mode,
                  cameraLabel: s.captureCamera,
                  galleryLabel: s.captureGallery,
                  hintMessage: _mode == CaptureMode.camera ? hintMessage : s.selectGalleryPhoto,
                  isPerfect: isPerfect,
                  arrowDirection: arrowDirection,
                  shutterEnabled: !_capturing && ready,
                  shutterLoading: _capturing,
                  compact: isLandscape,
                  showHint: _mode != CaptureMode.camera,
                  onModeChanged: _switchMode,
                  onShutter: _takePhoto,
                  onGalleryPick: _pickFromGallery,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewport(bool ready, AppStrings s, FrameCropSpec frameCrop) {
    if (_mode == CaptureMode.camera) {
      return ColoredBox(
        color: Colors.black,
        child: ready && _controller != null
            ? CameraPreviewView(
                controller: _controller!,
                fit: CameraPreviewFit.cover,
                overlay: CaptureHintOverlay(hint: _hint, crop: frameCrop),
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: CaptureChrome.accent, strokeWidth: 2.5),
                    const SizedBox(height: DesignTokens.spacing16),
                    Text(
                      _status == 'Initializing...' ? s.advisorConnecting : _status,
                      style: const TextStyle(color: CaptureChrome.textMuted, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      );
    }

    if (_galleryPreview != null) {
      return FramedPhotoPreview(
        imageBytes: _galleryPreview!,
        fit: BoxFit.contain,
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined, size: 56, color: CaptureChrome.accent.withValues(alpha: 0.6)),
          const SizedBox(height: DesignTokens.spacing12),
          Text(
            s.selectGalleryPhoto,
            style: const TextStyle(color: CaptureChrome.textMuted, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _CaptureTopBar extends StatelessWidget {
  final bool canPop;
  final String title;
  final SelectedBackground? selectedBackground;
  final String chooseBackgroundLabel;
  final VoidCallback onBack;
  final VoidCallback onBackgroundTap;

  const _CaptureTopBar({
    required this.canPop,
    required this.title,
    required this.selectedBackground,
    required this.chooseBackgroundLabel,
    required this.onBack,
    required this.onBackgroundTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacing8,
        DesignTokens.spacing4,
        DesignTokens.screenPaddingH,
        DesignTokens.spacing8,
      ),
      child: Row(
        children: [
          if (canPop)
            _IconTap(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
              semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
            )
          else
            const SizedBox(width: DesignTokens.minTapTarget),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: chooseBackgroundLabel,
            child: GestureDetector(
              onTap: onBackgroundTap,
              child: Container(
                width: DesignTokens.minTapTarget,
                height: DesignTokens.minTapTarget,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                  border: Border.all(color: CaptureChrome.borderAccent),
                  boxShadow: [
                    BoxShadow(
                      color: CaptureChrome.accentGlow,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusChip - 1),
                  child: selectedBackground != null
                      ? BackgroundScenePreview(
                          preset: selectedBackground!.preset,
                        )
                      : Icon(
                          Icons.wallpaper_outlined,
                          color: CaptureChrome.accent,
                          size: 22,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureBottomControls extends StatelessWidget {
  final CaptureMode mode;
  final String cameraLabel;
  final String galleryLabel;
  final String hintMessage;
  final bool isPerfect;
  final String arrowDirection;
  final bool shutterEnabled;
  final bool shutterLoading;
  final bool compact;
  final bool showHint;
  final ValueChanged<CaptureMode> onModeChanged;
  final VoidCallback onShutter;
  final VoidCallback onGalleryPick;

  const _CaptureBottomControls({
    required this.mode,
    required this.cameraLabel,
    required this.galleryLabel,
    required this.hintMessage,
    required this.isPerfect,
    required this.arrowDirection,
    required this.shutterEnabled,
    required this.shutterLoading,
    required this.compact,
    required this.showHint,
    required this.onModeChanged,
    required this.onShutter,
    required this.onGalleryPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.screenPaddingH,
        compact ? DesignTokens.spacing8 : DesignTokens.spacing12,
        DesignTokens.screenPaddingH,
        compact ? DesignTokens.spacing8 : DesignTokens.spacing12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHint) ...[
            CaptureHintBar(
              message: hintMessage,
              isPerfect: isPerfect,
              arrowDirection: mode == CaptureMode.camera ? arrowDirection : 'none',
            ),
            SizedBox(height: compact ? DesignTokens.spacing8 : DesignTokens.spacing16),
          ],
          if (mode == CaptureMode.camera)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IconTap(
                  icon: Icons.photo_library_outlined,
                  onTap: () => onModeChanged(CaptureMode.gallery),
                  semanticLabel: galleryLabel,
                  compact: compact,
                ),
                SizedBox(width: compact ? DesignTokens.spacing24 : DesignTokens.spacing32),
                _ShutterButton(
                  enabled: shutterEnabled,
                  isPerfect: isPerfect,
                  loading: shutterLoading,
                  compact: compact,
                  onTap: onShutter,
                ),
                SizedBox(width: compact ? DesignTokens.spacing24 : DesignTokens.spacing32),
                SizedBox(width: compact ? 40 : DesignTokens.minTapTarget),
              ],
            )
          else
            Column(
              children: [
                AppButton(
                  label: galleryLabel,
                  icon: Icons.upload_rounded,
                  onPressed: onGalleryPick,
                ),
                const SizedBox(height: DesignTokens.spacing12),
                TextButton.icon(
                  onPressed: () => onModeChanged(CaptureMode.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text(cameraLabel),
                  style: TextButton.styleFrom(foregroundColor: CaptureChrome.accent),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _IconTap extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;
  final bool compact;

  const _IconTap({
    required this.icon,
    required this.onTap,
    this.semanticLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : DesignTokens.minTapTarget;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: CaptureChrome.iconGlass,
        borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
              border: Border.all(color: CaptureChrome.borderGlass),
            ),
            child: Icon(icon, color: CaptureChrome.textPrimary, size: compact ? 20 : 22),
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool enabled;
  final bool isPerfect;
  final bool loading;
  final bool compact;
  final VoidCallback onTap;

  const _ShutterButton({
    required this.enabled,
    required this.isPerfect,
    required this.loading,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outer = compact ? 60.0 : 72.0;
    final inner = compact ? 48.0 : 58.0;

    return Semantics(
      button: true,
      enabled: enabled && !loading,
      label: context.strings.takePhoto,
      child: GestureDetector(
        onTap: enabled && !loading ? onTap : null,
        child: AnimatedContainer(
          duration: DesignTokens.durationNormal,
          width: outer,
          height: outer,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isPerfect ? CaptureChrome.perfect : CaptureChrome.accent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (isPerfect ? CaptureChrome.perfectGlow : CaptureChrome.accentGlow),
                blurRadius: 16,
              ),
            ],
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: compact ? 20 : 24,
                    height: compact ? 20 : 24,
                    child: const CircularProgressIndicator(strokeWidth: 2.5, color: CaptureChrome.accent),
                  )
                : Container(
                    width: inner,
                    height: inner,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isPerfect ? null : CaptureChrome.primaryGradient,
                      color: isPerfect ? CaptureChrome.perfect : null,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
