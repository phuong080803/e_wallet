import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TokenService {
  static const String _accessTokenKey = 'supabase_access_token';
  static const String _refreshTokenKey = 'supabase_refresh_token';
  static const String _userIdKey = 'supabase_user_id';
  static const String _userEmailKey = 'supabase_user_email';
  static const String _expiresAtKey = 'supabase_expires_at';

  static TokenService? _instance;
  static TokenService get instance => _instance ??= TokenService._();
  
  TokenService._();

  /// Lưu tokens từ session vào SharedPreferences
  Future<void> saveTokens(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_accessTokenKey, session.accessToken);
    await prefs.setString(_refreshTokenKey, session.refreshToken ?? '');
    await prefs.setString(_userIdKey, session.user.id);
    await prefs.setString(_userEmailKey, session.user.email ?? '');
    await prefs.setInt(_expiresAtKey, session.expiresAt ?? 0);
    
    print('✅ Tokens saved to SharedPreferences');
  }

  /// Lấy access token từ SharedPreferences
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Lấy refresh token từ SharedPreferences
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Lấy user ID từ SharedPreferences
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Lấy user email từ SharedPreferences
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Lấy thời gian hết hạn token
  Future<int?> getExpiresAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_expiresAtKey);
  }

  /// Kiểm tra xem có tokens được lưu không
  Future<bool> hasStoredTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// Kiểm tra xem token có hết hạn không
  Future<bool> isTokenExpired() async {
    final expiresAt = await getExpiresAt();
    if (expiresAt == null) return true;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expiresAt;
  }

  /// Khôi phục session từ stored tokens
  Future<Session?> restoreSession() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      
      if (accessToken == null || refreshToken == null) {
        print('❌ No stored tokens found');
        return null;
      }

      // Kiểm tra nếu token đã hết hạn, thử refresh
      if (await isTokenExpired()) {
        print('🔄 Token expired, attempting refresh...');
        return await refreshSession();
      }

      // Tạo session từ stored tokens
      final userId = await getUserId();
      final userEmail = await getUserEmail();
      final expiresAt = await getExpiresAt();

      if (userId == null) return null;

      // Set session vào Supabase client
      await Supabase.instance.client.auth.setSession(accessToken);
      
      print('✅ Session restored from stored tokens');
      return Supabase.instance.client.auth.currentSession;
      
    } catch (e) {
      print('❌ Error restoring session: $e');
      await clearTokens();
      return null;
    }
  }

  /// Refresh session sử dụng refresh token
  Future<Session?> refreshSession() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('❌ No refresh token available');
        return null;
      }

      final response = await Supabase.instance.client.auth.refreshSession(refreshToken);
      
      if (response.session != null) {
        await saveTokens(response.session!);
        print('✅ Session refreshed successfully');
        return response.session;
      }
      
      return null;
    } catch (e) {
      print('❌ Error refreshing session: $e');
      await clearTokens();
      return null;
    }
  }

  /// Xóa tất cả tokens khỏi SharedPreferences
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_expiresAtKey);
    
    print('✅ All tokens cleared from SharedPreferences');
  }

  /// Lấy thông tin user từ stored tokens
  Future<Map<String, String?>> getStoredUserInfo() async {
    return {
      'userId': await getUserId(),
      'email': await getUserEmail(),
      'accessToken': await getAccessToken(),
    };
  }

  /// Kiểm tra tính hợp lệ của session hiện tại
  Future<bool> isSessionValid() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return false;
      
      // Kiểm tra xem session có hết hạn không
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return (session.expiresAt ?? 0) > now;
    } catch (e) {
      return false;
    }
  }
}
