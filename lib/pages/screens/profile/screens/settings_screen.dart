import 'package:e_wallet/pages/screens/profile/widgets/build_setting_item.dart';
import '../../../../styles/constrant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:e_wallet/controllers/auth_controller.dart';
import 'package:e_wallet/pages/screens/auth/screens/login_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: k_black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Cài đặt",
          style: Theme.of(context).textTheme.displayMedium!.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Chung",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 15),
              ),
              SizedBox(height: 20),
              BuildSettingItem(
                title: "Ngôn ngữ",
                subTitle: "Thay đổi ngôn ngữ của ứng dụng.",
                imagePath: "assets/images/language_icon.png",
                onTap: () {},
              ),
              SizedBox(height: 25),
              BuildSettingItem(
                title: "Vị trí",
                subTitle: "Thêm vị trí nhà và nơi làm việc.",
                imagePath: "assets/images/location_icon.png",
                onTap: () {},
              ),
              SizedBox(height: 30),
              Text(
                "Thông báo",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 15),
              ),
              SizedBox(height: 20),
              BuildSettingItem(
                title: "Thông báo đẩy",
                subTitle: "Cập nhật hàng ngày và các thông báo khác.",
                imagePath: "assets/images/notifications _icon.png",
                onTap: () {},
              ),
              SizedBox(height: 25),
              BuildSettingItem(
                title: "Thông báo quảng cáo",
                subTitle: "Các chiến dịch và ưu đãi mới.",
                imagePath: "assets/images/notifications _icon.png",
                onTap: () {},
              ),
              SizedBox(height: 30),
              Text(
                "Tài khoản",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 15),
              ),
              SizedBox(height: 20),
              BuildSettingItem(
                title: "Liên hệ chúng tôi",
                subTitle: "Để biết thêm thông tin",
                imagePath: "assets/images/call_icon.png",
                onTap: () {},
              ),
              SizedBox(height: 25),
              BuildSettingItem(
                title: "Bảng điều khiển quản trị",
                subTitle: "Truy cập hệ thống quản trị",
                imagePath: "assets/images/settings_icon.png",
                onTap: () => Get.toNamed('/admin-dashboard'),
              ),
              SizedBox(height: 25),
              BuildSettingItem(
                title: "Đăng xuất",
                subTitle: "Đăng xuất khỏi tài khoản hiện tại",
                imagePath: "assets/images/logout_icon.png",
                onTap: () async {
                  try {
                    print('🚪 User logging out...');
                    final auth = Get.put(AuthController());
                    await auth.signOut();
                    Get.snackbar('Thành công', 'Đã đăng xuất thành công');
                    // Delay nhỏ để snackbar hiển thị
                    await Future.delayed(Duration(milliseconds: 500));
                    Get.offAll(() => LoginScreen());
                    print('✅ User logout successful');
                  } catch (e) {
                    print('❌ User logout error: $e');
                    Get.snackbar('Lỗi', 'Có lỗi xảy ra khi đăng xuất');
                    // Vẫn chuyển về login dù có lỗi
                    Get.offAll(() => LoginScreen());
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
