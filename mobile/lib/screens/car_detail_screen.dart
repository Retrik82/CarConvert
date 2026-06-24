import 'dart:convert';

import 'dart:io';

import 'dart:typed_data';



import 'package:flutter/material.dart';

import 'package:intl/intl.dart';



import '../core/l10n/app_strings.dart';

import '../core/theme/app_tokens.dart';

import '../core/theme/design_tokens.dart';

import '../models/car.dart';

import '../repositories/car_repository.dart';

import '../utils/image_export.dart';

import '../widgets/design_system/app_button.dart';

import '../widgets/design_system/app_card.dart';

import '../widgets/rename_dialog.dart';

import '../widgets/zoomable_image.dart';

import 'capture_screen.dart';

import 'result_screen.dart';



class CarDetailScreen extends StatefulWidget {

  final String carId;



  const CarDetailScreen({super.key, required this.carId});



  @override

  State<CarDetailScreen> createState() => _CarDetailScreenState();

}



class _CarDetailScreenState extends State<CarDetailScreen> {

  Car? _car;



  @override

  void initState() {

    super.initState();

    _load();

  }



  Future<void> _load() async {

    await CarRepository.instance.load();

    setState(() => _car = CarRepository.instance.getById(widget.carId));

  }



  Future<void> _renameCar() async {

    final car = _car;

    if (car == null) return;

    final s = context.strings;

    final name = await showRenameDialog(

      context,

      title: s.renameCar,

      label: s.carName,

      hint: s.carNameHint,

      initialValue: car.name,

    );

    if (name == null) return;

    await CarRepository.instance.updateCarName(widget.carId, name);

    _load();

  }



  Future<void> _renameRender(RenderResult render) async {

    final s = context.strings;

    final fallback = DateFormat('MMM d, yyyy · HH:mm').format(render.createdAt.toLocal());

    final name = await showRenameDialog(

      context,

      title: s.renameRender,

      label: s.renderName,

      hint: s.renderNameHint,

      initialValue: render.displayName(fallback),

    );

    if (name == null) return;

    await CarRepository.instance.updateRenderName(widget.carId, render.id, name);

    _load();

  }



  Future<void> _deleteCar() async {

    final confirmed = await showDialog<bool>(

      context: context,

      builder: (ctx) => AlertDialog(

        title: Text(context.strings.deleteCar),

        content: const Text('All renders for this car will be removed.'),

        actions: [

          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.strings.cancel)),

          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.strings.deleteRender)),

        ],

      ),

    );

    if (confirmed == true) {

      await CarRepository.instance.deleteCar(widget.carId);

      if (mounted) Navigator.pop(context);

    }

  }



  void _previewRender(RenderResult render) {

    final path = render.renderedPath ?? render.originalPath;

    if (path == null || !File(path).existsSync()) return;

    final fallback = DateFormat('MMM d, yyyy · HH:mm').format(render.createdAt.toLocal());

    openFullscreenImage(

      context,

      filePath: path,

      title: render.displayName(fallback),

    );

  }



  Future<void> _downloadRender(RenderResult render) async {

    final s = context.strings;

    final path = render.renderedPath;

    if (path == null || !File(path).existsSync()) return;

    try {

      final ext = path.endsWith('.png') ? 'png' : 'jpg';

      await ImageExport.saveFileToGallery(path, fileName: 'autocut_${render.id}.$ext');

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.photoSaved)));

      }

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${s.photoSaveFailed}: $e')));

      }

    }

  }



  Future<void> _openRender(RenderResult render) async {

    Uint8List original = Uint8List(0);

    Uint8List? rendered;



    if (render.originalPath != null && File(render.originalPath!).existsSync()) {

      original = await File(render.originalPath!).readAsBytes();

    }

    if (render.renderedPath != null && File(render.renderedPath!).existsSync()) {

      rendered = await File(render.renderedPath!).readAsBytes();

    }

    if (rendered == null) return;



    final fallback = DateFormat('MMM d, yyyy · HH:mm').format(render.createdAt.toLocal());



    if (!mounted) return;

    await Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => ResultScreen(

          originalBytes: original,

          resultBase64: base64Encode(rendered!),

          mimeType: render.renderedPath!.endsWith('.png') ? 'image/png' : 'image/jpeg',

          jobId: render.jobId,

          carId: widget.carId,

          renderId: render.id,

          initialRenderName: render.displayName(fallback),

        ),

      ),

    );

    _load();

  }



  @override

  Widget build(BuildContext context) {

    final tokens = context.tokens;

    final s = context.strings;

    final car = _car;

    if (car == null) {

      return Scaffold(

        backgroundColor: tokens.background,

        appBar: AppBar(title: Text(s.navCars)),

        body: Center(child: CircularProgressIndicator(color: tokens.accent)),

      );

    }



    return Scaffold(

      backgroundColor: tokens.background,

      appBar: AppBar(

        title: Text(car.name),

        actions: [

          IconButton(

            icon: const Icon(Icons.drive_file_rename_outline_rounded),

            tooltip: s.rename,

            onPressed: _renameCar,

          ),

        ],

      ),

      body: ListView(

        padding: const EdgeInsets.all(DesignTokens.screenPaddingH),

        children: [

          _CarInfoCard(car: car, onRename: _renameCar),

          const SizedBox(height: DesignTokens.spacing16),

          if (car.renders.isNotEmpty) ...[

            Text(s.preview, style: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w600)),

            const SizedBox(height: DesignTokens.spacing8),

            SizedBox(

              height: 160,

              child: ListView.separated(

                scrollDirection: Axis.horizontal,

                itemCount: car.renders.length,

                separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.spacing12),

                itemBuilder: (_, i) {

                  final render = car.renders[i];

                  final path = render.renderedPath ?? render.originalPath;

                  return GestureDetector(

                    onTap: () => _previewRender(render),

                    child: ClipRRect(

                      borderRadius: BorderRadius.circular(DesignTokens.radiusInput),

                      child: path != null && File(path).existsSync()

                          ? Image.file(File(path), width: 220, height: 160, fit: BoxFit.contain)

                          : Container(

                              width: 220,

                              height: 160,

                              color: tokens.surfaceMuted,

                              child: Icon(Icons.image_outlined, color: tokens.textTertiary),

                            ),

                    ),

                  );

                },

              ),

            ),

            const SizedBox(height: DesignTokens.spacing24),

          ],

          Text(s.renderHistory, style: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w600)),

          const SizedBox(height: DesignTokens.spacing8),

          ...car.renders.reversed.map(

            (render) => _RenderHistoryTile(

              render: render,

              onTap: () => _openRender(render),

              onRename: () => _renameRender(render),

              onDownload: () => _downloadRender(render),

              onPreview: () => _previewRender(render),

            ),

          ),

          const SizedBox(height: DesignTokens.spacing24),

          AppButton(

            label: s.addRender,

            icon: Icons.add_a_photo_outlined,

            onPressed: () {

              Navigator.push(

                context,

                MaterialPageRoute(builder: (_) => CaptureScreen(carId: car.id)),

              ).then((_) => _load());

            },

          ),

          const SizedBox(height: DesignTokens.spacing12),

          AppButton(

            label: s.deleteCar,

            icon: Icons.delete_outline,

            variant: AppButtonVariant.secondary,

            onPressed: _deleteCar,

          ),

        ],

      ),

    );

  }

}



