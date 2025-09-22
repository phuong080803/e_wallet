import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../controllers/wallet_controller.dart';
import '../../../styles/constrant.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_field.dart';
import 'transfer_success_screen.dart';

class TransferMoneyScreen extends StatefulWidget {
  @override
  _TransferMoneyScreenState createState() => _TransferMoneyScreenState();
}

class _TransferMoneyScreenState extends State<TransferMoneyScreen> {
  final _walletController = Get.find<WalletController>();
  final _recipientIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _otpController = TextEditingController();
  
  final RxBool _isLoadingRecipient = false.obs;
  final RxBool _isProcessingTransfer = false.obs;
  final RxBool _showOtpDialog = false.obs;
  final Rx<Map<String, dynamic>?> _recipientInfo = Rx<Map<String, dynamic>?>(null);
  final RxString _lookupError = ''.obs;
  
  @override
  void dispose() {
    _recipientIdController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _lookupRecipient() async {
    final recipientId = _recipientIdController.text.trim();
    if (recipientId.isEmpty) {
      _lookupError.value = 'Vui lòng nhập ID người nhận';
      return;
    }

    if (recipientId.length != 10) {
      _lookupError.value = 'ID ví phải có 10 chữ số';
      return;
    }

    _isLoadingRecipient.value = true;
    _lookupError.value = '';
    _recipientInfo.value = null;

    try {
      // First, find the wallet by wallet_id (using id column)
      final walletResponse = await Supabase.instance.client
          .from('wallets')
          .select('user_id, id, user_name, user_email')
          .eq('id', recipientId)
          .maybeSingle();
      
      if (walletResponse == null) {
        _lookupError.value = 'Không tìm thấy ví với ID này';
        return;
      }

      // Check if trying to transfer to own wallet
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (walletResponse['user_id'] == currentUser?.id) {
        _lookupError.value = 'Không thể chuyển tiền cho chính mình';
        return;
      }

      // Get user information from the wallet record in database
      String userName = 'Người dùng';
      String userEmail = 'Chưa có thông tin email';
      
      try {
        // Get user info directly from the wallet record
        userName = walletResponse['user_name'] ?? 'Người dùng';
        userEmail = walletResponse['user_email'] ?? 'Chưa có thông tin email';
        
        print('✅ Found user info from wallet: name=$userName, email=$userEmail');
      } catch (e) {
        print('❌ Could not fetch user info from wallet: $e');
        // Keep default values
        userName = 'Người dùng';
        userEmail = 'Chưa có thông tin email';
      }
        
      _recipientInfo.value = {
        'user_id': walletResponse['user_id'],
        'wallet_id': walletResponse['id'],
        'user_name': userName,
        'email': userEmail,
      };
    } catch (e) {
      print('❌ Error looking up recipient: $e');
      _lookupError.value = 'Lỗi khi tìm kiếm người nhận';
    } finally {
      _isLoadingRecipient.value = false;
    }
  }

  Future<void> _sendOtp() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser?.email == null) {
      Get.snackbar('Lỗi', 'Không tìm thấy email để gửi OTP');
      return;
    }

