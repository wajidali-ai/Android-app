import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_theme.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import '../providers/customer_provider.dart';
import 'bill_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCustomerLedger(Customer customer) async {
    final provider = context.read<CustomerProvider>();
    final bills = await provider.getCustomerBillHistory(customer.id);
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: ListView(
                controller: scrollController,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          if (customer.phone != null)
                            Text(
                              customer.phone!,
                              style: const TextStyle(color: AppTheme.textSecondaryLight),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: customer.totalBalance > 0
                              ? AppTheme.brandDanger.withOpacity(0.12)
                              : AppTheme.brandSuccess.withOpacity(0.12),
                          borderRadius: AppTheme.radiusMd,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Outstanding Balance', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(
                              'Rs. ${currencyFormat.format(customer.totalBalance)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: customer.totalBalance > 0 ? AppTheme.brandDanger : AppTheme.brandSuccess,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    'Bill Purchase History (${bills.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  if (bills.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppTheme.spaceXl),
                      child: Center(child: Text('No recorded bills for this customer.')),
                    )
                  else
                    ...bills.map((b) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BillDetailScreen(billId: b.id)),
                              );
                            },
                            title: Text(
                              'Bill #${b.billNumber}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${DateFormat("dd-MMM-yyyy").format(b.billDate)} • ${b.paymentStatus.name.toUpperCase()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              'Rs. ${currencyFormat.format(b.grandTotal)}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                        )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerProv = context.watch<CustomerProvider>();
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers & Balances', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customer name or phone...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          customerProv.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => customerProv.setSearchQuery(val),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => customerProv.loadCustomers(),
              child: customerProv.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : customerProv.customers.isEmpty
                      ? const Center(child: Text('No customer records found.'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
                          itemCount: customerProv.customers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceSm),
                          itemBuilder: (context, index) {
                            final customer = customerProv.customers[index];
                            final hasBalance = customer.totalBalance > 0;

                            return Card(
                              child: ListTile(
                                onTap: () => _showCustomerLedger(customer),
                                leading: CircleAvatar(
                                  backgroundColor: hasBalance
                                      ? AppTheme.brandDanger.withOpacity(0.15)
                                      : AppTheme.brandPrimary.withOpacity(0.15),
                                  child: Text(
                                    customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                    style: TextStyle(
                                      color: hasBalance ? AppTheme.brandDanger : AppTheme.brandPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  customer.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                subtitle: Text(
                                  customer.phone != null && customer.phone!.isNotEmpty
                                      ? customer.phone!
                                      : 'No phone number',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Rs. ${currencyFormat.format(customer.totalBalance)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: hasBalance ? AppTheme.brandDanger : AppTheme.brandSuccess,
                                      ),
                                    ),
                                    Text(
                                      hasBalance ? 'Credit Due' : 'Cleared',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: hasBalance ? AppTheme.brandDanger : AppTheme.brandSuccess,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
