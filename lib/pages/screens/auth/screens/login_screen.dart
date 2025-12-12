import 'package:e_wallet/pages/screens/auth/screens/forget_password_screen.dart';
import 'package:e_wallet/pages/screens/auth/screens/register_screen.dart';
import 'package:e_wallet/pages/screens/e-wallet_layout/e-wallet_layout_screen.dart';
import 'package:e_wallet/pages/widgets/custom_elevated_button.dart';
import 'package:e_wallet/pages/widgets/custom_textField.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../styles/constrant.dart';
import 'package:e_wallet/styles/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthController _authController = Get.put(AuthController());
  final _formKey = GlobalKey<FormState>();

  bool _anMatKhau = true;
  int _failedLoginAttempts = 0;
  DateTime? _lockUntil;
  String? _passwordError;

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Kiểm tra nếu đang bị khóa do nhập sai quá số lần cho phép
    if (_lockUntil != null && DateTime.now().isBefore(_lockUntil!)) {
      setState(() {
        _passwordError =
            'Bạn đã nhập sai quá 5 lần liên tiếp, hãy thử lại sau 10 phút';
      });
      return;
    }

    final success = await _authController.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!success) {
      setState(() {
        _failedLoginAttempts++;
        if (_failedLoginAttempts >= 5) {
          _lockUntil = DateTime.now().add(const Duration(minutes: 10));
          _passwordError =
              'Bạn đã nhập sai quá 5 lần liên tiếp, hãy thử lại sau 10 phút';
        } else {
          _passwordError = 'Sai mật khẩu';
        }
      });
    } else {
      // Đăng nhập thành công: reset lại trạng thái lỗi và bộ đếm
      setState(() {
        _failedLoginAttempts = 0;
        _lockUntil = null;
        _passwordError = null;
      });
    }
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
                  const SizedBox(height: 60),
                  
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
                          "Welcome Back!",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: k_black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign in to continue your financial journey",
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
                  
                  const SizedBox(height: 50),
                  
                  // Login Form
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email Field
                          Text(
                            "Địa chỉ Email",
                            style: TextStyle(
                              fontSize: 15,
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
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập email';
                                }
                                if (!GetUtils.isEmail(value)) {
                                  return 'Email không hợp lệ';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: "Nhập địa chỉ email của bạn",
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
                            "Mật khẩu",
                            style: TextStyle(
                              fontSize: 15,
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
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: _anMatKhau,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }
                                if (value.length < 6) {
                                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                if (_passwordError != null) {
                                  setState(() {
                                    _passwordError = null;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText: "Nhập mật khẩu của bạn",
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
                          if (_passwordError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _passwordError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 12),
                          
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Get.to(() => ForgetPasswordScreen()),
                              child: Text(
                                "Quên mật khẩu?",
                                style: TextStyle(
                                  color: k_blue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Login Button
                          Obx(() {
                            return Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _authController.isLoading.value 
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
                                onPressed: _authController.isLoading.value ? null : _onLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _authController.isLoading.value
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
                                          "Đang đăng nhập...",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      "Đăng nhập",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Sign Up Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Chưa có tài khoản? ",
                          style: TextStyle(color: k_fontGrey, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: () => Get.off(() => RegisterScreen()),
                          child: Text(
                            "Đăng ký",
                            style: TextStyle(
                              color: k_blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
