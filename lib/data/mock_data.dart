/// Flip this to false when the real backend is connected.
const bool kUseMockData = true;

/// The base URL for the real backend.
const String kBaseUrl = 'https://api.example.com/v1';

// ─────────────────────────────────────────────────────────────────────────────
// Users
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> kMockUsers = [
  {
    'id': 'cust-001',
    'firstName': 'Kasun',
    'lastName': 'Perera',
    'email': 'customer@gmail.com',
    'phone': '0771234567',
    'role': 'customer',
    'address': '42 Galle Road, Colombo 03',
    'points': 1160,
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

// ─────────────────────────────────────────────────────────────────────────────
// Employee — Profile Info
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, dynamic> kMockEmployeeProfiles = {
  'emp-001': {
    'phone': '0779876543',
    'title': 'Senior Attendant',
  },
};

const Map<String, String> kMockPasswords = {
  'cust-001': 'customer123',
  'emp-001': 'employee123',
};

// ─────────────────────────────────────────────────────────────────────────────
// OTP
// ─────────────────────────────────────────────────────────────────────────────

const String kMockOtp = '1234';

// ─────────────────────────────────────────────────────────────────────────────
// Transactions (Customer)
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> kMockTransactions = [
  // ── June 2026 — Active earned ─────────────────────────────────────────────
  {
    'id': 't1',
    'userId': 'cust-001',
    'business': 'Fuel Station',
    'points': 120,
    'isEarned': true,
    'isExpired': false,
    'hoursAgo': 3,
    'billNo': 'FS-20260616-001',
  },
  {
    'id': 't3',
    'userId': 'cust-001',
    'business': 'Gold Shop',
    'points': 200,
    'isEarned': true,
    'isExpired': false,
    'daysAgo': 3,
    'billNo': 'GS-20260613-003',
  },
  {
    'id': 't4',
    'userId': 'cust-001',
    'business': 'Fuel Station',
    'points': 120,
    'isEarned': true,
    'isExpired': false,
    'daysAgo': 5,
    'billNo': 'FS-20260611-004',
  },
  {
    'id': 't5',
    'userId': 'cust-001',
    'business': 'Laundry',
    'points': 80,
    'isEarned': true,
    'isExpired': false,
    'daysAgo': 7,
    'billNo': 'LN-20260609-005',
  },
  {
    'id': 't6',
    'userId': 'cust-001',
    'business': 'Gold Shop',
    'points': 200,
    'isEarned': true,
    'isExpired': false,
    'daysAgo': 10,
    'billNo': 'GS-20260606-006',
  },
  {
    'id': 't7',
    'userId': 'cust-001',
    'business': 'Fuel Station',
    'points': 120,
    'isEarned': true,
    'isExpired': false,
    'daysAgo': 12,
    'billNo': 'FS-20260604-007',
  },

  // ── June 2026 — Redeemed ──────────────────────────────────────────────────
  {
    'id': 't2',
    'userId': 'cust-001',
    'business': 'Laundry',
    'points': 250,
    'isEarned': false,
    'isExpired': false,
    'daysAgo': 1,
    'note': 'Free wash service',
  },

  // ── May 2026 — Active earned ──────────────────────────────────────────────
  {
    'id': 't11',
    'userId': 'cust-001',
    'business': 'Fuel Station',
    'points': 120,
    'isEarned': true,
    'isExpired': false,
    'daysAgo': 20,
    'billNo': 'FS-20260527-011',
  },
  {
    'id': 't12',
    'userId': 'cust-001',
    'business': 'Gold Shop',
    'points': 200,
    'isEarned': true,
    'isExpired': false,
    'daysAgo': 25,
    'billNo': 'GS-20260522-012',
  },
  {
    'id': 't13',
    'userId': 'cust-001',
    'business': 'Laundry',
    'points': 80,
    'isEarned': true,
    'isExpired': false,
    'daysAgo': 30,
    'billNo': 'LN-20260517-013',
  },

  // ── May 2026 — Redeemed ───────────────────────────────────────────────────
  {
    'id': 't16',
    'userId': 'cust-001',
    'business': 'Gold Shop',
    'points': 150,
    'isEarned': false,
    'isExpired': false,
    'daysAgo': 22,
    'note': 'Gold valuation service',
  },

  // ── April 2026 — Active earned ────────────────────────────────────────────
  {
    'id': 't14',
    'userId': 'cust-001',
    'business': 'Fuel Station',
    'points': 120,
    'isEarned': true,
    'isExpired': false,
    'daysAgo': 45,
    'billNo': 'FS-20260502-014',
  },
  {
    'id': 't15',
    'userId': 'cust-001',
    'business': 'Gold Shop',
    'points': 200,
    'isEarned': true,
    'isExpired': false,
    'daysAgo': 55,
    'billNo': 'GS-20260422-015',
  },

  // ── Expired (older — won't affect active balance) ─────────────────────────
  {
    'id': 't8',
    'userId': 'cust-001',
    'business': 'Gold Shop',
    'points': 150,
    'isEarned': true,
    'isExpired': true,
    'daysAgo': 75,
    'billNo': 'GS-20260402-008',
    'note': 'Points expired — not redeemed in time',
  },
  {
    'id': 't9',
    'userId': 'cust-001',
    'business': 'Fuel Station',
    'points': 120,
    'isEarned': true,
    'isExpired': true,
    'daysAgo': 90,
    'billNo': 'FS-20260317-009',
    'note': 'Points expired — not redeemed in time',
  },
  {
    'id': 't10',
    'userId': 'cust-001',
    'business': 'Laundry',
    'points': 80,
    'isEarned': true,
    'isExpired': true,
    'daysAgo': 110,
    'billNo': 'LN-20260226-010',
    'note': 'Points expired — not redeemed in time',
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// Weekly Points (Home Screen Chart)
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, List<int>> kMockWeeklyPoints = {
  'cust-001': [80, 210, 150, 60, 320, 200, 120],
  'emp-001': [0, 0, 0, 0, 0, 0, 0],
};

// ─────────────────────────────────────────────────────────────────────────────
// Advertisement Banners (Home Screen)
// ─────────────────────────────────────────────────────────────────────────────

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

const List<Map<String, dynamic>> kMockOffers = [
  // ── Laundry ───────────────────────────────────────────────────────────────
  {
    'id': 'o1',
    'title': 'Free wash service',
    'description': 'Any 1 load of laundry, any size',
    'business': 'Laundry',
    'pointsCost': 200,
    'isExpired': false,
  },
  {
    'id': 'o4',
    'title': 'Premium wash + iron',
    'description': 'Full laundry + ironing service',
    'business': 'Laundry',
    'pointsCost': 350,
    'isExpired': false,
  },
  {
    'id': 'o6',
    'title': 'Express same-day wash',
    'description': 'Ready within 4 hours',
    'business': 'Laundry',
    'pointsCost': 180,
    'isExpired': true,
  },
  // ── Fuel Station ──────────────────────────────────────────────────────────
  {
    'id': 'o2',
    'title': '10% fuel discount',
    'description': 'Per fill-up, any fuel type',
    'business': 'Fuel Station',
    'pointsCost': 150,
    'isExpired': false,
  },
  {
    'id': 'o7',
    'title': 'Free car wash',
    'description': 'With any fuel fill-up',
    'business': 'Fuel Station',
    'pointsCost': 100,
    'isExpired': true,
  },
  // ── Gold Shop ─────────────────────────────────────────────────────────────
  {
    'id': 'o3',
    'title': 'Gold jewellery polish',
    'description': 'Professional polish for any gold item',
    'business': 'Gold Shop',
    'pointsCost': 500,
    'isExpired': false,
  },
  {
    'id': 'o5',
    'title': 'Gold valuation service',
    'description': 'Free gold item valuation',
    'business': 'Gold Shop',
    'pointsCost': 300,
    'isExpired': false,
  },
  {
    'id': 'o8',
    'title': 'Free ring sizing',
    'description': 'Resize any gold ring',
    'business': 'Gold Shop',
    'pointsCost': 250,
    'isExpired': true,
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// Business Configuration
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, int> kBusinessPoints = {
  'Fuel Station': 120,
  'Laundry': 80,
  'Gold Shop': 200,
};

const String kBusinessFuel    = 'Fuel Station';
const String kBusinessLaundry = 'Laundry';
const String kBusinessGold    = 'Gold Shop';

// ─────────────────────────────────────────────────────────────────────────────
// Employee — Scanned Member
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, dynamic> kMockScannedMember = {
  'name': 'Amal Perera',
  'memberId': 'AP2024X1',
  'tier': 'Gold',
  'currentPoints': 3420,
  'phone': '071 234 5678',
};

// ─────────────────────────────────────────────────────────────────────────────
// Employee — Today's Scans (seed data)
// ─────────────────────────────────────────────────────────────────────────────

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

const Map<String, List<int>> kMockEmployeeWeeklyCommission = {
  'emp-001': [1240, 3800, 2650, 4200, 5100, 3200, 800],
};

// ─────────────────────────────────────────────────────────────────────────────
// Employee — Commission Sales History
// ─────────────────────────────────────────────────────────────────────────────

const double kCommissionRate = 0.02; // 2 %

const List<Map<String, dynamic>> kMockCommissionSales = [
  // ── June 2026 ─────────────────────────────────────────────────────────────
  {
    'id': 'sale-101',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Amal Perera',
    'litres': 32.0,
    'saleAmount': 7360.0,
    'time': '9:10 AM',
    'date': '10 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-102',
    'employeeId': 'emp-001',
    'business': 'Laundry',
    'customerName': 'Sanduni Wickrama',
    'litres': 0.0,
    'saleAmount': 3200.0,
    'time': '10:30 AM',
    'date': '10 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-103',
    'employeeId': 'emp-001',
    'business': 'Gold Shop',
    'customerName': 'Lakmal Jayasena',
    'litres': 0.0,
    'saleAmount': 45000.0,
    'time': '11:15 AM',
    'date': '9 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-104',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Nimal Silva',
    'litres': 20.0,
    'saleAmount': 4600.0,
    'time': '2:00 PM',
    'date': '9 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-105',
    'employeeId': 'emp-001',
    'business': 'Laundry',
    'customerName': 'Kamani Fernando',
    'litres': 0.0,
    'saleAmount': 1800.0,
    'time': '3:45 PM',
    'date': '8 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-106',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Ruwan Jayawardena',
    'litres': 45.0,
    'saleAmount': 10350.0,
    'time': '8:20 AM',
    'date': '10 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-107',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Thilini Kumari',
    'litres': 28.5,
    'saleAmount': 6555.0,
    'time': '11:40 AM',
    'date': '10 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-108',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Priya Wijesinghe',
    'litres': 50.0,
    'saleAmount': 11500.0,
    'time': '1:15 PM',
    'date': '10 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-109',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Kasun Madushanka',
    'litres': 18.0,
    'saleAmount': 4140.0,
    'time': '3:30 PM',
    'date': '9 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-110',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Chamara Dissanayake',
    'litres': 35.0,
    'saleAmount': 8050.0,
    'time': '4:50 PM',
    'date': '9 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-111',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Ishara Mendis',
    'litres': 22.0,
    'saleAmount': 5060.0,
    'time': '9:00 AM',
    'date': '8 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-112',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Roshan Gunawardena',
    'litres': 60.0,
    'saleAmount': 13800.0,
    'time': '11:10 AM',
    'date': '7 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-113',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Suresh Bandara',
    'litres': 12.5,
    'saleAmount': 2875.0,
    'time': '2:20 PM',
    'date': '7 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-114',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Dilini Ratnayake',
    'litres': 40.0,
    'saleAmount': 9200.0,
    'time': '10:05 AM',
    'date': '6 Jun',
    'month': 'Jun 2026',
  },
  {
    'id': 'sale-115',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Amal Perera',
    'litres': 25.0,
    'saleAmount': 5750.0,
    'time': '8:45 AM',
    'date': '5 Jun',
    'month': 'Jun 2026',
  },

  // ── May 2026 ──────────────────────────────────────────────────────────────
  {
    'id': 'sale-001',
    'employeeId': 'emp-001',
    'business': 'Fuel',
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
    'business': 'Fuel',
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
    'business': 'Laundry',
    'customerName': 'Kamani Fernando',
    'litres': 0.0,
    'saleAmount': 2800.0,
    'time': '9:58 AM',
    'date': '20 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-004',
    'employeeId': 'emp-001',
    'business': 'Fuel',
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
    'business': 'Gold Shop',
    'customerName': 'Dilini Ratnayake',
    'litres': 0.0,
    'saleAmount': 38000.0,
    'time': '9:22 AM',
    'date': '19 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-006',
    'employeeId': 'emp-001',
    'business': 'Fuel',
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
    'business': 'Laundry',
    'customerName': 'Priya Wijesinghe',
    'litres': 0.0,
    'saleAmount': 4200.0,
    'time': '1:45 PM',
    'date': '17 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-008',
    'employeeId': 'emp-001',
    'business': 'Fuel',
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
    'business': 'Gold Shop',
    'customerName': 'Thilini Kumari',
    'litres': 0.0,
    'saleAmount': 62000.0,
    'time': '10:05 AM',
    'date': '15 May',
    'month': 'May 2026',
  },
  {
    'id': 'sale-010',
    'employeeId': 'emp-001',
    'business': 'Fuel',
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
    'business': 'Fuel',
    'customerName': 'Amal Perera',
    'litres': 28.0,
    'saleAmount': 6440.0,
    'time': '2:30 PM',
    'date': '30 Apr',
    'month': 'Apr 2026',
  },
  {
    'id': 'sale-012',
    'employeeId': 'emp-001',
    'business': 'Laundry',
    'customerName': 'Chamara Dissanayake',
    'litres': 0.0,
    'saleAmount': 5500.0,
    'time': '11:00 AM',
    'date': '28 Apr',
    'month': 'Apr 2026',
  },
  {
    'id': 'sale-013',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Sanduni Wickrama',
    'litres': 22.0,
    'saleAmount': 5060.0,
    'time': '9:15 AM',
    'date': '25 Apr',
    'month': 'Apr 2026',
  },
  {
    'id': 'sale-014',
    'employeeId': 'emp-001',
    'business': 'Gold Shop',
    'customerName': 'Lakmal Jayasena',
    'litres': 0.0,
    'saleAmount': 52000.0,
    'time': '4:00 PM',
    'date': '22 Apr',
    'month': 'Apr 2026',
  },
  {
    'id': 'sale-015',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Nimal Silva',
    'litres': 12.0,
    'saleAmount': 2760.0,
    'time': '10:45 AM',
    'date': '20 Apr',
    'month': 'Apr 2026',
  },
  {
    'id': 'sale-016',
    'employeeId': 'emp-001',
    'business': 'Laundry',
    'customerName': 'Ishara Mendis',
    'litres': 0.0,
    'saleAmount': 3800.0,
    'time': '3:20 PM',
    'date': '15 Apr',
    'month': 'Apr 2026',
  },
  {
    'id': 'sale-017',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Priya Wijesinghe',
    'litres': 20.0,
    'saleAmount': 4600.0,
    'time': '8:50 AM',
    'date': '10 Apr',
    'month': 'Apr 2026',
  },
  {
    'id': 'sale-018',
    'employeeId': 'emp-001',
    'business': 'Gold Shop',
    'customerName': 'Dilini Ratnayake',
    'litres': 0.0,
    'saleAmount': 28000.0,
    'time': '1:10 PM',
    'date': '5 Apr',
    'month': 'Apr 2026',
  },

  // ── March 2026 ────────────────────────────────────────────────────────────
  {
    'id': 'sale-019',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Roshan Gunawardena',
    'litres': 42.0,
    'saleAmount': 9660.0,
    'time': '10:00 AM',
    'date': '29 Mar',
    'month': 'Mar 2026',
  },
  {
    'id': 'sale-020',
    'employeeId': 'emp-001',
    'business': 'Laundry',
    'customerName': 'Kasun Madushanka',
    'litres': 0.0,
    'saleAmount': 2200.0,
    'time': '2:00 PM',
    'date': '25 Mar',
    'month': 'Mar 2026',
  },
  {
    'id': 'sale-021',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Thilini Kumari',
    'litres': 60.0,
    'saleAmount': 13800.0,
    'time': '9:30 AM',
    'date': '20 Mar',
    'month': 'Mar 2026',
  },
  {
    'id': 'sale-022',
    'employeeId': 'emp-001',
    'business': 'Gold Shop',
    'customerName': 'Suresh Bandara',
    'litres': 0.0,
    'saleAmount': 31000.0,
    'time': '11:45 AM',
    'date': '15 Mar',
    'month': 'Mar 2026',
  },
  {
    'id': 'sale-023',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Amal Perera',
    'litres': 30.0,
    'saleAmount': 6900.0,
    'time': '3:00 PM',
    'date': '10 Mar',
    'month': 'Mar 2026',
  },

  // ── February 2026 ─────────────────────────────────────────────────────────
  {
    'id': 'sale-024',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Chamara Dissanayake',
    'litres': 25.0,
    'saleAmount': 5750.0,
    'time': '8:30 AM',
    'date': '28 Feb',
    'month': 'Feb 2026',
  },
  {
    'id': 'sale-025',
    'employeeId': 'emp-001',
    'business': 'Laundry',
    'customerName': 'Sanduni Wickrama',
    'litres': 0.0,
    'saleAmount': 4100.0,
    'time': '10:00 AM',
    'date': '24 Feb',
    'month': 'Feb 2026',
  },
  {
    'id': 'sale-026',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Lakmal Jayasena',
    'litres': 18.0,
    'saleAmount': 4140.0,
    'time': '1:20 PM',
    'date': '20 Feb',
    'month': 'Feb 2026',
  },
  {
    'id': 'sale-027',
    'employeeId': 'emp-001',
    'business': 'Gold Shop',
    'customerName': 'Ishara Mendis',
    'litres': 0.0,
    'saleAmount': 47000.0,
    'time': '3:00 PM',
    'date': '15 Feb',
    'month': 'Feb 2026',
  },
  {
    'id': 'sale-028',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Priya Wijesinghe',
    'litres': 33.0,
    'saleAmount': 7590.0,
    'time': '9:45 AM',
    'date': '10 Feb',
    'month': 'Feb 2026',
  },
  {
    'id': 'sale-029',
    'employeeId': 'emp-001',
    'business': 'Laundry',
    'customerName': 'Roshan Gunawardena',
    'litres': 0.0,
    'saleAmount': 2600.0,
    'time': '11:30 AM',
    'date': '5 Feb',
    'month': 'Feb 2026',
  },

  // ── January 2026 ──────────────────────────────────────────────────────────
  {
    'id': 'sale-030',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Amal Perera',
    'litres': 45.0,
    'saleAmount': 10350.0,
    'time': '8:00 AM',
    'date': '30 Jan',
    'month': 'Jan 2026',
  },
  {
    'id': 'sale-031',
    'employeeId': 'emp-001',
    'business': 'Gold Shop',
    'customerName': 'Nimal Silva',
    'litres': 0.0,
    'saleAmount': 55000.0,
    'time': '10:15 AM',
    'date': '25 Jan',
    'month': 'Jan 2026',
  },
  {
    'id': 'sale-032',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Kamani Fernando',
    'litres': 22.0,
    'saleAmount': 5060.0,
    'time': '2:30 PM',
    'date': '20 Jan',
    'month': 'Jan 2026',
  },
  {
    'id': 'sale-033',
    'employeeId': 'emp-001',
    'business': 'Laundry',
    'customerName': 'Thilini Kumari',
    'litres': 0.0,
    'saleAmount': 3500.0,
    'time': '9:00 AM',
    'date': '15 Jan',
    'month': 'Jan 2026',
  },
  {
    'id': 'sale-034',
    'employeeId': 'emp-001',
    'business': 'Fuel',
    'customerName': 'Suresh Bandara',
    'litres': 28.0,
    'saleAmount': 6440.0,
    'time': '11:00 AM',
    'date': '10 Jan',
    'month': 'Jan 2026',
  },
  {
    'id': 'sale-035',
    'employeeId': 'emp-001',
    'business': 'Gold Shop',
    'customerName': 'Kasun Madushanka',
    'litres': 0.0,
    'saleAmount': 39000.0,
    'time': '3:30 PM',
    'date': '5 Jan',
    'month': 'Jan 2026',
  },
];