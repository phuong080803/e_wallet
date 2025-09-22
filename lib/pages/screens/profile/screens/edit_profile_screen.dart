import 'package:e_wallet/controllers/profile_controller.dart';
import 'package:e_wallet/pages/widgets/custom_elevated_button.dart';
import 'package:e_wallet/pages/widgets/custom_textField.dart';
import 'package:e_wallet/styles/constrant.dart';
import 'package:e_wallet/styles/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileController _profileController = Get.put(ProfileController());
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  
  bool _isSubmitting = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final currentAuthUser = Supabase.instance.client.auth.currentUser;
    if (currentAuthUser != null) {
      final userMetadata = currentAuthUser.userMetadata ?? {};
      _nameController.text = userMetadata['ho_ten'] ?? userMetadata['name'] ?? '';
      
      // Load date of birth and format for display
      final dateOfBirth = userMetadata['ngay_sinh'];
      if (dateOfBirth != null) {
        try {
          final date = DateTime.parse(dateOfBirth);
          _dateOfBirthController.text = "${date.day}/${date.month}/${date.year}";
          _selectedDate = date;
        } catch (e) {
          _dateOfBirthController.text = '';
        }
      }
      
      _addressController.text = userMetadata['dia_chi'] ?? '';
      _imageController.text = userMetadata['hinh_anh'] ?? userMetadata['image'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final dateOfBirthText = _dateOfBirthController.text.trim();
    final address = _addressController.text.trim();
    final image = _imageController.text.trim();

    // Validation
    if (name.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập họ tên');
      return;
    }

    if (!_profileController.isValidName(name)) {
      Get.snackbar('Lỗi', 'Họ tên phải từ 2-100 ký tự');
      return;
    }

    String? dateOfBirthISO;
    if (dateOfBirthText.isNotEmpty && _selectedDate != null) {
      if (!_profileController.isValidDateOfBirth(_selectedDate!)) {
        Get.snackbar('Lỗi', 'Tuổi phải từ 16-120');
        return;
      }
      dateOfBirthISO = _selectedDate!.toIso8601String();
    }

    if (address.isNotEmpty && !_profileController.isValidAddress(address)) {
      Get.snackbar('Lỗi', 'Địa chỉ phải từ 10-500 ký tự');
      return;
    }

    if (image.isNotEmpty && !_profileController.isValidImageUrl(image)) {
      Get.snackbar('Lỗi', 'URL hình ảnh không hợp lệ');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _profileController.updateProfile(
        name: name,
        dateOfBirth: dateOfBirthISO,
        address: address.isEmpty ? null : address,
        image: image.isEmpty ? null : image,
      );

      if (success) {
        Get.back();
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Có lỗi xảy ra: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chỉnh sửa thông tin cá nhân',
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Thông tin cá nhân này sẽ được cập nhật ngay lập tức mà không cần xác thực.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              Text(
                'Thông tin cá nhân',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                title: "Họ và tên",
                hint: "Nhập họ và tên của bạn",
                textEditingController: _nameController,
                suffixIcon: Icon(Icons.person, color: k_blue),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now().subtract(Duration(days: 365 * 25)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: Locale('vi', 'VN'),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _dateOfBirthController.text = "${picked.day}/${picked.month}/${picked.year}";
                    });
                  }
                },
                child: AbsorbPointer(
                  child: CustomTextField(
                    title: "Ngày sinh",
                    hint: "Chọn ngày sinh của bạn (tùy chọn)",
                    textEditingController: _dateOfBirthController,
                    suffixIcon: Icon(Icons.calendar_today, color: k_blue),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                title: "Địa chỉ",
                hint: "Nhập địa chỉ của bạn (tùy chọn)",
                textEditingController: _addressController,
                suffixIcon: Icon(Icons.location_on, color: k_blue),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                title: "Ảnh đại diện (URL)",
                hint: "Nhập URL ảnh đại diện (tùy chọn)",
                textEditingController: _imageController,
                suffixIcon: Icon(Icons.image, color: k_blue),
              ),
              const SizedBox(height: 30),

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
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Lưu ý',
                          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Thông tin này sẽ được cập nhật ngay lập tức\n'
                      '• Không cần chờ admin xác thực\n'
                      '• Có thể chỉnh sửa bất cứ lúc nào\n'
                      '• Các trường có dấu (tùy chọn) có thể để trống',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              Container(
                width: SizeConfig.screenWidth,
                child: CustomElevatedButton(
                  label: _isSubmitting ? "Đang cập nhật..." : "Cập nhật thông tin",
                  color: k_blue,
                  onPressed: _isSubmitting ? null : _saveProfile,
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
    _nameController.dispose();
    _dateOfBirthController.dispose();
    _addressController.dispose();
    _imageController.dispose();
    super.dispose();
  }
}