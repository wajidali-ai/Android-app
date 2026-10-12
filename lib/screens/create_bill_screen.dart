import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../models/bill.dart';
import '../providers/billing_provider.dart';
import '../providers/printer_provider.dart';
import '../providers/bills_history_provider.dart';
import '../providers/dashboard_provider.dart';
import 'bill_detail_screen.dart';
import 'bluetooth_printer_screen.dart';

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final _customerNameController = TextEditingController(text: 'Walk-in Customer');
  final _customerPhoneController = TextEditingController();

  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _unitPriceController = TextEditingController();
  final _discountController = TextEditingController();
  final _paidAmountController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _discountController.addListener(_onDiscountChanged);
    _paidAmountController.addListener(_onPaidAmountChanged);
  }

  void _onDiscountChanged() {
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    context.read<BillingProvider>().setDiscount(discount);
  }

  void _onPaidAmountChanged() {
    if (_paidAmountController.text.isNotEmpty) {
      final paid = double.tryParse(_paidAmountController.text) ?? 0.0;
      context.read<BillingProvider>().setPaidAmount(paid, manual: true);
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _discountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _itemNameController.text.trim();
    final qty = double.tryParse(_quantityController.text) ?? 1.0;
    final price = double.tryParse(_unitPriceController.text) ?? 0.0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name')),
      );
      return;
    }

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid unit price')),
      );
      return;
    }

    context.read<BillingProvider>().addItem(
      name: name,
      quantity: qty,
      unitPrice: price,
    );

    // Clear item inputs for next item
    _itemNameController.clear();
    _quantityController.text = '1';
    _unitPriceController.clear();
  }

  Future<void> _handleSave({bool andPrint = false}) async {
    final billing = context.read<BillingProvider>();
    final printer = context.read<PrinterProvider>();
    final history = context.read<BillsHistoryProvider>();
    final dash = context.read<DashboardProvider>();

    if (billing.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to save the bill.')),
      );
      return;
    }

    // Set Customer info
    billing.setCustomer(
      name: _customerNameController.text,
      phone: _customerPhoneController.text,
    );

    // 1. SAVE TO SQLITE FIRST (Mandatory requirement)
    final savedBill = await billing.saveBill();

    if (savedBill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(billing.errorMessage ?? 'Error saving bill')),
      );
      return;
    }

    // Refresh history & dashboard providers
    history.loadBills();
    dash.loadTodaySummary();

    // 2. ATTEMPT BLUETOOTH PRINTING IF REQUESTED
    if (andPrint) {
      if (!printer.isConnected) {
        // Show gentle notification that bill is saved and prompt printer connection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bill saved! Printer not connected. Connect in Printer Settings.'),
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
      } else {
        final printed = await printer.printBill(savedBill);
        if (!printed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Printing failed, but Bill is safely saved in SQLite!'),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill #${savedBill.billNumber} saved successfully!')),
      );
    }

    // Reset billing form
    billing.reset();
    _customerNameController.text = 'Walk-in Customer';
    _customerPhoneController.clear();
    _discountController.clear();
    _paidAmountController.clear();

    // Navigate to bill detail preview
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BillDetailScreen(billId: savedBill.id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final printer = context.watch<PrinterProvider>();
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    // Sync paid amount text field when auto-paid is active
    if (billing.isAutoPaid) {
      final autoPaidStr = billing.grandTotal.toStringAsFixed(0);
      if (_paidAmountController.text != autoPaidStr) {
        _paidAmountController.text = autoPaidStr;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Bill', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Bluetooth Printer',
            icon: Icon(
              Icons.print,
              color: printer.isConnected ? AppTheme.brandSuccess : Colors.grey,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BluetoothPrinterScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Reset Bill',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              billing.reset();
              _customerNameController.text = 'Walk-in Customer';
              _customerPhoneController.clear();
              _discountController.clear();
              _paidAmountController.clear();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              children: [
                // 1. CUSTOMER INFORMATION CARD
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Details',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: AppTheme.spaceSm),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _customerNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Customer Name',
                                  prefixIcon: Icon(Icons.person_outline, size: 20),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceMd),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _customerPhoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone (Optional)',
                                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spaceMd),

                // 2. QUICK-PICK CROCKERY ITEMS CHIP BAR (NO stock tracking)
                const Text(
                  'Quick-Pick Crockery Items',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondaryLight),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.starterFrequentItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = AppConstants.starterFrequentItems[index];
                      return ActionChip(
                        elevation: 0,
                        backgroundColor: AppTheme.surfaceSecondaryLight,
                        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusPill),
                        label: Text(
                          '${item['name']} (Rs.${(item['price'] as num).toInt()})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          billing.addItem(
                            name: item['name'] as String,
                            quantity: 1,
                            unitPrice: (item['price'] as num).toDouble(),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppTheme.spaceMd),

                // 3. ADD ITEM ENTRY SECTION
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Item to Bill',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: AppTheme.spaceSm),
                        TextField(
                          controller: _itemNameController,
                          decoration: const InputDecoration(
                            labelText: 'Item Name / Description',
                            hintText: 'e.g. 6 Pcs Glass Cups or Dinner Plate',
                            prefixIcon: Icon(Icons.coffee_outlined, size: 20),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceSm),
                        Row(
                          children: [
                            // Quantity with Quick Stepper
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  IconButton.filledTonal(
                                    style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
                                    icon: const Icon(Icons.remove, size: 16),
                                    onPressed: () {
                                      final current = double.tryParse(_quantityController.text) ?? 1;
                                      if (current > 1) {
                                        _quantityController.text = (current - 1).toInt().toString();
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: TextField(
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        labelText: 'Qty',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton.filledTonal(
                                    style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
                                    icon: const Icon(Icons.add, size: 16),
                                    onPressed: () {
                                      final current = double.tryParse(_quantityController.text) ?? 1;
                                      _quantityController.text = (current + 1).toInt().toString();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceMd),
                            // Unit Price
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _unitPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Unit Price (Rs)',
                                  prefixText: 'Rs. ',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceSm),
                            // Add button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(AppTheme.minTouchTarget, AppTheme.minTouchTarget),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onPressed: _addItem,
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spaceMd),

                // 4. ITEMS LIST TABLE
                if (billing.items.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items in Bill (${billing.items.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        'Subtotal: Rs. ${currencyFormat.format(billing.subtotal)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.brandPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: billing.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = billing.items[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            item.itemName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2)} × Rs.${item.unitPrice.toStringAsFixed(0)}',
                            style: const TextStyle(color: AppTheme.textSecondaryLight),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rs. ${currencyFormat.format(item.lineTotal)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => billing.removeItem(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.spaceMd),

                // 5. PAYMENT & TOTALS CARD
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    child: Column(
                      children: [
                        // Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                            Text('Rs. ${currencyFormat.format(billing.subtotal)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spaceSm),

                        // Discount Row
                        Row(
                          children: [
                            const Text('Discount:', style: TextStyle(fontSize: 14)),
                            const Spacer(),
                            SizedBox(
                              width: 140,
                              child: TextField(
                                controller: _discountController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  prefixText: 'Rs. ',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Grand Total (Prominent)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'GRAND TOTAL:',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'Rs. ${currencyFormat.format(billing.grandTotal)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Payment Status & Method Selector
                        Row(
                          children: [
                            const Text('Payment Mode: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            SegmentedButton<PaymentMethod>(
                              segments: const [
                                ButtonSegment(value: PaymentMethod.cash, label: Text('Cash', style: TextStyle(fontSize: 11))),
                                ButtonSegment(value: PaymentMethod.online, label: Text('Online', style: TextStyle(fontSize: 11))),
                                ButtonSegment(value: PaymentMethod.credit, label: Text('Credit', style: TextStyle(fontSize: 11))),
                              ],
                              selected: {billing.paymentMethod},
                              onSelectionChanged: (set) {
                                billing.setPaymentMethod(set.first);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTheme.spaceMd),

                        // Paid Amount and Balance
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _paidAmountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount Paid (Rs)',
                                  prefixText: 'Rs. ',
                                  isDense: true,
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.check_circle_outline, size: 20),
                                    tooltip: 'Full Payment',
                                    onPressed: () => billing.setAutoPaid(true),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceMd),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: billing.balanceAmount > 0
                                      ? AppTheme.brandDanger.withOpacity(0.1)
                                      : AppTheme.brandSuccess.withOpacity(0.1),
                                  borderRadius: AppTheme.radiusMd,
                                  border: Border.all(
                                    color: billing.balanceAmount > 0 ? AppTheme.brandDanger : AppTheme.brandSuccess,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      billing.balanceAmount > 0 ? 'Remaining Balance' : 'Fully Paid',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: billing.balanceAmount > 0 ? AppTheme.brandDanger : AppTheme.brandSuccess,
                                      ),
                                    ),
                                    Text(
                                      'Rs. ${currencyFormat.format(billing.balanceAmount)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: billing.balanceAmount > 0 ? AppTheme.brandDanger : AppTheme.brandSuccess,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 6. BOTTOM ACTION BAR (Save & Print)
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Save Only
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(AppTheme.minTouchTarget, 52),
                        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                        side: const BorderSide(color: AppTheme.brandPrimary, width: 1.5),
                      ),
                      onPressed: billing.isSaving ? null : () => _handleSave(andPrint: false),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Only', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),

                  // Save & Print Receipt
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandPrimary,
                        minimumSize: const Size(AppTheme.minTouchTarget, 52),
                        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
                      ),
                      onPressed: billing.isSaving ? null : () => _handleSave(andPrint: true),
                      icon: const Icon(Icons.print, color: Colors.white),
                      label: const Text(
                        'Save & Print Receipt',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
