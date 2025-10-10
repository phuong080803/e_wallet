import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../styles/constrant.dart';
import '../../widgets/custom_elevated_button.dart';
import '../home/screens/home_screen.dart';
import '../e-wallet_layout/e-wallet_layout_screen.dart';
import 'transfer_money_screen.dart';

class TransferSuccessScreen extends StatelessWidget {
  final double amount;
  final String recipientName;
  final String recipientWalletId;
  final String? notes;

  const TransferSuccessScreen({
    Key? key,
    required this.amount,
    required this.recipientName,
    required this.recipientWalletId,
    this.notes,
  }) : super(key: key);

  String _formatBalance(double balance) {
    return '${balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND';
  }

  String _formatWalletId(String walletId) {
    if (walletId.length == 10) {
      return '${walletId.substring(0, 3)} ${walletId.substring(3, 6)} ${walletId.substring(6)}';
    }
    return walletId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 80,
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Success Title
                    Text(
                      'Chuyển tiền thành công!',
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 16),
                    
                    Text(
                      'Giao dịch của bạn đã được xử lý thành công',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Transaction Details Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          // Amount
                          Text(
                            'Số tiền đã chuyển',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _formatBalance(amount),
                            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: k_blue,
                            ),
                          ),
                          
                          SizedBox(height: 24),
                          
                          // Recipient Info
                          _buildDetailRow('Người nhận:', recipientName),
                          SizedBox(height: 12),
                          _buildDetailRow('ID ví:', _formatWalletId(recipientWalletId)),
                          
                          if (notes != null && notes!.isNotEmpty) ...[
                            SizedBox(height: 12),
                            _buildDetailRow('Ghi chú:', notes!),
                          ],
                          
                          SizedBox(height: 12),
                          _buildDetailRow('Thời gian:', _formatDateTime(DateTime.now())),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action Buttons
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    child: CustomElevatedButton(
                      label: 'Tiếp tục chuyển tiền',
                      color: k_blue,
                      onPressed: () {
                        // Navigate back to transfer screen and clear previous screens
                        Get.off(() => TransferMoneyScreen());
                      },
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  Container(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        // Navigate to home screen and clear all previous screens
                        Get.offAll(() => E_WalletLayoutScreen());
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Trở về trang chủ',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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
    );
  }

  String _formatDateTime(DateTime dateTime) {
    // Cộng thêm 7 giờ để chuyển từ UTC sang UTC+7 (Việt Nam)
    final vietnamTime = dateTime.add(const Duration(hours: 7));
    return '${vietnamTime.day.toString().padLeft(2, '0')}/${vietnamTime.month.toString().padLeft(2, '0')}/${vietnamTime.year} ${vietnamTime.hour.toString().padLeft(2, '0')}:${vietnamTime.minute.toString().padLeft(2, '0')}';
  }
}
