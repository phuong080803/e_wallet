import 'package:e_wallet/pages/screens/auth/screens/login_screen.dart';
import 'package:e_wallet/pages/widgets/custom_elevated_button.dart';
import 'package:e_wallet/pages/widgets/custom_textField.dart';
import 'package:e_wallet/styles/constrant.dart';
import 'package:e_wallet/styles/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:e_wallet/controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _tenController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _matKhauController = TextEditingController();
  final TextEditingController _nhapLaiMatKhauController = TextEditingController();
  final AuthController _authController = Get.put(AuthController());

  bool _dangTai = false;
  bool _anMatKhau = true;
  bool _anNhapLaiMatKhau = true;

  

  bool _laEmailHopLe(String email) {
    return GetUtils.isEmail(email);
  }

  Future<void> _dangKy() async {
    final ten = _tenController.text.trim();
    final email = _emailController.text.trim();
    final matKhau = _matKhauController.text.trim();
    final nhapLai = _nhapLaiMatKhauController.text.trim();

    if (ten.isEmpty || email.isEmpty || matKhau.isEmpty || nhapLai.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng điền đầy đủ tất cả các trường');
      return;
    }

    if (!_laEmailHopLe(email)) {
      Get.snackbar('Lỗi', 'Vui lòng nhập địa chỉ email hợp lệ');
      return;
    }

    final passwordRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(matKhau)) {
      Get.snackbar(
        'Mật khẩu yếu',
        'Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường và số.',
      );
      return;
    }

    if (matKhau != nhapLai) {
      Get.snackbar('Lỗi', 'Mật khẩu không khớp');
      return;
    }

    setState(() {
      _dangTai = true;
    });

    try {
      final ok = await _authController.signUp(
        email: email,
        password: matKhau,
        name: ten,
      );
      if (ok) {
        Get.snackbar('Thành công', 'Tạo tài khoản thành công. Vui lòng xác nhận email.');
        Get.off(() => LoginScreen());
      } else {
        Get.snackbar('Lỗi', 'Đăng ký thất bại');
      }
    } catch (e) {
      Get.snackbar('Lỗi', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() {
        _dangTai = false;
      });
    }
  }

  Widget _taoTruongMatKhau({
    required String tieuDe,
    required String goiY,
    required TextEditingController controller,
    required bool anMatKhau,
    required VoidCallback chuyenDoi,
  }) {
    return CustomTextField(
      title: tieuDe,
      hint: goiY,
      textEditingController: controller,
      obscureText: anMatKhau,
      suffixIcon: IconButton(
        icon: Icon(anMatKhau ? Icons.visibility_off : Icons.visibility),
        onPressed: chuyenDoi,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.safeInit(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              k_blue.withOpacity(0.1),
              Colors.white,
              k_blue.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo and Welcome Section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [k_blue, k_blue.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: k_blue.withOpacity(0.3),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: k_black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Join us and start your financial journey",
                          style: TextStyle(
                            fontSize: 16,
                            color: k_fontGrey,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Register Form
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name Field
                        Text(
                          "Full Name",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: k_black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: TextField(
                            controller: _tenController,
                            decoration: InputDecoration(
                              hintText: "Enter your full name",
                              hintStyle: TextStyle(color: k_fontGrey),
                              prefixIcon: Icon(Icons.person_outline, color: k_blue),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Email Field
                        Text(
                          "Email Address",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: k_black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: "Enter your email",
                              hintStyle: TextStyle(color: k_fontGrey),
                              prefixIcon: Icon(Icons.email_outlined, color: k_blue),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Password Field
                        Text(
                          "Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: k_black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: TextField(
                            controller: _matKhauController,
                            obscureText: _anMatKhau,
                            decoration: InputDecoration(
                              hintText: "Enter your password",
                              hintStyle: TextStyle(color: k_fontGrey),
                              prefixIcon: Icon(Icons.lock_outline, color: k_blue),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _anMatKhau ? Icons.visibility_off : Icons.visibility,
                                  color: k_fontGrey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _anMatKhau = !_anMatKhau;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Confirm Password Field
                        Text(
                          "Confirm Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: k_black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: TextField(
                            controller: _nhapLaiMatKhauController,
                            obscureText: _anNhapLaiMatKhau,
                            decoration: InputDecoration(
                              hintText: "Confirm your password",
                              hintStyle: TextStyle(color: k_fontGrey),
                              prefixIcon: Icon(Icons.lock_outline, color: k_blue),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _anNhapLaiMatKhau ? Icons.visibility_off : Icons.visibility,
                                  color: k_fontGrey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _anNhapLaiMatKhau = !_anNhapLaiMatKhau;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Password Requirements
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: k_blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: k_blue.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Password requirements:",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: k_blue,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "• At least 8 characters\n• Include uppercase and lowercase letters\n• Include at least one number",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: k_blue.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Register Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _dangTai 
                                ? [Colors.grey[400]!, Colors.grey[500]!]
                                : [k_blue, k_blue.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: k_blue.withOpacity(0.3),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _dangTai ? null : _dangKy,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _dangTai
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "Đang tạo tài khoản...",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  "Tạo tài khoản",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Sign In Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Đã có tài khoản? ",
                          style: TextStyle(color: k_fontGrey, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Get.off(() => LoginScreen()),
                          child: Text(
                            "Đăng nhập",
                            style: TextStyle(
                              color: k_blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tenController.dispose();
    _emailController.dispose();
    _matKhauController.dispose();
    _nhapLaiMatKhauController.dispose();
    super.dispose();
  }
}
