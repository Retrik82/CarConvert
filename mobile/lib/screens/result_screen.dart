import 'dart:convert';

import 'dart:typed_data';



import 'package:flutter/material.dart';

import 'package:intl/intl.dart';



import '../core/l10n/app_strings.dart';

import '../core/theme/app_tokens.dart';

import '../core/theme/design_tokens.dart';

import '../repositories/car_repository.dart';

import '../utils/image_export.dart';

import '../core/theme/page_transitions.dart';
import '../widgets/before_after_slider.dart';

import '../widgets/design_system/app_button.dart';

import '../widgets/design_system/app_card.dart';

import '../widgets/rename_dialog.dart';

import '../widgets/zoomable_image.dart';

import 'capture_screen.dart';



class ResultScreen extends StatefulWidget {

  final Uint8List originalBytes;

  final String resultBase64;

  final String mimeType;

  final String jobId;

  final String? carId;

  final String? renderId;

  final String? initialRenderName;



  const ResultScreen({

    super.key,

    required this.originalBytes,

    required this.resultBase64,

    required this.mimeType,

    required this.jobId,

    this.carId,

    this.renderId,

    this.initialRenderName,

  });



  @override

  State<ResultScreen> createState() => _ResultScreenState();

}



class _ResultScreenState extends State<ResultScreen> {

  bool _saved = false;

  bool _saving = false;

  bool _downloading = false;

  String? _savedCarId;

  String? _savedRenderId;

  String? _renderName;



  Uint8List get _resultBytes => base64Decode(widget.resultBase64);



  String _defaultRenderName() {

    return DateFormat('MMM d, yyyy · HH:mm').format(DateTime.now().toLocal());

  }



  Future<void> _save() async {

    final s = context.strings;

    final name = await showRenameDialog(

      context,

      title: s.saveToMyCars,

      label: s.renderName,

      hint: s.renderNameHint,

      initialValue: _renderName ?? widget.initialRenderName ?? _defaultRenderName(),

    );

    if (name == null || !mounted) return;



    setState(() => _saving = true);

    try {

      final car = await CarRepository.instance.addRender(

        carId: widget.carId,

        jobId: widget.jobId,

        originalBytes: widget.originalBytes,

        renderedBytes: _resultBytes,

        renderedExt: widget.mimeType.contains('png') ? 'png' : 'jpg',

        renderName: name,

      );

      setState(() {

        _saved = true;

        _savedCarId = car.id;

        _savedRenderId = car.renders.last.id;

        _renderName = name;

      });

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(s.savedToMyCars)),

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



  Future<void> _download() async {

    final s = context.strings;

    setState(() => _downloading = true);

    try {

      final ext = widget.mimeType.contains('png') ? 'png' : 'jpg';

      await ImageExport.saveToGallery(

        _resultBytes,

        fileName: 'autocut_${widget.jobId}.$ext',

      );

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(s.photoSaved)),

        );

      }

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('${s.photoSaveFailed}: $e')),

        );

      }

    } finally {

      if (mounted) setState(() => _downloading = false);

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

          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.strings.cancel)),

          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.strings.deleteRender)),

        ],

      ),

    );

    if (confirmed != true || !mounted) return;



    if (_saved) {

      final carId = widget.carId ?? _savedCarId;

      final renderId = widget.renderId ?? _savedRenderId;

      if (carId != null && renderId != null) {

        await CarRepository.instance.deleteRender(carId, renderId);

      } else if (carId != null) {

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
      AppPageTransitions.fadeSlide(
        page: CaptureScreen(carId: widget.carId),
      ),
    );
  }



  void _openFullscreen() {

    openFullscreenImage(

      context,

      bytes: _resultBytes,

      title: context.strings.afterLabel,

    );

  }



  @override

  Widget build(BuildContext context) {

    final tokens = context.tokens;

    final s = context.strings;

    final hasOriginal = widget.originalBytes.isNotEmpty;

    final bottomInset = MediaQuery.paddingOf(context).bottom;



    return Scaffold(

      backgroundColor: tokens.background,

      appBar: AppBar(

        title: Text(s.renderResultTitle),

        centerTitle: true,

        actions: [

          IconButton(

            icon: const Icon(Icons.download_outlined),

            tooltip: s.downloadPhoto,

            onPressed: _downloading ? null : _download,

          ),

          IconButton(

            icon: const Icon(Icons.fullscreen_rounded),

            tooltip: s.pinchToZoom,

            onPressed: _openFullscreen,

          ),

        ],

      ),

      body: Column(

        children: [

          Expanded(

            child: Padding(

              padding: const EdgeInsets.fromLTRB(

                DesignTokens.screenPaddingH,

                DesignTokens.spacing16,

                DesignTokens.screenPaddingH,

                DesignTokens.spacing8,

              ),

              child: hasOriginal

                  ? BeforeAfterSlider(

                      beforeBytes: widget.originalBytes,

                      afterBytes: _resultBytes,

                    )

                  : GestureDetector(

                      onTap: _openFullscreen,

                      child: Container(

                        decoration: BoxDecoration(

                          borderRadius: BorderRadius.circular(DesignTokens.radiusHero),

                          boxShadow: tokens.elevatedShadow,

                        ),

                        child: ClipRRect(

                          borderRadius: BorderRadius.circular(DesignTokens.radiusHero),

                          child: ZoomableImage(bytes: _resultBytes, showZoomHint: true),

                        ),

                      ),

                    ),

            ),

          ),

          SafeArea(

            top: false,

            child: Padding(

              padding: EdgeInsets.fromLTRB(

                DesignTokens.screenPaddingH,

                DesignTokens.spacing8,

                DesignTokens.screenPaddingH,

                bottomInset > 0 ? DesignTokens.spacing8 : DesignTokens.spacing16,

              ),

              child: AppCard(

                elevated: true,

                padding: const EdgeInsets.all(DesignTokens.spacing16),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    AppButton(

                      label: _saved ? s.savedToMyCars : s.saveToMyCars,

                      icon: _saved ? Icons.check_rounded : Icons.save_outlined,

                      loading: _saving,

                      onPressed: _saving || _saved ? null : _save,

                    ),

                    const SizedBox(height: DesignTokens.spacing12),

                    AppButton(

                      label: s.downloadPhoto,

                      icon: Icons.download_rounded,

                      variant: AppButtonVariant.secondary,

                      loading: _downloading,

                      onPressed: _downloading ? null : _download,

                    ),

                    const SizedBox(height: DesignTokens.spacing12),

                    Row(

                      children: [

                        Expanded(

                          child: AppButton(

                            label: s.deleteRender,

                            icon: Icons.delete_outline,

                            variant: AppButtonVariant.secondary,

                            onPressed: _delete,

                          ),

                        ),

                        const SizedBox(width: DesignTokens.spacing12),

                        Expanded(

                          child: AppButton(

                            label: s.reRender,

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

          ),

        ],

      ),

    );

  }

}

