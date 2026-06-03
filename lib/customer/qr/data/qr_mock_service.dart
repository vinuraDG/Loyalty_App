

import 'dart:convert';
import 'package:loyalty_app/customer/qr/data/qr_api_service.dart';

class QrMockService implements IQrService {
  QrMockService._();
  static final QrMockService instance = QrMockService._();

  @override
  Future<String> getQrPayload(String userId, String userName) async {
    // No network call in mock mode — build the payload locally.
    // The real backend will sign this so it cannot be faked.
    return jsonEncode({
      'userId': userId,
      'name': userName,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }
}