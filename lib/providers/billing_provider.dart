import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bill.dart';
import '../../models/bill_item.dart';
import '../constants/app_constants.dart';
import '../database/db_helper.dart';
import '../sync/sync_service.dart';

/// Manages state for the active billing transaction.
class BillingProvider extends ChangeNotifier {
  String _customerName = 'Walk-in Customer';
  String _customerPhone = '';
  String? _customerId;

  final List<BillItem> _items = [];
  double _discount = 0.0;
  double _paidAmount = 0.0;
  bool _isAutoPaid = true; // Automatically sets paidAmount = grandTotal by default
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  bool _isSaving = false;
  String? _errorMessage;

  // Getters
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String? get customerId => _customerId;
  List<BillItem> get items => List.unmodifiable(_items);
  double get discount => _discount;
  double get paidAmount => _paidAmount;
  bool get isAutoPaid => _isAutoPaid;
  PaymentMethod get paymentMethod => _paymentMethod;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  // Calculated totals
  double get subtotal => _items.fold(0.0, (sum, it) => sum + it.lineTotal);
  double get grandTotal {
    final total = subtotal - _discount;
    return total > 0 ? total : 0.0;
  }
  double get balanceAmount {
    final bal = grandTotal - _paidAmount;
    return bal > 0 ? bal : 0.0;
  }

  PaymentStatus get paymentStatus {
    if (_paidAmount >= grandTotal && grandTotal > 0) return PaymentStatus.paid;
    if (_paidAmount > 0 && _paidAmount < grandTotal) return PaymentStatus.partial;
    return PaymentStatus.unpaid;
  }

  // Setters & Mutators
  void setCustomer({required String name, String? phone, String? id}) {
    _customerName = name.trim().isEmpty ? 'Walk-in Customer' : name.trim();
    _customerPhone = phone?.trim() ?? '';
    _customerId = id;
    notifyListeners();
  }

  void addItem({
    required String name,
    required double quantity,
    required double unitPrice,
  }) {
    if (name.trim().isEmpty || quantity <= 0 || unitPrice < 0) return;

    // Check if item with exact same name & price already in list, if so increment
    final existingIdx = _items.indexWhere(
      (it) => it.itemName.toLowerCase() == name.trim().toLowerCase() && it.unitPrice == unitPrice,
    );

    if (existingIdx != -1) {
      final existing = _items[existingIdx];
      final newQty = existing.quantity + quantity;
      _items[existingIdx] = existing.copyWith(
        quantity: newQty,
        lineTotal: newQty * existing.unitPrice,
      );
    } else {
      _items.add(
        BillItem(
          billId: '', // Will be assigned on save
          itemName: name.trim(),
          quantity: quantity,
          unitPrice: unitPrice,
          lineTotal: quantity * unitPrice,
          sortOrder: _items.length,
        ),
      );
    }

    if (_isAutoPaid) {
      _paidAmount = grandTotal;
    }
    notifyListeners();
  }

  void updateItemQuantity(int index, double newQuantity) {
    if (index < 0 || index >= _items.length) return;
    if (newQuantity <= 0) {
      removeItem(index);
      return;
    }

    final item = _items[index];
    _items[index] = item.copyWith(
      quantity: newQuantity,
      lineTotal: newQuantity * item.unitPrice,
    );

    if (_isAutoPaid) {
      _paidAmount = grandTotal;
    }
    notifyListeners();
  }

  void removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    if (_isAutoPaid) {
      _paidAmount = grandTotal;
    }
    notifyListeners();
  }

  void setDiscount(double value) {
    _discount = value < 0 ? 0.0 : value;
    if (_isAutoPaid) {
      _paidAmount = grandTotal;
    }
    notifyListeners();
  }

  void setPaidAmount(double value, {bool manual = true}) {
    _paidAmount = value < 0 ? 0.0 : value;
    if (manual) {
      _isAutoPaid = false;
    }
    notifyListeners();
  }

  void setAutoPaid(bool value) {
    _isAutoPaid = value;
    if (value) {
      _paidAmount = grandTotal;
    }
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    if (method == PaymentMethod.credit) {
      _paidAmount = 0.0;
      _isAutoPaid = false;
    }
    notifyListeners();
  }

  /// Saves the bill and items to SQLite immediately.
  /// Generates human-readable sequential bill number.
  /// Queues for Supabase cloud sync.
  Future<Bill?> saveBill() async {
    if (_items.isEmpty) {
      _errorMessage = 'Please add at least one item to create a bill.';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final shopkeeperName = prefs.getString(AppConstants.keyShopkeeperName) ?? 'Main Counter';
      final shopkeeperId = prefs.getString(AppConstants.keyShopkeeperId);
      final deviceId = prefs.getString(AppConstants.keyDeviceId) ?? 'D1';

      // 1. Generate unique sequential bill number
      final billNumber = await DbHelper.instance.generateNextBillNumber(deviceId);

      // 2. Construct Bill model
      final bill = Bill(
        shopId: AppConstants.defaultShopId,
        billNumber: billNumber,
        customerId: _customerId,
        customerName: _customerName,
        customerPhone: _customerPhone.isEmpty ? null : _customerPhone,
        createdByMemberId: shopkeeperId,
        createdByName: shopkeeperName,
        deviceId: deviceId,
        billDate: DateTime.now(),
        subtotal: subtotal,
        discount: _discount,
        grandTotal: grandTotal,
        paidAmount: _paidAmount,
        balanceAmount: balanceAmount,
        paymentStatus: paymentStatus,
        paymentMethod: _paymentMethod,
        items: _items,
      );

      // 3. Save to local SQLite immediately
      final savedBill = await DbHelper.instance.saveBill(bill, _items);

      // 4. Update sync queue
      SyncService.instance.updatePendingCount();

      // Trigger background sync if online
      if (SyncService.instance.isOnline) {
        SyncService.instance.syncAllPending();
      }

      _isSaving = false;
      notifyListeners();
      return savedBill;
    } catch (e) {
      debugPrint('[BillingProvider] Error saving bill: $e');
      _errorMessage = 'Failed to save bill: $e';
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }

  /// Resets the billing screen for a fresh transaction.
  void reset() {
    _customerName = 'Walk-in Customer';
    _customerPhone = '';
    _customerId = null;
    _items.clear();
    _discount = 0.0;
    _paidAmount = 0.0;
    _isAutoPaid = true;
    _paymentMethod = PaymentMethod.cash;
    _errorMessage = null;
    _isSaving = false;
    notifyListeners();
  }
}
