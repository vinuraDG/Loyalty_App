import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loyalty_app/data/companies_api_service.dart';
import 'package:loyalty_app/data/customer_ledger_service.dart';

/// Global refresh key — increment to signal all pages to re-fetch.
final appRefreshKeyProvider = StateProvider<int>((ref) => 0);

/// Call from any page's onRefresh to clear all caches and notify all pages.
Future<void> appRefresh(WidgetRef ref) async {
  CompaniesApiService.instance.clearCache();
  CustomerLedgerService.instance.clearCache();
  ref.read(appRefreshKeyProvider.notifier).state++;
}
