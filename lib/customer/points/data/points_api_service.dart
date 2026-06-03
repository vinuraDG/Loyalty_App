
import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/models/transaction_model.dart';

abstract class IPointsService {
  /// All transactions for a user, newest first.
  Future<List<TransactionModel>> getTransactions(String userId);

  /// Transactions filtered by business name.
  Future<List<TransactionModel>> getTransactionsByBusiness(
      String userId, String business);

  /// Award points to a user after a purchase.
  Future<void> awardPoints(String userId, String business, int points);
}

class PointsApiService implements IPointsService {
  PointsApiService._();
  static final PointsApiService instance = PointsApiService._();

  @override
  Future<List<TransactionModel>> getTransactions(String userId) async {
    // TODO: GET $kBaseUrl/users/$userId/transactions
    // expect → List of TransactionModel JSON, sorted by date desc
    throw UnimplementedError('Backend not connected yet: GET $kBaseUrl/users/$userId/transactions');
  }

  @override
  Future<List<TransactionModel>> getTransactionsByBusiness(
      String userId, String business) async {
    // TODO: GET $kBaseUrl/users/$userId/transactions?business=$business
    throw UnimplementedError('Backend not connected yet.');
  }

  @override
  Future<void> awardPoints(String userId, String business, int points) async {
    // TODO: POST $kBaseUrl/users/$userId/transactions
    // body   → { "business": business, "points": points, "type": "earned" }
    // expect → 201 Created
    throw UnimplementedError('Backend not connected yet: POST $kBaseUrl/users/$userId/transactions');
  }
}