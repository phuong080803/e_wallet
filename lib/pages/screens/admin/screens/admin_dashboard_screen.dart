import 'package:e_wallet/controllers/admin_controller.dart';
import 'package:e_wallet/controllers/auth_controller.dart';
import 'package:e_wallet/pages/screens/admin/widgets/admin_verification_item.dart';
import 'package:e_wallet/pages/screens/admin/widgets/admin_user_item.dart';
import 'package:e_wallet/pages/screens/admin/widgets/admin_transaction_item.dart';
import 'package:e_wallet/styles/constrant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminController _adminController = Get.put(AdminController());
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    _adminController.loadPendingVerifications();
    _adminController.loadAllUsers();
    _adminController.loadAllTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: k_blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _adminController.logoutAdmin();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: [
            Tab(text: 'Xác thực', icon: Icon(Icons.verified_user)),
            Tab(text: 'Người dùng', icon: Icon(Icons.people)),
            Tab(text: 'Giao dịch', icon: Icon(Icons.account_balance_wallet)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVerificationsTab(),
          _buildUsersTab(),
          _buildTransactionsTab(),
        ],
      ),
    );
  }

  Widget _buildVerificationsTab() {
    return Obx(() {
      if (_adminController.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (_adminController.pendingVerifications.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Không có yêu cầu xác thực nào',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Người dùng có thể gửi yêu cầu xác thực thông tin cá nhân\nqua Settings > Xác thực thông tin',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await _adminController.loadPendingVerifications();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _adminController.pendingVerifications.length,
          itemBuilder: (context, index) {
            final verification = _adminController.pendingVerifications[index];
            return AdminVerificationItem(
              verification: verification,
              onApprove: () => _showApproveDialog(verification),
              onReject: () => _showRejectDialog(verification),
              onVerifyField: (fieldType, isVerified) => _showFieldVerifyDialog(
                verification,
                fieldType,
                isVerified,
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildUsersTab() {
    return Obx(() {
      if (_adminController.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (_adminController.allUsers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Không có người dùng nào',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await _adminController.loadAllUsers();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _adminController.allUsers.length,
          itemBuilder: (context, index) {
            final user = _adminController.allUsers[index];
            return AdminUserItem(user: user);
          },
        ),
      );
    });
  }

  Widget _buildTransactionsTab() {
    return Obx(() {
      if (_adminController.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (_adminController.allTransactions.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Không có giao dịch nào',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await _adminController.loadAllTransactions();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _adminController.allTransactions.length,
          itemBuilder: (context, index) {
            final transaction = _adminController.allTransactions[index];
            return AdminTransactionItem(transaction: transaction);
          },
        ),
      );
    });
  }

  void _showApproveDialog(verification) {
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Phê duyệt xác thực'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc chắn muốn phê duyệt xác thực này?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _adminController.approveVerification(
                verificationId: verification.id,
                adminNotes: notesController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: Text('Phê duyệt'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(verification) {
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Từ chối xác thực'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc chắn muốn từ chối xác thực này?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Lý do từ chối',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _adminController.rejectVerification(
                verificationId: verification.id,
                adminNotes: notesController.text.trim(),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _showFieldVerifyDialog(verification, String fieldType, bool isVerified) {
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isVerified ? 'Xác thực' : 'Từ chối'} $fieldType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc chắn muốn ${isVerified ? 'xác thực' : 'từ chối'} $fieldType?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _adminController.verifyIndividualField(
                verificationId: verification.id,
                fieldType: fieldType,
                isVerified: isVerified,
                adminNotes: notesController.text.trim(),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isVerified ? Colors.green : Colors.red,
            ),
            child: Text(isVerified ? 'Xác thực' : 'Từ chối'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
