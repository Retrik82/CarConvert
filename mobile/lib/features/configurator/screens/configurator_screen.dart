import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../screens/capture_screen.dart';
import '../../../widgets/design_system/app_button.dart';
import '../../../widgets/design_system/car_hero.dart';
import '../../../widgets/design_system/config_option.dart';
import '../../../widgets/design_system/config_progress.dart';
import '../../../widgets/design_system/summary_panel.dart';
import '../models/car_configuration.dart';

class ConfiguratorScreen extends StatefulWidget {
  final VoidCallback? onBalanceChanged;

  const ConfiguratorScreen({super.key, this.onBalanceChanged});

  @override
  State<ConfiguratorScreen> createState() => _ConfiguratorScreenState();
}

class _ConfiguratorScreenState extends State<ConfiguratorScreen> {
  final _controller = CarConfigurationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _stepLabels(AppStrings s) => [
        s.stepColor,
        s.stepWheels,
        s.stepInterior,
        s.stepStudio,
        s.stepSummary,
      ];

  String _stepTitle(AppStrings s, ConfigStep step) => switch (step) {
        ConfigStep.color => s.selectColor,
        ConfigStep.wheels => s.selectWheels,
        ConfigStep.interior => s.selectInterior,
        ConfigStep.studio => s.selectStudio,
        ConfigStep.summary => s.yourConfiguration,
      };

  void _onContinue() {
    if (_controller.step == ConfigStep.summary) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CaptureScreen(
            initialMode: CaptureMode.camera,
            onBalanceChanged: widget.onBalanceChanged,
          ),
        ),
      );
      return;
    }
    _controller.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final step = _controller.step;
        final config = _controller.config;

        return Scaffold(
          backgroundColor: tokens.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () {
                if (step == ConfigStep.color) {
                  Navigator.pop(context);
                } else {
                  _controller.previousStep();
                }
              },
            ),
            title: Text(s.configTitle),
          ),
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConfigProgress(
                              currentStep: step.index,
                              totalSteps: ConfigStep.values.length,
                              labels: _stepLabels(s),
                            ),
                            const SizedBox(height: DesignTokens.spacing24),
                            AnimatedSwitcher(
                              duration: DesignTokens.durationTheme,
                              switchInCurve: DesignTokens.curveEmphasized,
                              switchOutCurve: DesignTokens.curveStandard,
                              child: CarHero(
                                key: ValueKey('${step.name}-${config.exterior.name}'),
                                bodyColor: config.bodyColor,
                                height: 220,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spacing24),
                            Text(
                              _stepTitle(s, step),
                              style: tokens.textStyle(fontSize: 22, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: DesignTokens.spacing16),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
                      sliver: SliverToBoxAdapter(
                        child: _buildStepContent(step, config),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
              StickyBottomCta(
                child: AppButton(
                  label: step == ConfigStep.summary ? s.confirmAndCapture : s.continueStep,
                  icon: step == ConfigStep.summary ? Icons.camera_alt_outlined : Icons.arrow_forward_rounded,
                  onPressed: _onContinue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepContent(ConfigStep step, CarConfiguration config) {
    return switch (step) {
      ConfigStep.color => _ColorStep(
          selected: config.exterior,
          onSelect: _controller.setExterior,
        ),
      ConfigStep.wheels => _OptionListStep<WheelStyle>(
          values: WheelStyle.values,
          selected: config.wheels,
          onSelect: _controller.setWheels,
          label: (w) => w.label,
          subtitle: (w) => w.subtitle,
        ),
      ConfigStep.interior => _OptionListStep<InteriorStyle>(
          values: InteriorStyle.values,
          selected: config.interior,
          onSelect: _controller.setInterior,
          label: (i) => i.label,
          subtitle: (i) => i.subtitle,
        ),
      ConfigStep.studio => _OptionListStep<StudioEnvironment>(
          values: StudioEnvironment.values,
          selected: config.studio,
          onSelect: _controller.setStudio,
          label: (e) => e.label,
          subtitle: (e) => e.subtitle,
        ),
      ConfigStep.summary => SummaryPanel(
          title: context.strings.yourConfiguration,
          rows: [
            SummaryRow(
              label: context.strings.stepColor,
              value: config.exterior.label,
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: config.exterior.color, shape: BoxShape.circle),
              ),
            ),
            SummaryRow(label: context.strings.stepWheels, value: config.wheels.label),
            SummaryRow(label: context.strings.stepInterior, value: config.interior.label),
            SummaryRow(label: context.strings.stepStudio, value: config.studio.label),
          ],
        ),
    };
  }
}

class _ColorStep extends StatelessWidget {
  final ExteriorColor selected;
  final ValueChanged<ExteriorColor> onSelect;

  const _ColorStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DesignTokens.spacing16,
      runSpacing: DesignTokens.spacing16,
      alignment: WrapAlignment.center,
      children: ExteriorColor.values
          .map(
            (c) => ColorSwatchOption(
              color: c.color,
              label: c.label,
              selected: c == selected,
              onTap: () => onSelect(c),
            ),
          )
          .toList(),
    );
  }
}

class _OptionListStep<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final ValueChanged<T> onSelect;
  final String Function(T) label;
  final String Function(T) subtitle;

  const _OptionListStep({
    required this.values,
    required this.selected,
    required this.onSelect,
    required this.label,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: values.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spacing12),
          child: ConfigOption(
            label: label(item),
            subtitle: subtitle(item),
            selected: item == selected,
            onTap: () => onSelect(item),
          ),
        );
      }).toList(),
    );
  }
}
