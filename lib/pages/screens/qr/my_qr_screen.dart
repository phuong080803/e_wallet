import 'dart:convert';
import 'package:e_wallet/controllers/wallet_controller.dart';
import 'package:e_wallet/styles/constrant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyQrScreen extends StatelessWidget {
  MyQrScreen({Key? key}) : super(key: key);

  final _walletController = Get.put(WalletController());

  Map<String, dynamic> _buildQrPayload() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final email = currentUser?.email ?? '';
    final walletId = _walletController.userWallet.value?.walletId ?? '';
    return {
      'type': 'wallet',
      'wallet_id': walletId,
      'email': email,
      'app': 'e_wallet',
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã QR của tôi'),
        backgroundColor: k_blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        final hasWallet = _walletController.hasWallet.value;
        final wallet = _walletController.userWallet.value;
        final currentUser = Supabase.instance.client.auth.currentUser;
        final email = currentUser?.email ?? '';

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasWallet || wallet == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Text('Bạn chưa có ví. Vui lòng tạo ví để dùng mã QR.'),
                  )
                else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: QrImageView(
                      data: jsonEncode(_buildQrPayload()),
                      version: QrVersions.auto,
                      size: 240.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ID ví: ${wallet.walletId}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email.isNotEmpty ? email : 'Không có email',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Người khác có thể quét mã này để chuyển tiền cho bạn.\nChỉ chia sẻ với người tin cậy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}
