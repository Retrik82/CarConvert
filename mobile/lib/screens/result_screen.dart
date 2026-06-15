import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';
import '../repositories/car_repository.dart';
import '../widgets/before_after_slider.dart';
import '../widgets/design_system/app_button.dart';
import 'capture_screen.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List originalBytes;
  final String resultBase64;
  final String mimeType;
  final String jobId;
  final String? carId;

  const ResultScreen({
    super.key,
    required this.originalBytes,
    required this.resultBase64,
    required this.mimeType,
    required this.jobId,
    this.carId,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _saved = false;
  bool _saving = false;
  String? _savedCarId;

  Uint8List get _resultBytes => base64Decode(widget.resultBase64);

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final car = await CarRepository.instance.addRender(
        carId: widget.carId,
        jobId: widget.jobId,
        originalBytes: widget.originalBytes,
        renderedBytes: _resultBytes,
        renderedExt: widget.mimeType.contains('png') ? 'png' : 'jpg',
      );
      setState(() {
        _saved = true;
        _savedCarId = car.id;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Render saved to My Cars')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final message = _saved
        ? 'This will remove the saved render from My Cars.'
        : 'This will discard the current result.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete render?'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (_saved) {
      final carId = widget.carId ?? _savedCarId;
      if (carId != null) {
        final car = CarRepository.instance.getById(carId);
        final matching = car?.renders.where((r) => r.jobId == widget.jobId);
        if (matching != null && matching.isNotEmpty) {
          await CarRepository.instance.deleteRender(carId, matching.first.id);
        }
      }
    }

    if (mounted) Navigator.pop(context);
  }

  void _reRender() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureScreen(carId: widget.carId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasOriginal = widget.originalBytes.isNotEmpty;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Render Result')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spacing16,
                DesignTokens.spacing16,
                DesignTokens.spacing16,
                DesignTokens.spacing8,
              ),
              child: hasOriginal
                  ? BeforeAfterSlider(
                      beforeBytes: widget.originalBytes,
                      afterBytes: _resultBytes,
                    )
                  : InteractiveViewer(
                      child: Image.memory(_resultBytes, fit: BoxFit.contain),
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spacing16,
                DesignTokens.spacing8,
                DesignTokens.spacing16,
                bottomInset > 0 ? DesignTokens.spacing8 : DesignTokens.spacing16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: _saved ? 'Saved to My Cars' : 'Save to My Cars',
                    icon: _saved ? Icons.check_rounded : Icons.save_outlined,
                    loading: _saving,
                    onPressed: _saving || _saved ? null : _save,
                  ),
                  const SizedBox(height: DesignTokens.spacing12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Delete',
                          icon: Icons.delete_outline,
                          variant: AppButtonVariant.secondary,
                          onPressed: _delete,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacing12),
                      Expanded(
                        child: AppButton(
                          label: 'Re-render',
                          icon: Icons.refresh_rounded,
                          variant: AppButtonVariant.secondary,
                          onPressed: _reRender,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
