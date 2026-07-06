class AppConstants {
  static const appName = 'LoyaltyHub';
  static const mockOtp = '1234';

  static const prefUserId     = 'userId';
  static const prefUserRole   = 'userRole';
  static const prefIsLoggedIn = 'isLoggedIn';
  static const prefAuthToken    = 'authToken';
  static const prefUserPhone    = 'userPhone';
  static const prefUserEmail    = 'userEmail';
  static const prefUserPassword = 'userPassword';

  static const businessFuel    = 'Fuel Station';
  static const businessLaundry = 'Laundry';
  static const businessGold    = 'Gold';

  static const fuelPoints    = 120;
  static const laundryPoints = 80;
  static const goldPoints    = 200;

  static const baseUrl              = 'http://124.43.27.57:8080/';
  static const transactionCompanyId = 3; // Fuel (City Oil) — anchor for company-ID mapping

  // Runtime-resolved company ID. Set at employee login from the backend's
  // TransactionCompanyId field; falls back to transactionCompanyId (=3) when
  // the backend returns 0 (current state). Replace all hardcoded "3" usages
  // in service calls with AppConstants.activeCompanyId so a future backend
  // fix automatically propagates without touching 11 files.
  static int _activeCompanyId = transactionCompanyId;
  static int get activeCompanyId => _activeCompanyId;
  static void setActiveCompanyId(int id) {
    if (id > 0) _activeCompanyId = id;
  }

  static const prefCompanyId = 'companyId';

  // ── Flip this ONE line to switch the entire app ───────────────────────────
  static const bool useMockServices = false; // false = real backend

  // ── Set true while backend auth is not yet implemented ──────────────────
  // Set false once auth (Login) endpoint is working on the backend.
  static const bool devBypass = false;

  // Test data used when devBypass = true
  static const String devCustomerPhone = '0772274383';
  static const String devEmployeePhone = '0770064383';
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