import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import '../../models/bill.dart';

/// Offline-First Synchronization Service for Mashallah Crockery.
/// Coordinates bidirectional data sync between local SQLite and Supabase PostgreSQL.
class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  bool _isSyncing = false;
  int _pendingCount = 0;
  DateTime? _lastSyncTime;
  String? _syncErrorMessage;
  bool _isOnline = false;
  StreamSubscription? _connectivitySubscription;

  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncErrorMessage => _syncErrorMessage;
  bool get isOnline => _isOnline;

  /// Initializes connectivity listener and sync state.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncIso = prefs.getString(AppConstants.keyLastSyncTime);
    if (lastSyncIso != null) {
      _lastSyncTime = DateTime.tryParse(lastSyncIso);
    }

    // Check initial connectivity
    final connectivityResults = await Connectivity().checkConnectivity();
    _isOnline = !connectivityResults.contains(ConnectivityResult.none);

    // Listen to network changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);
      notifyListeners();

      // Automatically sync when internet returns
      if (wasOffline && _isOnline) {
        debugPrint('[SyncService] Network restored. Triggering automatic sync.');
        syncAllPending();
      }
    });

    await updatePendingCount();
  }

  /// Updates count of unsynced local bills.
  Future<void> updatePendingCount() async {
    final pending = await DbHelper.instance.getPendingSyncBills();
    _pendingCount = pending.length;
    notifyListeners();
  }

  /// Triggers full synchronization (Push local pending -> Pull cloud updates).
  Future<bool> syncAllPending() async {
    if (_isSyncing) return false;

    // Check internet
    if (!_isOnline) {
      _syncErrorMessage = 'No internet connection. Changes queued locally.';
      notifyListeners();
      return false;
    }

    // Verify Supabase client initialized
    SupabaseClient? client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      client = null;
    }

    if (client == null) {
      _syncErrorMessage = 'Supabase cloud credentials not initialized.';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _syncErrorMessage = null;
    notifyListeners();

    try {
      // 1. PUSH LOCAL PENDING BILLS TO CLOUD
      final pendingBills = await DbHelper.instance.getPendingSyncBills();
      int successCount = 0;

      for (final bill in pendingBills) {
        try {
          final billMap = bill.toMap();
          final itemsMap = bill.items.map((it) => it.toMap()).toList();

          // Execute atomic sync RPC function
          await client.rpc('sync_bill_with_items', params: {
            'p_bill': billMap,
            'p_items': itemsMap,
          });

          await DbHelper.instance.markBillSynced(bill.id);
          successCount++;
        } catch (itemErr) {
          debugPrint('[SyncService] Failed to sync bill ${bill.billNumber}: $itemErr');
          await DbHelper.instance.markBillSyncFailed(bill.id, itemErr.toString());
        }
      }

      // 2. PULL CLOUD BILLS (From other shopkeepers)
      await _pullCloudBills(client);

      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyLastSyncTime, _lastSyncTime!.toIso8601String());

      await updatePendingCount();
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[SyncService] Global sync error: $e');
      _syncErrorMessage = e.toString();
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Pulls recent bills created by other shopkeepers on other devices.
  Future<void> _pullCloudBills(SupabaseClient client) async {
    try {
      final since = _lastSyncTime ?? DateTime.now().subtract(const Duration(days: 7));
      final response = await client
          .from('bills')
          .select('*, bill_items(*)')
          .gte('updated_at', since.toIso8601String())
          .limit(100);

      final List<dynamic> cloudBills = response as List<dynamic>;
      for (final row in cloudBills) {
        final Map<String, dynamic> bMap = Map<String, dynamic>.from(row as Map);
        final rawItems = bMap['bill_items'] as List<dynamic>? ?? [];
        final items = rawItems
            .map((im) => BillItem.fromMap(Map<String, dynamic>.from(im as Map)))
            .toList();

        bMap['sync_status'] = 'synced';
        final cloudBill = Bill.fromMap(bMap, items: items);

        // Save into local SQLite without re-queueing to sync
        await DbHelper.instance.saveBill(cloudBill, items);
        await DbHelper.instance.markBillSynced(cloudBill.id);
      }
    } catch (e) {
      debugPrint('[SyncService] Error pulling cloud bills: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
