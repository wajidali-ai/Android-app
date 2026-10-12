import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/database/db_helper.dart';
import '../models/bill.dart';
import '../providers/printer_provider.dart';
import '../providers/bills_history_provider.dart';
import '../providers/dashboard_provider.dart';
import 'bluetooth_printer_screen.dart';

class BillDetailScreen extends StatefulWidget {
  final String billId;

  const BillDetailScreen({super.key, required this.billId});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  Bill? _bill;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  Future<void> _loadBill() async {
    final b = await DbHelper.instance.getBillWithItems(widget.billId);
    if (mounted) {
      setState(() {
        _bill = b;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleReprint() async {
    if (_bill == null) return;
    final printer = context.read<PrinterProvider>();

    if (!printer.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Printer not connected. Please connect via Bluetooth Settings.'),
          action: SnackBarAction(
            label: 'Connect',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BluetoothPrinterScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    final success = await printer.printBill(_bill!, isReprint: true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Receipt reprinted!' : 'Reprint failed. Check printer connection.'),
        ),
      );
    }
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancel / Void Bill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will void the transaction for audit records. The bill will remain in the database marked as CANCELLED.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryLight),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Mandatory Reason for Cancellation',
                  hintText: 'e.g. Customer returned goods / Wrong entry',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandDanger),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a cancellation reason.')),
                  );
                  return;
                }
                Navigator.pop(ctx);

                final history = context.read<BillsHistoryProvider>();
                final dash = context.read<DashboardProvider>();

                await history.cancelBill(_bill!.id, reason, _bill!.createdByName);
                await dash.loadTodaySummary();
                await _loadBill();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bill has been cancelled for audit.')),
                  );
                }
              },
              child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bill Not Found')),
        body: const Center(child: Text('This bill could not be found.')),
      );
    }

    final bill = _bill!;
    final isCancelled = bill.status == BillStatus.cancelled;

    Color paymentColor = AppTheme.brandSuccess;
    if (bill.paymentStatus == PaymentStatus.unpaid) paymentColor = AppTheme.brandDanger;
    if (bill.paymentStatus == PaymentStatus.partial) paymentColor = AppTheme.brandWarning;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bill #${bill.billNumber}', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Reprint Receipt',
            icon: const Icon(Icons.print),
            onPressed: _handleReprint,
          ),
          if (!isCancelled)
            IconButton(
              tooltip: 'Cancel / Void Bill',
              icon: const Icon(Icons.cancel_outlined, color: AppTheme.brandDanger),
              onPressed: _showCancelDialog,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        children: [
          // CANCELLED BANNER (If applicable)
          if (isCancelled) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: AppTheme.radiusMd,
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'TRANSACTION CANCELLED / VOIDED',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reason: ${bill.cancellationReason ?? "No reason specified"}',
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  if (bill.cancelledAt != null)
                    Text(
                      'Date: ${DateFormat("dd-MMM-yyyy hh:mm a").format(bill.cancelledAt!)}',
                      style: const TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
          ],

          // RECEIPT METADATA CARD
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        bill.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: paymentColor.withOpacity(0.12),
                          borderRadius: AppTheme.radiusPill,
                        ),
                        child: Text(
                          bill.paymentStatus.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: paymentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (bill.customerPhone != null && bill.customerPhone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('Phone: ${bill.customerPhone}', style: const TextStyle(color: AppTheme.textSecondaryLight)),
                  ],
                  const Divider(height: 20),
                  _buildMetaRow('Bill Number', bill.billNumber),
                  _buildMetaRow('Date & Time', DateFormat('dd-MMM-yyyy  hh:mm a').format(bill.billDate)),
                  _buildMetaRow('Created By', '${bill.createdByName} (${bill.deviceId})'),
                  _buildMetaRow('Payment Method', bill.paymentMethod.name.toUpperCase()),
                  _buildMetaRow(
                    'Cloud Sync Status',
                    bill.syncStatus.name.toUpperCase(),
                    valueColor: bill.syncStatus == SyncStatus.synced
                        ? AppTheme.brandSuccess
                        : AppTheme.brandWarning,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spaceMd),

          // LINE ITEMS CARD
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Line Items (Crockery)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  const Divider(),
                  ...bill.items.map((it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it.itemName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  Text(
                                    '${it.quantity.toStringAsFixed(it.quantity % 1 == 0 ? 0 : 2)} × Rs.${it.unitPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Rs. ${currencyFormat.format(it.lineTotal)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 24),

                  // TOTALS BREAKDOWN
                  _buildAmountRow('Subtotal', 'Rs. ${currencyFormat.format(bill.subtotal)}'),
                  if (bill.discount > 0)
                    _buildAmountRow('Discount', '- Rs. ${currencyFormat.format(bill.discount)}', isNegative: true),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'GRAND TOTAL',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Rs. ${currencyFormat.format(bill.grandTotal)}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildAmountRow('Paid Amount', 'Rs. ${currencyFormat.format(bill.paidAmount)}', isBold: true),
                  if (bill.balanceAmount > 0)
                    _buildAmountRow(
                      'Remaining Balance',
                      'Rs. ${currencyFormat.format(bill.balanceAmount)}',
                      isDanger: true,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spaceLg),

          // REPRINT ACTION BUTTON
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPrimary,
              minimumSize: const Size(AppTheme.minTouchTarget, 52),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
            ),
            onPressed: _handleReprint,
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text(
              'Reprint Thermal Receipt',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryLight)),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String value, {bool isNegative = false, bool isBold = false, bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold || isDanger ? FontWeight.bold : FontWeight.normal,
              color: isDanger ? AppTheme.brandDanger : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold || isDanger ? FontWeight.bold : FontWeight.normal,
              color: isNegative
                  ? AppTheme.brandSuccess
                  : isDanger
                      ? AppTheme.brandDanger
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}
