import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/token_service.dart';
import '../controllers/wallet_controller.dart';
import '../controllers/transaction_controller.dart';
import '../pages/screens/e-wallet_layout/e-wallet_layout_screen.dart';
import '../pages/screens/home/screens/home_screen.dart';

class ProfileModel {
  final String id;
  final String name;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    required this.id,
    required this.name,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class AuthController extends GetxController {
  final Rx<ProfileModel?> currentProfile = Rx<ProfileModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  final TokenService _tokenService = TokenService.instance;

  @override
  void onInit() {
    super.onInit();
    initializeAuth();
  }

  Future<void> initializeAuth() async {
    isLoading.value = true;
    try {
      // Thử khôi phục session từ stored tokens
      final session = await _tokenService.restoreSession();
      if (session != null) {
        isAuthenticated.value = true;
        await _loadProfile(session.user.id);
        print('✅ Authentication restored from stored tokens');
      } else {
        print('ℹ️ No valid stored session found');
        isAuthenticated.value = false;
      }
    } catch (e) {
      print('❌ Error initializing auth: $e');
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void checkCurrentUser() {
    final session = Supabase.instance.client.auth.currentSession;
    isAuthenticated.value = session != null;
    if (session?.user != null) {
      _loadProfile(session!.user.id);
    }
  }

  Future<void> _loadProfile(String userId) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata ?? {};
      final profile = ProfileModel(
        id: user.id,
        name: metadata['name'] ?? '', // Lấy từ field 'name' theo cấu trúc authentication JSON
        image: metadata['hinh_anh'],
        createdAt: DateTime.parse(metadata['ngay_tao'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(metadata['ngay_cap_nhat'] ?? DateTime.now().toIso8601String()),
      );
      currentProfile.value = profile;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? image,
  }) async {
    isLoading.value = true;
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name, // Sử dụng 'name' theo cấu trúc authentication JSON
          'role': 'user', // Mặc định role là 'user' khi đăng ký
          'ngay_tao': DateTime.now().toIso8601String(),
          'ngay_cap_nhat': DateTime.now().toIso8601String(),
        },
      );

      // Chỉ tạo auth user với metadata, không tạo profile record
      return true;
    } on AuthException catch (e) {
      // Bubble up Supabase auth errors with readable message
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = result.session;
      final user = result.user;
      
      if (user == null || session == null) return false;

      // Lưu tokens vào SharedPreferences
      await _tokenService.saveTokens(session);
      
      await _loadProfile(user.id);
      isAuthenticated.value = true;
      
      // Kiểm tra role trong user_metadata để điều hướng
      final userMetadata = user.userMetadata ?? {};
      final userRole = userMetadata['role'] ?? 'user';
      
      print('✅ User signed in and tokens saved');
      print('🔍 User role: $userRole');
      
      if (userRole == 'admin') {
        print('🔐 Admin user detected: $email');
        Get.snackbar('Thành công', 'Đăng nhập admin thành công');
        await Future.delayed(Duration(milliseconds: 500));
        print('🚀 Navigating to admin dashboard...');
        Get.offAllNamed('/admin-dashboard');
      } else {
        print('👤 Regular user login: $email');
        Get.snackbar('Thành công', 'Đăng nhập thành công');
        await Future.delayed(Duration(milliseconds: 500));
        print('🚀 Attempting navigation to /home...');
        final result = Get.offAllNamed('/home');
        print('🔍 Navigation result: $result');
        if (result == null) {
          print('❌ Navigation failed, trying direct navigation');
          Get.offAll(() => E_WalletLayoutScreen());
        }

        // Force reload wallet for new user
        try {
          final walletController = Get.find<WalletController>();
          await walletController.forceReloadWallet();
        } catch (e) {
          print('⚠️ Could not reload wallet after sign in: $e');
        }
      }
      
      return true;
    } catch (e) {
      print('❌ Sign in error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      print('🚪 Signing out...');
      await Supabase.instance.client.auth.signOut();

      // Xóa tokens khỏi SharedPreferences
      await _tokenService.clearTokens();

      // Clear tất cả state
      currentProfile.value = null;
      isAuthenticated.value = false;

      // Clear wallet state
      final walletController = Get.find<WalletController>();
      walletController.userWallet.value = null;
      walletController.hasWallet.value = false;

      // Clear transaction state nếu có
      try {
        final transactionController = Get.find<TransactionController>();
        transactionController.clearAllTransactions();
      } catch (e) {
        print('⚠️ TransactionController not found during signout');
      }

      print('✅ Sign out successful and all states cleared');

      // Navigate to login screen
      Get.offAllNamed('/login');
    } catch (e) {
      print('❌ Sign out error: $e');
      // Vẫn reset state local và clear tokens dù có lỗi
      await _tokenService.clearTokens();
      currentProfile.value = null;
      isAuthenticated.value = false;

      // Clear wallet state even if signout failed
      try {
        final walletController = Get.find<WalletController>();
        walletController.userWallet.value = null;
        walletController.hasWallet.value = false;
      } catch (e) {
        print('⚠️ WalletController not found during error handling');
      }

      // Navigate to login screen even if there was an error
      Get.offAllNamed('/login');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? image,
  }) async {
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;
    
    final currentMetadata = currentUser.userMetadata ?? {};
    final newMetadata = Map<String, dynamic>.from(currentMetadata);
    
    if (name != null) {
      newMetadata['name'] = name; // Cập nhật vào field 'name' theo cấu trúc authentication JSON
    }
    if (image != null) {
      newMetadata['hinh_anh'] = image;
    }
    newMetadata['ngay_cap_nhat'] = DateTime.now().toIso8601String();
    
    await supabase.auth.updateUser(
      UserAttributes(
        data: newMetadata,
      ),
    );
    await _loadProfile(currentUser.id);
  }

  // Helper method để kiểm tra role của user hiện tại
  String getCurrentUserRole() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'guest';
    
    final userMetadata = user.userMetadata ?? {};
    final role = userMetadata['role'] ?? 'user';
    print('🔍 getCurrentUserRole() returning: $role');
    return role;
  }

  // Helper method để kiểm tra xem user có phải admin không
  bool isCurrentUserAdmin() {
    return getCurrentUserRole() == 'admin';
  }

  // Helper method để kiểm tra xem user có phải user thường không
  bool isCurrentUserRegular() {
    return getCurrentUserRole() == 'user';
  }
}
