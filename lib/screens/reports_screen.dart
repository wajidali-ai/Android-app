import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../providers/dashboard_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'daily';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadReport(_selectedPeriod);
    });
  }

  void _onPeriodChanged(String period) {
    setState(() => _selectedPeriod = period);
    context.read<DashboardProvider>().loadReport(period);
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    final summary = dash.reportData['summary'] as Map<String, dynamic>? ?? {};
    final shopkeepers = (dash.reportData['by_shopkeeper'] as List<dynamic>?) ?? [];

    final totalSales = (summary['total_sales'] as num?)?.toDouble() ?? 0.0;
    final totalPaid = (summary['total_paid'] as num?)?.toDouble() ?? 0.0;
    final totalOutstanding = (summary['total_outstanding'] as num?)?.toDouble() ?? 0.0;
    final totalBills = (summary['total_bills'] as num?)?.toInt() ?? 0;
    final totalDiscounts = (summary['total_discounts'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Audit Reports', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: dash.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              children: [
                // PERIOD TOGGLE
                Center(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'daily', label: Text('Today')),
                      ButtonSegment(value: 'weekly', label: Text('Last 7 Days')),
                      ButtonSegment(value: 'monthly', label: Text('This Month')),
                    ],
                    selected: {_selectedPeriod},
                    onSelectionChanged: (set) => _onPeriodChanged(set.first),
                  ),
                ),

                const SizedBox(height: AppTheme.spaceLg),

                // SUMMARY METRIC CARD
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Revenue Overview',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppTheme.spaceMd),
                        _buildMetricRow('Total Gross Sales', 'Rs. ${currencyFormat.format(totalSales)}', isBold: true, color: AppTheme.brandPrimary),
                        const Divider(height: 16),
                        _buildMetricRow('Cash & Online Collected', 'Rs. ${currencyFormat.format(totalPaid)}', color: AppTheme.brandSuccess),
                        _buildMetricRow('Outstanding Customer Credit', 'Rs. ${currencyFormat.format(totalOutstanding)}', color: totalOutstanding > 0 ? AppTheme.brandDanger : null),
                        _buildMetricRow('Total Discounts Given', 'Rs. ${currencyFormat.format(totalDiscounts)}'),
                        _buildMetricRow('Total Transactions', '$totalBills bills'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spaceMd),

                // SHOPKEEPER PERFORMANCE / PHONE BREAKDOWN
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sales by Shopkeeper Phone',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            Icon(Icons.people_outline, size: 20),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceSm),
                        const Text(
                          'Track transactions created across all active devices.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                        ),
                        const Divider(height: 20),
                        if (shopkeepers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: Text('No recorded sales in this period.')),
                          )
                        else
                          ...shopkeepers.map((sk) {
                            final name = sk['created_by_name'] as String? ?? 'Counter';
                            final count = (sk['bills_created'] as num?)?.toInt() ?? 0;
                            final volume = (sk['sales_volume'] as num?)?.toDouble() ?? 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      Text('$count bills generated', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight)),
                                    ],
                                  ),
                                  Text(
                                    'Rs. ${currencyFormat.format(volume)}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryLight)),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
