import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:e_wallet/controllers/biometric_controller.dart';
import '../../../../styles/constrant.dart';
import 'face_enrollment_screen.dart';

class BiometricSettingsScreen extends StatefulWidget {
  const BiometricSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BiometricSettingsScreen> createState() => _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState extends State<BiometricSettingsScreen> {
  final _biometric = Get.put(BiometricController());
  bool _loading = true;
  bool _supported = false;
  bool _faceAvailable = false;
  bool _fpAvailable = false;
  bool _enabled = false;
  bool _faceEnrolled = false;
  bool _fpEnrolled = false;
  String? _enrollmentDate;
  String _preferred = 'face';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final supports = await _biometric.deviceSupportsBiometrics();
    final faceAvail = await _biometric.isFaceAvailable();
    final fpAvail = await _biometric.isFingerprintAvailable();
    final enabled = await _biometric.isFaceEnabled();
    final enrolled = await _biometric.isFaceEnrolled();
    final enrollDate = await _biometric.getFaceEnrollmentDate();
    // We don't need a separate fingerprint enable flag; using the single global biometric toggle
    final fpEnrolled = await _biometric.isFingerprintEnrolled();
    final preferred = await _biometric.getPreferredMethod();

    setState(() {
      _supported = supports;
      _faceAvailable = faceAvail;
      _fpAvailable = fpAvail;
      _enabled = enabled;
      _faceEnrolled = enrolled;
      _enrollmentDate = enrollDate;
      _fpEnrolled = fpEnrolled;
      _preferred = preferred;
      _loading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() => _loading = true);
    await _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinh trắc học', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: k_blue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Face Recognition Section
                  // Container(
                  //   width: double.infinity,
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.blueGrey.withOpacity(0.05),
                  //     borderRadius: BorderRadius.circular(12),
                  //     border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
                  //   ),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Row(
                  //         children: [
                  //           Icon(Icons.face_retouching_natural, color: k_blue),
                  //           const SizedBox(width: 8),
                  //           const Text('Nhận diện khuôn mặt', style: TextStyle(fontWeight: FontWeight.bold)),
                  //         ],
                  //       ),
                  //       const SizedBox(height: 8),
                  //       Text(_supported
                  //           ? (_faceAvailable
                  //               ? 'Thiết bị hỗ trợ nhận diện khuôn mặt.'
                  //               : 'Thiết bị không có/không bật nhận diện khuôn mặt.')
                  //           : 'Thiết bị không hỗ trợ sinh trắc học.'),
                  //     ],
                  //   ),
                  // ),

                  // const SizedBox(height: 20),

                  // // Face Enrollment Status
                  // if (_supported && _faceAvailable) ...[
                  //   Container(
                  //     width: double.infinity,
                  //     padding: const EdgeInsets.all(16),
                  //     decoration: BoxDecoration(
                  //       color: _faceEnrolled ? Colors.green.shade50 : Colors.orange.shade50,
                  //       borderRadius: BorderRadius.circular(12),
                  //       border: Border.all(color: _faceEnrolled ? Colors.green.shade200 : Colors.orange.shade200),
                  //     ),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Row(
                  //           children: [
                  //             Icon(
                  //               _faceEnrolled ? Icons.verified : Icons.warning,
                  //               color: _faceEnrolled ? Colors.green : Colors.orange,
                  //             ),
                  //             const SizedBox(width: 8),
                  //             Text(
                  //               _faceEnrolled ? 'Đã đăng ký khuôn mặt' : 'Chưa đăng ký khuôn mặt',
                  //               style: TextStyle(
                  //                 fontWeight: FontWeight.bold,
                  //                 color: _faceEnrolled ? Colors.green : Colors.orange,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //         if (_faceEnrolled && _enrollmentDate != null) ...[
                  //           const SizedBox(height: 8),
                  //           Text(
                  //             'Ngày đăng ký: ${_formatDate(_enrollmentDate!)}',
                  //             style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  //           ),
                  //         ],
                  //         if (!_faceEnrolled) ...[
                  //           const SizedBox(height: 8),
                  //           Text(
                  //             'Để sử dụng xác thực khuôn mặt, bạn cần đăng ký khuôn mặt trước.',
                  //             style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  //           ),
                  //         ],
                  //       ],
                  //     ),
                  //   ),

                  //   const SizedBox(height: 16),

                  //   // Face Enrollment Button
                  //   SizedBox(
                  //     width: double.infinity,
                  //     child: ElevatedButton.icon(
                  //       onPressed: _faceEnrolled ? null : () => _enrollFace(),
                  //       icon: Icon(_faceEnrolled ? Icons.verified : Icons.face_retouching_natural),
                  //       label: Text(_faceEnrolled ? 'Đã đăng ký' : 'Đăng ký khuôn mặt'),
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: _faceEnrolled ? Colors.grey : k_blue,
                  //         foregroundColor: Colors.white,
                  //         padding: const EdgeInsets.symmetric(vertical: 12),
                  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  //       ),
                  //     ),
                  //   ),

                  //   if (_faceEnrolled) ...[
                  //     const SizedBox(height: 8),
                  //     SizedBox(
                  //       width: double.infinity,
                  //       child: OutlinedButton.icon(
                  //         onPressed: () => _unenrollFace(),
                  //         icon: const Icon(Icons.delete_outline),
                  //         label: const Text('Hủy đăng ký'),
                  //         style: OutlinedButton.styleFrom(
                  //           foregroundColor: Colors.red,
                  //           side: const BorderSide(color: Colors.red),
                  //           padding: const EdgeInsets.symmetric(vertical: 12),
                  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  //         ),
                  //       ),
                  //     ),
                  //   ],

                  //   const SizedBox(height: 20),
                  // ],

                  // Fingerprint Recognition Section
                  if (_supported && _fpAvailable) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.fingerprint, color: k_blue),
                              const SizedBox(width: 8),
                              const Text('Nhận diện vân tay', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_supported
                              ? (_fpAvailable
                                  ? 'Thiết bị hỗ trợ nhận diện vân tay. Sẽ sử dụng xác thực hệ thống của điện thoại.'
                                  : 'Thiết bị không có/không bật nhận diện vân tay.')
                              : 'Thiết bị không hỗ trợ sinh trắc học.'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Fingerprint Status (using system fingerprint)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _fpEnrolled ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _fpEnrolled ? Colors.green.shade200 : Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _fpEnrolled ? Icons.verified : Icons.warning,
                                color: _fpEnrolled ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _fpEnrolled ? 'Sẵn sàng sử dụng' : 'Chưa sẵn sàng',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _fpEnrolled ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          if (_fpEnrolled) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Vân tay của hệ thống đã được kích hoạt. Bạn có thể sử dụng để xác thực giao dịch giá trị cao.',
                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              'Để sử dụng xác thực vân tay, hãy thêm vân tay trong cài đặt hệ thống của điện thoại.',
                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],

                  // Biometric Toggle
                  if (_supported && (_faceAvailable || _fpAvailable) && (_faceEnrolled || _fpEnrolled))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bật xác thực sinh trắc học cho giao dịch giá trị cao (≥ 20,000,000 VND)', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Yêu cầu xác thực sinh trắc học'),
                              Obx(() => _biometric.isBusy.value
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Switch(
                                      value: _enabled,
                                      activeColor: k_blue,
                                      onChanged: (val) async {
                                        setState(() => _enabled = val);
                                        await _biometric.setFaceEnabled(val);
                                      },
                                    )),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Preferred Method Selection
                  // if (_faceEnrolled && _fpEnrolled)
                  //   Container(
                  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(12),
                  //       border: Border.all(color: Colors.grey.shade300),
                  //     ),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         const Text('Phương thức xác thực mặc định', style: TextStyle(fontWeight: FontWeight.bold)),
                  //         const SizedBox(height: 12),
                  //         Row(
                  //           children: [
                  //             Flexible(
                  //               child: Row(
                  //                 children: [
                  //                   Radio(
                  //                     value: 'face',
                  //                     groupValue: _preferred,
                  //                     onChanged: (val) async {
                  //                       setState(() => _preferred = val as String);
                  //                       await _biometric.setPreferredMethod(val as String);
                  //                     },
                  //                   ),
                  //                   const Text('Khuôn mặt'),
                  //                 ],
                  //               ),
                  //             ),
                  //             const SizedBox(width: 16),
                  //             Flexible(
                  //               child: Row(
                  //                 children: [
                  //                   Radio(
                  //                     value: 'fingerprint',
                  //                     groupValue: _preferred,
                  //                     onChanged: (val) async {
                  //                       setState(() => _preferred = val as String);
                  //                       await _biometric.setPreferredMethod(val as String);
                  //                     },
                  //                   ),
                  //                   const Text('Vân tay'),
                  //                 ],
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ],
                  //     ),
                  //   ),

                  // const SizedBox(height: 12),

                  // Information Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            const Text('Quy trình xác thực giao dịch', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('• Giao dịch < 20,000,000 VND: Chỉ cần xác thực PIN'),
                        const Text('• Giao dịch ≥ 20,000,000 VND: Xác thực sinh trắc học (khuôn mặt hoặc vân tay) → Nhập PIN → Xác nhận'),
                        const SizedBox(height: 8),
                        Text(
                          'Lưu ý: Hệ thống sử dụng xác thực sinh trắc học của điện thoại. Hãy thêm vân tay/khuôn mặt trong cài đặt hệ thống.',
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    '* Khi bật, các giao dịch giá trị cao yêu cầu xác thực sinh trắc học trước khi nhập Digital OTP PIN.\n* Bạn có thể chọn giữa Vân tay hoặc Khuôn mặt.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _enrollFace() async {
    final result = await Get.to(() => const FaceEnrollmentScreen());
    if (result == true) {
      await _refreshData();
    }
  }

  Future<void> _unenrollFace() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hủy đăng ký khuôn mặt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn hủy đăng ký khuôn mặt?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      const Text('Lưu ý:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Bạn sẽ không thể sử dụng xác thực khuôn mặt cho giao dịch giá trị cao'),
                  const Text('• Để sử dụng lại, bạn cần đăng ký khuôn mặt lại'),
                  const Text('• Bạn vẫn có thể chuyển tiền bình thường với xác thực PIN'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _biometric.unenrollFace();
        await _refreshData();
        Get.snackbar(
          'Đã hủy đăng ký',
          'Bạn đã hủy đăng ký khuôn mặt thành công. Bạn có thể đăng ký lại bất cứ lúc nào.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } catch (e) {
        Get.snackbar('Lỗi', 'Không thể hủy đăng ký. Vui lòng thử lại.');
      }
    }
  }

  // Removed _enrollFingerprint() - not needed for system fingerprint
  // Removed _unenrollFingerprint() - not needed for system fingerprint

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateString;
    }
  }
}
