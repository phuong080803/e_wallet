import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../controllers/wallet_controller.dart';
import '../../../controllers/digital_otp_controller.dart';
import '../../../services/transfer_service.dart';
import '../../../styles/constrant.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_field.dart';
import 'transfer_success_screen.dart';
import '../../../config/external_payment_config.dart';

class TransferMoneyScreen extends StatefulWidget {
  final String? initialWalletId;
  final String? initialEmail;
  // External (bank/wallet) recipient info from scanned external QR
  final bool isExternalRecipient;
  final String? externalBankCode;
  final String? externalAccountNumber;
  final String? externalAccountName;
  final double? initialAmount;

  TransferMoneyScreen({
    Key? key,
    this.initialWalletId,
    this.initialEmail,
    this.isExternalRecipient = false,
    this.externalBankCode,
    this.externalAccountNumber,
    this.externalAccountName,
    this.initialAmount,
  }) : super(key: key);

  @override
  _TransferMoneyScreenState createState() => _TransferMoneyScreenState();
}

class _TransferMoneyScreenState extends State<TransferMoneyScreen> {
  final _walletController = Get.find<WalletController>();
  final _digitalOtpController = Get.put(DigitalOtpController());
  final _transferService = TransferService();
  
  final _recipientIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  
  final RxBool _isProcessingTransfer = false.obs;
  final RxBool _showPinDialog = false.obs;
  final RxBool _showOtpDialog = false.obs;
  final RxBool _isLoadingRecipient = false.obs;
  final Rx<Map<String, dynamic>?> _recipientInfo = Rx<Map<String, dynamic>?>(null);
  final RxString _lookupError = ''.obs;
  final RxString _challengeId = ''.obs;
  final RxString _generatedOtp = ''.obs;
  final RxInt _otpSecondsLeft = 0.obs;
  // Trigger UI rebuilds for form state (amount changes, etc.)
  final RxInt _formTick = 0.obs;
  
  Timer? _otpTimer;
  
