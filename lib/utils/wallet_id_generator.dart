import 'dart:math';

class WalletIdGenerator {
  static final Random _random = Random();
  
  // Tạo ID ví 10 số ngẫu nhiên
  static String generateWalletId() {
    // Tạo số ngẫu nhiên từ 0 đến 9999999999
    int randomNumber = _random.nextInt(10000000000);
    
    // Chuyển thành chuỗi và đảm bảo có đủ 10 chữ số
    String walletId = randomNumber.toString().padLeft(10, '0');
    
    return walletId;
  }
  
  // Tạo ID ví với format đẹp (có dấu gạch ngang)
  static String generateFormattedWalletId() {
    String id = generateWalletId();
    return '${id.substring(0, 4)}-${id.substring(4, 8)}-${id.substring(8)}';
  }
  
  // Validate ID ví
  static bool isValidWalletId(String walletId) {
    // Loại bỏ dấu gạch ngang
    String cleanId = walletId.replaceAll('-', '');
    
    // Kiểm tra độ dài và chỉ chứa số
    return cleanId.length == 10 && RegExp(r'^\d{10}$').hasMatch(cleanId);
  }
  
  // Làm sạch ID ví (loại bỏ dấu gạch ngang)
  static String cleanWalletId(String walletId) {
    return walletId.replaceAll('-', '');
  }
  
  // Format ID ví với dấu gạch ngang
  static String formatWalletId(String walletId) {
    String cleanId = cleanWalletId(walletId);
    if (cleanId.length == 10) {
      return '${cleanId.substring(0, 4)}-${cleanId.substring(4, 8)}-${cleanId.substring(8)}';
    }
    return walletId;
  }
}

