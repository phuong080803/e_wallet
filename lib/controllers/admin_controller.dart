import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/database_models.dart' as models;
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
      // Call Edge Function to list users (server verifies admin privileges)
      final result = await Supabase.instance.client.functions.invoke('admin-list-users');
      final data = result.data as List<dynamic>? ?? [];

      allUsers.value = data.map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        return models.User(
          id: map['id'] ?? '',
          name: map['name'] ?? 'Không có tên',
          email: map['email'] ?? 'Không có email',
          image: map['image'],
          createdAt: DateTime.parse(map['created_at']),
          updatedAt: DateTime.parse(map['updated_at']),
          age: map['tuoi']?.toString(),
          address: map['dia_chi'],
          dateOfBirth: map['ngay_sinh'],
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
      // Gọi Edge Function để phê duyệt (server tự cập nhật DB và metadata)
      await Supabase.instance.client.functions.invoke(
        'admin-approve-verification',
        body: {
          'verification_id': verificationId,
          'admin_notes': adminNotes,
        },
      );

      print('✅ Approved verification via Edge Function: $verificationId');
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
      await Supabase.instance.client.functions.invoke(
        'admin-reject-verification',
        body: {
          'verification_id': verificationId,
          'admin_notes': adminNotes,
        },
      );

      print('✅ Rejected verification via Edge Function: $verificationId');
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
      await Supabase.instance.client.functions.invoke(
        'admin-verify-field',
        body: {
          'verification_id': verificationId,
          'field_type': fieldType,
          'is_verified': isVerified,
          'admin_notes': adminNotes,
        },
      );

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
