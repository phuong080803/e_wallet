import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/database_models.dart' as models;

class ProfileController extends GetxController {
  final Rx<models.User?> currentUser = Rx<models.User?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    isLoading.value = true;
    try {
      final currentAuthUser = Supabase.instance.client.auth.currentUser;
      if (currentAuthUser == null) {
        print('No authenticated user found');
        return;
      }

      // Lấy dữ liệu từ user metadata theo cấu trúc authentication JSON
      final userMetadata = currentAuthUser.userMetadata ?? {};
      
      // Tạo User object từ metadata với cấu trúc đúng
      final userData = {
        'id': currentAuthUser.id,
        'email': currentAuthUser.email,
        'name': userMetadata['name'] ?? '', // Lấy từ name trong user_metadata
        'dateOfBirth': userMetadata['ngay_sinh'],
        'address': userMetadata['dia_chi'],
        'image': userMetadata['hinh_anh'],
        'created_at': currentAuthUser.createdAt,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      currentUser.value = models.User.fromJson(userData);
      print('✅ Loaded user profile from metadata: ${currentUser.value?.name}');
    } catch (e) {
      print('❌ Error loading user profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? dateOfBirth,
    String? address,
    String? image,
  }) async {
    isLoading.value = true;
    try {
      final currentAuthUser = Supabase.instance.client.auth.currentUser;
      if (currentAuthUser == null) {
        Get.snackbar('Lỗi', 'Vui lòng đăng nhập lại');
        return false;
      }

      // Lấy metadata hiện tại
      final currentMetadata = currentAuthUser.userMetadata ?? {};
      
      // Tạo metadata mới
      final newMetadata = Map<String, dynamic>.from(currentMetadata);
      
      if (name != null) newMetadata['name'] = name;
      if (dateOfBirth != null) newMetadata['ngay_sinh'] = dateOfBirth;
      if (address != null) newMetadata['dia_chi'] = address;
      if (image != null) newMetadata['hinh_anh'] = image;
      
      newMetadata['updated_at'] = DateTime.now().toIso8601String();

      // Cập nhật user metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: newMetadata,
        ),
      );

      // Reload profile data từ metadata
      await loadUserProfile();

      Get.snackbar('Thành công', 'Cập nhật thông tin cá nhân thành công');
      return true;
    } catch (e) {
      print('❌ Update profile error: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật thông tin cá nhân');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Validation methods
  bool isValidName(String name) {
    return name.trim().length >= 2 && name.trim().length <= 100;
  }

  bool isValidDateOfBirth(DateTime dateOfBirth) {
    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;
    final hasHadBirthdayThisYear = now.month > dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
    
    final actualAge = hasHadBirthdayThisYear ? age : age - 1;
    return actualAge >= 16 && actualAge <= 120;
  }

  bool isValidAddress(String address) {
    return address.trim().length >= 10 && address.trim().length <= 500;
  }

  bool isValidImageUrl(String url) {
    if (url.isEmpty) return true; // Allow empty image
    return Uri.tryParse(url) != null;
  }
}
