import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DigitalOtpController extends GetxController {
  static const _pinKey = 'digital_otp_pin';
  final _supabase = Supabase.instance.client;

  final RxBool isBusy = false.obs;

  // Hash PIN để bảo mật
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<bool> hasPin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      final metadata = user.userMetadata ?? {};
      final pin = metadata[_pinKey];
      return pin != null && pin.toString().isNotEmpty;
    } catch (e) {
      print('❌ Error checking PIN: $e');
      return false;
    }
  }

  Future<void> setPin(String pin) async {
    if (pin.length != 6 || int.tryParse(pin) == null) {
      throw Exception('PIN không hợp lệ. Vui lòng nhập 6 chữ số.');
    }
    
    isBusy.value = true;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      // Hash PIN trước khi lưu
      final hashedPin = _hashPin(pin);
      
      // Lấy metadata hiện tại
      final currentMetadata = user.userMetadata ?? {};
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      
      // Cập nhật PIN
      newMetadata[_pinKey] = hashedPin;
      newMetadata['digital_otp_updated_at'] = DateTime.now().toIso8601String();
      
      // Lưu vào Supabase user_metadata
      await _supabase.auth.updateUser(
        UserAttributes(data: newMetadata),
      );
      
      print('✅ PIN đã được lưu vào Supabase metadata');
    } catch (e) {
      print('❌ Error setting PIN: $e');
      throw Exception('Không thể lưu PIN: $e');
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;
      
      final metadata = user.userMetadata ?? {};
      final savedHashedPin = metadata[_pinKey];
      
      if (savedHashedPin == null) return false;
      
      // Hash PIN nhập vào và so sánh
      final hashedPin = _hashPin(pin);
      return savedHashedPin == hashedPin;
    } catch (e) {
      print('❌ Error verifying PIN: $e');
      return false;
    }
  }

  Future<void> clearPin() async {
    isBusy.value = true;
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Vui lòng đăng nhập lại');
      }

      // Lấy metadata hiện tại
      final currentMetadata = user.userMetadata ?? {};
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      
      // Xóa PIN
      newMetadata.remove(_pinKey);
      newMetadata.remove('digital_otp_updated_at');
      
      // Cập nhật Supabase
      await _supabase.auth.updateUser(
        UserAttributes(data: newMetadata),
      );
      
      print('✅ PIN đã được xóa khỏi Supabase metadata');
    } catch (e) {
      print('❌ Error clearing PIN: $e');
      throw Exception('Không thể xóa PIN: $e');
    } finally {
      isBusy.value = false;
    }
  }
}
