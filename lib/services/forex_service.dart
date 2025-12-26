import 'package:intl/intl.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/services/http_client.dart';

class ForexService {
  ForexService({HttpClientService? client})
    : _client = client ?? HttpClientService();

  final HttpClientService _client;
  static const _baseUrl = 'https://api.frankfurter.dev';

  Future<Map<String, double>> fetchRates({
    required DateTime date,
    required String base,
    required List<String> symbols,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final uri = Uri.parse(
      '$_baseUrl/v1/$formattedDate',
    ).replace(queryParameters: {'base': base, 'symbols': symbols.join(',')});

    final json = await _client.getJson(uri);
    final rates = <String, double>{};
    final map = json['rates'] as Map<String, dynamic>? ?? {};
    map.forEach((key, value) {
      rates[key] = (value as num).toDouble();
    });
    return rates;
  }

  Future<double?> latestRate({
    String base = AppConfig.baseCurrency,
    required String symbol,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/v1/latest',
    ).replace(queryParameters: {'base': base, 'symbols': symbol});
    final json = await _client.getJson(uri);
    final rates = json['rates'] as Map<String, dynamic>? ?? {};
    if (!rates.containsKey(symbol)) return null;
    return (rates[symbol] as num).toDouble();
  }
}
