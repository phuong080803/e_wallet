import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:e_wallet/controllers/wallet_controller.dart';
import 'package:e_wallet/styles/constrant.dart';
import 'package:e_wallet/styles/size_config.dart';
import 'package:e_wallet/pages/widgets/custom_elevated_button.dart';
import 'transfer_money_screen.dart';
import 'transaction_history_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletController _walletController = Get.put(WalletController());

  @override
  void initState() {
    super.initState();
    _walletController.loadUserWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: k_grey,
      appBar: AppBar(
        title: Text(
          'Ví điện tử',
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
      body: Obx(() {
        if (_walletController.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet Balance Card
                _buildWalletCard(),
                const SizedBox(height: 30),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 30),

                // Recent Transactions
                _buildRecentTransactions(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWalletCard() {
    final wallet = _walletController.userWallet.value;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [k_blue, k_blue.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: k_blue.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: wallet != null ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số dư khả dụng',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _walletController.formatBalance(wallet.balance),
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID Ví',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    _walletController.formatWalletId(wallet.walletId),
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  wallet.isActive ? 'Hoạt động' : 'Tạm khóa',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ) : Column(
        children: [
          Icon(Icons.wallet, size: 64, color: Colors.white70),
          const SizedBox(height: 16),
          Text(
            'Chưa có ví điện tử',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo ví để bắt đầu sử dụng dịch vụ',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thao tác nhanh',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add,
                title: 'Nạp tiền',
                color: Colors.green,
                onTap: () => _showTopUpDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.send_outlined,
                title: 'Chuyển tiền',
                color: Colors.blue,
                onTap: _handleTransfer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.qr_code_scanner,
                title: 'Quét QR',
                color: Colors.orange,
                onTap: () => _showDevelopmentMessage('Quét QR'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.history,
                title: 'Lịch sử',
                color: Colors.purple,
                onTap: () => Get.to(() => TransactionHistoryScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giao dịch gần đây',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Chưa có giao dịch',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Các giao dịch của bạn sẽ hiển thị tại đây',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleTransfer() {
    Get.to(() => TransferMoneyScreen());
  }

  void _showTopUpDialog() {
    final TextEditingController amountController = TextEditingController();
    final List<double> quickAmounts = [50000, 100000, 200000, 500000, 1000000, 2000000];
    
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Nạp tiền vào ví'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn số tiền nạp:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              SizedBox(height: 16),
              
              // Quick amount buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickAmounts.map((amount) {
                  return GestureDetector(
                    onTap: () {
                      amountController.text = amount.toStringAsFixed(0);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${(amount / 1000).toStringAsFixed(0)}K',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              SizedBox(height: 16),
              Text(
                'Hoặc nhập số tiền khác:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              
              // Custom amount input
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền (VND)',
                  prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.green),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Số tiền tối thiểu: 10,000 VND\nSố tiền tối đa: 10,000,000 VND',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final amountText = amountController.text.trim();
              if (amountText.isEmpty) {
                Get.snackbar('Lỗi', 'Vui lòng nhập số tiền');
                return;
              }
              
              final amount = double.tryParse(amountText);
              if (amount == null || amount <= 0) {
                Get.snackbar('Lỗi', 'Số tiền không hợp lệ');
                return;
              }
              
              if (amount < 10000) {
                Get.snackbar('Lỗi', 'Số tiền tối thiểu là 10,000 VND');
                return;
              }
              
              if (amount > 10000000) {
                Get.snackbar('Lỗi', 'Số tiền tối đa là 10,000,000 VND');
                return;
              }
              
              Get.back();
              _processTopUp(amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Nạp tiền'),
          ),
        ],
      ),
    );
  }

  void _processTopUp(double amount) {
    _executeTopUp(amount);
  }

  void _executeTopUp(double amount) async {
    try {
      // Update wallet balance
      final success = await _walletController.updateWalletBalance(amount);
      
      if (success) {
        Get.snackbar(
          'Thành công',
          'Nạp tiền thành công! +${_walletController.formatBalance(amount)}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
        
        // Refresh wallet data
        await _walletController.loadUserWallet();
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể nạp tiền. Vui lòng thử lại.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Đã xảy ra lỗi khi nạp tiền: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showDevelopmentMessage(String feature) {
    Get.snackbar(
      'Thông báo',
      'Tính năng $feature đang phát triển',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: Duration(seconds: 2),
    );
  }
}
