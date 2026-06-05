import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/car.dart';
import '../services/car_service.dart';
import '../theme/app_theme.dart';
import 'capture_screen.dart';
import 'car_detail_screen.dart';

class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  List<Car> _cars = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await CarService.instance.load();
    setState(() {
      _cars = CarService.instance.cars;
      _loading = false;
    });
  }

  void _openCapture(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaptureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cars'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCapture(context),
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Capture'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cars.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingScreenH),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car_outlined, size: 64, color: AppTheme.textTertiary),
                        const SizedBox(height: AppTheme.spacingElement),
                        Text(
                          'No cars yet',
                          style: AppTheme.textStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: AppTheme.spacingSection),
                        FilledButton.icon(
                          onPressed: () => _openCapture(context),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Take your first photo'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingScreenH,
                      8,
                      AppTheme.spacingScreenH,
                      96,
                    ),
                    itemCount: _cars.length,
                    itemBuilder: (_, i) => _CarCard(
                      car: _cars[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CarDetailScreen(carId: _cars[i].id),
                          ),
                        );
                        _load();
                      },
                    ),
                  ),
                ),
    );
  }
}

class _CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback onTap;

  const _CarCard({required this.car, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final previewPath = car.lastRenderPreview;
    final date = DateFormat('MMM d, yyyy').format(car.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingElement),
      child: Material(
        color: AppTheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: const BorderSide(color: AppTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              SizedBox(
                width: 104,
                height: 104,
                child: previewPath != null && File(previewPath).existsSync()
                    ? Image.file(File(previewPath), fit: BoxFit.cover)
                    : ColoredBox(
                        color: AppTheme.surfaceMuted,
                        child: Icon(Icons.directions_car_outlined, color: AppTheme.textTertiary, size: 40),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingElement),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        car.name,
                        style: AppTheme.textStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Created $date',
                        style: AppTheme.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${car.renders.length} render${car.renders.length == 1 ? '' : 's'}',
                        style: AppTheme.textStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right, color: AppTheme.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
