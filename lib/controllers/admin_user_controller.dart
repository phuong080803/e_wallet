import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/database_models.dart' as models;

class AdminUserController extends GetxController {
  final RxList<models.AdminUser> adminUsers = <models.AdminUser>[].obs;
  final Rx<models.AdminUser?> currentAdmin = Rx<models.AdminUser?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> loadAllAdminUsers() async {
    isLoading.value = true;
    try {
      final response = await Supabase.instance.client
          .from('admin_users')
          .select('*')
          .order('created_at', ascending: false);
      
      adminUsers.value = (response as List)
          .map((json) => models.AdminUser.fromJson(json))
          .toList();
      
      print('✅ Loaded ${adminUsers.length} admin users');
    } catch (e) {
      print('❌ Error loading admin users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createAdminUser({
    required String username,
    required String password,
    String? email,
    String? fullName,
  }) async {
    isLoading.value = true;
    try {
      final adminData = {
        'username': username,
        'password': password, // Trong thực tế nên hash password
        'email': email,
        'full_name': fullName,
        'is_active': true,
      };
      
      await Supabase.instance.client
          .from('admin_users')
          .insert(adminData);

      await loadAllAdminUsers();
      Get.snackbar('Thành công', 'Tạo admin user thành công');
      return true;
    } catch (e) {
      print('❌ Create admin user error: $e');
      Get.snackbar('Lỗi', 'Không thể tạo admin user');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateAdminUser({
    required String adminId,
    String? username,
    String? password,
    String? email,
    String? fullName,
    bool? isActive,
  }) async {
    isLoading.value = true;
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (username != null) updateData['username'] = username;
      if (password != null) updateData['password'] = password;
      if (email != null) updateData['email'] = email;
      if (fullName != null) updateData['full_name'] = fullName;
      if (isActive != null) updateData['is_active'] = isActive;
      
      await Supabase.instance.client
          .from('admin_users')
          .update(updateData)
          .eq('id', adminId);

      await loadAllAdminUsers();
      Get.snackbar('Thành công', 'Cập nhật admin user thành công');
      return true;
    } catch (e) {
      print('❌ Update admin user error: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật admin user');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteAdminUser(String adminId) async {
    isLoading.value = true;
    try {
      await Supabase.instance.client
          .from('admin_users')
          .delete()
          .eq('id', adminId);

      await loadAllAdminUsers();
      Get.snackbar('Thành công', 'Xóa admin user thành công');
      return true;
    } catch (e) {
      print('❌ Delete admin user error: $e');
      Get.snackbar('Lỗi', 'Không thể xóa admin user');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> loginAdmin({
    required String username,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final response = await Supabase.instance.client
          .from('admin_users')
          .select('*')
          .eq('username', username)
          .eq('password', password) // Trong thực tế nên hash và compare
          .eq('is_active', true)
          .maybeSingle();
      
      if (response != null) {
        currentAdmin.value = models.AdminUser.fromJson(response);
        
        // Cập nhật last_login
        await Supabase.instance.client
            .from('admin_users')
            .update({
              'last_login': DateTime.now().toIso8601String(),
            })
            .eq('id', response['id']);
        
        Get.snackbar('Thành công', 'Đăng nhập admin thành công');
        return true;
      } else {
        Get.snackbar('Lỗi', 'Tên đăng nhập hoặc mật khẩu không đúng');
        return false;
      }
    } catch (e) {
      print('❌ Admin login error: $e');
      Get.snackbar('Lỗi', 'Không thể đăng nhập admin');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logoutAdmin() async {
    currentAdmin.value = null;
    Get.snackbar('Thông báo', 'Đã đăng xuất khỏi admin');
  }

  // Validation methods
  bool isValidUsername(String username) {
    return username.trim().length >= 3 && username.trim().length <= 50;
  }

  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}


