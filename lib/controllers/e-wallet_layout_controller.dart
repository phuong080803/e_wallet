import '../pages/screens/profile/screens/profile_screen.dart';
import 'package:e_wallet/pages/screens/home/screens/home_screen.dart';
import 'package:e_wallet/pages/screens/wallet/transaction_history_screen.dart';
import 'package:e_wallet/pages/screens/qr/my_qr_screen.dart';
import 'package:e_wallet/styles/Iconly-Broken_icons.dart';
import 'package:flutter/material.dart';

class _BoardingItem {
  final String label;
  final Icon icon;
  final Widget screen;

  _BoardingItem({
    required this.label,
    required this.icon,
    required this.screen,
  });
}

class E_WalletLayoutController {
  static int currentIndex = 0;
  static List<_BoardingItem> item = [
    _BoardingItem(label: "Trang chủ", icon: Icon(Iconly_Broken.Home), screen: HomeScreen()),
    _BoardingItem(
        label: "Giao dịch", icon: Icon(Iconly_Broken.Wallet), screen: TransactionHistoryScreen()),
    _BoardingItem(label: "Mã QR", icon: Icon(Icons.qr_code_2), screen: MyQrScreen()),
    _BoardingItem(label: "Hồ sơ", icon: Icon(Iconly_Broken.User), screen: ProfileScreen()),
  ];

  static void changeIndex(int newIndex) {
    currentIndex = newIndex;
  }
}
