import 'package:flutter/foundation.dart';
import '../../models/bill.dart';
import '../database/db_helper.dart';
import '../sync/sync_service.dart';

/// Manages bill history listing, search, filtering, and cancellations.
class BillsHistoryProvider extends ChangeNotifier {
  List<Bill> _bills = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _paymentStatusFilter = 'all'; // 'all', 'paid', 'partial', 'unpaid'
  DateTime? _startDate;
  DateTime? _endDate;

  List<Bill> get bills => List.unmodifiable(_bills);
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get paymentStatusFilter => _paymentStatusFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  /// Loads bills from local SQLite with current search and filters applied.
  Future<void> loadBills() async {
    _isLoading = true;
    notifyListeners();

    try {
      _bills = await DbHelper.instance.getBills(
        searchQuery: _searchQuery,
        paymentStatus: _paymentStatusFilter,
        startDate: _startDate,
        endDate: _endDate,
        limit: 100,
      );
    } catch (e) {
      debugPrint('[BillsHistoryProvider] Error loading bills: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadBills();
  }

  void setPaymentFilter(String status) {
    _paymentStatusFilter = status;
    loadBills();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    loadBills();
  }

  void clearFilters() {
    _searchQuery = '';
    _paymentStatusFilter = 'all';
    _startDate = null;
    _endDate = null;
    loadBills();
  }

  /// Cancels a bill with a mandatory audit reason.
  Future<bool> cancelBill(String billId, String reason, String shopkeeperName) async {
    try {
      await DbHelper.instance.cancelBill(billId, reason, shopkeeperName);
      await loadBills();
      // Queue update for sync
      SyncService.instance.updatePendingCount();
      return true;
    } catch (e) {
      debugPrint('[BillsHistoryProvider] Error cancelling bill: $e');
      return false;
    }
  }
}
