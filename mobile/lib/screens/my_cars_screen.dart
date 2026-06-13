import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../models/car.dart';
import '../repositories/car_repository.dart';
import '../widgets/design_system/state_views.dart';
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

  void _openCapture(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaptureScreen()),
    );
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
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCapture(context),
        icon: const Icon(Icons.camera_alt_outlined),
        label: Text(s.takePhoto),
      ),
      body: _loading
          ? Padding(
              padding: const EdgeInsets.all(DesignTokens.screenPaddingH),
              child: Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.spacing16),
                    child: LoadingSkeleton(
                      height: 100,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
                    ),
                  ),
                ),
              ),
            )
          : _cars.isEmpty
              ? EmptyStateView(
                  icon: Icons.directions_car_outlined,
                  title: s.emptyCars,
                  subtitle: s.emptyCarsSubtitle,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(DesignTokens.screenPaddingH),
                    itemCount: _cars.length,
                    itemBuilder: (context, index) {
                      final car = _cars[index];
                      return _CarListTile(
                        car: car,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CarDetailScreen(carId: car.id)),
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _CarListTile extends StatelessWidget {
  final Car car;
  final VoidCallback onTap;

  const _CarListTile({required this.car, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacing12),
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacing16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
              border: Border.all(color: tokens.border.withValues(alpha: 0.7)),
              boxShadow: tokens.cardShadow,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                  child: car.lastRenderPreview != null && File(car.lastRenderPreview!).existsSync()
                      ? Image.file(File(car.lastRenderPreview!), width: 72, height: 72, fit: BoxFit.cover)
                      : Container(
                          width: 72,
                          height: 72,
                          color: tokens.surfaceMuted,
                          child: Icon(Icons.directions_car_outlined, color: tokens.textTertiary),
                        ),
                ),
                const SizedBox(width: DesignTokens.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        car.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tokens.textStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().format(car.createdAt.toLocal()),
                        style: tokens.textStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: tokens.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
