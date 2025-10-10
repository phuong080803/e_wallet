import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/database_models.dart';
import 'package:intl/intl.dart';

class TransactionController extends GetxController {
  final _transactions = <Transaction>[].obs;
  final _isLoading = false.obs;
  final _selectedFilter = 'all'.obs; // all, incoming, outgoing
  final _isAdmin = false.obs;

  List<Transaction> get transactions => _transactions;
  RxBool get isLoading => _isLoading;
  RxString get selectedFilter => _selectedFilter;
  bool get isAdmin => _isAdmin.value;

  // Transaction statistics getter for UI
  Map<String, double> get transactionStats {
    return {
      'totalIncoming': totalIncoming,
      'totalOutgoing': totalOutgoing,
      'incomingCount': incomingCount.toDouble(),
      'outgoingCount': outgoingCount.toDouble(),
    };
  }

  List<Transaction> get filteredTransactions {
    switch (_selectedFilter.value) {
      case 'incoming':
        return _transactions.where((t) => 
          ['transfer_in', 'deposit', 'payment_in'].contains(t.transactionType)
        ).toList();
      case 'outgoing':
        return _transactions.where((t) => 
          ['transfer_out', 'withdraw', 'payment_out'].contains(t.transactionType)
        ).toList();
      default:
        return _transactions;
    }
  }

  double get totalIncoming {
    return _transactions
        .where((t) => ['transfer_in', 'deposit', 'payment_in'].contains(t.transactionType))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalOutgoing {
    return _transactions
        .where((t) => ['transfer_out', 'withdraw', 'payment_out'].contains(t.transactionType))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  int get incomingCount {
    return _transactions
        .where((t) => ['transfer_in', 'deposit', 'payment_in'].contains(t.transactionType))
        .length;
  }

  int get outgoingCount {
    return _transactions
        .where((t) => ['transfer_out', 'withdraw', 'payment_out'].contains(t.transactionType))
        .length;
  }

  @override
  void onInit() {
    super.onInit();
    checkAdminRole();
    loadTransactions();
  }

  Future<void> checkAdminRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Check if user is admin by querying admin_users table
        final adminResponse = await Supabase.instance.client
            .from('admin_users')
            .select('id')
            .eq('email', user.email ?? '')
            .maybeSingle();
        
        _isAdmin.value = adminResponse != null;
      }
    } catch (e) {
      print('Error checking admin role: $e');
      _isAdmin.value = false;
    }
  }

  Future<void> loadTransactions({String? userId}) async {
    try {
      _isLoading.value = true;
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      PostgrestFilterBuilder query;
      
      if (_isAdmin.value) {
        // Admin view - use admin_transaction_history with full details
        query = Supabase.instance.client
            .from('admin_transaction_history')
            .select('*');
        
        // If specific user ID provided (for admin viewing specific user)
        if (userId != null) {
          query = query.eq('user_id', userId);
        }
      } else {
        // User view - use user_transaction_history (hides sender/recipient details)
        query = Supabase.instance.client
            .from('user_transaction_history')
            .select('*')
            .eq('user_id', user.id);
      }

      // Do not rely on DB column names for ordering; fetch then sort in Dart to match whichever
      // timestamp your view/table provides and what the model can parse.
      final response = await query
          .limit(100); // Limit for performance

      final List<Transaction> loadedTransactions = [];
      
      for (final item in response) {
        loadedTransactions.add(Transaction.fromJson(item));
      }

      // Sort by createdAt desc in app to avoid DB column name mismatches
      loadedTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _transactions.value = loadedTransactions;
    } catch (e) {
      print('Error loading transactions: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải lịch sử giao dịch: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    _selectedFilter.value = filter;
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String formatAmount(double amount) {
    return formatCurrency(amount);
  }

  String formatBalance(double balance) {
    return formatCurrency(balance);
  }

  String formatDate(DateTime date) {
    // Cộng thêm 7 giờ để chuyển từ UTC sang UTC+7 (Việt Nam)
    final vietnamTime = date.add(const Duration(hours: 7));
    return DateFormat('dd/MM/yyyy HH:mm').format(vietnamTime);
  }

  String formatDateTime(DateTime date) {
    // Cộng thêm 7 giờ để chuyển từ UTC sang UTC+7 (Việt Nam)
    final vietnamTime = date.add(const Duration(hours: 7));
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(vietnamTime);
  }

  String getTransactionPrefix(String transactionType) {
    switch (transactionType) {
      case 'transfer_in':
      case 'deposit':
      case 'payment_in':
        return '+';
      case 'transfer_out':
      case 'withdraw':
      case 'payment_out':
        return '-';
      default:
        return '';
    }
  }

  // Admin-specific methods
  Future<void> loadAllTransactions() async {
    if (!_isAdmin.value) return;
    await loadTransactions();
  }

  Future<void> loadUserTransactions(String userId) async {
    if (!_isAdmin.value) return;
    await loadTransactions(userId: userId);
  }

  // Clear all transaction data (useful for sign out)
  void clearAllTransactions() {
    transactions.clear();
    filteredTransactions.clear();
    transactionStats.clear();
    selectedFilter.value = 'all';
    print('✅ All transaction data cleared');
  }

  Future<void> refreshTransactions() async {
    await loadTransactions();
  }
}
