import 'package:uuid/uuid.dart';
import 'bill_item.dart';

enum PaymentStatus { paid, partial, unpaid }
enum PaymentMethod { cash, online, credit }
enum BillStatus { active, cancelled }
enum SyncStatus { pending, synced, failed }

/// Main Bill model for Mashallah Crockery.
class Bill {
  final String id;
  final String shopId;
  final String billNumber;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final String? createdByMemberId;
  final String createdByName;
  final String deviceId;
  final DateTime billDate;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final double paidAmount;
  final double balanceAmount;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final BillStatus status;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String? syncError;
  final List<BillItem> items;

  Bill({
    String? id,
    required this.shopId,
    required this.billNumber,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    this.createdByMemberId,
    required this.createdByName,
    required this.deviceId,
    DateTime? billDate,
    required this.subtotal,
    this.discount = 0.0,
    required this.grandTotal,
    required this.paidAmount,
    required this.balanceAmount,
    this.paymentStatus = PaymentStatus.paid,
    this.paymentMethod = PaymentMethod.cash,
    this.status = BillStatus.active,
    this.cancellationReason,
    this.cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.pending,
    this.syncError,
    this.items = const [],
  })  : id = id ?? const Uuid().v4(),
        billDate = billDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Bill.fromMap(Map<String, dynamic> map, {List<BillItem>? items}) {
    return Bill(
      id: map['id'] as String,
      shopId: map['shop_id'] as String,
      billNumber: map['bill_number'] as String,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String?,
      createdByMemberId: map['created_by_member_id'] as String?,
      createdByName: map['created_by_name'] as String? ?? 'Shopkeeper',
      deviceId: map['device_id'] as String? ?? 'DEFAULT-DEVICE',
      billDate: map['bill_date'] != null
          ? DateTime.parse(map['bill_date'] as String)
          : DateTime.now(),
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num).toDouble(),
      balanceAmount: (map['balance_amount'] as num).toDouble(),
      paymentStatus: _parsePaymentStatus(map['payment_status'] as String?),
      paymentMethod: _parsePaymentMethod(map['payment_method'] as String?),
      status: map['status'] == 'cancelled' ? BillStatus.cancelled : BillStatus.active,
      cancellationReason: map['cancellation_reason'] as String?,
      cancelledAt: map['cancelled_at'] != null
          ? DateTime.parse(map['cancelled_at'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
      syncStatus: _parseSyncStatus(map['sync_status'] as String?),
      syncError: map['sync_error'] as String?,
      items: items ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'bill_number': billNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'created_by_member_id': createdByMemberId,
      'created_by_name': createdByName,
      'device_id': deviceId,
      'bill_date': billDate.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'balance_amount': balanceAmount,
      'payment_status': paymentStatus.name,
      'payment_method': paymentMethod.name,
      'status': status.name,
      'cancellation_reason': cancellationReason,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus.name,
      'sync_error': syncError,
    };
  }

  Bill copyWith({
    String? id,
    String? shopId,
    String? billNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? createdByMemberId,
    String? createdByName,
    String? deviceId,
    DateTime? billDate,
    double? subtotal,
    double? discount,
    double? grandTotal,
    double? paidAmount,
    double? balanceAmount,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    BillStatus? status,
    String? cancellationReason,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    String? syncError,
    List<BillItem>? items,
  }) {
    return Bill(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      billNumber: billNumber ?? this.billNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      createdByMemberId: createdByMemberId ?? this.createdByMemberId,
      createdByName: createdByName ?? this.createdByName,
      deviceId: deviceId ?? this.deviceId,
      billDate: billDate ?? this.billDate,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      items: items ?? this.items,
    );
  }

  static PaymentStatus _parsePaymentStatus(String? status) {
    if (status == 'unpaid') return PaymentStatus.unpaid;
    if (status == 'partial') return PaymentStatus.partial;
    return PaymentStatus.paid;
  }

  static PaymentMethod _parsePaymentMethod(String? method) {
    if (method == 'online') return PaymentMethod.online;
    if (method == 'credit') return PaymentMethod.credit;
    return PaymentMethod.cash;
  }

  static SyncStatus _parseSyncStatus(String? status) {
    if (status == 'synced') return SyncStatus.synced;
    if (status == 'failed') return SyncStatus.failed;
    return SyncStatus.pending;
  }
}
