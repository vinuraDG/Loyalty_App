

import 'package:loyalty_app/data/mock_data.dart';
import 'package:loyalty_app/customer/home/data/home_api_service.dart';

class HomeMockService implements IHomeService {
  HomeMockService._();
  static final HomeMockService instance = HomeMockService._();

  @override
  Future<List<AdItem>> getAds() async {
    await _delay(ms: 400);
    // Converts raw maps from mock_data.dart → AdItem objects
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
    // Falls back to an empty week if userId has no entry
    return kMockWeeklyPoints[userId] ?? [0, 0, 0, 0, 0, 0, 0];
  }

  Future<void> _delay({int ms = 300}) =>
      Future.delayed(Duration(milliseconds: ms));
}