import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  
  // Store transfer data temporarily for OTP verification
  final Rx<Map<String, dynamic>?> _pendingTransferData = Rx<Map<String, dynamic>?>(null);

  // Send OTP using Supabase's native functionality
  Future<bool> sendTransferOtp({
    required String recipientWalletId,
    required double amount,
    String? notes,
  }) async {
    isSending.value = true;
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser?.email == null) {
        Get.snackbar('Lỗi', 'Không tìm thấy email để gửi OTP');
        return false;
      }

      // Store transfer data for verification
      _pendingTransferData.value = {
        'recipient_wallet_id': recipientWalletId,
        'amount': amount,
        'notes': notes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Use Supabase's native OTP functionality
      await Supabase.instance.client.auth.signInWithOtp(
        email: currentUser!.email!,
        emailRedirectTo: null, // No redirect needed for mobile app
        shouldCreateUser: false, // Don't create new user
      );

      Get.snackbar(
        'OTP đã gửi',
        'Mã OTP đã được gửi đến email ${currentUser.email}',
        duration: Duration(seconds: 5),
      );
      
      return true;
    } catch (e) {
      print('❌ Error sending OTP: $e');
      Get.snackbar('Lỗi', 'Không thể gửi OTP: $e');
      return false;
    } finally {
      isSending.value = false;
    }
  }

  // Verify OTP using Supabase's native functionality
  Future<Map<String, dynamic>?> verifyTransferOtp(String enteredOtp) async {
    isLoading.value = true;
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser?.email == null) {
        Get.snackbar('Lỗi', 'Vui lòng đăng nhập lại');
        return null;
      }

      // Check if transfer data exists and is not expired (5 minutes)
      if (_pendingTransferData.value == null) {
        Get.snackbar('Lỗi', 'Không tìm thấy thông tin giao dịch');
        return null;
      }

      final transferData = _pendingTransferData.value!;
      final timestamp = transferData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check if data is expired (5 minutes = 300000 milliseconds)
      if (now - timestamp > 300000) {
        Get.snackbar('Lỗi', 'Thông tin giao dịch đã hết hạn');
        _pendingTransferData.value = null;
        return null;
      }

      // Rate limit: ensure attempts are allowed within window
      await Supabase.instance.client.rpc('assert_otp_verify_allowed', params: {
        'p_user_id': currentUser!.id,
        'p_max_attempts': 5,
        'p_window_seconds': 300,
      });

      // Verify OTP with Supabase
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: currentUser.email!,
        token: enteredOtp,
        type: OtpType.email,
      );

      if (response.user != null) {
        // OTP verified successfully, return transfer data
        final data = Map<String, dynamic>.from(transferData);
        data.remove('timestamp'); // Remove timestamp before returning
        
        // Clear pending data
        _pendingTransferData.value = null;
        // Log success attempt
        try {
          await Supabase.instance.client.rpc('log_otp_attempt', params: {
            'p_user_id': currentUser.id,
            'p_context': 'transfer',
            'p_ip': null,
            'p_success': true,
          });
        } catch (_) {}
        
        return data;
      } else {
        Get.snackbar('Lỗi', 'Mã OTP không đúng');
        // Log failed attempt
        try {
          await Supabase.instance.client.rpc('log_otp_attempt', params: {
            'p_user_id': currentUser.id,
            'p_context': 'transfer',
            'p_ip': null,
            'p_success': false,
          });
        } catch (_) {}
        return null;
      }
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      if (e.toString().contains('rate_limit_exceeded')) {
        Get.snackbar('Giới hạn', 'Bạn đã nhập OTP quá số lần cho phép. Vui lòng thử lại sau.');
        return null;
      }
      if (e.toString().contains('invalid_token') || e.toString().contains('token_expired')) {
        Get.snackbar('Lỗi', 'Mã OTP không đúng hoặc đã hết hạn');
      } else {
        Get.snackbar('Lỗi', 'Lỗi xác thực OTP: $e');
      }
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Send OTP for other purposes using Supabase native functionality
  Future<bool> sendOtp({
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    isSending.value = true;
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser?.email == null) {
        Get.snackbar('Lỗi', 'Không tìm thấy email để gửi OTP');
        return false;
      }

      // Store metadata if needed
      if (metadata != null) {
        // You can store metadata in a separate table or use other methods
        // For now, we'll just store it temporarily in memory
      }

      // Use Supabase's native OTP functionality
      await Supabase.instance.client.auth.signInWithOtp(
        email: currentUser.email!,
        emailRedirectTo: null,
        shouldCreateUser: false,
      );

      Get.snackbar(
        'OTP đã gửi',
        'Mã OTP đã được gửi đến email ${currentUser.email}',
        duration: Duration(seconds: 5),
      );
      
      return true;
    } catch (e) {
      print('❌ Error sending OTP: $e');
      Get.snackbar('Lỗi', 'Không thể gửi OTP: $e');
      return false;
    } finally {
      isSending.value = false;
    }
  }

  // Verify OTP for general purposes
  Future<bool> verifyOtp(String enteredOtp) async {
    isLoading.value = true;
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser?.email == null) {
        Get.snackbar('Lỗi', 'Vui lòng đăng nhập lại');
        return false;
      }

      // Rate limit: ensure attempts are allowed within window
      await Supabase.instance.client.rpc('assert_otp_verify_allowed', params: {
        'p_user_id': currentUser!.id,
        'p_max_attempts': 5,
        'p_window_seconds': 300,
      });

      // Verify OTP with Supabase
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: currentUser.email!,
        token: enteredOtp,
        type: OtpType.email,
      );

      if (response.user != null) {
        // Log success attempt
        try {
          await Supabase.instance.client.rpc('log_otp_attempt', params: {
            'p_user_id': currentUser.id,
            'p_context': 'generic',
            'p_ip': null,
            'p_success': true,
          });
        } catch (_) {}
        return true;
      } else {
        Get.snackbar('Lỗi', 'Mã OTP không đúng');
        // Log failed attempt
        try {
          await Supabase.instance.client.rpc('log_otp_attempt', params: {
            'p_user_id': currentUser.id,
            'p_context': 'generic',
            'p_ip': null,
            'p_success': false,
          });
        } catch (_) {}
        return false;
      }
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      if (e.toString().contains('rate_limit_exceeded')) {
        Get.snackbar('Giới hạn', 'Bạn đã nhập OTP quá số lần cho phép. Vui lòng thử lại sau.');
        return false;
      }
      if (e.toString().contains('invalid_token') || e.toString().contains('token_expired')) {
        Get.snackbar('Lỗi', 'Mã OTP không đúng hoặc đã hết hạn');
      } else {
        Get.snackbar('Lỗi', 'Lỗi xác thực OTP: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Clear pending transfer data
  void clearPendingData() {
    _pendingTransferData.value = null;
  }

  // Check if there's pending transfer data
  bool get hasPendingTransfer => _pendingTransferData.value != null;
}
