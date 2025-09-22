import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class AdminConfig {
  // ⚠️ QUAN TRỌNG: Thay thế bằng Service Role Key thực tế từ Supabase Dashboard
  static const String serviceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNqdGRxa252Zm1heXJ3eHhudXVrIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1Njk3OTYyNywiZXhwIjoyMDcyNTU1NjI3fQ.AjJZ-hkx6VpiN5HDrQ5uIp4cetXGkwHnM93YpX_hJYY';
  
  static SupabaseClient get adminClient {
    return SupabaseClient(
      SupabaseConfig.url,
      serviceRoleKey,
    );
  }
  
  // Kiểm tra user có quyền admin không
  static bool isAdmin(String? userRole) {
    return userRole == 'admin';
  }
}
