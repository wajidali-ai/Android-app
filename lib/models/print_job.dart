import 'package:uuid/uuid.dart';

enum PrintStatus { pending, success, failed }

/// Tracks Bluetooth printer attempts and status for auditability
class PrintJob {
  final String id;
  final String billId;
  final String? printerName;
  final String? printerMac;
  final PrintStatus status;
  final String? errorMessage;
  final DateTime attemptedAt;

  PrintJob({
    String? id,
    required this.billId,
    this.printerName,
    this.printerMac,
    this.status = PrintStatus.pending,
    this.errorMessage,
    DateTime? attemptedAt,
  })  : id = id ?? const Uuid().v4(),
        attemptedAt = attemptedAt ?? DateTime.now();

  factory PrintJob.fromMap(Map<String, dynamic> map) {
    return PrintJob(
      id: map['id'] as String,
      billId: map['bill_id'] as String,
      printerName: map['printer_name'] as String?,
      printerMac: map['printer_mac'] as String?,
      status: map['status'] == 'success'
          ? PrintStatus.success
          : map['status'] == 'failed'
              ? PrintStatus.failed
              : PrintStatus.pending,
      errorMessage: map['error_message'] as String?,
      attemptedAt: map['attempted_at'] != null
          ? DateTime.parse(map['attempted_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_id': billId,
      'printer_name': printerName,
      'printer_mac': printerMac,
      'status': status.name,
      'error_message': errorMessage,
      'attempted_at': attemptedAt.toIso8601String(),
    };
  }
}

/// Helper model for fast item autocomplete during billing.
/// NOTE: This does NOT track stock quantities, only frequent names & usual prices.
class FrequentItem {
  final String id;
  final String shopId;
  final String itemName;
  final double defaultUnitPrice;
  final int usageCount;

  FrequentItem({
    String? id,
    required this.shopId,
    required this.itemName,
    this.defaultUnitPrice = 0.0,
    this.usageCount = 1,
  }) : id = id ?? const Uuid().v4();

  factory FrequentItem.fromMap(Map<String, dynamic> map) {
    return FrequentItem(
      id: map['id'] as String,
      shopId: map['shop_id'] as String,
      itemName: map['item_name'] as String,
      defaultUnitPrice: (map['default_unit_price'] as num?)?.toDouble() ?? 0.0,
      usageCount: (map['usage_count'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'item_name': itemName,
      'default_unit_price': defaultUnitPrice,
      'usage_count': usageCount,
    };
  }
}
