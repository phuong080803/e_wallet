import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../controllers/digital_otp_controller.dart';
import '../../../../styles/constrant.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_field.dart';

class DigitalOtpPinScreen extends StatefulWidget {
  @override
  _DigitalOtpPinScreenState createState() => _DigitalOtpPinScreenState();
}

class _DigitalOtpPinScreenState extends State<DigitalOtpPinScreen> {
  final _digitalOtpController = Get.find<DigitalOtpController>();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  
  final RxBool _hasPin = false.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _showCurrentPin = false.obs;
  final RxBool _showNewPin = false.obs;
  final RxBool _showConfirmPin = false.obs;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _checkPinStatus() async {
    _isLoading.value = true;
    try {
      final hasPin = await _digitalOtpController.hasPin();
      _hasPin.value = hasPin;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _createPin() async {
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (newPin.length != 6 || int.tryParse(newPin) == null) {
      Get.snackbar('Lỗi', 'PIN phải gồm 6 chữ số');
      return;
    }

    if (newPin != confirmPin) {
      Get.snackbar('Lỗi', 'PIN xác nhận không khớp');
      return;
    }

    _isLoading.value = true;
    try {
      await _digitalOtpController.setPin(newPin);
      _hasPin.value = true;
      _newPinController.clear();
      _confirmPinController.clear();
      Get.snackbar(
        'Thành công',
        'Đã tạo PIN Digital OTP thành công',
        backgroundColor: Colors.green[100],
      );
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _changePin() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (currentPin.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập PIN hiện tại');
      return;
    }

    // Verify current PIN
    final isValid = await _digitalOtpController.verifyPin(currentPin);
    if (!isValid) {
      Get.snackbar('Lỗi', 'PIN hiện tại không đúng');
      return;
    }

    if (newPin.length != 6 || int.tryParse(newPin) == null) {
      Get.snackbar('Lỗi', 'PIN mới phải gồm 6 chữ số');
      return;
    }

    if (newPin != confirmPin) {
      Get.snackbar('Lỗi', 'PIN xác nhận không khớp');
      return;
    }

    if (currentPin == newPin) {
      Get.snackbar('Lỗi', 'PIN mới phải khác PIN hiện tại');
      return;
    }

    _isLoading.value = true;
    try {
      await _digitalOtpController.setPin(newPin);
      _currentPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();
      Get.snackbar(
        'Thành công',
        'Đã thay đổi PIN Digital OTP thành công',
        backgroundColor: Colors.green[100],
      );
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _deletePin() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Xác nhận xóa PIN'),
        content: Text('Bạn có chắc chắn muốn xóa PIN Digital OTP? Bạn sẽ cần tạo PIN mới để sử dụng tính năng này.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _isLoading.value = true;
      try {
        await _digitalOtpController.clearPin();
        _hasPin.value = false;
        _currentPinController.clear();
        _newPinController.clear();
        _confirmPinController.clear();
        Get.snackbar(
          'Thành công',
          'Đã xóa PIN Digital OTP',
          backgroundColor: Colors.orange[100],
        );
      } catch (e) {
        Get.snackbar('Lỗi', e.toString());
      } finally {
        _isLoading.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Digital OTP PIN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: k_blue,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Obx(() => _isLoading.value
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [k_blue, k_blue.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.security, color: Colors.white, size: 32),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Digital OTP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _hasPin.value ? 'Đã kích hoạt' : 'Chưa kích hoạt',
                                    style: TextStyle(
                                      color: _hasPin.value ? Colors.green[200] : Colors.orange[200],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Digital OTP giúp bạn xác thực giao dịch một cách nhanh chóng và an toàn bằng mã PIN 6 số.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Form based on PIN status
                  if (!_hasPin.value) ...[
                    // Create PIN Form
                    Text(
                      'Tạo PIN Digital OTP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tạo mã PIN 6 số để sử dụng Digital OTP khi chuyển tiền',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 24),
                    CustomTextField(
                      controller: _newPinController,
                      hintText: 'Nhập PIN mới (6 số)',
                      keyboardType: TextInputType.number,
                      obscureText: !_showNewPin.value,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNewPin.value ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => _showNewPin.value = !_showNewPin.value,
                      ),
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPinController,
                      hintText: 'Xác nhận PIN (6 số)',
                      keyboardType: TextInputType.number,
                      obscureText: !_showConfirmPin.value,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPin.value ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => _showConfirmPin.value = !_showConfirmPin.value,
                      ),
                    ),
                    SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      child: CustomElevatedButton(
                        label: 'Tạo PIN',
                        color: k_blue,
                        onPressed: _createPin,
                      ),
                    ),
                  ] else ...[
                    // Change PIN Form
                    Text(
                      'Thay đổi PIN Digital OTP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nhập PIN hiện tại và PIN mới để thay đổi',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 24),
                    CustomTextField(
                      controller: _currentPinController,
                      hintText: 'PIN hiện tại (6 số)',
                      keyboardType: TextInputType.number,
                      obscureText: !_showCurrentPin.value,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showCurrentPin.value ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => _showCurrentPin.value = !_showCurrentPin.value,
                      ),
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _newPinController,
                      hintText: 'PIN mới (6 số)',
                      keyboardType: TextInputType.number,
                      obscureText: !_showNewPin.value,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNewPin.value ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => _showNewPin.value = !_showNewPin.value,
                      ),
                    ),
                    SizedBox(height: 16),
                    CustomTextField(
                      controller: _confirmPinController,
                      hintText: 'Xác nhận PIN mới (6 số)',
                      keyboardType: TextInputType.number,
                      obscureText: !_showConfirmPin.value,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPin.value ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () => _showConfirmPin.value = !_showConfirmPin.value,
                      ),
                    ),
                    SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      child: CustomElevatedButton(
                        label: 'Thay đổi PIN',
                        color: k_blue,
                        onPressed: _changePin,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _deletePin,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.red),
                          ),
                        ),
                        child: Text(
                          'Xóa PIN',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 30),

                  // Security Tips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Lưu ý bảo mật',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildSecurityTip('• Không chia sẻ PIN với bất kỳ ai'),
                        _buildSecurityTip('• Sử dụng PIN khó đoán, tránh dùng ngày sinh'),
                        _buildSecurityTip('• Thay đổi PIN định kỳ để bảo mật'),
                        _buildSecurityTip('• PIN được mã hóa và lưu trữ an toàn'),
                      ],
                    ),
                  ),
                ],
              ),
            )),
    );
  }

  Widget _buildSecurityTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.orange[800],
          fontSize: 13,
        ),
      ),
    );
  }
}
