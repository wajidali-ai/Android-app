import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/sync/sync_service.dart';
import '../providers/dashboard_provider.dart';
import '../providers/bills_history_provider.dart';
import 'bill_detail_screen.dart';
import 'create_bill_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToBilling;

  const DashboardScreen({super.key, required this.onNavigateToBilling});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadTodaySummary();
      context.read<BillsHistoryProvider>().loadBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final history = context.watch<BillsHistoryProvider>();
    final sync = context.watch<SyncService>();
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppConstants.appName,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
            ),
          ],
        ),
        actions: [
          // Live Sync Status Badge
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              borderRadius: AppTheme.radiusPill,
              onTap: () {
                sync.syncAllPending();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(sync.isOnline
                        ? 'Synchronizing pending bills with Supabase...'
                        : 'Offline. Bills are safely queued in SQLite.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: sync.isSyncing
                      ? AppTheme.brandWarning.withOpacity(0.15)
                      : sync.pendingCount > 0
                          ? AppTheme.brandAccent.withOpacity(0.15)
                          : AppTheme.brandSuccess.withOpacity(0.15),
                  borderRadius: AppTheme.radiusPill,
                  border: Border.all(
                    color: sync.isSyncing
                        ? AppTheme.brandWarning
                        : sync.pendingCount > 0
                            ? AppTheme.brandAccent
                            : AppTheme.brandSuccess,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sync.isSyncing
                          ? Icons.sync
                          : sync.pendingCount > 0
                              ? Icons.cloud_upload_outlined
                              : Icons.cloud_done,
                      size: 16,
                      color: sync.isSyncing
                          ? AppTheme.brandWarning
                          : sync.pendingCount > 0
                              ? AppTheme.brandAccent
                              : AppTheme.brandSuccess,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sync.isSyncing
                          ? 'Syncing'
                          : sync.pendingCount > 0
                              ? '${sync.pendingCount} Pending'
                              : 'Synced',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sync.isSyncing
                            ? AppTheme.brandWarning
                            : sync.pendingCount > 0
                                ? AppTheme.brandAccent
                                : AppTheme.brandSuccess,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await dash.loadTodaySummary();
          await history.loadBills();
          await sync.updatePendingCount();
        },
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          children: [
            // PRIMARY ACTION BANNER
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.brandPrimary, Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppTheme.radiusLg,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brandPrimary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Crockery Counter Billing',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Create New Bill',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Instant SQLite save & thermal print',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.brandPrimary,
                      shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: widget.onNavigateToBilling,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Start Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceLg),

            // TODAY SALES METRICS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Sales Summary",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
                  },
                  icon: const Icon(Icons.bar_chart, size: 16),
                  label: const Text('Full Reports', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),

            // 4 KEY METRICS TILES
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppTheme.spaceMd,
              mainAxisSpacing: AppTheme.spaceMd,
              childAspectRatio: 1.5,
              children: [
                _buildMetricCard(
                  title: "Today's Sales",
                  value: 'Rs. ${currencyFormat.format(dash.todaySales)}',
                  subtitle: '${dash.todayBillCount} bills generated',
                  icon: Icons.payments_outlined,
                  color: AppTheme.brandPrimary,
                ),
                _buildMetricCard(
                  title: 'Cash Collected',
                  value: 'Rs. ${currencyFormat.format(dash.todayCash)}',
                  subtitle: 'In drawer',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppTheme.brandSuccess,
                ),
                _buildMetricCard(
                  title: 'Online Collected',
                  value: 'Rs. ${currencyFormat.format(dash.todayOnline)}',
                  subtitle: 'Bank / JazzCash / Nayapay',
                  icon: Icons.qr_code_2,
                  color: const Color(0xFF3182CE),
                ),
                _buildMetricCard(
                  title: 'Outstanding Balance',
                  value: 'Rs. ${currencyFormat.format(dash.todayBalance)}',
                  subtitle: 'Pending customer credit',
                  icon: Icons.pending_actions,
                  color: dash.todayBalance > 0 ? AppTheme.brandDanger : AppTheme.textSecondaryLight,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spaceXl),

            // RECENT BILLS SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${history.bills.length} saved locally',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),

            if (history.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spaceXl),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (history.bills.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space2xl),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: AppTheme.spaceMd),
                      const Text(
                        'No bills created yet',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap "Start Bill" to record your first crockery sale.',
                        style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...history.bills.take(5).map((bill) => _buildRecentBillTile(context, bill)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight, fontWeight: FontWeight.w600),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBillTile(BuildContext context, dynamic bill) {
    final currencyFormat = NumberFormat('#,##0', 'en_US');
    final timeStr = DateFormat('hh:mm a').format(bill.billDate);

    Color statusColor = AppTheme.brandSuccess;
    if (bill.paymentStatus.name == 'unpaid') statusColor = AppTheme.brandDanger;
    if (bill.paymentStatus.name == 'partial') statusColor = AppTheme.brandWarning;
    if (bill.status.name == 'cancelled') statusColor = Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: InkWell(
        borderRadius: AppTheme.radiusLg,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BillDetailScreen(billId: bill.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: AppTheme.radiusMd,
                ),
                child: Icon(Icons.receipt, color: statusColor, size: 22),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bill.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        if (bill.status.name == 'cancelled') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: AppTheme.radiusSm,
                            ),
                            child: const Text(
                              'CANCELLED',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bill.billNumber} • $timeStr • By ${bill.createdByName}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${currencyFormat.format(bill.grandTotal)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: AppTheme.radiusPill,
                    ),
                    child: Text(
                      bill.paymentStatus.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
