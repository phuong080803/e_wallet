import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TokenService {
  static const String _accessTokenKey = 'supabase_access_token';
  static const String _refreshTokenKey = 'supabase_refresh_token';
  static const String _userIdKey = 'supabase_user_id';
  static const String _userEmailKey = 'supabase_user_email';
  static const String _expiresAtKey = 'supabase_expires_at';
  static const String _lastActivityAtKey = 'app_last_activity_at';

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
    await setLastActivityNow();
    
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

  /// Cập nhật thời điểm hoạt động gần nhất (epoch seconds)
  Future<void> setLastActivityNow() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await prefs.setInt(_lastActivityAtKey, now);
  }

  /// Lấy thời điểm hoạt động gần nhất
  Future<int?> getLastActivityAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastActivityAtKey);
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

  /// Khôi phục session chuẩn Supabase bằng refresh token
  Future<Session?> restoreSession() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('❌ No stored refresh token found');
        return null;
      }

      final response = await Supabase.instance.client.auth.recoverSession(refreshToken);
      final session = response.session;
      if (session != null) {
        await saveTokens(session);
        print('✅ Session recovered via refresh token');
        return session;
      }
      return null;
    } catch (e) {
      print('❌ Error recovering session: $e');
      await clearTokens();
      return null;
    }
  }

  /// Refresh session chuẩn Supabase (dựa trên session hiện tại)
  Future<Session?> refreshSession() async {
    try {
      final response = await Supabase.instance.client.auth.refreshSession();
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
