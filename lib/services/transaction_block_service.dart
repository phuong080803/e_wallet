import 'package:shared_preferences/shared_preferences.dart';

class TransactionBlockService {
  static const String _blockUntilKey = 'transaction_block_until';
  
  /// Block transactions for 5 minutes from now
  Future<void> blockTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final blockUntil = now.add(const Duration(minutes: 5));
    await prefs.setString(_blockUntilKey, blockUntil.toIso8601String());
    print('✅ Transactions blocked until: ${blockUntil.toIso8601String()}');
  }
  
  /// Check if transactions are currently blocked
  Future<bool> isTransactionBlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final blockUntilStr = prefs.getString(_blockUntilKey);
    if (blockUntilStr == null) {
      return false;
    }
    
    try {
      final blockUntil = DateTime.parse(blockUntilStr);
      final now = DateTime.now();
      final isBlocked = now.isBefore(blockUntil);
      
      if (!isBlocked) {
        // Block has expired, clear it
        await prefs.remove(_blockUntilKey);
        print('✅ Transaction block has expired, cleared');
      }
      
      return isBlocked;
    } catch (e) {
      print('❌ Error parsing block time: $e');
      await prefs.remove(_blockUntilKey);
      return false;
    }
  }
  
  /// Get remaining block time in seconds (0 if not blocked)
  Future<int> getRemainingBlockTime() async {
    final prefs = await SharedPreferences.getInstance();
    final blockUntilStr = prefs.getString(_blockUntilKey);
    if (blockUntilStr == null) {
      return 0;
    }
    
    try {
      final blockUntil = DateTime.parse(blockUntilStr);
      final now = DateTime.now();
      final difference = blockUntil.difference(now);
      return difference.isNegative ? 0 : difference.inSeconds;
    } catch (e) {
      print('❌ Error calculating remaining time: $e');
      return 0;
    }
  }
  
  /// Clear the transaction block immediately (admin function or emergency)
  Future<void> clearBlock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_blockUntilKey);
    print('✅ Transaction block cleared');
  }
}

