import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/app_widgets.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _SaleEntry {
  final String customerName;
  final double litres;
  final double saleAmount; // LKR
  final String time;
  final String date;
  final String month;

  const _SaleEntry({
    required this.customerName,
    required this.litres,
    required this.saleAmount,
    required this.time,
    required this.date,
    required this.month,
  });

  double get commission => saleAmount * 0.02; // 2% of sale
}

// ── Mock data ─────────────────────────────────────────────────────────────────

const _allSales = [
  // May 2026
  _SaleEntry(customerName: 'Amal Perera',       litres: 30.0, saleAmount: 6900,  time: '10:32 AM', date: '20 May', month: 'May 2026'),
  _SaleEntry(customerName: 'Nimal Silva',        litres: 15.5, saleAmount: 3565,  time: '10:15 AM', date: '20 May', month: 'May 2026'),
  _SaleEntry(customerName: 'Kamani Fernando',    litres: 45.0, saleAmount: 10350, time: '9:58 AM',  date: '20 May', month: 'May 2026'),
  _SaleEntry(customerName: 'Ruwan Jayawardena',  litres: 20.0, saleAmount: 4600,  time: '9:40 AM',  date: '19 May', month: 'May 2026'),
  _SaleEntry(customerName: 'Dilini Ratnayake',   litres: 60.0, saleAmount: 13800, time: '9:22 AM',  date: '19 May', month: 'May 2026'),
  _SaleEntry(customerName: 'Suresh Bandara',     litres: 10.0, saleAmount: 2300,  time: '3:10 PM',  date: '18 May', month: 'May 2026'),
  _SaleEntry(customerName: 'Priya Wijesinghe',   litres: 25.0, saleAmount: 5750,  time: '1:45 PM',  date: '17 May', month: 'May 2026'),
  _SaleEntry(customerName: 'Kasun Madushanka',   litres: 40.0, saleAmount: 9200,  time: '11:20 AM', date: '16 May', month: 'May 2026'),
  _SaleEntry(customerName: 'Thilini Kumari',     litres: 18.0, saleAmount: 4140,  time: '10:05 AM', date: '15 May', month: 'May 2026'),
  _SaleEntry(customerName: 'Roshan Gunawardena', litres: 35.0, saleAmount: 8050,  time: '9:00 AM',  date: '14 May', month: 'May 2026'),
  // April 2026
  _SaleEntry(customerName: 'Amal Perera',        litres: 28.0, saleAmount: 6440,  time: '2:30 PM',  date: '30 Apr', month: 'April 2026'),
  _SaleEntry(customerName: 'Chamara Dissanayake',litres: 50.0, saleAmount: 11500, time: '11:00 AM', date: '28 Apr', month: 'April 2026'),
  _SaleEntry(customerName: 'Sanduni Wickrama',   litres: 22.0, saleAmount: 5060,  time: '9:15 AM',  date: '25 Apr', month: 'April 2026'),
  _SaleEntry(customerName: 'Lakmal Jayasena',    litres: 38.0, saleAmount: 8740,  time: '4:00 PM',  date: '22 Apr', month: 'April 2026'),
  _SaleEntry(customerName: 'Nimal Silva',        litres: 12.0, saleAmount: 2760,  time: '10:45 AM', date: '20 Apr', month: 'April 2026'),
  _SaleEntry(customerName: 'Ishara Mendis',      litres: 55.0, saleAmount: 12650, time: '3:20 PM',  date: '15 Apr', month: 'April 2026'),
  _SaleEntry(customerName: 'Priya Wijesinghe',   litres: 20.0, saleAmount: 4600,  time: '8:50 AM',  date: '10 Apr', month: 'April 2026'),
  _SaleEntry(customerName: 'Dilini Ratnayake',   litres: 33.0, saleAmount: 7590,  time: '1:10 PM',  date: '5 Apr',  month: 'April 2026'),
  // March 2026
  _SaleEntry(customerName: 'Roshan Gunawardena', litres: 42.0, saleAmount: 9660,  time: '10:00 AM', date: '29 Mar', month: 'March 2026'),
  _SaleEntry(customerName: 'Kasun Madushanka',   litres: 17.0, saleAmount: 3910,  time: '2:00 PM',  date: '25 Mar', month: 'March 2026'),
  _SaleEntry(customerName: 'Thilini Kumari',     litres: 60.0, saleAmount: 13800, time: '9:30 AM',  date: '20 Mar', month: 'March 2026'),
  _SaleEntry(customerName: 'Suresh Bandara',     litres: 25.0, saleAmount: 5750,  time: '11:45 AM', date: '15 Mar', month: 'March 2026'),
  _SaleEntry(customerName: 'Amal Perera',        litres: 30.0, saleAmount: 6900,  time: '3:00 PM',  date: '10 Mar', month: 'March 2026'),
];

