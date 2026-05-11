class AppConstants {
  static const appName     = 'LoyaltyHub';
  static const mockOtp     = '1234';

  // SharedPreferences keys
  static const prefUserId     = 'userId';
  static const prefUserRole   = 'userRole';
  static const prefIsLoggedIn = 'isLoggedIn';

  // Business names
  static const businessFuel    = 'Fuel Station';
  static const businessLaundry = 'Laundry';
  static const businessGolf    = 'Golf';

  // Points per visit (mock)
  static const fuelPoints    = 120;
  static const laundryPoints = 80;
  static const golfPoints    = 200;
}

class AppRoutes {
  static const splash    = '/';
  static const login     = '/login';
  static const signup    = '/signup';
  static const otp       = '/otp';
  static const home      = '/home';
  static const points    = '/points';
  static const redeem    = '/redeem';
  static const qrCode    = '/qr-code';
  static const profile   = '/profile';
  static const empLogin  = '/employee-login';
  static const empDash   = '/employee-dashboard';
}
