import 'dart:math';

class TransferService {
  // Tự sinh OTP 6 số và trả về cả challengeId + otp để UI hiển thị
  Future<Map<String, String>> createChallenge({
    required String senderWalletId,
    required String recipientWalletId,
    required double amount,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString(); // 100000-999999

    final challengeId = 'local_challenge_${DateTime.now().millisecondsSinceEpoch}';

    // Nếu cần giữ thêm metadata tạm thời, có thể lưu vào bộ nhớ tĩnh hoặc state management
    return {
      'challengeId': challengeId,
      'otp': otp,
    };
  }

  // Xác nhận OTP và thực thi chuyển tiền qua RPC (DEV: luôn thành công)
  Future<Map<String, dynamic>?> confirmTransfer({
    required String challengeId,
    required String otp,
  }) async {
    return {
      'success': true,
      'reference': 'TXN${DateTime.now().millisecondsSinceEpoch}',
    };
  }
}