const _months = ['May 2026', 'April 2026', 'March 2026'];

// ── Page ──────────────────────────────────────────────────────────────────────

class EmployeeCommissionPage extends StatefulWidget {
  final UserModel employee;
  const EmployeeCommissionPage({super.key, required this.employee});

  @override
  State<EmployeeCommissionPage> createState() => _EmployeeCommissionPageState();
}

class _EmployeeCommissionPageState extends State<EmployeeCommissionPage> {
  String _selectedMonth = 'May 2026';

  List<_SaleEntry> get _filtered =>
      _allSales.where((s) => s.month == _selectedMonth).toList();

  double get _totalCommission =>
      _filtered.fold(0, (sum, s) => sum + s.commission);

  double get _totalSales =>
      _filtered.fold(0, (sum, s) => sum + s.saleAmount);

  int get _customerCount =>
      _filtered.map((s) => s.customerName).toSet().length;

  @override
  Widget build(BuildContext context) {
    final sales = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Static header + filter + summary ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Commission', style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  const Text('Per-sale earnings breakdown',
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 20),

                  // Month filter chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _months.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final m = _months[i];
                        final selected = m == _selectedMonth;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedMonth = m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? const LinearGradient(
                                      colors: AppColors.buttonGradient)
                                  : null,
                              color: selected ? null : AppColors.bgCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? Colors.transparent
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              m,
                              style: AppTextStyles.caption.copyWith(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textMuted,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Summary card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.buttonGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedMonth,
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text(
                          'LKR ${_totalCommission.toStringAsFixed(2)}',
                          style: AppTextStyles.h2
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total sales: LKR ${_totalSales.toStringAsFixed(0)}  •  2% commission rate',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white60),
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          _MiniStat(
                              label: 'Transactions',
                              value: '${sales.length}'),
                          const SizedBox(width: 28),
                          _MiniStat(
                              label: 'Customers',
                              value: '$_customerCount'),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(children: [
                    Text('Sales in $_selectedMonth', style: AppTextStyles.h4),
                    const Spacer(),
                    Text('${sales.length} transactions',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted)),
                  ]),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── Scrollable transaction list ────────────────────────
            Expanded(
              child: sales.isEmpty
                  ? Center(
                      child: Text(
                        'No sales recorded for $_selectedMonth',
                        style: AppTextStyles.bodySmall,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: sales.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _SaleTile(sale: sales[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction tile ──────────────────────────────────────────────────────────

class _SaleTile extends StatelessWidget {
  final _SaleEntry sale;
  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        // Icon
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_gas_station_rounded,
              color: AppColors.primaryLight, size: 20),
        ),
        const SizedBox(width: 12),

        // Customer info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sale.customerName, style: AppTextStyles.labelMedium),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.water_drop_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text('${sale.litres.toStringAsFixed(1)} L',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(width: 10),
                const Icon(Icons.access_time_rounded,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    '${sale.date}  ${sale.time}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              Text('Sale: LKR ${sale.saleAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),

        // Commission badge
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+LKR ${sale.commission.toStringAsFixed(2)}',
              style: AppTextStyles.caption.copyWith(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('2% rate',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted, fontSize: 10)),
        ]),
      ]),
    );
  }
}

// ── Mini stat (inside summary card) ──────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: AppTextStyles.h4.copyWith(color: Colors.white)),
      Text(label,
          style: AppTextStyles.caption.copyWith(color: Colors.white60)),
    ]);
  }
}