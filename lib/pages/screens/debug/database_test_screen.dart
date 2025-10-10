import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseTestScreen extends StatefulWidget {
  @override
  _DatabaseTestScreenState createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  String _testResult = 'Chưa test';

  Future<void> testRPC() async {
    setState(() {
      _testResult = 'Đang test...';
    });

    try {
      // Test RPC function exists
      final result = await Supabase.instance.client.rpc('perform_transfer', params: {
        'p_sender_wallet_id': '1234567890',
        'p_recipient_wallet_id': '0987654321',
        'p_amount': 1000.0,
        'p_notes': 'Test transfer',
      });

      setState(() {
        _testResult = '✅ RPC thành công: $result';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Lỗi RPC: $e';
      });
    }
  }

  Future<void> testWalletsTable() async {
    setState(() {
      _testResult = 'Đang kiểm tra bảng wallets...';
    });

    try {
      final response = await Supabase.instance.client
          .from('wallets')
          .select('id, user_id, so_du')
          .limit(5);

      setState(() {
        _testResult = '✅ Bảng wallets: ${response.length} bản ghi';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Lỗi bảng wallets: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Database')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_testResult),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: testWalletsTable,
              child: Text('Test Wallets Table'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: testRPC,
              child: Text('Test RPC Function'),
            ),
          ],
        ),
      ),
    );
  }
}
