import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../models/car.dart';
import '../repositories/car_repository.dart';
import '../widgets/design_system/app_card.dart';
import '../widgets/design_system/state_views.dart';
import '../widgets/rename_dialog.dart';
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
    await CarRepository.instance.load();
    setState(() {
      _cars = CarRepository.instance.cars;
      _loading = false;
    });
  }

  Future<void> _renameCar(Car car) async {
    final s = context.strings;
    final name = await showRenameDialog(
      context,
      title: s.renameCar,
      label: s.carName,
      hint: s.carNameHint,
      initialValue: car.name,
    );
    if (name == null) return;
    await CarRepository.instance.updateCarName(car.id, name);
    _load();
  }

  Future<void> _createCar() async {
    final s = context.strings;
    final name = await showRenameDialog(
      context,
      title: s.createCar,
      label: s.carName,
      hint: s.carNameHint,
      initialValue: '',
    );
    if (name == null || name.trim().isEmpty) return;
    await CarRepository.instance.createCar(name: name.trim());
    _load();
  }

  void _openCapture(BuildContext context, {String? carId}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaptureScreen(carId: carId)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(s.navCars),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: s.createCar,
            onPressed: _createCar,
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      floatingActionButton: _cars.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
                boxShadow: [
                  BoxShadow(
                    color: tokens.accent.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _openCapture(context),
                backgroundColor: tokens.accent,
                foregroundColor: tokens.onAccent,
                elevation: 0,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(s.takePhoto),
              ),
            ),
      body: _loading
          ? Padding(
              padding: const EdgeInsets.all(DesignTokens.screenPaddingH),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: DesignTokens.spacing12,
                  mainAxisSpacing: DesignTokens.spacing12,
                  childAspectRatio: 0.82,
                ),
                itemCount: 4,
                itemBuilder: (_, __) => LoadingSkeleton(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
                ),
              ),
            )
          : _cars.isEmpty
              ? EmptyStateView(
                  icon: Icons.directions_car_outlined,
                  title: s.emptyCars,
                  subtitle: s.emptyCarsSubtitle,
                  actionLabel: s.takePhoto,
                  onAction: () => _openCapture(context),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(DesignTokens.screenPaddingH),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: DesignTokens.spacing12,
                      mainAxisSpacing: DesignTokens.spacing12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _cars.length,
                    itemBuilder: (context, index) {
                      final car = _cars[index];
                      return _CarGridCard(
                        car: car,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CarDetailScreen(carId: car.id)),
                          ).then((_) => _load());
                        },
                        onRename: () => _renameCar(car),
                        onAddPhoto: () => _openCapture(context, carId: car.id),
                      );
                    },
                  ),
                ),
    );
  }
}

class _CarGridCard extends StatelessWidget {
  final Car car;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onAddPhoto;

  const _CarGridCard({
    required this.car,
    required this.onTap,
    required this.onRename,
    required this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final preview = car.lastRenderPreview;
    final photoCount = car.renders.length;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(DesignTokens.radiusCard),
                  ),
                  child: preview != null && File(preview).existsSync()
                      ? Image.file(File(preview), fit: BoxFit.cover)
                      : Container(
                          color: tokens.surfaceMuted,
                          child: Icon(Icons.directions_car_outlined, size: 48, color: tokens.textTertiary),
                        ),
                ),
                if (photoCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                      ),
                      child: Text(
                        '$photoCount',
                        style: tokens.textStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacing12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.textStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().format(car.createdAt.toLocal()),
                  style: tokens.textStyle(fontSize: 12, fontWeight: FontWeight.w400, color: tokens.textSecondary),
                ),
                const SizedBox(height: DesignTokens.spacing8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onAddPhoto,
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(s.addRender, style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.drive_file_rename_outline_rounded, size: 18, color: tokens.textTertiary),
                      onPressed: onRename,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
