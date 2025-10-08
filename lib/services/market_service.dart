import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketService {
  static const _coingecko = 'https://api.coingecko.com/api/v3';
  static const _frankfurter = 'https://api.frankfurter.app/latest';

  Future<List<Map<String, dynamic>>> getCryptoMarkets({String vs = 'vnd', List<String> ids = const ['bitcoin','ethereum','binancecoin']}) async {
    final uri = Uri.parse('$_coingecko/coins/markets?vs_currency=$vs&ids=${ids.join(',')}&price_change_percentage=24h');
    final res = await http.get(uri, headers: {'accept': 'application/json'});
    if (res.statusCode != 200) throw Exception('Crypto API ${res.statusCode}');
    final data = json.decode(res.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getForex({String base = 'USD', List<String> symbols = const ['VND','EUR','JPY']}) async {
    final uri = Uri.parse('$_frankfurter?from=$base&to=${symbols.join(',')}');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Forex API ${res.statusCode}');
    return json.decode(res.body) as Map<String, dynamic>;
  }
}