  @override
  void initState() {
    super.initState();
    // Prefill from in-app wallet QR
    if (!widget.isExternalRecipient && widget.initialWalletId != null && widget.initialWalletId!.isNotEmpty) {
      _recipientIdController.text = widget.initialWalletId!;
      // Trigger lookup; after lookup, optionally override email from QR
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _lookupRecipient();
        if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty && _recipientInfo.value != null) {
          final info = Map<String, dynamic>.from(_recipientInfo.value!);
          info['email'] = widget.initialEmail!;
          _recipientInfo.value = info;
        }
      });
    }

    // Prefill from external QR (VietQR/MoMo/ZaloPay)
    if (widget.isExternalRecipient) {
      // Amount prefill if provided
      if (widget.initialAmount != null && widget.initialAmount! > 0) {
        _amountController.text = widget.initialAmount!.toStringAsFixed(0);
      }
    }
  }

  // Đã bỏ dialog nhập OTP cá nhân. Sau khi xác thực PIN, sẽ tự động tạo và hiển thị OTP (countdown).

  @override
  void dispose() {
    _recipientIdController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    _otpTimer?.cancel();
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
      // Chỉ select các cột thực tế có trong bảng wallets (tiếng Việt)
      final walletResponse = await Supabase.instance.client
          .from('wallets')
          .select('user_id, id')
          .eq('id', recipientId)
          .maybeSingle();
      
      if (walletResponse == null) {
        _lookupError.value = 'Không tìm thấy ví với ID này';
        return;
      }

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        _lookupError.value = 'Vui lòng đăng nhập lại';
        return;
      }

      if (walletResponse['user_id'] == currentUser.id) {
        _lookupError.value = 'Không thể chuyển tiền cho chính mình';
        return;
      }

      // Lấy thông tin người dùng từ auth metadata (không phải từ bảng wallets)
      String userName = 'Người dùng';
      String userEmail = 'Chưa có thông tin email';
      
      try {
        // Không dùng auth.admin vì đã loại bỏ quyền admin từ client
        // Thay vào đó, tạm thời hiển thị tên mặc định và email mặc định
        // Thông tin chi tiết sẽ được hiển thị sau khi giao dịch thành công
        userName = 'Người nhận ${recipientId.substring(recipientId.length - 4)}'; // Hiển thị 4 số cuối
        userEmail = 'Chưa có thông tin email';
        print('✅ Using fallback user info: name=$userName');
      } catch (e) {
        print('❌ Error getting user info: $e');
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

  // Digital OTP Flow - Bước 1: Kiểm tra và yêu cầu PIN
  Future<void> _sendOtp() async {
    final hasPin = await _digitalOtpController.hasPin();
    if (!hasPin) {
      // Hiển thị thông báo yêu cầu tạo PIN trong Profile
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: k_blue),
              SizedBox(width: 12),
              Text('Chưa có Digital OTP PIN'),
            ],
          ),
          content: Text(
            'Bạn cần tạo mã PIN Digital OTP trong phần Hồ sơ trước khi có thể chuyển tiền.\n\nVui lòng vào Hồ sơ > Digital OTP PIN để thiết lập.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.toNamed('/digital-otp-pin');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: k_blue,
              ),
              child: Text('Đi tới thiết lập'),
            ),
          ],
        ),
      );
      return;
    }
    _showPinDialog.value = true;
  }

  // Digital OTP Flow - Bước 2 (nhánh B): Tự sinh OTP và hiển thị với countdown (dùng từ lần 2 trở đi)
  Future<void> _createChallengeAndPromptOtp() async {
    try {
      final amount = double.parse(_amountController.text);
      final senderWalletId = _walletController.userWallet.value!.id;
      final recipientId = widget.isExternalRecipient
          ? ExternalPaymentConfig.payoutWalletId
          : _recipientIdController.text.trim();

      final challenge = await _transferService.createChallenge(
        senderWalletId: senderWalletId,
        recipientWalletId: recipientId,
        amount: amount,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      _challengeId.value = challenge['challengeId'] ?? '';
      _generatedOtp.value = challenge['otp'] ?? '';
      if (_generatedOtp.value.isEmpty) {
        Get.snackbar('Lỗi', 'Không thể tạo mã OTP');
        return;
      }

      _otpSecondsLeft.value = 120; // 120 giây
      _showOtpDialog.value = true;

      _otpTimer?.cancel();
      _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_otpSecondsLeft.value <= 1) {
          timer.cancel();
          _showOtpDialog.value = false;
          Get.snackbar('Hết hạn', 'Mã OTP đã hết hạn, vui lòng thử lại');
        } else {
          _otpSecondsLeft.value--;
        }
      });
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể khởi tạo giao dịch: $e');
    }
  }

  // Digital OTP Flow - Bước 3: Xác thực OTP và chuyển tiền (sử dụng OTP đã sinh)
  Future<void> _verifyOtpAndTransfer() async {
    _isProcessingTransfer.value = true;

    try {
      final amount = double.parse(_amountController.text);
      bool success = false;

      // Tự động sử dụng OTP đã sinh thay vì gọi server
      final generatedOtp = _generatedOtp.value;
      if (generatedOtp.isEmpty) {
        Get.snackbar('Lỗi', 'Không tìm thấy mã OTP');
        return;
      }

      if (widget.isExternalRecipient) {
        // A2: chuyển nội bộ vào ví placeholder, ghi chú kèm thông tin ngân hàng/STK
        final bank = widget.externalBankCode ?? 'Ngoài hệ thống';
        final acc = widget.externalAccountNumber ?? '-';
        final name = (widget.externalAccountName ?? '').trim();
        final extra = ' (Ngân hàng/Ứng dụng: ' + bank + ', STK/ID: ' + acc + (name.isNotEmpty ? ', Tên: ' + name : '') + ')';
        final combinedNotes = (_notesController.text.trim().isNotEmpty
                ? _notesController.text.trim() + extra
                : 'Chuyển ra ngoài' + extra)
            .trim();

        success = await _walletController.transferMoney(
          recipientWalletId: ExternalPaymentConfig.payoutWalletId,
          amount: amount,
          notes: combinedNotes,
        );

        if (success) {
          _showOtpDialog.value = false;
          _otpTimer?.cancel();

          final displayRecipientName = (name.isNotEmpty ? name : (bank + ' - ' + acc));
          Get.off(() => TransferSuccessScreen(
                amount: amount,
                recipientName: displayRecipientName,
                recipientWalletId: ExternalPaymentConfig.payoutWalletId,
                notes: combinedNotes.isEmpty ? null : combinedNotes,
              ));
        }
      } else {
        final successInternal = await _walletController.transferMoney(
          recipientWalletId: _recipientIdController.text.trim(),
          amount: amount,
          notes: _notesController.text.trim(),
        );

        success = successInternal;

        if (successInternal) {
          _showOtpDialog.value = false;
          _otpTimer?.cancel();
          Get.off(() => TransferSuccessScreen(
                amount: amount,
                recipientName: _recipientInfo.value!['user_name'],
                recipientWalletId: _recipientIdController.text.trim(),
                notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              ));
        }
      }

    } catch (e) {
      print('❌ Error transferring: $e');
      Get.snackbar('Lỗi', 'Chuyển tiền thất bại');
    } finally {
      _isProcessingTransfer.value = false;
    }
  }

  bool _isValidTransfer() {
    // Tie Obx rebuild to form changes
    final _ = _formTick.value;
    if (_amountController.text.isEmpty) return false;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return false;
    final currentBalance = _walletController.userWallet.value?.balance ?? 0;
    if (amount > currentBalance) return false;
    if (widget.isExternalRecipient) {
      // external mode: chỉ cần số tiền hợp lệ; hạn mức/số dư sẽ được check trong transferMoney()
      return true;
    }
    // internal mode: cần có recipient info hợp lệ
    return _recipientInfo.value != null;
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
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
                
                // Recipient Input/Panel
                if (!widget.isExternalRecipient) ...[
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
                ] else ...[
                  // External recipient info panel
                  Text(
                    'Người nhận (ngoài hệ thống)',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
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
                        _buildInfoRow('Ngân hàng/Ứng dụng:', widget.externalBankCode ?? 'Không rõ'),
                        _buildInfoRow('STK/ID:', widget.externalAccountNumber ?? 'Không rõ'),
                        if ((widget.externalAccountName ?? '').isNotEmpty)
                          _buildInfoRow('Tên:', widget.externalAccountName!),
                        SizedBox(height: 4),
                        Text(
                          '* Thông tin người nhận thuộc hệ thống bên ngoài. Giao dịch sẽ trừ số dư ví của bạn và ghi nhận chuyển ra ngoài.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
                
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
                    _formTick.value++;
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
                
                SizedBox(height: 24),
              ],
            ),
          ),
          
          // Digital OTP Dialog (hiển thị mã OTP với countdown)
          Obx(() => _showOtpDialog.value
              ? _buildDigitalOtpDialog()
              : SizedBox.shrink()),
          
          // PIN Dialog (nhập PIN để lấy OTP)
          Obx(() => _showPinDialog.value
              ? _buildPinDialog()
              : SizedBox.shrink()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: Obx(() => SizedBox(
                width: double.infinity,
                child: CustomElevatedButton(
                  label: _isProcessingTransfer.value ? 'Đang xử lý...' : 'Xác nhận chuyển tiền',
                  color: k_blue,
                  onPressed: _isProcessingTransfer.value || !_isValidTransfer() ? null : _sendOtp,
                ),
              )),
        ),
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

  // Dialog hiển thị OTP với countdown (hiển thị OTP đã sinh)
  Widget _buildDigitalOtpDialog() {
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
          child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.security,
                color: k_blue,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Xác thực Digital OTP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Mã xác thực',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
              // Hiển thị mã OTP 6 số với spacing
              Text(
                _generatedOtp.value.split('').join(' '),
                style: TextStyle(
                  letterSpacing: 8,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.brown[800],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Mã xác thực giao dịch (OTP) có hiệu lực trong vòng ${_otpSecondsLeft.value} giây',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Bấm Xác thực để tự động điền mã.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 24),
              // Nút Xác thực (tự động dùng mã đã sinh)
              Container(
                width: double.infinity,
                child: Obx(() => CustomElevatedButton(
                  label: _isProcessingTransfer.value ? 'Đang xử lý...' : 'Xác thực',
                  color: Colors.red[700]!,
                  onPressed: _isProcessingTransfer.value ? null : _verifyOtpAndTransfer,
                )),
              ),
            ],
          )),
        ),
      ),
    );
  }

  // Dialog nhập PIN (giống hình 1)
  Widget _buildPinDialog() {
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
              Text(
                'Xác thực Digital OTP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Vui lòng nhập mã PIN Digital OTP để nhận mã xác thực giao dịch',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 24),
              // TextField hiển thị rõ ràng để nhập PIN
              Container(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  obscureText: true,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 20,
                    color: Colors.brown[800],
                  ),
                  decoration: InputDecoration(
                    hintText: '● ● ● ● ● ●',
                    hintStyle: TextStyle(
                      fontSize: 32,
                      letterSpacing: 20,
                      color: Colors.grey[400],
                    ),
                    counterText: '',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.brown[800]!, width: 2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.brown[800]!, width: 3),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[400]!, width: 2),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (value) {
                    setState(() {});
                    if (value.length == 6) {
                      _verifyPinAndShowOtp();
                    }
                  },
                ),
              ),
              SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  _showPinDialog.value = false;
                  Get.toNamed('/digital-otp-pin');
                  _pinController.clear();
                },
                child: Text(
                  'Đặt lại mã PIN',
                  style: TextStyle(color: Colors.brown[800]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyPinAndShowOtp() async {
    final ok = await _digitalOtpController.verifyPin(_pinController.text.trim());
    if (!ok) {
      Get.snackbar('Lỗi', 'PIN không đúng');
      _pinController.clear();
      return;
    }
    _showPinDialog.value = false;
    _pinController.clear();
    // Bỏ dialog OTP cá nhân, gửi OTP tự sinh luôn
    await _createChallengeAndPromptOtp();
  }
}
