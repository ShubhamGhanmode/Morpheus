class CategoryPrediction {
  const CategoryPrediction({required this.category, required this.confidence, this.support = 0});

  final String category;
  final double confidence;
  final int support; // Number of training examples for this category

  /// Returns confidence as a percentage string (e.g., "85%")
  String get confidencePercent => '${(confidence * 100).round()}%';

  /// Whether this prediction is high confidence (>70%)
  bool get isHighConfidence => confidence >= 0.7;

  /// Whether this prediction is medium confidence (40-70%)
  bool get isMediumConfidence => confidence >= 0.4 && confidence < 0.7;

  factory CategoryPrediction.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String? ?? '';
    final confidence = (json['confidence'] as num?)?.toDouble() ?? 0;
    final support = (json['support'] as num?)?.toInt() ?? 0;
    return CategoryPrediction(category: category, confidence: confidence, support: support);
  }

  Map<String, dynamic> toJson() => {'category': category, 'confidence': confidence, 'support': support};

  @override
  String toString() => 'CategoryPrediction(category: $category, confidence: $confidencePercent, support: $support)';
}
