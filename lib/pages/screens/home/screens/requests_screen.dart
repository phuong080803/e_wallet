import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../styles/constrant.dart';
import 'package:e_wallet/styles/size_config.dart';
import 'package:e_wallet/controllers/transaction_controller.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({Key? key}) : super(key: key);

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final TransactionController _txController = Get.put(TransactionController());
  StreamSubscription<List<Map<String, dynamic>>>? _txSub;

  @override
  void initState() {
    super.initState();
    _subscribeBalanceChanges();
  }

  void _subscribeBalanceChanges() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Listen realtime for current user's transactions to notify balance changes
    _txSub = Supabase.instance.client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .listen((rows) {
      if (rows.isEmpty) return;
      // Take the last row as the latest change (rows is the full snapshot)
      final last = rows.last;
      final amount = (last['amount'] ?? last['so_tien'] ?? 0).toDouble();
      final type = (last['transaction_type'] ?? last['loai_giao_dich'] ?? '').toString();
      final isIncoming = ['transfer_in', 'deposit', 'payment_in'].contains(type);
      final prefix = isIncoming ? '+' : '-';
      Get.snackbar(
        'Số dư đã thay đổi',
        '$prefix${NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(amount)} VND',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      _txController.refreshTransactions();
    });
  }

  @override
  void dispose() {
    _txSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Thông báo',
            style: Theme.of(context).textTheme.displayMedium!.copyWith(fontSize: 20),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: k_black),
            onPressed: () => Get.back(),
          ),
          actions: [
            IconButton(
              tooltip: 'Làm mới',
              icon: const Icon(Icons.refresh, color: k_black),
              onPressed: () => _txController.refreshTransactions(),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() {
            final txs = _txController.transactions;
            final latest = txs.take(3).toList();

            if (_txController.isLoading.value && latest.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (latest.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.separated(
              itemCount: latest.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final t = latest[index];
                final isIncoming = t.isIncoming;
                final color = isIncoming ? Colors.green : Colors.red;
                final prefix = isIncoming ? '+' : '-';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(isIncoming ? Icons.arrow_downward : Icons.arrow_upward, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.transactionLabel,
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt),
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$prefix${NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(t.amount)}',
                            style: Theme.of(context).textTheme.titleMedium!.copyWith(color: color, fontWeight: FontWeight.bold),
                          ),
                          Text('VND', style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Chưa có thông báo thay đổi số dư',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          Text(
            'Khi số dư thay đổi, thông báo sẽ hiển thị tại đây',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey[500]),
          )
        ],
      ),
    );
  }
}
