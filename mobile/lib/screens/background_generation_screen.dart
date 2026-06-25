import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../models/background.dart';
import '../repositories/auth_repository.dart';
import '../repositories/background_repository.dart';
import '../utils/error_utils.dart';
import '../utils/money_format.dart';
import '../widgets/background_preview_grid.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/app_card.dart';

enum _GenerationPhase { processing, result, error }

class BackgroundGenerationScreen extends StatefulWidget {
  final String name;
  final String prompt;
  final double priceUsd;

  const BackgroundGenerationScreen({
    super.key,
    required this.name,
    required this.prompt,
    required this.priceUsd,
  });

  @override
  State<BackgroundGenerationScreen> createState() => _BackgroundGenerationScreenState();
}

class _BackgroundGenerationScreenState extends State<BackgroundGenerationScreen> {
  final _repo = BackgroundRepository.instance;
  _GenerationPhase _phase = _GenerationPhase.processing;
  String _status = '';
  double _progress = 0;
  String? _error;
  BackgroundPreset? _result;
  Timer? _progressTimer;
  bool _syncedBalanceAfterRun = false;
  bool _apiCallStarted = false;

  @override
  void initState() {
    super.initState();
    _startGeneration();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _tickProgress() {
    if (!mounted || _phase != _GenerationPhase.processing) return;
    setState(() {
      final maxProgress = _apiCallStarted ? 95.0 : 28.0;
      if (_progress < maxProgress) {
        final step = _apiCallStarted ? 2.0 : 1.5;
        _progress = (_progress + step).clamp(0, maxProgress);
      }
    });
  }

  Future<void> _startGeneration() async {
    final s = context.strings;
    final auth = AuthRepository.instance;
    _syncedBalanceAfterRun = false;
    _apiCallStarted = false;
    _progressTimer?.cancel();
    setState(() {
      _phase = _GenerationPhase.processing;
      _progress = 5;
      _error = null;
      _result = null;
      _status = s.backgroundGeneratingStatus;
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 400), (_) => _tickProgress());

    try {
      // Short warm-up + auth in parallel. The generation POST has a 15 min timeout
      // and itself wakes cold hosts — no need for multi-minute blocking here.
      await Future.wait([
        auth.ensureSessionReady(),
        auth.httpClient.wakeServer(
          attempts: 2,
          requestTimeout: const Duration(seconds: 60),
        ),
      ]);

      final user = await auth.refreshCurrentUser();
      if (user.balance < widget.priceUsd) {
        throw Exception(
          'Insufficient balance. Need ${MoneyFormat.usd(widget.priceUsd)}, available ${MoneyFormat.usd(user.balance)}',
        );
      }

      if (!mounted) return;
      setState(() {
        _apiCallStarted = true;
        _progress = 32;
        _status = s.backgroundGeneratingAngles;
      });

      final preset = await _repo.createCustomBackground(name: widget.name, prompt: widget.prompt);
      _repo.clearImageCache();
      try {
        await AuthRepository.instance.refreshCurrentUser();
        _syncedBalanceAfterRun = true;
      } catch (_) {}

      _progressTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _result = preset;
        _progress = 100;
        _phase = _GenerationPhase.result;
        _status = s.backgroundGenerated;
      });
    } catch (e) {
      _progressTimer?.cancel();
      if (!mounted) return;

      final recovered = await _recoverGeneratedBackground();
      if (recovered != null) {
        _repo.clearImageCache();
        if (!mounted) return;
        setState(() {
          _result = recovered;
          _progress = 100;
          _phase = _GenerationPhase.result;
          _status = s.backgroundGenerated;
          _error = null;
        });
        return;
      }

      setState(() {
        _phase = _GenerationPhase.error;
        _error = isTimeoutError(e) ? s.backgroundGenerationTimeoutError : userFacingError(e);
        _status = s.errorGeneric;
      });
    } finally {
      if (_syncedBalanceAfterRun) return;
      try {
        await AuthRepository.instance.refreshCurrentUser();
      } catch (_) {}
    }
  }

  Future<BackgroundPreset?> _recoverGeneratedBackground() async {
    try {
      final catalog = await _repo.fetchCatalog();
      final normalizedTargetName = _normalize(widget.name);
      final normalizedTargetPrompt = _normalize(widget.prompt);
      final candidates = catalog.custom;

      for (final candidate in candidates.reversed) {
        final candidateName = _normalize(candidate.name);
        if (candidateName != normalizedTargetName) continue;

        final candidatePrompt = _normalize(candidate.generationPrompt ?? '');
        if (candidatePrompt.isNotEmpty &&
            normalizedTargetPrompt.isNotEmpty &&
            candidatePrompt != normalizedTargetPrompt) {
          continue;
        }
        return candidate;
      }
    } catch (_) {}
    return null;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _useBackground() {
    final preset = _result;
    if (preset == null) return;
    _repo.select(preset);
    Navigator.pop(context, _repo.selected);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;

    return PopScope(
      canPop: _phase != _GenerationPhase.processing,
      child: Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          title: Text(s.backgroundGeneratingTitle),
          leading: _phase == _GenerationPhase.processing
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.screenPaddingH),
            child: switch (_phase) {
              _GenerationPhase.processing => _ProcessingBody(
                  name: widget.name,
                  progress: _progress,
                  status: _status,
                  tokens: tokens,
                  s: s,
                ),
              _GenerationPhase.result => _ResultBody(
                  preset: _result!,
                  onUse: _useBackground,
                  s: s,
                  tokens: tokens,
                ),
              _GenerationPhase.error => _ErrorBody(
                  message: _error ?? s.errorGeneric,
                  onRetry: _startGeneration,
                  s: s,
                  tokens: tokens,
                ),
            },
          ),
        ),
      ),
    );
  }
}

