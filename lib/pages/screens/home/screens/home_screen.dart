import 'package:e_wallet/pages/screens/home/screens/requests_screen.dart';
import 'package:flutter/material.dart';

import 'package:e_wallet/models/user_model.dart';
import 'package:e_wallet/pages/screens/home/widgets/build_home_user_item.dart';
import 'package:e_wallet/pages/widgets/user_image.dart';
import 'package:e_wallet/styles/Iconly-Broken_icons.dart';
import '../../../../styles/constrant.dart';
import 'package:e_wallet/styles/size_config.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../controllers/verification_controller.dart';
import '../../../../controllers/wallet_controller.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../wallet/wallet_screen.dart';
import '../../wallet/transaction_history_screen.dart';
import '../../qr/qr_scan_screen.dart';
import '../../../../controllers/e-wallet_layout_controller.dart';
import '../../e-wallet_layout/e-wallet_layout_screen.dart';
import '../../../../controllers/market_controller.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controllers with Get.put to ensure they are created
    final _verificationController = Get.put(VerificationController());
    final _walletController = Get.put(WalletController());
    final _marketController = Get.put(MarketController());
    
    // Balance visibility state
    final RxBool _isBalanceVisible = false.obs;

    // Lấy thông tin user từ auth metadata
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userMetadata = currentUser?.userMetadata ?? {};
    final userName = userMetadata['ho_ten'] ?? userMetadata['name'] ?? 'Người dùng';
    final userImage = userMetadata['hinh_anh'] ?? userMetadata['image'] ?? k_imagePath;

    // Sample crypto and forex data (in real app, fetch from API)
    final cryptoRates = [
      {'name': 'Bitcoin', 'symbol': 'BTC', 'price': '2,156,000,000', 'change': '+2.45%', 'isPositive': true},
      {'name': 'Ethereum', 'symbol': 'ETH', 'price': '86,400,000', 'change': '-1.23%', 'isPositive': false},
      {'name': 'BNB', 'symbol': 'BNB', 'price': '14,800,000', 'change': '+0.87%', 'isPositive': true},
    ];

    final forexRates = [
      {'name': 'USD/VND', 'rate': '24,350', 'change': '+0.12%', 'isPositive': true},
      {'name': 'EUR/VND', 'rate': '26,120', 'change': '-0.34%', 'isPositive': false},
      {'name': 'JPY/VND', 'rate': '163.5', 'change': '+0.08%', 'isPositive': true},
    ];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _walletController.loadUserWallet();
          await _marketController.fetchAll(force: true);
        },
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header Section with Balance
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [k_blue, k_blue.withOpacity(0.8)],
                    ),
                  ),
                  width: SizeConfig.screenWidth,
                  height: 300,
                ),
                Container(
                  height: 300,
                  width: SizeConfig.screenWidth,
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Dashboard",
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            InkWell(
                              onTap: () => Get.to(() => RequestsScreen()),
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Iconly_Broken.Notification,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        Row(
                          children: [
                            UserImage(
                              imagePath: userImage,
                              raduis: 30,
                            ),
                            SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Xin chào,",
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  userName,
                                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 25),
                        Text(
                          "Số dư ví",
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Obx(() {
                                if (_walletController.hasWallet.value && _walletController.userWallet.value != null) {
                                  final wallet = _walletController.userWallet.value!;
                                  return Text(
                                    _isBalanceVisible.value 
                                        ? _walletController.formatBalance(wallet.balance)
                                        : "••••••••",
                                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  );
                                } else {
                                  return Text(
                                    _isBalanceVisible.value ? "0 VNĐ" : "••••••••",
                                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  );
                                }
                              }),
                            ),
                            SizedBox(width: 12),
                            Obx(() => InkWell(
                              onTap: () => _isBalanceVisible.toggle(),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _isBalanceVisible.value 
                                      ? Icons.visibility_off 
                                      : Icons.visibility,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Quick Actions Section
            Obx(() {
              if (_walletController.hasWallet.value) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thao tác nhanh",
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              icon: Icons.add_circle_outline,
                              label: "Nạp tiền",
                              color: Colors.green,
                              onTap: () => Get.to(() => WalletScreen()),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              icon: Icons.send_outlined,
                              label: "Chuyển tiền",
                              color: Colors.blue,
                              onTap: () => Get.to(() => WalletScreen()),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              icon: Icons.qr_code_scanner,
                              label: "Quét QR",
                              color: Colors.purple,
                              onTap: () => Get.to(() => QRScanScreen()),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionButton(
                              context,
                              icon: Icons.history,
                              label: "Lịch sử",
                              color: Colors.orange,
                              onTap: () {
                                E_WalletLayoutController.changeIndex(1);
                                Get.offAll(() => E_WalletLayoutScreen());
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              return SizedBox.shrink();
            }),

            // Wallet Status Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Wallet Creation Section - Only show if verified and no wallet
                  Obx(() {
                    if (_verificationController.isUserVerified && !_walletController.hasWallet.value) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tạo ví điện tử',
                                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        'Bắt đầu giao dịch ngay hôm nay',
                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                          color: Colors.green.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tài khoản của bạn đã được xác thực. Tạo ví điện tử để bắt đầu sử dụng các dịch vụ thanh toán.',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Colors.green.shade600,
                                height: 1.4,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              child: CustomElevatedButton(
                                label: _walletController.isLoading.value ? "Đang tạo..." : "Tạo ví điện tử",
                                color: Colors.green,
                                onPressed: _walletController.isLoading.value ? null : () async {
                                  await _walletController.createWallet();
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }),

                  // Wallet Info Section - Show if user has wallet
                  Obx(() {
                    if (_walletController.hasWallet.value && _walletController.userWallet.value != null) {
                      final wallet = _walletController.userWallet.value!;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [k_blue.withOpacity(0.1), k_blue.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: k_blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: k_blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ví điện tử',
                                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: k_blue,
                                        ),
                                      ),
                                      Text(
                                        'Đã kích hoạt và sẵn sàng sử dụng',
                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                          color: k_blue.withOpacity(0.7),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () => Get.to(() => WalletScreen()),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: k_blue,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Xem chi tiết',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'ID Ví:',
                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _walletController.formatWalletId(wallet.walletId),
                                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: k_blue,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Số dư hiện tại:',
                                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Obx(() => Text(
                                        _isBalanceVisible.value 
                                            ? _walletController.formatBalance(wallet.balance)
                                            : "••••••••",
                                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade600,
                                          fontSize: 16,
                                        ),
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  }),
                ],
              ),
            ),

            // Market Dynamic Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Thị trường tài chính",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Ticker
                  Obx(() {
                    if (_marketController.isLoading.value && _marketController.crypto.isEmpty) {
                      return Container(
                        height: 38,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: Text('Đang tải thị trường...'),
                      );
                    }
                    return _buildMarketTicker(context, _marketController);
                  }),
                  const SizedBox(height: 12),
                  // Summary Cards
                  Obx(() {
                    return _buildMarketSummary(context, _marketController);
                  }),
                ],
              ),
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketTicker(BuildContext context, MarketController mc) {
    final items = mc.crypto;
    if (items.isEmpty) {
      return Container(
        height: 38,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text('Không có dữ liệu thị trường'),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final it = items[index];
          final name = (it['name'] ?? '').toString();
          final price = (it['current_price'] ?? '').toString();
          final change = (it['price_change_percentage_24h'] ?? 0).toDouble();
          final positive = change >= 0;
          return Container(
            width: 150,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        price,
                        style: TextStyle(color: Colors.black87, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: positive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${change.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: positive ? Colors.green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w600
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildMarketSummary(BuildContext context, MarketController mc) {
    final crypto = mc.crypto;
    final forex = mc.forex;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3, offset: const Offset(0,1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [Icon(Icons.currency_bitcoin, color: Colors.orange, size: 20), SizedBox(width: 6), Text('Crypto', style: TextStyle(fontWeight: FontWeight.bold))]),
                const SizedBox(height: 8),
                if (crypto.isEmpty) Text('—') else ...crypto.take(2).map((it) {
                  final name = (it['symbol'] ?? '').toString().toUpperCase();
                  final price = (it['current_price'] ?? '').toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          price,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3, offset: const Offset(0,1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [Icon(Icons.attach_money, color: Colors.green, size: 20), SizedBox(width: 6), Text('Forex', style: TextStyle(fontWeight: FontWeight.bold))]),
                const SizedBox(height: 8),
                if (forex.isEmpty) const Text('—') else ...["VND","EUR","JPY"].map((code){
                  final rate = forex['rates']?[code];
                  if (rate == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'USD/$code',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          rate.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRateItem(
    BuildContext context, {
    required String name,
    required String symbol,
    required String price,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (symbol.isNotEmpty)
                  Text(
                    symbol,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              price,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                change,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
