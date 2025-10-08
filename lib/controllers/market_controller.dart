import 'package:get/get.dart';
import '../services/market_service.dart';

class MarketController extends GetxController {
  final MarketService _service = MarketService();

  final isLoading = false.obs;
  final crypto = <Map<String, dynamic>>[].obs; // from CoinGecko
  final forex = <String, dynamic>{}.obs; // from Frankfurter
  DateTime? _lastFetch;

  Future<void> fetchAll({bool force = false}) async {
    if (!force && _lastFetch != null && DateTime.now().difference(_lastFetch!).inMinutes < 5) return;
    isLoading.value = true;
    try {
      final c = await _service.getCryptoMarkets();
      final f = await _service.getForex();
      crypto.assignAll(c);
      forex.assignAll(f);
      _lastFetch = DateTime.now();
    } catch (e) {
      // Keep previous cache; optionally log
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }
}
