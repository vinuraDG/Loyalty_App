

import 'package:loyalty_app/data/mock_data.dart';

abstract class IQrService {
  /// Returns the QR payload string to encode for a given user.
  /// The real backend may sign this token for security.
  Future<String> getQrPayload(String userId, String userName);
}

class QrApiService implements IQrService {
  QrApiService._();
  static final QrApiService instance = QrApiService._();

  @override
  Future<String> getQrPayload(String userId, String userName) async {
    // TODO: GET $kBaseUrl/users/$userId/qr-token
    // expect → { "token": "signed-jwt-or-payload-string" }
    // The backend signs the payload so employees can verify it is genuine.
    throw UnimplementedError('Backend not connected yet: GET $kBaseUrl/users/$userId/qr-token');
  }
}