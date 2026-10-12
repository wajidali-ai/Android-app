import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';

/// Manages data for the live sales dashboard and reports.
class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;

  // Today's metrics
  int _todayBillCount = 0;
  double _todaySales = 0.0;
  double _todayPaid = 0.0;
  double _todayBalance = 0.0;
  double _todayCash = 0.0;
  double _todayOnline = 0.0;

  // Periodic Report data
  Map<String, dynamic> _reportData = {};
  String _selectedReportPeriod = 'daily'; // 'daily', 'weekly', 'monthly'

  bool get isLoading => _isLoading;
  int get todayBillCount => _todayBillCount;
  double get todaySales => _todaySales;
  double get todayPaid => _todayPaid;
  double get todayBalance => _todayBalance;
  double get todayCash => _todayCash;
  double get todayOnline => _todayOnline;
  Map<String, dynamic> get reportData => _reportData;
  String get selectedReportPeriod => _selectedReportPeriod;

  /// Loads today's live summary from SQLite.
  Future<void> loadTodaySummary() async {
    _isLoading = true;
    notifyListeners();

    try {
      final summary = await DbHelper.instance.getTodaySalesSummary();
      _todayBillCount = (summary['bill_count'] as num?)?.toInt() ?? 0;
      _todaySales = (summary['total_sales'] as num?)?.toDouble() ?? 0.0;
      _todayPaid = (summary['total_paid'] as num?)?.toDouble() ?? 0.0;
      _todayBalance = (summary['total_balance'] as num?)?.toDouble() ?? 0.0;
      _todayCash = (summary['cash_collected'] as num?)?.toDouble() ?? 0.0;
      _todayOnline = (summary['online_collected'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('[DashboardProvider] Error loading today summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads reports for daily, weekly, or monthly periods.
  Future<void> loadReport(String period) async {
    _selectedReportPeriod = period;
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      DateTime start;
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

      if (period == 'daily') {
        start = DateTime(now.year, now.month, now.day);
      } else if (period == 'weekly') {
        start = now.subtract(const Duration(days: 7));
      } else {
        // monthly
        start = DateTime(now.year, now.month, 1);
      }

      _reportData = await DbHelper.instance.getSalesReport(start, end);
    } catch (e) {
      debugPrint('[DashboardProvider] Error loading report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
