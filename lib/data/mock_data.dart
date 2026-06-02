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
  'emp-001': 'employee123',
};

// ─────────────────────────────────────────────────────────────────────────────
// OTP
// ─────────────────────────────────────────────────────────────────────────────

/// The mock OTP used in development/demo mode.
/// The real backend will send an actual SMS.
const String kMockOtp = '1234';

// ─────────────────────────────────────────────────────────────────────────────
// Transactions (Customer)
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
  'emp-001': [0, 0, 0, 0, 0, 0, 0],
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
const String kBusinessFuel = 'Fuel Station';
const String kBusinessLaundry = 'Laundry';
const String kBusinessGold = 'Gold Shop';

// ─────────────────────────────────────────────────────────────────────────────
// Employee — Scanned Member
// ─────────────────────────────────────────────────────────────────────────────

/// The member returned when an employee scans a customer QR code.
/// Fields: name, memberId, tier, currentPoints.
/// The real backend returns this from GET /members/{userId}.
const Map<String, dynamic> kMockScannedMember = {
  'name': 'Amal Perera',
  'memberId': 'AP2024X1',
  'tier': 'Gold',
  'currentPoints': 3420,
};

// ─────────────────────────────────────────────────────────────────────────────
// Employee — Today's Scans (seed data)
// ─────────────────────────────────────────────────────────────────────────────

