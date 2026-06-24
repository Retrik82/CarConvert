import 'package:flutter/foundation.dart';

@immutable
class PricingStepEstimate {
  const PricingStepEstimate({
    required this.stepId,
    required this.label,
    required this.model,
    required this.calls,
    required this.costUsd,
  });

  final String stepId;
  final String label;
  final String model;
  final int calls;
  final double costUsd;

  factory PricingStepEstimate.fromJson(Map<String, dynamic> json) {
    return PricingStepEstimate(
      stepId: json['step_id'] as String,
      label: json['label'] as String,
      model: json['model'] as String,
      calls: json['calls'] as int,
      costUsd: _toDouble(json['cost_usd']),
    );
  }
}

@immutable
class ServicePricingEstimate {
  const ServicePricingEstimate({
    required this.serviceId,
    required this.label,
    required this.actualCostMinUsd,
    required this.actualCostMaxUsd,
    required this.recommendedPriceUsd,
    required this.steps,
  });

  final String serviceId;
  final String label;
  final double actualCostMinUsd;
  final double actualCostMaxUsd;
  final double recommendedPriceUsd;
  final List<PricingStepEstimate> steps;

  factory ServicePricingEstimate.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'] as List<dynamic>? ?? const [];
    return ServicePricingEstimate(
      serviceId: json['service_id'] as String,
      label: json['label'] as String,
      actualCostMinUsd: _toDouble(json['actual_cost_min_usd']),
      actualCostMaxUsd: _toDouble(json['actual_cost_max_usd']),
      recommendedPriceUsd: _toDouble(json['recommended_price_usd']),
      steps: stepsJson
          .map((item) => PricingStepEstimate.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
class AdminPricingEstimate {
  const AdminPricingEstimate({
    required this.generation,
    required this.customBackground,
    required this.chargedGenerationPriceUsd,
    required this.chargedCustomBackgroundPriceUsd,
  });

  final ServicePricingEstimate generation;
  final ServicePricingEstimate customBackground;
  final double chargedGenerationPriceUsd;
  final double chargedCustomBackgroundPriceUsd;

  factory AdminPricingEstimate.fromJson(Map<String, dynamic> json) {
    return AdminPricingEstimate(
      generation: ServicePricingEstimate.fromJson(json['generation'] as Map<String, dynamic>),
      customBackground: ServicePricingEstimate.fromJson(json['custom_background'] as Map<String, dynamic>),
      chargedGenerationPriceUsd: _toDouble(json['charged_generation_price_usd']),
      chargedCustomBackgroundPriceUsd: _toDouble(json['charged_custom_background_price_usd']),
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
