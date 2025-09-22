import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/transaction_controller.dart';
import '../../../models/database_models.dart';
import '../../../styles/constrant.dart';

class TransactionHistoryScreen extends StatelessWidget {
  TransactionHistoryScreen({Key? key}) : super(key: key);

  final TransactionController _transactionController = Get.put(TransactionController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lịch sử giao dịch',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: k_blue,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _transactionController.refreshTransactions(),
            icon: Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: k_blue,
            child: Obx(() => Row(
              children: [
                _buildFilterTab('Tất cả', 'all'),
                _buildFilterTab('Tiền vào', 'incoming'),
                _buildFilterTab('Tiền ra', 'outgoing'),
              ],
            )),
          ),
          
          // Statistics Summary
          Obx(() {
            final stats = _transactionController.transactionStats;
            return Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Tiền vào',
                      _transactionController.formatAmount(stats['totalIncoming']!),
                      '${stats['incomingCount']!.toInt()} giao dịch',
                      Colors.green,
                      Icons.arrow_downward,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Tiền ra',
                      _transactionController.formatAmount(stats['totalOutgoing']!),
                      '${stats['outgoingCount']!.toInt()} giao dịch',
                      Colors.red,
                      Icons.arrow_upward,
                    ),
                  ),
                ],
              ),
            );
          }),
          
          // Transaction List
          Expanded(
            child: Obx(() {
              if (_transactionController.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }
              
              final transactions = _transactionController.filteredTransactions;
              
              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có giao dịch nào',
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
                onRefresh: _transactionController.refreshTransactions,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _buildTransactionItem(transaction);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String filter) {
    final isSelected = _transactionController.selectedFilter.value == filter;
    return Expanded(
      child: InkWell(
        onTap: () => _transactionController.setFilter(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String amount, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            count,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncoming = transaction.isIncoming;
    final color = isIncoming ? Colors.green : Colors.red;
    final icon = isIncoming ? Icons.add_circle : Icons.remove_circle;
    final amountPrefix = isIncoming ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
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
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.transactionLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (transaction.counterpartName != null)
                      Text(
                        isIncoming 
                            ? 'Từ: ${transaction.counterpartName}'
                            : 'Đến: ${transaction.counterpartName}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix${_transactionController.formatAmount(transaction.amount)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _transactionController.formatDateTime(transaction.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Balance Information
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Số dư trước:',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                Text(
                  _transactionController.formatBalance(transaction.balanceBefore),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 4),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Số dư sau:',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _transactionController.formatBalance(transaction.balanceAfter),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Description and Notes
          if (transaction.description.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              transaction.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
          
          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              'Ghi chú: ${transaction.notes}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          // Reference Number
          if (transaction.referenceNumber != null) ...[
            SizedBox(height: 4),
            Text(
              'Mã GD: ${transaction.referenceNumber}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
