import 'dart:convert';
import 'package:loyalty_app/customer/qr/data/qr_api_service.dart';

class QrMockService implements IQrService {
  QrMockService._();
  static final QrMockService instance = QrMockService._();

  @override
  Future<String> getQrPayload(String userId, String userName) async {
    return jsonEncode({
      'userId': userId,
      'name': userName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }
}