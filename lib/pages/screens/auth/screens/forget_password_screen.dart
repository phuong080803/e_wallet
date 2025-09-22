import 'package:e_wallet/pages/widgets/custom_button_navigation_bar.dart';
import 'package:e_wallet/pages/widgets/custom_textField.dart';
import '../../../../styles/constrant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgetPasswordScreen extends StatelessWidget {
  ForgetPasswordScreen({Key? key}) : super(key: key);
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: k_black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Đặt lại mật khẩu",
          style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Nhập email của bạn để gửi hướng dẫn đặt lại mật khẩu",
              style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 15),
            ),
            SizedBox(height: 40),
            CustomTextField(
              title: "Email",
              hint: "Nhập email của bạn",
              textEditingController: _emailController,
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomButtonNavigationBar(
        color: k_blue,
        label: "Gửi Email",
        onPress: () {},
      ),
    );
  }
}
