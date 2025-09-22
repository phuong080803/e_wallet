# Token-Based Supabase Integration Guide

## Tổng quan
Hệ thống này sử dụng SharedPreferences để lưu trữ và quản lý tokens Supabase, cho phép người dùng duy trì trạng thái đăng nhập và thực hiện các tương tác với cơ sở dữ liệu một cách an toàn.

## Các thành phần chính

### 1. TokenService (`lib/services/token_service.dart`)
Quản lý việc lưu trữ, khôi phục và refresh tokens từ SharedPreferences.

**Chức năng chính:**
- `saveTokens(Session session)` - Lưu tokens từ session
- `getAccessToken()` - Lấy access token
- `restoreSession()` - Khôi phục session từ stored tokens
- `refreshSession()` - Refresh session khi token hết hạn
- `clearTokens()` - Xóa tất cả tokens
- `isTokenExpired()` - Kiểm tra token có hết hạn không

### 2. SupabaseService (`lib/services/supabase_service.dart`)
Wrapper cho tất cả các tương tác với Supabase database, tự động đảm bảo có session hợp lệ.

**Chức năng chính:**
- `select()` - Thực hiện SELECT queries
- `insert()` - Thực hiện INSERT operations
- `update()` - Thực hiện UPDATE operations
- `delete()` - Thực hiện DELETE operations
- `rpc()` - Gọi stored functions
- `uploadFile()` - Upload files
- `subscribeToTable()` - Realtime subscriptions

### 3. AuthController (Updated)
Controller xác thực đã được cập nhật để sử dụng token persistence.

## Cách sử dụng

### 1. Khởi tạo trong Controller

```dart
import '../services/supabase_service.dart';

class MyController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  // Các methods của bạn...
}
```

### 2. Thực hiện Database Operations

#### SELECT Data
```dart
// Lấy tất cả records
final users = await _supabaseService.select(table: 'users');

// Lấy với filters
final userWallet = await _supabaseService.select(
  table: 'wallets',
  filters: {'user_id': userId},
);

// Lấy với ordering và limit
final recentTransactions = await _supabaseService.select(
  table: 'transactions',
  filters: {'user_id': userId},
  orderBy: 'created_at',
  ascending: false,
  limit: 10,
);
```

#### INSERT Data
```dart
final newTransaction = await _supabaseService.insert(
  table: 'transactions',
  data: {
    'sender_id': senderId,
    'receiver_id': receiverId,
    'amount': amount,
    'type': 'transfer',
    'status': 'completed',
    'created_at': DateTime.now().toIso8601String(),
  },
);
```

#### UPDATE Data
```dart
await _supabaseService.update(
  table: 'wallets',
  data: {'balance': newBalance},
  filters: {'user_id': userId},
);
```

#### DELETE Data
```dart
await _supabaseService.delete(
  table: 'transactions',
  filters: {'id': transactionId},
);
```

### 3. File Upload
```dart
final imageUrl = await _supabaseService.uploadFile(
  bucket: 'avatars',
  path: 'user_${userId}_avatar.jpg',
  fileBytes: imageBytes,
  metadata: {'contentType': 'image/jpeg'},
);
```

### 4. Realtime Subscriptions
```dart
final channel = _supabaseService.subscribeToTable(
  table: 'transactions',
  onInsert: (data) {
    print('New transaction: $data');
    // Cập nhật UI
  },
  onUpdate: (data) {
    print('Transaction updated: $data');
  },
  onDelete: (data) {
    print('Transaction deleted: $data');
  },
);
```

### 5. RPC Calls
```dart
final result = await _supabaseService.rpc(
  functionName: 'calculate_user_balance',
  params: {'user_id': userId},
);
```

## Ví dụ thực tế: WalletController

```dart
class WalletController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final Rx<Wallet?> currentWallet = Rx<Wallet?>(null);

  // Load wallet của user
  Future<void> loadWallet(String userId) async {
    try {
      final walletData = await _supabaseService.select(
        table: 'wallets',
        filters: {'user_id': userId},
      );
      
      if (walletData != null && walletData.isNotEmpty) {
        currentWallet.value = Wallet.fromJson(walletData.first);
      }
    } catch (e) {
      print('Error loading wallet: $e');
    }
  }

  // Gửi tiền
  Future<bool> sendMoney({
    required String senderId,
    required String receiverId,
    required double amount,
  }) async {
    try {
      // Tạo transaction
      await _supabaseService.insert(
        table: 'transactions',
        data: {
          'sender_id': senderId,
          'receiver_id': receiverId,
          'amount': amount,
          'type': 'transfer',
          'status': 'completed',
        },
      );

      // Cập nhật balance
      await _supabaseService.update(
        table: 'wallets',
        data: {'balance': currentWallet.value!.balance - amount},
        filters: {'user_id': senderId},
      );

      return true;
    } catch (e) {
      print('Send money error: $e');
      return false;
    }
  }
}
```

## Xử lý lỗi và Authentication

### Tự động Token Refresh
Service tự động kiểm tra và refresh tokens khi cần thiết:

```dart
// Trong _ensureValidSession()
if (await _tokenService.isTokenExpired()) {
  final refreshedSession = await _tokenService.refreshSession();
  return refreshedSession != null;
}
```

### Xử lý lỗi Authentication
```dart
try {
  final data = await _supabaseService.select(table: 'users');
} catch (e) {
  if (e.toString().contains('Authentication required')) {
    // Redirect to login
    Get.offAllNamed('/login');
  }
}
```

## Best Practices

### 1. Error Handling
Luôn wrap database calls trong try-catch:

```dart
try {
  final result = await _supabaseService.select(table: 'users');
  // Process result
} catch (e) {
  print('Database error: $e');
  // Show user-friendly error message
  Get.snackbar('Error', 'Failed to load data');
}
```

### 2. Loading States
Sử dụng loading indicators:

```dart
final RxBool isLoading = false.obs;

Future<void> loadData() async {
  isLoading.value = true;
  try {
    // Database operations
  } finally {
    isLoading.value = false;
  }
}
```

### 3. Session Management
Kiểm tra session validity trước khi thực hiện operations quan trọng:

```dart
final sessionInfo = _supabaseService.getSessionInfo();
if (sessionInfo == null) {
  // Handle unauthenticated state
  return;
}
```

## Cấu trúc Database đề xuất

### Tables cần thiết:
- `profiles` - Thông tin user profiles
- `wallets` - Ví điện tử của users
- `transactions` - Lịch sử giao dịch

### RLS (Row Level Security) Policies:
```sql
-- Chỉ cho phép users xem/sửa data của chính họ
CREATE POLICY "Users can view own data" ON profiles
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON profiles
FOR UPDATE USING (auth.uid() = id);
```

## Troubleshooting

### 1. Token không được lưu
- Kiểm tra SharedPreferences permissions
- Đảm bảo `WidgetsFlutterBinding.ensureInitialized()` được gọi

### 2. Session không được khôi phục
- Kiểm tra token expiry time
- Verify refresh token validity

### 3. Database operations fail
- Check network connectivity
- Verify RLS policies
- Ensure proper authentication

## Kết luận

Hệ thống token-based này cung cấp:
- ✅ Persistent authentication state
- ✅ Automatic token refresh
- ✅ Secure database interactions
- ✅ Error handling và recovery
- ✅ Easy-to-use API wrapper

Tất cả database operations giờ đây được bảo vệ bởi authentication tokens được lưu trữ an toàn trong SharedPreferences.
