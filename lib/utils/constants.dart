// Transaction types
class TransactionType {
  static const String transfer = 'transfer';
  static const String request = 'request';
  static const String payment = 'payment';
}

// Transaction status
class TransactionStatus {
  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';
}

// Currency
class Currency {
  static const String usd = 'USD';
  static const String vnd = 'VND';
  static const String eur = 'EUR';
}

// Error messages
class ErrorMessages {
  static const String insufficientBalance = 'Insufficient balance';
  static const String userNotFound = 'User not found';
  static const String invalidAmount = 'Invalid amount';
  static const String networkError = 'Network error';
  static const String unknownError = 'Unknown error occurred';
}

// Success messages
class SuccessMessages {
  static const String moneySent = 'Money sent successfully';
  static const String requestSent = 'Money request sent';
  static const String profileUpdated = 'Profile updated successfully';
  static const String contactAdded = 'Contact added successfully';
  static const String contactDeleted = 'Contact deleted successfully';
}

