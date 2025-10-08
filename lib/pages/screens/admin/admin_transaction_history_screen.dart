import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/transaction_controller.dart';
import '../../../models/database_models.dart';
import 'package:intl/intl.dart';

class AdminTransactionHistoryScreen extends StatelessWidget {
  final String? userId; // Optional: view transactions for specific user
  
  const AdminTransactionHistoryScreen({Key? key, this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TransactionController controller = Get.put(TransactionController());
    
    // Load transactions for specific user if provided
    if (userId != null) {
      controller.loadUserTransactions(userId!);
    } else {
      controller.loadAllTransactions();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          userId != null ? 'Lịch sử giao dịch người dùng' : 'Tất cả giao dịch',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.refreshTransactions(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            child: Obx(() => Row(
              children: [
                _buildFilterTab(controller, 'all', 'Tất cả'),
                _buildFilterTab(controller, 'incoming', 'Tiền vào'),
                _buildFilterTab(controller, 'outgoing', 'Tiền ra'),
              ],
            )),
          ),
          
          // Statistics cards
          Obx(() => Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Tổng tiền vào',
                    controller.totalIncoming,
                    controller.incomingCount,
                    Colors.green,
                    Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Tổng tiền ra',
                    controller.totalOutgoing,
                    controller.outgoingCount,
                    Colors.red,
                    Icons.arrow_upward,
                  ),
                ),
              ],
            ),
          )),
          
          // Transaction list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2E7D32),
                  ),
                );
              }

              final transactions = controller.filteredTransactions;
              
              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có giao dịch nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshTransactions,
                color: const Color(0xFF2E7D32),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _buildAdminTransactionCard(transaction);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(TransactionController controller, String filter, String label) {
    final isSelected = controller.selectedFilter.value == filter;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setFilter(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '$count giao dịch',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTransactionCard(Transaction transaction) {
    final isIncoming = transaction.isIncoming;
    final color = isIncoming ? Colors.green : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with transaction type and amount
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.transactionLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transaction.amountPrefix}${NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'VND',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // User information (Admin view)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin người dùng:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tên: ${transaction.displayUserName}',
                  style: const TextStyle(fontSize: 13),
                ),
                if (transaction.userEmail != null)
                  Text(
                    'Email: ${transaction.userEmail}',
                    style: const TextStyle(fontSize: 13),
                  ),
                Text(
                  'Ví ID: ${transaction.walletId}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          
          // Counterpart information (if exists)
          if (transaction.counterpartName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin đối tác:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tên: ${transaction.displayCounterpartName}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (transaction.counterpartEmail != null)
                    Text(
                      'Email: ${transaction.counterpartEmail}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  if (transaction.counterpartWalletId != null)
                    Text(
                      'Ví ID: ${transaction.counterpartWalletId}',
                      style: const TextStyle(fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Balance information
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số dư trước:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(transaction.balanceBefore),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Số dư sau:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(transaction.balanceAfter),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Transaction details
          if (transaction.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Mô tả: ${transaction.description}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
          
          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Ghi chú: ${transaction.notes}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
          
          if (transaction.referenceNumber != null) ...[
            const SizedBox(height: 4),
            Text(
              'Mã tham chiếu: ${transaction.referenceNumber}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
