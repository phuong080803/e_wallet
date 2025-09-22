import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/database_models.dart' as models;
import '../config/admin_config.dart';
import '../pages/screens/auth/screens/login_screen.dart';

class AdminController extends GetxController {
  final RxList<models.UserVerification> pendingVerifications = <models.UserVerification>[].obs;
  final RxList<models.User> allUsers = <models.User>[].obs;
  final RxList<models.Transaction> allTransactions = <models.Transaction>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = true.obs; // Admin luôn đăng nhập khi vào dashboard

  @override
  void onInit() {
    super.onInit();
    loadPendingVerifications();
    loadAllUsers();
    loadAllTransactions();
  }

  Future<void> logoutAdmin() async {
    try {
      print('🚪 Admin logging out...');
      isLoggedIn.value = false;
      Get.snackbar('Thông báo', 'Đã đăng xuất khỏi admin');
      // Chuyển về màn hình login (sử dụng Get.offAll thay vì Get.offAllNamed)
      Get.offAll(() => LoginScreen());
      print('✅ Admin logout successful');
    } catch (e) {
      print('❌ Admin logout error: $e');
      // Vẫn chuyển về login dù có lỗi
      Get.offAll(() => LoginScreen());
    }
  }

  Future<void> loadPendingVerifications() async {
    isLoading.value = true;
    try {
      final response = await Supabase.instance.client
          .from('user_verifications')
          .select('*')
          .eq('verification_status', 'pending');
      
      pendingVerifications.value = (response as List)
          .map((json) => models.UserVerification.fromJson(json))
          .toList();
      
      print('✅ Loaded ${pendingVerifications.length} pending verifications');
    } catch (e) {
      print('❌ Error loading pending verifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAllUsers() async {
    isLoading.value = true;
    try {
      // Use admin client with service role key
      final response = await AdminConfig.adminClient.auth.admin.listUsers();
      
      allUsers.value = response.map((authUser) {
        final metadata = authUser.userMetadata ?? {};
        return models.User(
          id: authUser.id,
          name: metadata['name'] ?? metadata['ho_ten'] ?? 'Không có tên',
          email: authUser.email ?? 'Không có email',
          image: metadata['hinh_anh'] ?? metadata['image'],
          createdAt: DateTime.parse(authUser.createdAt),
          updatedAt: authUser.updatedAt != null 
              ? DateTime.parse(authUser.updatedAt!) 
              : DateTime.parse(authUser.createdAt),
          // Additional metadata fields
          age: metadata['tuoi']?.toString(),
          address: metadata['dia_chi'],
          dateOfBirth: metadata['ngay_sinh'],
        );
      }).toList();
      
      print('✅ Loaded ${allUsers.length} users from auth metadata');
    } catch (e) {
      print('❌ Error loading users: $e');
      allUsers.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAllTransactions() async {
    isLoading.value = true;
    try {
      final response = await Supabase.instance.client
          .from('transactions')
          .select('*')
          .order('ngay_tao', ascending: false);
      
      allTransactions.value = (response as List)
          .map((json) => models.Transaction.fromJson(json))
          .toList();
      
      print('✅ Loaded ${allTransactions.length} transactions');
    } catch (e) {
      print('❌ Error loading transactions: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> approveVerification({
    required String verificationId,
    required String adminNotes,
  }) async {
    isLoading.value = true;
    try {
      // Lấy thông tin verification trước
      final verificationResponse = await Supabase.instance.client
          .from('user_verifications')
          .select('*')
          .eq('id', verificationId)
          .single();

      final verification = models.UserVerification.fromJson(verificationResponse);
      
      // Cập nhật trạng thái verification
      await Supabase.instance.client
          .from('user_verifications')
          .update({
            'verification_status': 'verified',
            'admin_notes': adminNotes,
            'phone_verified': true,
            'id_card_verified': true,
          })
          .eq('id', verificationId);

      // Cập nhật metadata của user với trạng thái xác thực
      try {
        await AdminConfig.adminClient.auth.admin.updateUserById(
          verification.userId,
          attributes: AdminUserAttributes(
            userMetadata: {
              'verification_status': 'verified',
              'verified_at': DateTime.now().toIso8601String(),
              'verified_by_admin': true,
            },
          ),
        );
        print('✅ Updated user metadata with verification status');
      } catch (metadataError) {
        print('⚠️ Warning: Could not update user metadata: $metadataError');
      }

      print('✅ Approved verification for user: ${verification.userId}');
      Get.snackbar('Thành công', 'Xác thực đã được phê duyệt');
      await loadPendingVerifications();
      return true;
    } catch (e) {
      print('❌ Approve verification error: $e');
      Get.snackbar('Lỗi', 'Không thể phê duyệt xác thực');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> rejectVerification({
    required String verificationId,
    required String adminNotes,
  }) async {
    isLoading.value = true;
    try {
      await Supabase.instance.client
          .from('user_verifications')
          .update({
            'verification_status': 'rejected',
            'admin_notes': adminNotes,
          })
          .eq('id', verificationId);

      print('✅ Rejected verification: $verificationId');
      Get.snackbar('Thành công', 'Xác thực đã bị từ chối');
      await loadPendingVerifications();
      return true;
    } catch (e) {
      print('❌ Reject verification error: $e');
      Get.snackbar('Lỗi', 'Không thể từ chối xác thực');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyIndividualField({
    required String verificationId,
    required String fieldType, // 'phone', 'id_card'
    required bool isVerified,
    required String adminNotes,
  }) async {
    isLoading.value = true;
    try {
      Map<String, dynamic> updateData = {
        'admin_notes': adminNotes,
      };

      if (fieldType == 'phone') {
        updateData['phone_verified'] = isVerified;
      } else if (fieldType == 'id_card') {
        updateData['id_card_verified'] = isVerified;
      }

      await Supabase.instance.client
          .from('user_verifications')
          .update(updateData)
          .eq('id', verificationId);

      Get.snackbar('Thành công', 'Trường $fieldType đã được ${isVerified ? 'xác thực' : 'từ chối'}');
      await loadPendingVerifications();
      return true;
    } catch (e) {
      print('Verify individual field error: $e');
      Get.snackbar('Lỗi', 'Không thể cập nhật trường $fieldType');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
