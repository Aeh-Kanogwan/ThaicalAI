import 'food.dart';
import 'quota.dart';

/// A single detected food item within a scan.
/// {
///   "label": "ข้าวผัดกะเพราไก่",
///   "confidence": 0.97,
///   "estimatedPortion": "1 จาน",
///   "matchedFood": { ...Food } | null,
///   "grams": 350
/// }
class ScanItem {
  final String label;
  final double confidence;
  final String? estimatedPortion;
  final Food? matchedFood;
  final double grams;

  const ScanItem({
    required this.label,
    required this.confidence,
    this.estimatedPortion,
    this.matchedFood,
    required this.grams,
  });

  bool get isMatched => matchedFood != null;
  int get confidencePct => (confidence * 100).round();

  factory ScanItem.fromJson(Map<String, dynamic> json) {
    final matched = json['matchedFood'];
    return ScanItem(
      label: json['label'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      estimatedPortion: json['estimatedPortion'] as String?,
      matchedFood: (matched is Map)
          ? Food.fromJson(matched.cast<String, dynamic>())
          : null,
      grams: (json['grams'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'estimatedPortion': estimatedPortion,
        'matchedFood': matchedFood?.toJson(),
        'grams': grams,
      };
}

/// POST /api/v1/scan → { scanId, confidence, items[], quota }
class ScanResult {
  final String scanId;
  final double confidence;
  final List<ScanItem> items;
  final Quota quota;

  const ScanResult({
    required this.scanId,
    required this.confidence,
    required this.items,
    required this.quota,
  });

  int get confidencePct => (confidence * 100).round();

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      scanId: json['scanId']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      items: ((json['items'] as List?) ?? const [])
          .map((e) => ScanItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      quota: Quota.fromJson(
          (json['quota'] as Map?)?.cast<String, dynamic>() ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'scanId': scanId,
        'confidence': confidence,
        'items': items.map((e) => e.toJson()).toList(),
        'quota': quota.toJson(),
      };
}
