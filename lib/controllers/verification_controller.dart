import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../models/database_models.dart';
import 'dart:io';

class VerificationController extends GetxController {
  final Rx<UserVerification?> userVerification = Rx<UserVerification?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> loadUserVerification() async {
    isLoading.value = true;
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        print('No authenticated user found');
        return;
      }

      final response = await Supabase.instance.client
          .from('user_verifications')
          .select('*')
          .eq('user_id', currentUser.id)
          .maybeSingle();
      
      if (response != null) {
        userVerification.value = UserVerification.fromJson(response);
        print('✅ Loaded user verification: ${userVerification.value?.verificationStatus}');
      } else {
        print('No verification data found for user');
        userVerification.value = null;
      }
    } catch (e) {
      print('❌ Error loading user verification: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadVerification(String userId) async {
    isLoading.value = true;
    try {
      final response = await Supabase.instance.client
          .from('user_verifications')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null) {
        userVerification.value = UserVerification.fromJson(response);
      } else {
        userVerification.value = null;
      }
    } catch (e) {
      print('Error loading verification: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitVerification({
    required String phoneNumber,
    required String idCardNumber,
    required File frontIdImage,
    required File backIdImage,
  }) async {
    isLoading.value = true;
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        Get.snackbar('Lỗi', 'Vui lòng đăng nhập lại');
        return false;
      }

      // Upload images to Supabase Storage
      String? frontImageUrl;
      String? backImageUrl;
      
      try {
        if (frontIdImage != null) {
          final frontFileName = 'front_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await Supabase.instance.client.storage
              .from('verification_images')
              .uploadBinary(frontFileName, await frontIdImage.readAsBytes());
          
          frontImageUrl = Supabase.instance.client.storage
              .from('verification_images')
              .getPublicUrl(frontFileName);
        }
        
        if (backIdImage != null) {
          final backFileName = 'back_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await Supabase.instance.client.storage
              .from('verification_images')
              .uploadBinary(backFileName, await backIdImage.readAsBytes());
          
          backImageUrl = Supabase.instance.client.storage
              .from('verification_images')
              .getPublicUrl(backFileName);
        }
      } catch (storageError) {
        print('⚠️ Storage upload failed: $storageError');
        Get.snackbar(
          'Cảnh báo', 
          'Không thể upload ảnh. Thông tin xác thực sẽ được lưu không có ảnh.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        // Continue without images
      }

      // Save verification data with image URLs
      final verificationData = {
        'user_id': currentUser.id,
        'phone_number': phoneNumber,
        'id_card_number': idCardNumber,
        'verification_status': 'pending',
        'phone_verified': false,
        'id_card_verified': false,
        'front_id_image_url': frontImageUrl,
        'back_id_image_url': backImageUrl,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await Supabase.instance.client
          .from('user_verifications')
          .upsert(verificationData);

      // Reload verification data
      await loadUserVerification();

      return true;
    } catch (e) {
      print('❌ Submit verification error: $e');
      Get.snackbar('Lỗi', 'Không thể gửi thông tin xác thực: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateVerification({
    required String verificationId,
    required String phoneNumber,
    required String idCardNumber,
  }) async {
    isLoading.value = true;
    try {
      final verificationData = {
        'phone_number': phoneNumber,
        'id_card_number': idCardNumber,
        'verification_status': 'pending',
        'phone_verified': false,
        'id_card_verified': false,
      };
      await Supabase.instance.client
          .from('user_verifications')
          .update(verificationData)
          .eq('id', verificationId);

      // Reload verification data
      await loadUserVerification();

      Get.snackbar('Thành công', 'Thông tin xác thực đã được cập nhật');
      return true;
    } catch (e) {
      print('❌ Update verification error: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật thông tin xác thực');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Check if user is verified
  bool get isUserVerified {
    return userVerification.value?.verificationStatus == 'approved';
  }

  // Check if user has pending verification
  bool get hasPendingVerification {
    return userVerification.value?.verificationStatus == 'pending';
  }

  // Validation methods
  bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    return phoneRegex.hasMatch(phone);
  }

  bool isValidIdCard(String idCard) {
    final idCardRegex = RegExp(r'^[0-9]{9,12}$');
    return idCardRegex.hasMatch(idCard);
  }
}
