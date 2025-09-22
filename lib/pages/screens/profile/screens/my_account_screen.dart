import 'package:e_wallet/controllers/profile_controller.dart';
import 'package:e_wallet/controllers/verification_controller.dart';
import 'package:e_wallet/controllers/wallet_controller.dart';
import 'package:e_wallet/pages/screens/profile/screens/edit_profile_screen.dart';
import 'package:e_wallet/pages/screens/profile/screens/verification_screen.dart';
import 'package:e_wallet/pages/widgets/custom_elevated_button.dart';
import 'package:e_wallet/styles/constrant.dart';
import 'package:e_wallet/styles/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({Key? key}) : super(key: key);

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final ProfileController _profileController = Get.put(ProfileController());
  final VerificationController _verificationController = Get.put(VerificationController());
  final WalletController _walletController = Get.put(WalletController());
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy dữ liệu từ auth user metadata thay vì profile table
      final currentAuthUser = Supabase.instance.client.auth.currentUser;
      if (currentAuthUser == null) {
        Get.snackbar('Lỗi', 'Vui lòng đăng nhập lại');
        return;
      }

      // Lấy metadata từ auth user
      final userMetadata = currentAuthUser.userMetadata ?? {};
      
      // Cập nhật controllers với dữ liệu từ metadata
      _nameController.text = userMetadata['ho_ten'] ?? userMetadata['name'] ?? '';
      _addressController.text = userMetadata['dia_chi'] ?? '';
      _emailController.text = currentAuthUser.email ?? '';

      // Load verification data (vẫn từ verification table)
      _verificationController.loadUserVerification();
      
      if (_verificationController.userVerification.value != null) {
        final verification = _verificationController.userVerification.value!;
        _phoneController.text = verification.phoneNumber ?? '';
      }

      // Cập nhật profile controller để sync với metadata
      await _profileController.loadUserProfile();
      
      // Load wallet data
      await _walletController.loadUserWallet();
      
    } catch (e) {
      print('Error loading user data: $e');
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu người dùng');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  String _getVerificationStatus() {
    // Check verification status from user metadata first
    final currentAuthUser = Supabase.instance.client.auth.currentUser;
    if (currentAuthUser != null) {
      final userMetadata = currentAuthUser.userMetadata ?? {};
      final metadataStatus = userMetadata['verification_status'];
      if (metadataStatus == 'verified') {
        return 'Đã xác thực';
      }
    }
    
    // Fallback to verification table
    final verification = _verificationController.userVerification.value;
    if (verification == null) return 'Chưa xác thực';
    switch (verification.verificationStatus) {
      case 'pending':
        return 'Đang chờ xác thực';
      case 'verified':
        return 'Đã xác thực';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return 'Chưa xác thực';
    }
  }

  Color _getVerificationStatusColor() {
    // Check verification status from user metadata first
    final currentAuthUser = Supabase.instance.client.auth.currentUser;
    if (currentAuthUser != null) {
      final userMetadata = currentAuthUser.userMetadata ?? {};
      final metadataStatus = userMetadata['verification_status'];
      if (metadataStatus == 'verified') {
        return Colors.green;
      }
    }
    
    // Fallback to verification table
    final verification = _verificationController.userVerification.value;
    if (verification == null) return Colors.grey;
    switch (verification.verificationStatus) {
      case 'pending':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _isVerified() {
    // Check verification status from user metadata first
    final currentAuthUser = Supabase.instance.client.auth.currentUser;
    if (currentAuthUser != null) {
      final userMetadata = currentAuthUser.userMetadata ?? {};
      final metadataStatus = userMetadata['verification_status'];
      if (metadataStatus == 'verified') {
        return true;
      }
    }
    
    // Fallback to verification table
    final verification = _verificationController.userVerification.value;
    return verification?.verificationStatus == 'verified';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tài khoản của tôi',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: k_black),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit, color: k_blue),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verification Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getVerificationStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getVerificationStatusColor().withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: _getVerificationStatusColor(),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trạng thái xác thực',
                                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _getVerificationStatus(),
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: _getVerificationStatusColor(),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_getVerificationStatus() == 'Chưa xác thực' ||
                              _getVerificationStatus() == 'Bị từ chối')
                            TextButton(
                              onPressed: () => Get.to(() => VerificationScreen()),
                              child: Text(
                                'Xác thực',
                                style: TextStyle(color: k_blue),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Personal Information Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Thông tin cá nhân',
                                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18),
                              ),
                              TextButton(
                                onPressed: () => Get.to(() => EditProfileScreen()),
                                child: Text(
                                  'Chỉnh sửa',
                                  style: TextStyle(color: k_blue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          
                          // Display personal information
                          Obx(() {
                            final user = _profileController.currentUser.value;
                            return Column(
                              children: [
                                _buildInfoRow('Họ và tên', user?.name ?? 'Chưa cập nhật'),
                                const SizedBox(height: 10),
                                _buildInfoRow('Email', user?.email ?? 'Chưa cập nhật'),
                                const SizedBox(height: 10),
                                _buildInfoRow('Ngày sinh', user?.dateOfBirth ?? 'Chưa cập nhật'),
                                const SizedBox(height: 10),
                                _buildInfoRow('Địa chỉ', user?.address ?? 'Chưa cập nhật'),
                                const SizedBox(height: 10),
                                _buildInfoRow('Ảnh đại diện', user?.image != null ? 'Đã cập nhật' : 'Chưa cập nhật'),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Verification Information Section OR Wallet Creation Section
                    _isVerified() ? _buildWalletSection() : _buildVerificationSection(),
                    
                    const SizedBox(height: 30),

                    // Action Buttons
                    _isVerified() ? _buildWalletActionButton() : _buildVerificationActionButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVerificationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin cần xác thực',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 15),
          
          // Display verification information
          Obx(() {
            final verification = _verificationController.userVerification.value;
            return Column(
              children: [
                _buildInfoRow('Số điện thoại', verification?.phoneNumber ?? 'Chưa cập nhật'),
                const SizedBox(height: 10),
                _buildInfoRow('Số căn cước', verification?.idCardNumber ?? 'Chưa cập nhật'),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: k_blue, size: 24),
              const SizedBox(width: 8),
              Text(
                'Ví điện tử',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          Obx(() {
            final wallet = _walletController.userWallet.value;
            if (wallet != null) {
              return Column(
                children: [
                  _buildInfoRow('ID Ví', _walletController.formatWalletId(wallet.walletId)),
                  const SizedBox(height: 10),
                  _buildInfoRow('Tên ví', wallet.walletName),
                  const SizedBox(height: 10),
                  _buildInfoRow('Số dư', _walletController.formatBalance(wallet.balance)),
                  const SizedBox(height: 10),
                  _buildInfoRow('Trạng thái', wallet.isActive ? 'Đang hoạt động' : 'Tạm khóa'),
                ],
              );
            } else {
              return Column(
                children: [
                  Icon(Icons.wallet, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'Bạn chưa có ví điện tử',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo ví để bắt đầu sử dụng các dịch vụ thanh toán',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildVerificationActionButton() {
    return Container(
      width: SizeConfig.screenWidth,
      child: CustomElevatedButton(
        label: "Xác thực thông tin",
        color: k_blue,
        onPressed: () => Get.to(() => VerificationScreen()),
      ),
    );
  }

  Widget _buildWalletActionButton() {
    return Obx(() {
      final wallet = _walletController.userWallet.value;
      final isLoading = _walletController.isLoading.value;
      
      if (wallet != null) {
        return Row(
          children: [
            Expanded(
              child: CustomElevatedButton(
                label: "Nạp tiền",
                color: Colors.green,
                onPressed: () {
                  // TODO: Navigate to top-up screen
                  Get.snackbar('Thông báo', 'Tính năng nạp tiền đang phát triển');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomElevatedButton(
                label: "Chuyển tiền",
                color: k_blue,
                onPressed: () {
                  // TODO: Navigate to transfer screen
                  Get.snackbar('Thông báo', 'Tính năng chuyển tiền đang phát triển');
                },
              ),
            ),
          ],
        );
      } else {
        return Container(
          width: SizeConfig.screenWidth,
          child: CustomElevatedButton(
            label: isLoading ? "Đang tạo ví..." : "Tạo ví điện tử",
            color: k_blue,
            onPressed: isLoading ? null : () async {
              final success = await _walletController.createWallet();
              if (success) {
                setState(() {}); // Refresh UI
              }
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