/// Seed scan entries shown in the employee home on first load.
/// Fields: memberName (String), saleAmount (double), points (int), time (String).
/// The real backend returns these from GET /employees/{id}/scans/today.
const List<Map<String, dynamic>> kMockTodayScans = [
  {
    'memberName': 'Nimal Silva',
    'saleAmount': 3565.0,
    'points': 180,
    'time': '10:15 AM',
  },
  {
    'memberName': 'Kamani Fernando',
    'saleAmount': 10350.0,
    'points': 320,
    'time': '9:58 AM',
  },
  {
    'memberName': 'Ruwan Jayawardena',
    'saleAmount': 4600.0,
    'points': 150,
    'time': '9:40 AM',
  },
  {
    'memberName': 'Dilini Ratnayake',
    'saleAmount': 13800.0,
    'points': 400,
    'time': '9:22 AM',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// Employee — Weekly Commission Chart
// ─────────────────────────────────────────────────────────────────────────────

/// Weekly commission amounts per employee in LKR cents (÷100 = LKR).
/// Index 0 = Monday … index 6 = Sunday.
/// The real backend returns this from GET /employees/{id}/commission/weekly.
const Map<String, List<int>> kMockEmployeeWeeklyCommission = {
  'emp-001': [1240, 3800, 2650, 4200, 5100, 3200, 800],
};

// ─────────────────────────────────────────────────────────────────────────────
// Employee — Commission Sales History
// ─────────────────────────────────────────────────────────────────────────────

/// Commission rate applied to every fuel sale.
/// The real backend will return this from a config endpoint.
const double kCommissionRate = 0.02; // 2 %

/// All fuel sale records used in the commission page.
/// Fields: id, employeeId, customerName, litres, saleAmount, time, date, month.
/// The real backend returns these from GET /employees/{id}/sales?month={month}.
const List<Map<String, dynamic>> kMockCommissionSales = [
  // ── May 2026 ──────────────────────────────────────────────────────────────
  {
    'id': 'sale-001',
    'employeeId': 'emp-001',
    'customerName': 'Amal Perera',
    'litres': 30.0,
    'saleAmount': 6900.0,
    'time': '10:32 AM',
    'date': '20 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-002',
    'employeeId': 'emp-001',
    'customerName': 'Nimal Silva',
    'litres': 15.5,
    'saleAmount': 3565.0,
    'time': '10:15 AM',
    'date': '20 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-003',
    'employeeId': 'emp-001',
    'customerName': 'Kamani Fernando',
    'litres': 45.0,
    'saleAmount': 10350.0,
    'time': '9:58 AM',
    'date': '20 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-004',
    'employeeId': 'emp-001',
    'customerName': 'Ruwan Jayawardena',
    'litres': 20.0,
    'saleAmount': 4600.0,
    'time': '9:40 AM',
    'date': '19 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-005',
    'employeeId': 'emp-001',
    'customerName': 'Dilini Ratnayake',
    'litres': 60.0,
    'saleAmount': 13800.0,
    'time': '9:22 AM',
    'date': '19 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-006',
    'employeeId': 'emp-001',
    'customerName': 'Suresh Bandara',
    'litres': 10.0,
    'saleAmount': 2300.0,
    'time': '3:10 PM',
    'date': '18 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-007',
    'employeeId': 'emp-001',
    'customerName': 'Priya Wijesinghe',
    'litres': 25.0,
    'saleAmount': 5750.0,
    'time': '1:45 PM',
    'date': '17 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-008',
    'employeeId': 'emp-001',
    'customerName': 'Kasun Madushanka',
    'litres': 40.0,
    'saleAmount': 9200.0,
    'time': '11:20 AM',
    'date': '16 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-009',
    'employeeId': 'emp-001',
    'customerName': 'Thilini Kumari',
    'litres': 18.0,
    'saleAmount': 4140.0,
    'time': '10:05 AM',
    'date': '15 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-010',
    'employeeId': 'emp-001',
    'customerName': 'Roshan Gunawardena',
    'litres': 35.0,
    'saleAmount': 8050.0,
    'time': '9:00 AM',
    'date': '14 May',
    'month': 'May 2026',
  },
  // ── April 2026 ────────────────────────────────────────────────────────────
  {
    'id': 'sale-011',
    'employeeId': 'emp-001',
    'customerName': 'Amal Perera',
    'litres': 28.0,
    'saleAmount': 6440.0,
    'time': '2:30 PM',
    'date': '30 Apr',
    'month': 'April 2026',
  },
  {
    'id': 'sale-012',
    'employeeId': 'emp-001',
    'customerName': 'Chamara Dissanayake',
    'litres': 50.0,
    'saleAmount': 11500.0,
    'time': '11:00 AM',
    'date': '28 Apr',
    'month': 'April 2026',
  },
  {
    'id': 'sale-013',
    'employeeId': 'emp-001',
    'customerName': 'Sanduni Wickrama',
    'litres': 22.0,
    'saleAmount': 5060.0,
    'time': '9:15 AM',
    'date': '25 Apr',
    'month': 'April 2026',
  },
  {
    'id': 'sale-014',
    'employeeId': 'emp-001',
    'customerName': 'Lakmal Jayasena',
    'litres': 38.0,
    'saleAmount': 8740.0,
    'time': '4:00 PM',
    'date': '22 Apr',
    'month': 'April 2026',
  },
  {
    'id': 'sale-015',
    'employeeId': 'emp-001',
    'customerName': 'Nimal Silva',
    'litres': 12.0,
    'saleAmount': 2760.0,
    'time': '10:45 AM',
    'date': '20 Apr',
    'month': 'April 2026',
  },
  {
    'id': 'sale-016',
    'employeeId': 'emp-001',
    'customerName': 'Ishara Mendis',
    'litres': 55.0,
    'saleAmount': 12650.0,
    'time': '3:20 PM',
    'date': '15 Apr',
    'month': 'April 2026',
  },
  {
    'id': 'sale-017',
    'employeeId': 'emp-001',
    'customerName': 'Priya Wijesinghe',
    'litres': 20.0,
    'saleAmount': 4600.0,
    'time': '8:50 AM',
    'date': '10 Apr',
    'month': 'April 2026',
  },
  {
    'id': 'sale-018',
    'employeeId': 'emp-001',
    'customerName': 'Dilini Ratnayake',
    'litres': 33.0,
    'saleAmount': 7590.0,
    'time': '1:10 PM',
    'date': '5 Apr',
    'month': 'April 2026',
  },
  // ── March 2026 ────────────────────────────────────────────────────────────
  {
    'id': 'sale-019',
    'employeeId': 'emp-001',
    'customerName': 'Roshan Gunawardena',
    'litres': 42.0,
    'saleAmount': 9660.0,
    'time': '10:00 AM',
    'date': '29 Mar',
    'month': 'March 2026',
  },
  {
    'id': 'sale-020',
    'employeeId': 'emp-001',
    'customerName': 'Kasun Madushanka',
    'litres': 17.0,
    'saleAmount': 3910.0,
    'time': '2:00 PM',
    'date': '25 Mar',
    'month': 'March 2026',
  },
  {
    'id': 'sale-021',
    'employeeId': 'emp-001',
    'customerName': 'Thilini Kumari',
    'litres': 60.0,
    'saleAmount': 13800.0,
    'time': '9:30 AM',
    'date': '20 Mar',
    'month': 'March 2026',
  },
  {
    'id': 'sale-022',
    'employeeId': 'emp-001',
    'customerName': 'Suresh Bandara',
    'litres': 25.0,
    'saleAmount': 5750.0,
    'time': '11:45 AM',
    'date': '15 Mar',
    'month': 'March 2026',
  },
  {
    'id': 'sale-023',
    'employeeId': 'emp-001',
    'customerName': 'Amal Perera',
    'litres': 30.0,
    'saleAmount': 6900.0,
    'time': '3:00 PM',
    'date': '10 Mar',
    'month': 'March 2026',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// Employee — Profile Info
// ─────────────────────────────────────────────────────────────────────────────

/// Extra profile info shown on the employee profile page.
/// The real backend returns this from GET /employees/{id}/profile.
const Map<String, dynamic> kMockEmployeeProfiles = {
  'emp-001': {
    'appVersion': '1.0.0',
    'department': 'Fuel Station',
    'joinedDate': '2023-01-10',
  },
};