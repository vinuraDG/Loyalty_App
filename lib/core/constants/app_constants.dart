class AppConstants {
  static const appName = 'LoyaltyHub';
  static const mockOtp = '1234';

  static const prefUserId     = 'userId';
  static const prefUserRole   = 'userRole';
  static const prefIsLoggedIn = 'isLoggedIn';
  static const prefAuthToken  = 'authToken';
  static const prefUserPhone  = 'userPhone';

  static const businessFuel    = 'Fuel Station';
  static const businessLaundry = 'Laundry';
  static const businessGold    = 'Gold';

  static const fuelPoints    = 120;
  static const laundryPoints = 80;
  static const goldPoints    = 200;

  static const baseUrl              = 'http://124.43.27.57:8080/';
  static const transactionCompanyId = 1;

  // ── Flip this ONE line to switch the entire app ───────────────────────────
  static const bool useMockServices = true;
}

class AppRoutes {
  static const splash   = '/';
  static const login    = '/login';
  static const signup   = '/signup';
  static const otp      = '/otp';
  static const home     = '/home';
  static const points   = '/points';
  static const redeem   = '/redeem';
  static const qrCode   = '/qr-code';
  static const profile  = '/profile';
  static const empLogin = '/employee-login';
  static const empDash  = '/employee-dashboard';
}