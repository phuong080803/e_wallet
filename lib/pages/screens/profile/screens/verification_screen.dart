import 'package:e_wallet/controllers/verification_controller.dart';
import 'package:e_wallet/pages/widgets/custom_elevated_button.dart';
import 'package:e_wallet/pages/widgets/custom_textField.dart';
import 'package:e_wallet/styles/constrant.dart';
import 'package:e_wallet/styles/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({Key? key}) : super(key: key);

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idCardController = TextEditingController();
  final VerificationController _verificationController = Get.put(VerificationController());

  bool _isSubmitting = false;
  File? _frontIdImage;
  File? _backIdImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExistingVerification();
  }

  void _loadExistingVerification() {
    _verificationController.loadUserVerification();
  }

  Future<void> _submitVerification() async {
    final phone = _phoneController.text.trim();
    final idCard = _idCardController.text.trim();

    // Validation
    if (phone.isEmpty || idCard.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng điền đầy đủ tất cả các trường');
      return;
    }

    if (!_verificationController.isValidPhoneNumber(phone)) {
      Get.snackbar('Lỗi', 'Số điện thoại không hợp lệ (10-11 chữ số)');
      return;
    }

    if (!_verificationController.isValidIdCard(idCard)) {
      Get.snackbar('Lỗi', 'Số căn cước không hợp lệ (9-12 chữ số)');
      return;
    }

    if (_frontIdImage == null || _backIdImage == null) {
      Get.snackbar('Lỗi', 'Vui lòng chụp ảnh cả hai mặt của căn cước');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _verificationController.submitVerification(
        phoneNumber: phone,
        idCardNumber: idCard,
        frontIdImage: _frontIdImage!,
        backIdImage: _backIdImage!,
      );

      if (success) {
        Get.back();
        Get.snackbar('Thành công', 'Gửi yêu cầu xác thực thành công. Vui lòng chờ admin phê duyệt.');
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Có lỗi xảy ra: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _pickImage(bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          if (isFront) {
            _frontIdImage = File(image.path);
          } else {
            _backIdImage = File(image.path);
          }
        });
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể chọn ảnh: $e');
    }
  }

  Future<void> _takePhoto(bool isFront) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          if (isFront) {
            _frontIdImage = File(image.path);
          } else {
            _backIdImage = File(image.path);
          }
        });
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể chụp ảnh: $e');
    }
  }

  void _showImageSourceDialog(bool isFront) {
    Get.dialog(
      AlertDialog(
        title: Text('Chọn nguồn ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: k_blue),
              title: Text('Chụp ảnh'),
              onTap: () {
                Get.back();
                _takePhoto(isFront);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: k_blue),
              title: Text('Chọn từ thư viện'),
              onTap: () {
                Get.back();
                _pickImage(isFront);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Xác thực thông tin',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: k_black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: k_blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: k_blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: k_blue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Thông tin xác thực sẽ được admin kiểm tra và phê duyệt trong vòng 24-48 giờ.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: k_blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              Text(
                'Thông tin cần xác thực',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                title: "Số điện thoại",
                hint: "Nhập số điện thoại của bạn",
                textEditingController: _phoneController,
                keyboardType: TextInputType.phone,
                suffixIcon: Icon(Icons.phone, color: k_blue),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                title: "Số căn cước công dân",
                hint: "Nhập số căn cước công dân",
                textEditingController: _idCardController,
                keyboardType: TextInputType.number,
                suffixIcon: Icon(Icons.credit_card, color: k_blue),
              ),
              const SizedBox(height: 20),

              // ID Card Front Image Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ảnh căn cước mặt trước',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    
                    // Image preview area
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: _frontIdImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _frontIdImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.credit_card, size: 40, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'Chưa có ảnh mặt trước',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Action buttons for front image
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _takePhoto(true),
                            icon: Icon(Icons.camera_alt, size: 18),
                            label: Text('Chụp ảnh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: k_blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(true),
                            icon: Icon(Icons.photo_library, size: 18),
                            label: Text('Chọn ảnh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ID Card Back Image Section
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
                    Text(
                      'Ảnh căn cước mặt sau',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    
                    // Image preview area
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: _backIdImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _backIdImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.credit_card, size: 40, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'Chưa có ảnh mặt sau',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Action buttons for back image
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _takePhoto(false),
                            icon: Icon(Icons.camera_alt, size: 18),
                            label: Text('Chụp ảnh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(false),
                            icon: Icon(Icons.photo_library, size: 18),
                            label: Text('Chọn ảnh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Lưu ý quan trọng',
                          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Thông tin phải chính xác và trung thực\n'
                      '• Số điện thoại phải là số thật và đang sử dụng\n'
                      '• Số căn cước phải đúng với giấy tờ tùy thân\n'
                      '• Admin sẽ xem xét và phê duyệt yêu cầu của bạn',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Container(
                width: SizeConfig.screenWidth,
                child: CustomElevatedButton(
                  label: _isSubmitting ? "Đang gửi..." : "Gửi yêu cầu xác thực",
                  color: k_blue,
                  onPressed: _isSubmitting ? null : _submitVerification,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _idCardController.dispose();
    super.dispose();
  }
}
