import 'package:supabase_flutter/supabase_flutter.dart';
import 'token_service.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();

  final TokenService _tokenService = TokenService.instance;
  SupabaseClient get _client => Supabase.instance.client;

  /// Đảm bảo có session hợp lệ trước khi thực hiện operations
  Future<bool> _ensureValidSession() async {
    try {
      // Kiểm tra session hiện tại
      final currentSession = _client.auth.currentSession;
      
      if (currentSession == null) {
        // Thử khôi phục từ stored tokens
        final restoredSession = await _tokenService.restoreSession();
        return restoredSession != null;
      }

      // Kiểm tra session có hết hạn không
      if (await _tokenService.isTokenExpired()) {
        // Thử refresh session
        final refreshedSession = await _tokenService.refreshSession();
        return refreshedSession != null;
      }

      return true;
    } catch (e) {
      print('❌ Error ensuring valid session: $e');
      return false;
    }
  }

  /// Thực hiện SELECT query với token authentication
  Future<List<Map<String, dynamic>>?> select({
    required String table,
    String columns = '*',
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    if (!await _ensureValidSession()) {
      throw Exception('Authentication required');
    }

    try {
      var query = _client.from(table).select(columns);

      // Áp dụng filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      // Áp dụng order by
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Áp dụng limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error in select operation: $e');
      rethrow;
    }
  }

  /// Thực hiện INSERT operation với token authentication
  Future<Map<String, dynamic>?> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    if (!await _ensureValidSession()) {
      throw Exception('Authentication required');
    }

    try {
      final response = await _client
          .from(table)
          .insert(data)
          .select()
          .single();
      
      print('✅ Insert successful in table: $table');
      return response;
    } catch (e) {
      print('❌ Error in insert operation: $e');
      rethrow;
    }
  }

  /// Thực hiện UPDATE operation với token authentication
  Future<Map<String, dynamic>?> update({
    required String table,
    required Map<String, dynamic> data,
    required Map<String, dynamic> filters,
  }) async {
    if (!await _ensureValidSession()) {
      throw Exception('Authentication required');
    }

    try {
      var query = _client.from(table).update(data);

      // Áp dụng filters
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      final response = await query.select().single();
      print('✅ Update successful in table: $table');
      return response;
    } catch (e) {
      print('❌ Error in update operation: $e');
      rethrow;
    }
  }

  /// Thực hiện DELETE operation với token authentication
  Future<void> delete({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    if (!await _ensureValidSession()) {
      throw Exception('Authentication required');
    }

    try {
      var query = _client.from(table).delete();

      // Áp dụng filters
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });

      await query;
      print('✅ Delete successful in table: $table');
    } catch (e) {
      print('❌ Error in delete operation: $e');
      rethrow;
    }
  }

  /// Lấy thông tin user hiện tại
  Future<Map<String, dynamic>?> getCurrentUser() async {
    if (!await _ensureValidSession()) {
      return null;
    }

    final session = _client.auth.currentSession;
    if (session?.user != null) {
      return {
        'id': session!.user.id,
        'email': session.user.email,
        'created_at': session.user.createdAt,
        'last_sign_in_at': session.user.lastSignInAt,
      };
    }
    return null;
  }

  /// Lấy profile của user hiện tại
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = await getCurrentUser();
    if (user == null) return null;

    try {
      final profile = await select(
        table: 'profiles',
        filters: {'id': user['id']},
      );
      
      return profile?.isNotEmpty == true ? profile!.first : null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Thực hiện RPC (Remote Procedure Call) với token authentication
  Future<dynamic> rpc({
    required String functionName,
    Map<String, dynamic>? params,
  }) async {
    if (!await _ensureValidSession()) {
      throw Exception('Authentication required');
    }

    try {
      final response = await _client.rpc(functionName, params: params);
      print('✅ RPC call successful: $functionName');
      return response;
    } catch (e) {
      print('❌ Error in RPC call: $e');
      rethrow;
    }
  }

  /// Upload file với token authentication
  Future<String?> uploadFile({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    Map<String, String>? metadata,
  }) async {
    if (!await _ensureValidSession()) {
      throw Exception('Authentication required');
    }

    try {
      await _client.storage.from(bucket).uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(
          metadata: metadata,
        ),
      );

      final url = _client.storage.from(bucket).getPublicUrl(path);
      print('✅ File upload successful: $path');
      return url;
    } catch (e) {
      print('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// Download file với token authentication
  Future<List<int>?> downloadFile({
    required String bucket,
    required String path,
  }) async {
    if (!await _ensureValidSession()) {
      throw Exception('Authentication required');
    }

    try {
      final response = await _client.storage.from(bucket).download(path);
      print('✅ File download successful: $path');
      return response;
    } catch (e) {
      print('❌ Error downloading file: $e');
      rethrow;
    }
  }

  /// Realtime subscription với token authentication
  RealtimeChannel? subscribeToTable({
    required String table,
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    final session = _client.auth.currentSession;
    if (session == null) {
      print('❌ No valid session for realtime subscription');
      return null;
    }

    try {
      final channel = _client
          .channel('public:$table')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: table,
            callback: (payload) => onInsert(payload.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: table,
            callback: (payload) => onUpdate(payload.newRecord),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: table,
            callback: (payload) => onDelete(payload.oldRecord),
          )
          .subscribe();

      print('✅ Realtime subscription created for table: $table');
      return channel;
    } catch (e) {
      print('❌ Error creating realtime subscription: $e');
      return null;
    }
  }

  /// Kiểm tra kết nối và trạng thái authentication
  Future<bool> checkConnection() async {
    try {
      await _client.from('profiles').select('id').limit(1);
      return true;
    } catch (e) {
      print('❌ Connection check failed: $e');
      return false;
    }
  }

  /// Lấy thông tin session hiện tại
  Map<String, dynamic>? getSessionInfo() {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    return {
      'access_token': session.accessToken,
      'refresh_token': session.refreshToken,
      'expires_at': session.expiresAt,
      'user_id': session.user.id,
      'user_email': session.user.email,
    };
  }
}
