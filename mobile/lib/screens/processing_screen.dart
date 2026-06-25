import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../repositories/auth_repository.dart';
import '../models/background.dart';
import '../repositories/photo_repository.dart';
import '../utils/error_utils.dart';
import '../utils/frame_crop.dart';
import '../core/theme/page_transitions.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/framed_photo_preview.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String? sessionId;
  final String? carId;
  final VoidCallback? onCharged;
  final bool autoStart;
  final SelectedBackground? selectedBackground;

  const ProcessingScreen({
    super.key,
    required this.imageBytes,
    this.sessionId,
    this.carId,
    this.onCharged,
    this.autoStart = true,
    this.selectedBackground,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String _status = 'Uploading image...';
  Timer? _pollTimer;
  String? _jobId;
  double _progress = 0;
  bool _hasError = false;
  DateTime? _pollStartedAt;

  static const _pollInterval = Duration(seconds: 2);
  static const _pollTimeout = Duration(minutes: 6);

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) _start();
  }

  void _setProgress(double value, String status, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _progress = value.clamp(0, 100);
      _status = status;
      _hasError = isError;
    });
  }

  Future<void> _start() async {
    _pollTimer?.cancel();
    _pollStartedAt = null;
    _jobId = null;
    _hasError = false;
    try {
      _setProgress(5, context.strings.advisorConnecting);
      await Future.wait([
        AuthRepository.instance.ensureSessionReady(),
        PhotoRepository.instance.wakeServer(attempts: 2),
      ]);
      _setProgress(15, 'Uploading image...');
      final job = await PhotoRepository.instance.processPhoto(
        widget.imageBytes,
        'capture.jpg',
        sessionId: widget.sessionId,
        backgroundPresetId: widget.selectedBackground?.presetId,
        backgroundPresetSlug: widget.selectedBackground?.presetSlug,
        userBackgroundId: widget.selectedBackground?.userBackgroundId,
      );
      await AuthRepository.instance.refreshCurrentUser();
      widget.onCharged?.call();
      _jobId = job.jobId;
      _pollStartedAt = DateTime.now();
      _setProgress(25, context.strings.processingQueued);
      _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
      await _poll();
    } catch (e) {
      _setProgress(_progress, userFacingError(e), isError: true);
    }
  }

  void _stopPollingWithError(String message) {
    _pollTimer?.cancel();
    _setProgress(_progress, message, isError: true);
    AuthRepository.instance.refreshCurrentUser().then((_) {
      widget.onCharged?.call();
    });
  }

  Future<void> _poll() async {
    if (_jobId == null) return;

    final startedAt = _pollStartedAt;
    if (startedAt != null && DateTime.now().difference(startedAt) > _pollTimeout) {
      _stopPollingWithError('Processing is taking too long. Please try again.');
      return;
    }

    try {
      final result = await PhotoRepository.instance.getResult(_jobId!);
      if (result.status == 'queued') {
        _setProgress((_progress + 2).clamp(20, 85), context.strings.processingQueued);
      } else if (result.status == 'processing') {
        _setProgress((_progress + 6).clamp(30, 92), context.strings.processingRendering);
      } else if (result.isCompleted) {
        _pollTimer?.cancel();
        if (result.imageBase64 == null) {
          _setProgress(_progress, 'Result image is missing. Please try again.', isError: true);
          return;
        }
        _setProgress(100, 'Complete');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          AppPageTransitions.fadeSlide(
            page: ResultScreen(
              originalBytes: widget.imageBytes,
              resultBase64: result.imageBase64!,
              mimeType: result.mimeType ?? 'image/png',
              jobId: _jobId!,
              carId: widget.carId,
            ),
          ),
        );
      } else if (result.isFailed) {
        _stopPollingWithError(result.error ?? 'Processing failed');
      } else {
        _setProgress((_progress + 4).clamp(30, 90), context.strings.processingRendering);
      }
    } catch (e) {
      _stopPollingWithError(userFacingError(e));
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.strings.processingTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
          child: Column(
            children: [
              const SizedBox(height: DesignTokens.spacing24),
              Expanded(
                child: FramedPhotoPreview(
                  imageBytes: widget.imageBytes,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
                    boxShadow: tokens.elevatedShadow,
                    border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
                    color: tokens.textPrimary.withValues(alpha: 0.92),
                  ),
                  overlays: [
                    if (!_hasError)
                      Container(
                        color: tokens.textPrimary.withValues(alpha: 0.35),
                        child: Center(
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              value: _progress > 0 && _progress < 100 ? _progress / 100 : null,
                              color: Colors.white,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                    if (_hasError)
                      Container(
                        color: tokens.error.withValues(alpha: 0.15),
                        child: Icon(Icons.error_outline_rounded, size: 56, color: tokens.error),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.spacing32),
              Text(
                _hasError
                    ? 'Something went wrong'
                    : (_status == context.strings.processingQueued
                        ? context.strings.processingQueued
                        : context.strings.processingRendering),
                style: tokens.textStyle(fontSize: 22, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spacing16),
              if (!_hasError) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 8,
                    backgroundColor: tokens.surfaceMuted,
                    color: tokens.accent,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing8),
                Text(
                  '${_progress.round()}%',
                  style: tokens.textStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.spacing12),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: tokens.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _hasError ? tokens.error : tokens.textTertiary,
                ),
              ),
              if (_hasError) ...[
                const SizedBox(height: DesignTokens.spacing24),
                AppButton(
                  label: 'Try again',
                  icon: Icons.refresh_rounded,
                  onPressed: _start,
                ),
              ],
              SizedBox(height: MediaQuery.paddingOf(context).bottom + DesignTokens.spacing24),
            ],
          ),
        ),
      ),
    );
  }
}
