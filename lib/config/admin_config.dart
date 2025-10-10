// ĐÃ LOẠI BỎ SERVICE ROLE KHỎI ỨNG DỤNG CLIENT
// Mọi tác vụ admin phải được thực thi qua Edge Functions/Backend phía server.

class AdminConfig {
  // Helper thuần túy cho UI; Ủy quyền thật sự phải kiểm tra ở server
  static bool isAdmin(String? userRole) {
    return userRole == 'admin';
  }
}
