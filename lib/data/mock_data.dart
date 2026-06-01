/// Flip this to false when the real backend is connected.
const bool kUseMockData = true;

/// The base URL for the real backend.
/// Replace this with the URL the backend developer gives you.
/// Example: 'https://api.yourdomain.com/v1'
const String kBaseUrl = 'https://api.example.com/v1';

// ─────────────────────────────────────────────────────────────────────────────
// Users
// ─────────────────────────────────────────────────────────────────────────────

/// All mock user accounts.
const List<Map<String, dynamic>> kMockUsers = [
  {
    'id': 'cust-001',
    'firstName': 'Kasun',
    'lastName': 'Perera',
    'email': 'customer@gmail.com',
    'phone': '0771234567',
    'role': 'customer',
    'address': '42 Galle Road, Colombo 03',
    'points': 4820,
  },
  {
    'id': 'emp-001',
    'firstName': 'Nimal',
    'lastName': 'Silva',
    'email': 'employee@gmail.com',
    'phone': '0779876543',
    'role': 'employee',
    'address': '',
    'points': 0,
  },
];

/// Mock passwords keyed by user id.
/// In a real app passwords are never stored like this — this is only for the
/// mock/demo flow. The backend will handle authentication properly.
const Map<String, String> kMockPasswords = {
  'cust-001': 'password123',
  'emp-001':  'employee123',
};

// ─────────────────────────────────────────────────────────────────────────────
// OTP
// ─────────────────────────────────────────────────────────────────────────────

/// The mock OTP used in development/demo mode.
/// The real backend will send an actual SMS.
const String kMockOtp = '1234';

// ─────────────────────────────────────────────────────────────────────────────
// Transactions
// ─────────────────────────────────────────────────────────────────────────────

/// Mock transaction records keyed by userId.
/// Fields mirror what the real API will return:
///   id, userId, business, points, isEarned, daysAgo (int, relative to now)
///
/// Using daysAgo instead of ISO strings so dates stay accurate at runtime.
const List<Map<String, dynamic>> kMockTransactions = [
  {
    'id': 't1',
    'userId': 'cust-001',
    'business': 'Fuel Station',
    'points': 120,
    'isEarned': true,
    'hoursAgo': 3,
  },
  {
    'id': 't2',
    'userId': 'cust-001',
    'business': 'Laundry',
    'points': 200,
    'isEarned': false,
    'daysAgo': 1,
  },
  {
    'id': 't3',
    'userId': 'cust-001',
    'business': 'Gold Shop',
    'points': 200,
    'isEarned': true,
    'daysAgo': 3,
  },
  {
    'id': 't4',
    'userId': 'cust-001',
    'business': 'Fuel Station',
    'points': 120,
    'isEarned': true,
    'daysAgo': 5,
  },
  {
    'id': 't5',
    'userId': 'cust-001',
    'business': 'Laundry',
    'points': 80,
    'isEarned': true,
    'daysAgo': 7,
  },
  {
    'id': 't6',
    'userId': 'cust-001',
    'business': 'Gold Shop',
    'points': 200,
    'isEarned': true,
    'daysAgo': 10,
  },
  {
    'id': 't7',
    'userId': 'cust-001',
    'business': 'Fuel Station',
    'points': 120,
    'isEarned': true,
    'daysAgo': 12,
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// Weekly Points (Home Screen Chart)
// ─────────────────────────────────────────────────────────────────────────────

/// Mock weekly points per user, index 0 = Monday … index 6 = Sunday.
/// The real backend will compute these from the transaction history.
const Map<String, List<int>> kMockWeeklyPoints = {
  'cust-001': [80, 210, 150, 60, 320, 200, 120],
  'emp-001':  [0, 0, 0, 0, 0, 0, 0],
};

// ─────────────────────────────────────────────────────────────────────────────
// Advertisement Banners (Home Screen)
// ─────────────────────────────────────────────────────────────────────────────

/// Mock promotional banners shown on the home screen carousel.
/// The real backend will return these as a list from a CMS or promotions API.
const List<Map<String, dynamic>> kMockAds = [
  {
    'id': 'ad_001',
    'tag': '2× Points',
    'title': 'Double points this weekend',
    'subtitle': 'At all fuel stations',
    'gradientStart': 0xFF2D1B69,
    'gradientEnd': 0xFF7C3AED,
    'tagColor': 0xFFE9D5FF,
  },
  {
    'id': 'ad_002',
    'tag': 'New',
    'title': 'Earn at Gold Shops now',
    'subtitle': '+200 pts on every visit',
    'gradientStart': 0xFF064E3B,
    'gradientEnd': 0xFF059669,
    'tagColor': 0xFFA7F3D0,
  },
  {
    'id': 'ad_003',
    'tag': 'Limited',
    'title': 'Laundry free wash promo',
    'subtitle': 'Redeem 150 pts today',
    'gradientStart': 0xFF7C2D12,
    'gradientEnd': 0xFFEA580C,
    'tagColor': 0xFFFED7AA,
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// Offers / Rewards
// ─────────────────────────────────────────────────────────────────────────────

/// Mock redeemable offers shown on the rewards screen.
/// The real backend will serve these from a promotions API.
const List<Map<String, dynamic>> kMockOffers = [
  {
    'id': 'o1',
    'title': 'Free wash service',
    'description': 'Any 1 load of laundry, any size',
    'business': 'Laundry',
    'pointsCost': 200,
  },
  {
    'id': 'o2',
    'title': '10% fuel discount',
    'description': 'Per fill-up, any fuel type',
    'business': 'Fuel Station',
    'pointsCost': 150,
  },
  {
    'id': 'o3',
    'title': 'Free gold jewellery polish',
    'description': 'Professional polish for any gold item',
    'business': 'Gold Shop',
    'pointsCost': 500,
  },
  {
    'id': 'o4',
    'title': 'Premium wash + iron',
    'description': 'Full laundry + ironing service',
    'business': 'Laundry',
    'pointsCost': 350,
  },
  {
    'id': 'o5',
    'title': 'Gold valuation service',
    'description': 'Free gold item valuation',
    'business': 'Gold Shop',
    'pointsCost': 300,
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// Business Configuration
// ─────────────────────────────────────────────────────────────────────────────

/// Points earned per visit at each business type.
/// When the backend is ready these values will come from a config API endpoint.
const Map<String, int> kBusinessPoints = {
  'Fuel Station': 120,
  'Laundry': 80,
  'Gold Shop': 200,
};

/// Business display names (single source — used in transactions and UI).
const String kBusinessFuel    = 'Fuel Station';
const String kBusinessLaundry = 'Laundry';
const String kBusinessGold    = 'Gold Shop';