class _ProcessingBody extends StatelessWidget {
  final String name;
  final double progress;
  final String status;
  final AppTokens tokens;
  final AppStrings s;

  const _ProcessingBody({
    required this.name,
    required this.progress,
    required this.status,
    required this.tokens,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: DesignTokens.spacing24),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tokens.surfaceMuted,
                  tokens.surface,
                  tokens.accent.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
              boxShadow: tokens.elevatedShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    value: progress > 0 && progress < 100 ? progress / 100 : null,
                    color: tokens.accent,
                    backgroundColor: tokens.surfaceMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing24),
                Icon(Icons.auto_awesome_rounded, size: 40, color: tokens.accent.withValues(alpha: 0.7)),
                const SizedBox(height: DesignTokens.spacing12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing24),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: tokens.textStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacing32),
        Text(
          s.backgroundGeneratingTitle,
          style: tokens.textStyle(fontSize: 22, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spacing16),
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
          child: LinearProgressIndicator(
            value: progress / 100,
            minHeight: 8,
            backgroundColor: tokens.surfaceMuted,
            color: tokens.accent,
          ),
        ),
        const SizedBox(height: DesignTokens.spacing8),
        Text(
          '${progress.round()}%',
          style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w500, color: tokens.textSecondary),
        ),
        const SizedBox(height: DesignTokens.spacing12),
        Text(
          status,
          textAlign: TextAlign.center,
          style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: tokens.textTertiary),
        ),
        const SizedBox(height: DesignTokens.spacing32),
      ],
    );
  }
}

class _ResultBody extends StatelessWidget {
  final BackgroundPreset preset;
  final VoidCallback onUse;
  final AppStrings s;
  final AppTokens tokens;

  const _ResultBody({
    required this.preset,
    required this.onUse,
    required this.s,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: DesignTokens.spacing8),
        Text(
          s.backgroundGenerated,
          style: tokens.textStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: DesignTokens.spacing8),
        Text(
          preset.name,
          style: tokens.textStyle(fontSize: 15, fontWeight: FontWeight.w400, color: tokens.textSecondary),
        ),
        const SizedBox(height: DesignTokens.spacing24),
        Expanded(
          child: AppCard(
            elevated: true,
            padding: const EdgeInsets.all(DesignTokens.spacing12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.backgroundResultPreview,
                  style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DesignTokens.spacing12),
                Expanded(
                  child: SingleChildScrollView(
                    child: BackgroundPreviewGrid(preset: preset),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacing24),
        AppButton(
          label: s.useThisBackground,
          icon: Icons.check_rounded,
          onPressed: onUse,
        ),
        const SizedBox(height: DesignTokens.spacing12),
        AppButton(
          label: s.cancel,
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.pop(context, null),
        ),
        const SizedBox(height: DesignTokens.spacing16),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AppStrings s;
  final AppTokens tokens;

  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.s,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, size: 56, color: tokens.error),
        const SizedBox(height: DesignTokens.spacing16),
        Text(
          s.errorGeneric,
          style: tokens.textStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: DesignTokens.spacing8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: tokens.textStyle(fontSize: 14, fontWeight: FontWeight.w400, color: tokens.textSecondary),
        ),
        const SizedBox(height: DesignTokens.spacing24),
        AppButton(label: s.retry, icon: Icons.refresh_rounded, onPressed: onRetry),
      ],
    );
  }
}
