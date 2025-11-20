import 'package:e_wallet/models/user_model.dart';
import 'package:e_wallet/pages/screens/profile/screens/edit_profile_screen.dart';
import 'package:e_wallet/pages/screens/profile/screens/my_account_screen.dart';
import 'package:e_wallet/pages/screens/profile/screens/my_cards_screen.dart';
import 'package:e_wallet/pages/screens/profile/screens/settings_screen.dart';
import 'package:e_wallet/pages/screens/profile/screens/digital_otp_pin_screen.dart';
import 'package:e_wallet/pages/screens/profile/screens/biometric_settings_screen.dart';
import 'package:e_wallet/pages/screens/wallet/wallet_screen.dart';
import 'package:e_wallet/pages/widgets/user_image.dart';
import 'package:e_wallet/controllers/auth_controller.dart';
import 'package:e_wallet/controllers/wallet_controller.dart';
import '../../../../styles/constrant.dart';
import 'package:e_wallet/styles/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/build_profile_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Đăng xuất'),
          content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Perform logout directly without loading dialog
                final authController = Get.find<AuthController>();
                await authController.signOut();
              },
              child: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleWalletAction() async {
    // Navigate to wallet screen
    Get.to(() => WalletScreen());
  }

  void _showWalletCreationDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Tạo ví điện tử'),
        content: Text('Bạn chưa có ví điện tử. Bạn có muốn tạo ví mới không?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final walletController = Get.put(WalletController());
              
              // Show loading
              Get.dialog(
                Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang tạo ví...'),
                      ],
                    ),
                  ),
                ),
                barrierDismissible: false,
              );
              
              try {
                // Create wallet
                final success = await walletController.createWallet();
                
                // Always close loading dialog
                if (Get.isDialogOpen == true) {
                  Get.back();
                }
                
                if (success) {
                  Get.snackbar(
                    'Thành công', 
                    'Ví điện tử đã được tạo thành công!',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } else {
                  Get.snackbar(
                    'Lỗi', 
                    'Không thể tạo ví điện tử. Vui lòng thử lại.',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              } catch (e) {
                // Always close loading dialog on error
                if (Get.isDialogOpen == true) {
                  Get.back();
                }
                
                Get.snackbar(
                  'Lỗi', 
                  'Đã xảy ra lỗi khi tạo ví: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: Text('Tạo ví', style: TextStyle(color: k_blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            AppBar(
              backgroundColor: k_grey,
              title: Text(
                "Hồ sơ của tôi",
                style: Theme.of(context).textTheme.displayMedium!.copyWith(fontSize: 22),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => Get.to(() => EditProfileScreen()),
                  icon: Image.asset(
                    "assets/images/edit_icon.png",
                    color: k_blue,
                  ),
                ),
                SizedBox(width: 10),
              ],
            ),
            Container(
              width: SizeConfig.screenWidth,
              color: k_grey,
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  UserImage(imagePath: k_imagePath, raduis: 130),
                  SizedBox(height: 15),
                  Text(
                    Get.find<AuthController>().currentProfile.value?.name ?? 'Người dùng',
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(fontSize: 18),
                  ),
                  SizedBox(height: 15),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  BuildProfileItem(
                    context: context,
                    iconPath: "assets/images/profile_icon.png",
                    title: "Tài khoản của tôi",
                    onTap: () => Get.to(() => MyAccountScreen()),
                  ),
                  SizedBox(height: 20),
                  BuildProfileItem(
                    context: context,
                    iconPath: "assets/images/card_icon.png",
                    title: "Ví điện tử",
                    onTap: _handleWalletAction,
                    trailing: Obx(() {
                      final walletController = Get.find<WalletController>();
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: walletController.hasWallet.value 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          walletController.hasWallet.value ? 'Đã tạo' : 'Chưa tạo',
                          style: TextStyle(
                            color: walletController.hasWallet.value 
                                ? Colors.green 
                                : Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20),
                  BuildProfileItem(
                    context: context,
                    iconPath: "assets/images/settings_icon.png",
                    title: "Digital OTP PIN",
                    onTap: () => Get.toNamed('/digital-otp-pin'),
                  ),
                  SizedBox(height: 20),
                  BuildProfileItem(
                    context: context,
                    iconPath: "assets/images/settings_icon.png",
                    title: "Sinh trắc học",
                    onTap: () => Get.to(() => const BiometricSettingsScreen()),
                  ),
                  SizedBox(height: 20),
                  SizedBox(height: 20),
                  BuildProfileItem(
                    context: context,
                    iconPath: "assets/images/settings_icon.png",
                    title: "Cài đặt",
                    onTap: () => Get.to(() => SettingScreen()),
                  ),
                  SizedBox(height: 20),
                  BuildProfileItem(
                    context: context,
                    iconPath: "assets/images/logout_icon.png",
                    title: "Đăng xuất",
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
