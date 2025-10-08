import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../wallet/transfer_money_screen.dart';
import 'external_qr_preview_screen.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;
  String? _lastValue;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndScan() async {
    try {
      if (kIsWeb) {
        Get.snackbar('Không hỗ trợ', 'Quét QR từ ảnh chưa hỗ trợ trên Web');
        return;
      }
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final dynamic result = await _controller.analyzeImage(image.path);
      if (result is List<Barcode> && result.isNotEmpty) {
        _handleScanResult(result.first.rawValue ?? '');
        return;
      }
      if (result is BarcodeCapture && result.barcodes.isNotEmpty) {
        _handleScanResult(result.barcodes.first.rawValue ?? '');
        return;
      }
      if (result is Barcode && (result.rawValue ?? '').isNotEmpty) {
        _handleScanResult(result.rawValue!);
        return;
      }
      if (result is bool && result == true) {
        // Some platforms may only return success without payload
        Get.snackbar('Đã quét', 'Ảnh chứa mã QR');
        return;
      }
      Get.snackbar('Không tìm thấy QR', 'Vui lòng chọn ảnh khác');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể quét từ ảnh: $e');
    }
  }

  void _handleScanResult(String value) {
    if (_hasScanned && value == _lastValue) return;
    setState(() {
      _hasScanned = true;
      _lastValue = value;
    });

    // Try parse wallet QR JSON (in-app)
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map && decoded['type'] == 'wallet') {
        final walletId = (decoded['wallet_id'] ?? '').toString();
        final email = (decoded['email'] ?? '').toString();
        if (walletId.isNotEmpty) {
          Get.off(() => TransferMoneyScreen(initialWalletId: walletId, initialEmail: email));
          return;
        }
      }
    } catch (_) {}

    // Try parse external QR formats
    final external = _tryParseExternalQr(value);
    if (external != null) {
      // Route directly to TransferMoneyScreen in external mode
      Get.off(() => TransferMoneyScreen(
            isExternalRecipient: true,
            externalBankCode: external.type == 'momo'
                ? 'MoMo'
                : external.type == 'zalopay'
                    ? 'ZaloPay'
                    : external.bankCode,
            externalAccountNumber: external.accountNumber,
            externalAccountName: external.accountName,
            initialAmount: external.amount,
          ));
      return;
    }

    // Fallback: show raw value
    Get.snackbar('Đã quét QR', value, duration: const Duration(seconds: 3), snackPosition: SnackPosition.BOTTOM);
  }

  ExternalQrData? _tryParseExternalQr(String raw) {
    // Case 1: EMV/VietQR payload starts with digits and tag '00'
    if (RegExp(r'^\d{4,}').hasMatch(raw)) {
      final emv = _parseEmvCo(raw);
      if (emv != null) return emv;
    }

    // Case 2: URL-based QR (momo/zalopay/bank links)
    Uri? uri;
    try { uri = Uri.parse(raw); } catch (_) {}
    if (uri != null && (uri.scheme.startsWith('http') || raw.contains('://'))) {
      final host = uri.host.toLowerCase();
      // MoMo
      if (host.contains('momo') || raw.startsWith('momo://')) {
        final amount = double.tryParse(uri.queryParameters['amount'] ?? uri.queryParameters['a'] ?? '');
        return ExternalQrData(type: 'momo', amount: amount, raw: raw, sourceUrl: uri);
      }
      // ZaloPay
      if (host.contains('zalopay') || raw.startsWith('zalopay://')) {
        final amount = double.tryParse(uri.queryParameters['amount'] ?? uri.queryParameters['amt'] ?? '');
        return ExternalQrData(type: 'zalopay', amount: amount, raw: raw, sourceUrl: uri);
      }
      // VietQR hosted images/links
      if (host.contains('vietqr') || host.contains('img.vietqr.io')) {
        return ExternalQrData(type: 'vietqr', raw: raw, sourceUrl: uri);
      }
      // Generic bank url
      if (host.contains('napas') || host.contains('vnpay') || host.contains('bank')) {
        return ExternalQrData(type: 'bank_url', raw: raw, sourceUrl: uri);
      }
    }

    return null;
  }

  // Minimal EMVCo parser with VietQR extensions (ID 38)
  ExternalQrData? _parseEmvCo(String payload) {
    int idx = 0;
    String? getTagValue(String tag) {
      // iterate TLV
      int i = 0;
      while (i + 4 <= payload.length) {
        final t = payload.substring(i, i + 2);
        final l = int.tryParse(payload.substring(i + 2, i + 4));
        if (l == null || i + 4 + l > payload.length) return null;
        final v = payload.substring(i + 4, i + 4 + l);
        if (t == tag) return v;
        i = i + 4 + l;
      }
      return null;
    }

    // Amount (54), Merchant Name (59), City (60) not critical; focus VietQR bank info under 38
    final addl = getTagValue('62'); // Additional data field template
    final amountStr = getTagValue('54');
    final amount = amountStr != null ? double.tryParse(amountStr) : null;

    String? bankCode;
    String? accountNumber;
    String? accountName;

    String? id38 = getTagValue('38');
    if (id38 != null) {
      // parse sub-tags
      int j = 0;
      while (j + 4 <= id38.length) {
        final st = id38.substring(j, j + 2);
        final sl = int.tryParse(id38.substring(j + 2, j + 4));
        if (sl == null || j + 4 + sl > id38.length) break;
        final sv = id38.substring(j + 4, j + 4 + sl);
        // VietQR convention: 00=AID, 01=Bank Code, 02=Account Number, 03=Account Name
        if (st == '01') bankCode = sv;
        if (st == '02') accountNumber = sv;
        if (st == '03') accountName = sv;
        j = j + 4 + sl;
      }
    }

    // If we have bank/account -> treat as VietQR
    if (bankCode != null || accountNumber != null) {
      return ExternalQrData(
        type: 'vietqr',
        bankCode: bankCode,
        accountNumber: accountNumber,
        accountName: accountName,
        amount: amount,
        raw: payload,
      );
    }

    // Otherwise still an EMV, show generic
    // If nothing meaningful parsed, return null
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.image_outlined),
            tooltip: 'Chọn ảnh để quét',
            onPressed: _pickImageAndScan,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_outlined),
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on_outlined),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final String value = barcodes.first.rawValue ?? '';
                      if (value.isNotEmpty) {
                        _handleScanResult(value);
                      }
                    }
                  },
                ),
                if (_hasScanned && _lastValue != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      color: Colors.black54,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kết quả:',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _lastValue!,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => setState(() => _hasScanned = false),
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Quét lại'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Get.back(result: _lastValue);
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Dùng kết quả'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Hướng camera vào mã QR hoặc chọn ảnh từ thư viện',
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}
