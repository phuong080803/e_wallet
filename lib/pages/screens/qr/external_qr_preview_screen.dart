import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalQrData {
  final String type; // vietqr | emv | momo | zalopay | bank_url | unknown
  final String? bankCode;
  final String? accountNumber;
  final String? accountName;
  final double? amount;
  final String? raw;
  final Uri? sourceUrl;

  ExternalQrData({
    required this.type,
    this.bankCode,
    this.accountNumber,
    this.accountName,
    this.amount,
    this.raw,
    this.sourceUrl,
  });
}

class ExternalQrPreviewScreen extends StatelessWidget {
  final ExternalQrData data;
  const ExternalQrPreviewScreen({Key? key, required this.data}) : super(key: key);

  String _fmtAmount(double? v) {
    if (v == null) return '-';
    return NumberFormat.currency(locale: 'vi_VN', symbol: '', decimalDigits: 0).format(v) + ' VND';
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR bên ngoài'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tile('Loại', _typeLabel(data.type)),
            const SizedBox(height: 8),
            if (data.bankCode != null) _tile('Ngân hàng', data.bankCode!),
            if (data.accountNumber != null) _tile('Số tài khoản/ID', data.accountNumber!),
            if (data.accountName != null) _tile('Tên', data.accountName!),
            _tile('Số tiền', _fmtAmount(data.amount)),
            if (data.sourceUrl != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final url = data.sourceUrl!;
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    Get.snackbar('Không thể mở liên kết', url.toString());
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Mở bằng ứng dụng ngoài'),
              ),
            ],
            const Spacer(),
            Text(
              'Lưu ý: Đây là QR từ ứng dụng/bank khác. Bạn có thể dùng thông tin trên để chuyển tiền thủ công.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            )
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Get.snackbar('Đã sao chép', value, snackPosition: SnackPosition.BOTTOM);
            },
          )
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'vietqr':
        return 'VietQR (Ngân hàng)';
      case 'emv':
        return 'EMV QR (chuẩn)';
      case 'momo':
        return 'Ví MoMo';
      case 'zalopay':
        return 'Ví ZaloPay';
      case 'bank_url':
        return 'Liên kết ngân hàng';
      default:
        return 'Không xác định';
    }
  }
}
