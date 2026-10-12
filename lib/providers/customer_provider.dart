import 'package:flutter/foundation.dart';
import '../../models/customer.dart';
import '../../models/bill.dart';
import '../database/db_helper.dart';

/// Manages customer profiles, outstanding balance ledgers, and bill history.
class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Customer> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _customers = await DbHelper.instance.getCustomers(query: _searchQuery);
    } catch (e) {
      debugPrint('[CustomerProvider] Error loading customers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadCustomers();
  }

  /// Fetches bill history for a specific customer.
  Future<List<Bill>> getCustomerBillHistory(String customerId) async {
    final db = await DbHelper.instance.database;
    final rows = await db.query(
      'bills',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'bill_date DESC',
    );

    final List<Bill> list = [];
    for (final r in rows) {
      final bill = await DbHelper.instance.getBillWithItems(r['id'] as String);
      if (bill != null) list.add(bill);
    }
    return list;
  }
}