class _CarInfoCard extends StatelessWidget {

  final Car car;

  final VoidCallback onRename;



  const _CarInfoCard({required this.car, required this.onRename});



  @override

  Widget build(BuildContext context) {

    final tokens = context.tokens;

    final s = context.strings;



    return AppCard(

      elevated: true,

      padding: const EdgeInsets.all(DesignTokens.spacing24),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Expanded(

                child: Text(car.name, style: tokens.textStyle(fontSize: 22, fontWeight: FontWeight.w700)),

              ),

              IconButton(

                icon: const Icon(Icons.drive_file_rename_outline_rounded, size: 20),

                tooltip: s.rename,

                onPressed: onRename,

              ),

            ],

          ),

          const SizedBox(height: DesignTokens.spacing8),

          Text(

            'Created ${DateFormat('MMM d, yyyy').format(car.createdAt.toLocal())}',

            style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: tokens.textSecondary),

          ),

          const SizedBox(height: DesignTokens.spacing4),

          Text(

            '${car.renders.length} render${car.renders.length == 1 ? '' : 's'}',

            style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.accent),

          ),

        ],

      ),

    );

  }

}



class _RenderHistoryTile extends StatelessWidget {

  final RenderResult render;

  final VoidCallback onTap;

  final VoidCallback onRename;

  final VoidCallback onDownload;

  final VoidCallback onPreview;



  const _RenderHistoryTile({

    required this.render,

    required this.onTap,

    required this.onRename,

    required this.onDownload,

    required this.onPreview,

  });



  @override

  Widget build(BuildContext context) {

    final tokens = context.tokens;

    final s = context.strings;

    final path = render.renderedPath ?? render.originalPath;

    final fallback = DateFormat('MMM d, yyyy · HH:mm').format(render.createdAt.toLocal());

    final title = render.displayName(fallback);



    return Padding(

      padding: const EdgeInsets.only(bottom: DesignTokens.spacing8),

      child: AppCard(

        onTap: onTap,

        padding: const EdgeInsets.all(DesignTokens.spacing12),

        child: Row(

          children: [

            GestureDetector(

              onTap: onPreview,

              child: ClipRRect(

                borderRadius: BorderRadius.circular(DesignTokens.radiusChip),

                child: path != null && File(path).existsSync()

                    ? Image.file(File(path), width: 64, height: 64, fit: BoxFit.cover)

                    : Container(

                        width: 64,

                        height: 64,

                        color: tokens.surfaceMuted,

                        child: Icon(Icons.image_outlined, color: tokens.textTertiary),

                      ),

              ),

            ),

            const SizedBox(width: DesignTokens.spacing12),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(title, style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2),

                  Text(

                    DateFormat('MMM d, yyyy · HH:mm').format(render.createdAt.toLocal()),

                    style: tokens.textStyle(fontSize: 12, fontWeight: FontWeight.w400, color: tokens.textSecondary),

                  ),

                  if (render.qualityScore != null)

                    Text(

                      'Quality ${(render.qualityScore! * 100).round()}%',

                      style: tokens.textStyle(fontSize: 12, fontWeight: FontWeight.w400, color: tokens.textSecondary),

                    ),

                ],

              ),

            ),

            PopupMenuButton<String>(

              icon: Icon(Icons.more_vert_rounded, color: tokens.textTertiary),

              onSelected: (value) {

                switch (value) {

                  case 'rename':

                    onRename();

                  case 'download':

                    onDownload();

                  case 'preview':

                    onPreview();

                }

              },

              itemBuilder: (_) => [

                PopupMenuItem(value: 'preview', child: Text(s.pinchToZoom)),

                PopupMenuItem(value: 'rename', child: Text(s.rename)),

                PopupMenuItem(value: 'download', child: Text(s.downloadPhoto)),

              ],

            ),

          ],

        ),

      ),

    );

  }

}