    try {
      // Generate 6-digit OTP
      final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      
      // Store OTP in user metadata temporarily (in real app, use secure storage)
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'transfer_otp': otp,
            'otp_expires_at': DateTime.now().add(Duration(minutes: 5)).toIso8601String(),
          },
        ),
      );

      // In a real app, you would send email via Supabase Edge Functions or email service
      // For demo purposes, we'll show the OTP in a snackbar
      Get.snackbar(
        'OTP đã gửi', 
        'Mã OTP: $otp (Demo - trong ứng dụng thực sẽ gửi qua email)',
        duration: Duration(seconds: 10),
      );

      _showOtpDialog.value = true;
    } catch (e) {
      print('❌ Error sending OTP: $e');
      Get.snackbar('Lỗi', 'Không thể gửi OTP');
    }
  }

  Future<void> _verifyOtpAndTransfer() async {
    final enteredOtp = _otpController.text.trim();
    if (enteredOtp.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập mã OTP');
      return;
    }

    _isProcessingTransfer.value = true;

    try {
      // Verify OTP
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userMetadata = currentUser?.userMetadata ?? {};
      final storedOtp = userMetadata['transfer_otp'];
      final expiresAt = userMetadata['otp_expires_at'];

      if (storedOtp != enteredOtp) {
        Get.snackbar('Lỗi', 'Mã OTP không đúng');
        return;
      }

      if (expiresAt != null && DateTime.parse(expiresAt).isBefore(DateTime.now())) {
        Get.snackbar('Lỗi', 'Mã OTP đã hết hạn');
        return;
      }

      // Process transfer
      final amount = double.parse(_amountController.text);
      final success = await _walletController.transferMoney(
        recipientWalletId: _recipientIdController.text.trim(),
        amount: amount,
        notes: _notesController.text.trim(),
      );

      if (success) {
        // Clear OTP from metadata
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'transfer_otp': null,
              'otp_expires_at': null,
            },
          ),
        );

        _showOtpDialog.value = false;
        
        // Navigate to success screen with transfer details
        Get.off(() => TransferSuccessScreen(
          amount: amount,
          recipientName: _recipientInfo.value!['user_name'],
          recipientWalletId: _recipientIdController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ));
      }
    } catch (e) {
      print('❌ Error verifying OTP and transferring: $e');
      Get.snackbar('Lỗi', 'Chuyển tiền thất bại');
    } finally {
      _isProcessingTransfer.value = false;
    }
  }

  bool _isValidTransfer() {
    if (_recipientInfo.value == null) return false;
    if (_amountController.text.isEmpty) return false;
    
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return false;
    
    final currentBalance = _walletController.userWallet.value?.balance ?? 0;
    if (amount > currentBalance) return false;
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chuyển tiền',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: k_blue,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Balance Card
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
                      Text(
                        'Số dư hiện tại',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Obx(() => Text(
                        _walletController.userWallet.value != null
                            ? _walletController.formatBalance(_walletController.userWallet.value!.balance)
                            : '0 VND',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ],
                  ),
                ),
                
                SizedBox(height: 30),
                
                // Recipient ID Input
                Text(
                  'ID ví người nhận',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _recipientIdController,
                        hintText: 'Nhập 10 chữ số ID ví',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (value) {
                          if (value.length == 10) {
                            _lookupRecipient();
                          } else {
                            _recipientInfo.value = null;
                            _lookupError.value = '';
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Obx(() => _isLoadingRecipient.value
                        ? Container(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _recipientInfo.value != null
                            ? Container(
                                padding: EdgeInsets.all(12),
                                child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                              )
                            : SizedBox.shrink()),
                  ],
                ),
                
                // Recipient Error
                Obx(() => _lookupError.value.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _lookupError.value,
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      )
                    : SizedBox.shrink()),
                
                // Recipient Info Display
                Obx(() => _recipientInfo.value != null
                    ? Container(
                        margin: const EdgeInsets.only(top: 16),
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
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Thông tin người nhận',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildInfoRow('Tên:', _recipientInfo.value!['user_name']),
                            _buildInfoRow('Email:', _recipientInfo.value!['email']),
                            _buildInfoRow('ID ví:', _recipientInfo.value!['wallet_id']),
                          ],
                        ),
                      )
                    : SizedBox.shrink()),
                
                SizedBox(height: 30),
                
                // Amount Input
                Text(
                  'Số tiền chuyển',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                CustomTextField(
                  controller: _amountController,
                  hintText: 'Nhập số tiền (VND)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    // Trigger UI update when amount changes
                    _recipientInfo.refresh();
                  },
                  suffixIcon: Icon(Icons.attach_money, color: k_blue),
                ),
                
                SizedBox(height: 24),
                
                // Notes Input
                Text(
                  'Ghi chú (tùy chọn)',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                CustomTextField(
                  controller: _notesController,
                  hintText: 'Nhập ghi chú cho giao dịch',
                  maxLines: 3,
                  maxLength: 200,
                ),
                
                SizedBox(height: 40),
                
                // Transfer Button
                Container(
                  width: double.infinity,
                  child: Obx(() => CustomElevatedButton(
                    label: 'Xác nhận chuyển tiền',
                    color: k_blue,
                    onPressed: _isValidTransfer() ? _sendOtp : null,
                  )),
                ),
                
                SizedBox(height: 20),
              ],
            ),
          ),
          
          // OTP Dialog
          Obx(() => _showOtpDialog.value
              ? _buildOtpDialog()
              : SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpDialog() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.security,
                color: k_blue,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Xác thực OTP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Nhập mã OTP đã được gửi đến email của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 24),
              CustomTextField(
                controller: _otpController,
                hintText: 'Nhập mã OTP 6 chữ số',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _showOtpDialog.value = false;
                        _otpController.clear();
                      },
                      child: Text('Hủy'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => CustomElevatedButton(
                      label: _isProcessingTransfer.value ? 'Đang xử lý...' : 'Xác nhận',
                      color: k_blue,
                      onPressed: _isProcessingTransfer.value ? null : _verifyOtpAndTransfer,
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
