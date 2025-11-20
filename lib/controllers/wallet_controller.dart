import 'transaction_controller.dart';
import 'auth_controller.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/database_models.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletController extends GetxController {
  final Rx<Wallet?> userWallet = Rx<Wallet?>(null);
  final RxBool isLoading = false.obs;
  final RxBool hasWallet = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserWallet();
  }

  Future<void> loadUserWallet() async {
    isLoading.value = true;
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        print('No authenticated user found');
        userWallet.value = null;
        hasWallet.value = false;
        return;
      }

      print('🔍 Loading wallet for user: ${currentUser.id}');

      final response = await Supabase.instance.client
          .from('wallets')
          .select('*')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        userWallet.value = Wallet.fromJson(response);
        hasWallet.value = true;
        print('✅ Loaded user wallet: ${userWallet.value?.walletId} (balance: ${userWallet.value?.balance})');
      } else {
        print('No wallet found for user');
        userWallet.value = null;
        hasWallet.value = false;
      }
    } catch (e) {
      print('❌ Error loading user wallet: $e');
      userWallet.value = null;
      hasWallet.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  String _generateUniqueWalletId() {
    final random = Random();
    String walletId;
    
    do {
      // Generate 10-digit number
      walletId = '';
      for (int i = 0; i < 10; i++) {
        walletId += random.nextInt(10).toString();
      }
    } while (walletId.startsWith('0')); // Ensure it doesn't start with 0
    
    return walletId;
  }

  Future<bool> _isWalletIdUnique(String walletId) async {
    try {
      final response = await Supabase.instance.client
          .from('wallets')
          .select('id')
          .eq('id', walletId)
          .maybeSingle();
      
      return response == null;
    } catch (e) {
      print('❌ Error checking wallet ID uniqueness: $e');
      return false;
    }
  }

  Future<bool> createWallet({String? customName}) async {
    isLoading.value = true;
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        Get.snackbar('Lỗi', 'Vui lòng đăng nhập lại');
        return false;
      }

      // Check if user already has a wallet
      if (hasWallet.value) {
        Get.snackbar('Thông báo', 'Bạn đã có ví điện tử');
        return false;
      }

      // Get user name and email from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');

      // Generate unique wallet ID
      String walletId;
      bool isUnique = false;
      int attempts = 0;
      
      do {
        walletId = _generateUniqueWalletId();
        isUnique = await _isWalletIdUnique(walletId);
        attempts++;
        
        if (attempts > 10) {
          throw Exception('Không thể tạo ID ví duy nhất');
        }
      } while (!isUnique);

      // Create wallet with current database schema
      final walletData = {
        'id': walletId,
        'user_id': currentUser.id,
        'so_du': 0.0,
        'loai_tien_te': 'VND',
        'ngay_tao': DateTime.now().toIso8601String(),
        'ngay_cap_nhat': DateTime.now().toIso8601String(),
        'user_name': userName,
        'user_email': userEmail,
      };

      final response = await Supabase.instance.client
          .from('wallets')
          .insert(walletData)
          .select()
          .single();

      userWallet.value = Wallet.fromJson(response);
      hasWallet.value = true;

      Get.snackbar('Thành công', 'Tạo ví điện tử thành công!\nID ví: $walletId');
      return true;
    } catch (e) {
      print('❌ Create wallet error: $e');
      Get.snackbar('Lỗi', 'Không thể tạo ví điện tử: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateWalletBalance(double amount) async {
    if (userWallet.value == null) return false;
    
    try {
      final newBalance = userWallet.value!.balance + amount;
      
      await Supabase.instance.client
          .from('wallets')
          .update({
            'so_du': newBalance,
            'ngay_cap_nhat': DateTime.now().toIso8601String(),
          })
          .eq('id', userWallet.value!.id);

      userWallet.value = userWallet.value!.copyWith(
        balance: newBalance,
        updatedAt: DateTime.now(),
      );

      return true;
    } catch (e) {
      print('❌ Update wallet balance error: $e');
      return false;
    }
  }

  String formatWalletId(String walletId) {
    if (walletId.length == 10) {
      return '${walletId.substring(0, 3)} ${walletId.substring(3, 6)} ${walletId.substring(6)}';
    }
    return walletId;
  }

  String formatBalance(double balance) {
    return '${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND';
  }

  // Force reload wallet (useful after sign in/out)
  Future<void> forceReloadWallet() async {
    print('🔄 Force reloading wallet...');
    await loadUserWallet();
  }

  Future<bool> transferMoney({
    required String recipientWalletId,
    required double amount,
    String? notes,
  }) async {
    if (userWallet.value == null) {
      Get.snackbar('Lỗi', 'Không tìm thấy ví của bạn');
      return false;
    }

    if (amount <= 0) {
      Get.snackbar('Lỗi', 'Số tiền phải lớn hơn 0');
      return false;
    }

    // Remove redundant balance check - RPC will handle this with proper locking
    // if (amount > userWallet.value!.balance) {
    //   Get.snackbar('Lỗi', 'Số dư không đủ');
    //   return false;
    // }

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        Get.snackbar('Lỗi', 'Vui lòng đăng nhập lại');
        return false;
      }

      // Gọi RPC thực thi giao dịch nguyên tử trên server
      print('🔄 Calling RPC perform_transfer with params: ${{
        'p_sender_wallet_id': userWallet.value!.id,
        'p_recipient_wallet_id': recipientWalletId,
        'p_amount': amount,
        'p_notes': notes,
      }}');

      final result = await Supabase.instance.client.rpc('perform_transfer', params: {
        'p_sender_wallet_id': userWallet.value!.id,
        'p_recipient_wallet_id': recipientWalletId,
        'p_amount': amount,
        'p_notes': notes,
      });

      print('✅ RPC result: $result');

      // Sau khi RPC thành công, làm mới số dư ví hiện tại từ DB
      await loadUserWallet();

      // Làm mới lịch sử giao dịch để hiển thị giao dịch mới
      try {
        final transactionController = Get.find<TransactionController>();
        await transactionController.refreshTransactions();
        print('✅ Transactions refreshed after transfer');
      } catch (e) {
        print('⚠️ Could not refresh transactions: $e');
      }

      print('✅ Transfer completed via RPC: $result');
      return true;
    } catch (e) {
      print('❌ Transfer error: $e');
      Get.snackbar('Lỗi', 'Chuyển tiền thất bại: $e');
      return false;
    }
  }
}
