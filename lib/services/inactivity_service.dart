import 'dart:async';
import '../services/token_service.dart';

class InactivityService {
  InactivityService._();
  static InactivityService? _instance;
  static InactivityService get instance => _instance ??= InactivityService._();

  Duration _timeout = const Duration(minutes: 5);
  Future<void> Function()? _onTimeout;
  Timer? _timer;

  void configure({required Duration timeout, required Future<void> Function() onTimeout}) {
    _timeout = timeout;
    _onTimeout = () async {
      try {
        await onTimeout();
      } catch (_) {}
    };
  }

  void start() {
    _timer?.cancel();
    _timer = Timer(_timeout, _notify);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void resetTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = Timer(_timeout, _notify);
    }
  }

  void notifyActivity() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = Timer(_timeout, _notify);
    }
    // Cập nhật mốc hoạt động cho token/session
    TokenService.instance.setLastActivityNow();
  }

  Future<void> _notify() async {
    final cb = _onTimeout;
    if (cb != null) {
      await cb();
    }
  }
}
