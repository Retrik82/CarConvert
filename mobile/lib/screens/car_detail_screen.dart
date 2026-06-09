import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/car.dart';
import '../repositories/car_repository.dart';
import '../theme/app_theme.dart';
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

  Future<void> _deleteCar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete car?'),
        content: const Text('All renders for this car will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await CarRepository.instance.deleteCar(widget.carId);
      if (mounted) Navigator.pop(context);
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
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final car = _car;
    if (car == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Car Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(car.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CarInfoCard(car: car),
          const SizedBox(height: 16),
          if (car.renders.isNotEmpty) ...[
            Text(
              'Preview',
              style: AppTheme.textStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: car.renders.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final render = car.renders[i];
                  final path = render.renderedPath ?? render.originalPath;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                    child: path != null && File(path).existsSync()
                        ? Image.file(File(path), width: 160, height: 120, fit: BoxFit.cover)
                        : Container(
                            width: 160,
                            height: 120,
                            color: AppTheme.surface,
                            child: const Icon(Icons.image, color: AppTheme.textSecondary),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Render History',
            style: AppTheme.textStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          ...car.renders.reversed.map((render) => _RenderHistoryTile(
                render: render,
                onTap: () => _openRender(render),
              )),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CaptureScreen(carId: car.id)),
              ).then((_) => _load());
            },
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add Render'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _deleteCar,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Car'),
            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
          ),
        ],
      ),
    );
  }
}

class _CarInfoCard extends StatelessWidget {
  final Car car;

  const _CarInfoCard({required this.car});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingElement),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            car.name,
            style: AppTheme.textStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Created ${DateFormat('MMM d, yyyy').format(car.createdAt.toLocal())}',
            style: AppTheme.textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '${car.renders.length} render${car.renders.length == 1 ? '' : 's'}',
            style: AppTheme.textStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _RenderHistoryTile extends StatelessWidget {
  final RenderResult render;
  final VoidCallback onTap;

  const _RenderHistoryTile({required this.render, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final path = render.renderedPath ?? render.originalPath;
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: path != null && File(path).existsSync()
              ? Image.file(File(path), width: 48, height: 48, fit: BoxFit.cover)
              : Container(
                  width: 48,
                  height: 48,
                  color: AppTheme.surfaceMuted,
                  child: const Icon(Icons.image_outlined, color: AppTheme.textTertiary),
                ),
        ),
        title: Text(
          DateFormat('MMM d, yyyy · HH:mm').format(render.createdAt.toLocal()),
          style: AppTheme.textStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
        ),
        subtitle: render.qualityScore != null
            ? Text(
                'Quality ${(render.qualityScore! * 100).round()}%',
                style: AppTheme.textStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
      ),
    );
  }
}
