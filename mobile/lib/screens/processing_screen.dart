import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';
import '../models/background.dart';
import '../repositories/photo_repository.dart';
import '../theme/app_theme.dart';
import '../utils/error_utils.dart';
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
    _jobId = null;
    try {
      _setProgress(5, 'Connecting to server...');
      await PhotoRepository.instance.wakeServer();
      _setProgress(15, 'Uploading image...');
      final job = await PhotoRepository.instance.processPhoto(
        widget.imageBytes,
        'capture.jpg',
        sessionId: widget.sessionId,
        backgroundPresetId: widget.selectedBackground?.presetId,
        backgroundVariantId: widget.selectedBackground?.presetVariantId,
        userBackgroundId: widget.selectedBackground?.userBackgroundId,
        userBackgroundVariantId: widget.selectedBackground?.userVariantId,
      );
      await AuthRepository.instance.refreshCurrentUser();
      widget.onCharged?.call();
      _jobId = job.jobId;
      _setProgress(35, 'Rendering your car...');
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
    } catch (e) {
      _setProgress(_progress, userFacingError(e), isError: true);
    }
  }

  Future<void> _poll() async {
    if (_jobId == null) return;
    try {
      final result = await PhotoRepository.instance.getResult(_jobId!);
      if (result.status == 'processing') {
        _setProgress((_progress + 8).clamp(35, 90), 'Rendering your car...');
      } else if (result.isCompleted && result.imageBase64 != null) {
        _pollTimer?.cancel();
        _setProgress(100, 'Complete');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              originalBytes: widget.imageBytes,
              resultBase64: result.imageBase64!,
              mimeType: result.mimeType ?? 'image/png',
              jobId: _jobId!,
              carId: widget.carId,
            ),
          ),
        );
      } else if (result.isFailed) {
        _pollTimer?.cancel();
        _setProgress(_progress, result.error ?? 'Processing failed', isError: true);
      } else {
        _setProgress((_progress + 5).clamp(35, 85), 'Rendering your car...');
      }
    } catch (e) {
      _setProgress(_progress, userFacingError(e), isError: true);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Processing'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  value: !_hasError && _progress > 0 && _progress < 100 ? _progress / 100 : null,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _hasError ? 'Something went wrong' : 'Rendering your car...',
                style: AppTheme.textStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              if (!_hasError)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 6,
                    backgroundColor: AppTheme.surfaceMuted,
                    color: AppTheme.accent,
                  ),
                ),
              if (!_hasError) ...[
                const SizedBox(height: 8),
                Text(
                  '${_progress.round()}%',
                  style: AppTheme.textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: AppTheme.textStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _hasError ? Colors.redAccent : AppTheme.textTertiary,
                ),
              ),
              if (_hasError) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
