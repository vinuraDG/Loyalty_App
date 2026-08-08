import 'dart:async';

import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/customer/home/data/home_api_service.dart';

class HomeMockService implements IHomeService {
  HomeMockService._();
  static final HomeMockService instance = HomeMockService._();

  @override
  Future<List<AdItem>> getAds() async {
    await _delay(ms: 400);
    return kMockAds
        .map((m) => AdItem(
              id: m['id'] as String,
              tag: m['tag'] as String,
              title: m['title'] as String,
              subtitle: m['subtitle'] as String,
              gradientStart: m['gradientStart'] as int,
              gradientEnd: m['gradientEnd'] as int,
              tagColor: m['tagColor'] as int,
            ))
        .toList();
  }

  @override
  Future<List<int>> getWeeklyPoints(String userId) async {
    await _delay(ms: 200);
    return kMockWeeklyPoints[userId] ?? [0, 0, 0, 0, 0, 0, 0];
  }

  @override
  Future<int> getTotalPoints(String userId) async {
    await _delay(ms: 200);
    // Sum weekly points as a rough mock balance, or use a fixed value
    final weekly = kMockWeeklyPoints[userId] ?? [0, 0, 0, 0, 0, 0, 0];
    return weekly.fold(0, (sum, pts) => sum + pts);
  }

  @override
  Future<int> getPointsExpire(String userId) async => 0;

  Future<void> _delay({int ms = 300}) =>
      Future.delayed(Duration(milliseconds: ms));
}

extension on FutureOr<int> {
  FutureOr<int> operator +(int other) => this;
}