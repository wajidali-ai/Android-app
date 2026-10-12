import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../models/bill.dart';
import '../providers/bills_history_provider.dart';
import 'bill_detail_screen.dart';

class BillsHistoryScreen extends StatefulWidget {
  const BillsHistoryScreen({super.key});

  @override
  State<BillsHistoryScreen> createState() => _BillsHistoryScreenState();
}

class _BillsHistoryScreenState extends State<BillsHistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillsHistoryProvider>().loadBills();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final history = context.read<BillsHistoryProvider>();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: history.startDate != null && history.endDate != null
          ? DateTimeRange(start: history.startDate!, end: history.endDate!)
          : null,
    );

    if (picked != null) {
      history.setDateRange(picked.start, picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<BillsHistoryProvider>();
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill History', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Filter by Date',
            icon: Icon(
              Icons.date_range,
              color: history.startDate != null ? AppTheme.brandPrimary : null,
            ),
            onPressed: _pickDateRange,
          ),
          if (history.startDate != null || history.searchQuery.isNotEmpty || history.paymentStatusFilter != 'all')
            IconButton(
              tooltip: 'Clear Filters',
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                _searchController.clear();
                history.clearFilters();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. SEARCH INPUT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg, vertical: AppTheme.spaceSm),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customer, phone or bill number...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          history.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => history.setSearchQuery(val),
            ),
          ),

          // 2. PAYMENT STATUS FILTER CHIPS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', history),
                  const SizedBox(width: 8),
                  _buildFilterChip('Paid', 'paid', history),
                  const SizedBox(width: 8),
                  _buildFilterChip('Partial', 'partial', history),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unpaid (Credit)', 'unpaid', history),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spaceSm),

          // ACTIVE DATE FILTER INDICATOR
          if (history.startDate != null && history.endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.brandPrimary.withOpacity(0.08),
                  borderRadius: AppTheme.radiusSm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, size: 14, color: AppTheme.brandPrimary),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat("dd MMM").format(history.startDate!)} — ${DateFormat("dd MMM").format(history.endDate!)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.brandPrimary),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => history.setDateRange(null, null),
                      child: const Icon(Icons.close, size: 16, color: AppTheme.brandPrimary),
                    ),
                  ],
                ),
              ),
            ),

          // 3. BILLS LIST
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => history.loadBills(),
              child: history.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : history.bills.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: AppTheme.spaceMd),
                              const Text('No bills match your search', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              const Text('Try modifying your query or filters.', style: TextStyle(color: AppTheme.textSecondaryLight)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppTheme.spaceLg),
                          itemCount: history.bills.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceSm),
                          itemBuilder: (context, index) {
                            final bill = history.bills[index];
                            return _buildBillCard(context, bill, currencyFormat);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, BillsHistoryProvider history) {
    final isSelected = history.paymentStatusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : null,
      ),
      selectedColor: AppTheme.brandPrimary,
      onSelected: (_) => history.setPaymentFilter(value),
    );
  }

  Widget _buildBillCard(BuildContext context, Bill bill, NumberFormat currencyFormat) {
    final isCancelled = bill.status == BillStatus.cancelled;
    Color paymentColor = AppTheme.brandSuccess;
    if (bill.paymentStatus == PaymentStatus.unpaid) paymentColor = AppTheme.brandDanger;
    if (bill.paymentStatus == PaymentStatus.partial) paymentColor = AppTheme.brandWarning;
    if (isCancelled) paymentColor = Colors.grey;

    return Card(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Customer Name & Payment Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            bill.customerName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCancelled) ...[
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
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: paymentColor.withOpacity(0.12),
                      borderRadius: AppTheme.radiusPill,
                    ),
                    child: Text(
                      bill.paymentStatus.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: paymentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Middle Row: Bill Number & Date
              Text(
                '${bill.billNumber} • ${DateFormat("dd-MMM-yyyy hh:mm a").format(bill.billDate)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
              ),

              const Divider(height: 16),

              // Bottom Row: Created by, Cloud sync icon, and Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        bill.syncStatus == SyncStatus.synced
                            ? Icons.cloud_done
                            : bill.syncStatus == SyncStatus.failed
                                ? Icons.cloud_off
                                : Icons.cloud_upload_outlined,
                        size: 16,
                        color: bill.syncStatus == SyncStatus.synced
                            ? AppTheme.brandSuccess
                            : bill.syncStatus == SyncStatus.failed
                                ? AppTheme.brandDanger
                                : AppTheme.brandWarning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'By ${bill.createdByName}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs. ${currencyFormat.format(bill.grandTotal)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      if (bill.balanceAmount > 0)
                        Text(
                          'Bal: Rs. ${currencyFormat.format(bill.balanceAmount)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.brandDanger),
                        ),
                    ],
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
