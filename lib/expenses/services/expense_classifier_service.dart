import 'package:cloud_functions/cloud_functions.dart';
import 'package:morpheus/expenses/models/category_prediction.dart';

/// Response from the category prediction API
class PredictionResult {
  const PredictionResult({required this.predictions, this.reason, this.totalDocs, this.tokensUsed, this.tokensKnown});

  final List<CategoryPrediction> predictions;
  final String? reason;
  final int? totalDocs;
  final int? tokensUsed;
  final int? tokensKnown;

  bool get hasData => predictions.isNotEmpty;
  bool get needsMoreData => reason == 'insufficient_data';
  bool get isNewUser => reason == 'no_model' || reason == 'no_training_data';
}

class ExpenseClassifierService {
  ExpenseClassifierService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  /// Cache to avoid redundant API calls
  final Map<String, PredictionResult> _cache = {};
  static const int _maxCacheSize = 50;

  Future<List<CategoryPrediction>> predictCategories(String title) async {
    final result = await predictCategoriesWithMeta(title);
    return result.predictions;
  }

  Future<PredictionResult> predictCategoriesWithMeta(String title) async {
    final normalized = title.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const PredictionResult(predictions: [], reason: 'empty_input');
    }

    // Check cache first
    if (_cache.containsKey(normalized)) {
      return _cache[normalized]!;
    }

    final callable = _functions.httpsCallable('predictExpenseCategory');
    final result = await callable.call(<String, dynamic>{'title': title});
    final data = result.data;

    if (data is! Map) {
      return const PredictionResult(predictions: [], reason: 'invalid_response');
    }

    final reason = data['reason'] as String?;
    final meta = data['meta'] as Map?;
    final raw = data['predictions'];

    final predictions = <CategoryPrediction>[];
    if (raw is List) {
      for (final entry in raw.whereType<Map>()) {
        final prediction = CategoryPrediction.fromJson(Map<String, dynamic>.from(entry));
        if (prediction.category.isNotEmpty) {
          predictions.add(prediction);
        }
      }
    }

    final predictionResult = PredictionResult(
      predictions: predictions,
      reason: reason,
      totalDocs: (meta?['totalDocs'] as num?)?.toInt(),
      tokensUsed: (meta?['tokensUsed'] as num?)?.toInt(),
      tokensKnown: (meta?['tokensKnown'] as num?)?.toInt(),
    );

    // Update cache (with size limit)
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[normalized] = predictionResult;

    return predictionResult;
  }

  /// Clear the prediction cache
  void clearCache() => _cache.clear();
}
