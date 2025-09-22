class User {
  final String id;
  final String email;
  final String name;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? age;
  final String? address;
  final String? dateOfBirth;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    this.age,
    this.address,
    this.dateOfBirth,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'] ?? json['ho_ten'] ?? '',
      image: json['image'] ?? json['hinh_anh'],
      createdAt: DateTime.parse(json['created_at'] ?? json['ngay_tao']),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['ngay_cap_nhat']),
      age: json['age']?.toString() ?? json['tuoi']?.toString(),
      address: json['address'] ?? json['dia_chi'],
      dateOfBirth: json['date_of_birth'] ?? json['ngay_sinh'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'image': image,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'age': age,
      'address': address,
      'date_of_birth': dateOfBirth,
    };
  }
}

class Wallet {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userName;
  final String? userEmail;

  // Computed properties for backward compatibility
  String get walletId => id;
  bool get isActive => true; // Default to active
  String get walletName => userName ?? 'Ví của $userId';

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userEmail,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balance: (json['so_du'] as num?)?.toDouble() ?? 0.0,
      currency: json['loai_tien_te'] as String? ?? 'VND',
      createdAt: DateTime.parse(json['ngay_tao'] as String),
      updatedAt: DateTime.parse(json['ngay_cap_nhat'] as String),
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'so_du': balance,
      'loai_tien_te': currency,
      'ngay_tao': createdAt.toIso8601String(),
      'ngay_cap_nhat': updatedAt.toIso8601String(),
      'user_name': userName,
      'user_email': userEmail,
    };
  }

  Wallet copyWith({
    String? id,
    String? userId,
    double? balance,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userEmail,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

class Transaction {
  final String id;
  final String userId;
  final String walletId;
  final String transactionGroupId;
  final String transactionType;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? counterpartUserId;
  final String? counterpartWalletId;
  final String? counterpartName;
  final String description;
  final String? notes;
  final String status;
  final String? referenceNumber;
  final double feeAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  
  // Admin-only fields (null for user view)
  final String? userName;
  final String? userEmail;
  final String? counterpartFullName;
  final String? counterpartEmail;

  Transaction({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.transactionGroupId,
    required this.transactionType,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.counterpartUserId,
    this.counterpartWalletId,
    this.counterpartName,
    required this.description,
    this.notes,
    required this.status,
    this.referenceNumber,
    required this.feeAmount,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.userName,
    this.userEmail,
    this.counterpartFullName,
    this.counterpartEmail,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      walletId: json['wallet_id'] ?? '',
      transactionGroupId: json['transaction_group_id'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      balanceBefore: (json['balance_before'] ?? 0).toDouble(),
      balanceAfter: (json['balance_after'] ?? 0).toDouble(),
      counterpartUserId: json['counterpart_user_id'],
      counterpartWalletId: json['counterpart_wallet_id'],
      counterpartName: json['counterpart_name'],
      description: json['description'] ?? '',
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      referenceNumber: json['reference_number'],
      feeAmount: (json['fee_amount'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      // Admin-only fields
      userName: json['user_name'],
      userEmail: json['user_email'],
      counterpartFullName: json['counterpart_full_name'],
      counterpartEmail: json['counterpart_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'wallet_id': walletId,
      'transaction_group_id': transactionGroupId,
      'transaction_type': transactionType,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'counterpart_user_id': counterpartUserId,
      'counterpart_wallet_id': counterpartWalletId,
      'counterpart_name': counterpartName,
      'description': description,
      'notes': notes,
      'status': status,
      'reference_number': referenceNumber,
      'fee_amount': feeAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'user_name': userName,
      'user_email': userEmail,
      'counterpart_full_name': counterpartFullName,
      'counterpart_email': counterpartEmail,
    };
  }

  // Helper getters for UI
  bool get isIncoming => ['transfer_in', 'deposit', 'payment_in'].contains(transactionType);
  bool get isOutgoing => ['transfer_out', 'withdraw', 'payment_out'].contains(transactionType);
  
  double get balanceChange => balanceAfter - balanceBefore;
  
  String get transactionLabel {
    switch (transactionType) {
      case 'transfer_in':
        return 'Nhận tiền';
      case 'transfer_out':
        return 'Chuyển tiền';
      case 'deposit':
        return 'Nạp tiền';
      case 'withdraw':
        return 'Rút tiền';
      case 'payment_in':
        return 'Thanh toán nhận';
      case 'payment_out':
        return 'Thanh toán gửi';
      default:
        return 'Giao dịch';
    }
  }
  
  String get amountPrefix {
    return isIncoming ? '+' : '-';
  }
  
  // Display name for counterpart (use full name for admin, regular name for user)
  String get displayCounterpartName {
    if (counterpartFullName != null && counterpartFullName!.isNotEmpty) {
      return counterpartFullName!; // Admin view
    }
    return counterpartName ?? 'Không rõ'; // User view
  }
  
  // Display user name (admin view only)
  String get displayUserName {
    return userName ?? 'Không rõ';
  }

  // Backward compatibility getters
  String get nguoiGuiId => counterpartUserId ?? '';
  String get nguoiNhanId => counterpartUserId ?? '';
  double get soTien => amount;
  String get loai => transactionType;
  String? get ghiChu => notes;
  String get trangThai => status;
  DateTime get ngayTao => createdAt;
  DateTime get ngayCapNhat => updatedAt;

  // Legacy compatibility
  String get senderId => counterpartUserId ?? '';
  String get receiverId => counterpartUserId ?? '';
  String get type => transactionType;
  String? get note => notes;
}

class Contact {
  final String id;
  final String userId;
  final String hoTen;
  final String email;
  final String? soDienThoai;
  final String? hinhAnh;
  final DateTime ngayTao;
  final DateTime ngayCapNhat;

  Contact({
    required this.id,
    required this.userId,
    required this.hoTen,
    required this.email,
    this.soDienThoai,
    this.hinhAnh,
    required this.ngayTao,
    required this.ngayCapNhat,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      userId: json['user_id'],
      hoTen: json['ho_ten'],
      email: json['email'],
      soDienThoai: json['so_dien_thoai'],
      hinhAnh: json['hinh_anh'],
      ngayTao: DateTime.parse(json['ngay_tao']),
      ngayCapNhat: DateTime.parse(json['ngay_cap_nhat']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ho_ten': hoTen,
      'email': email,
      'so_dien_thoai': soDienThoai,
      'hinh_anh': hinhAnh,
      'ngay_tao': ngayTao.toIso8601String(),
      'ngay_cap_nhat': ngayCapNhat.toIso8601String(),
    };
  }

  // Helper getter for backward compatibility
  String get name => hoTen;
  String? get phone => soDienThoai;
  String? get image => hinhAnh;
  DateTime get createdAt => ngayTao;
  DateTime get updatedAt => ngayCapNhat;
}

class UserVerification {
  final String id;
  final String userId;
  final String? phoneNumber;
  final bool phoneVerified;
  final DateTime? phoneVerificationDate;
  final String? idCardNumber;
  final bool idCardVerified;
  final DateTime? idCardVerificationDate;
  final String? address;
  final bool addressVerified;
  final DateTime? addressVerificationDate;
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final String? adminNotes;
  final String? frontIdImageUrl;
  final String? backIdImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserVerification({
    required this.id,
    required this.userId,
    this.phoneNumber,
    required this.phoneVerified,
    this.phoneVerificationDate,
    this.idCardNumber,
    required this.idCardVerified,
    this.idCardVerificationDate,
    this.address,
    required this.addressVerified,
    this.addressVerificationDate,
    required this.verificationStatus,
    this.adminNotes,
    this.frontIdImageUrl,
    this.backIdImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserVerification.fromJson(Map<String, dynamic> json) {
    return UserVerification(
      id: json['id'],
      userId: json['user_id'],
      phoneNumber: json['phone_number'],
      phoneVerified: json['phone_verified'] ?? false,
      phoneVerificationDate: json['phone_verification_date'] != null
          ? DateTime.parse(json['phone_verification_date'])
          : null,
      idCardNumber: json['id_card_number'],
      idCardVerified: json['id_card_verified'] ?? false,
      idCardVerificationDate: json['id_card_verification_date'] != null
          ? DateTime.parse(json['id_card_verification_date'])
          : null,
      address: json['address'],
      addressVerified: json['address_verified'] ?? false,
      addressVerificationDate: json['address_verification_date'] != null
          ? DateTime.parse(json['address_verification_date'])
          : null,
      verificationStatus: json['verification_status'] ?? 'pending',
      adminNotes: json['admin_notes'],
      frontIdImageUrl: json['front_id_image_url'],
      backIdImageUrl: json['back_id_image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'phone_number': phoneNumber,
      'phone_verified': phoneVerified,
      'phone_verification_date': phoneVerificationDate?.toIso8601String(),
      'id_card_number': idCardNumber,
      'id_card_verified': idCardVerified,
      'id_card_verification_date': idCardVerificationDate?.toIso8601String(),
      'address': address,
      'address_verified': addressVerified,
      'address_verification_date': addressVerificationDate?.toIso8601String(),
      'verification_status': verificationStatus,
      'admin_notes': adminNotes,
      'front_id_image_url': frontIdImageUrl,
      'back_id_image_url': backIdImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper getter for backward compatibility
  String? get getPhoneNumber => phoneNumber;
  bool get isPhoneVerified => phoneVerified;
  DateTime? get getPhoneVerificationDate => phoneVerificationDate;
  String? get getIdCardNumber => idCardNumber;
  bool get isIdCardVerified => idCardVerified;
  DateTime? get getIdCardVerificationDate => idCardVerificationDate;
  String? get getAddress => address;
  bool get isAddressVerified => addressVerified;
  DateTime? get getAddressVerificationDate => addressVerificationDate;
  String get getVerificationStatus => verificationStatus;
  String? get getAdminNotes => adminNotes;
  DateTime get getCreatedAt => createdAt;
  DateTime get getUpdatedAt => updatedAt;

  // Helper methods
  bool get isFullyVerified => phoneVerified && idCardVerified && addressVerified;
  bool get isPending => verificationStatus == 'pending';
  bool get isVerified => verificationStatus == 'verified';
  bool get isRejected => verificationStatus == 'rejected';
}

// Model cho Admin User
class AdminUser {
  final String id;
  final String username;
  final String password;
  final String? email;
  final String? fullName;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminUser({
    required this.id,
    required this.username,
    required this.password,
    this.email,
    this.fullName,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      email: json['email'],
      fullName: json['full_name'],
      isActive: json['is_active'] ?? true,
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'full_name': fullName,
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  String get name => fullName ?? username;
  bool get isLoggedIn => lastLogin != null;
  DateTime get created => createdAt;
  DateTime get updated => updatedAt;
}
