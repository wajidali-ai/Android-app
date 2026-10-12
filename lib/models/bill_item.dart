import 'package:uuid/uuid.dart';

/// Represents an individual item on a bill.
/// NOTE: This item is directly entered during billing and does NOT track stock quantity.
class BillItem {
  final String id;
  final String billId;
  final String itemName;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final int sortOrder;
  final DateTime createdAt;

  BillItem({
    String? id,
    required this.billId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    double? lineTotal,
    this.sortOrder = 0,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        lineTotal = lineTotal ?? (quantity * unitPrice),
        createdAt = createdAt ?? DateTime.now();

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'] as String,
      billId: map['bill_id'] as String,
      itemName: map['item_name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      lineTotal: (map['line_total'] as num).toDouble(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_id': billId,
      'item_name': itemName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BillItem copyWith({
    String? id,
    String? billId,
    String? itemName,
    double? quantity,
    double? unitPrice,
    double? lineTotal,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return BillItem(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? ((quantity ?? this.quantity) * (unitPrice ?? this.unitPrice)),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
