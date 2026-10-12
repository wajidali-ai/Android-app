import 'package:uuid/uuid.dart';

/// Customer model for tracking customer profiles, contact, and outstanding balance.
class Customer {
  final String id;
  final String shopId;
  final String name;
  final String? phone;
  final double totalBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    String? id,
    required this.shopId,
    required this.name,
    this.phone,
    this.totalBalance = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      shopId: map['shop_id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      totalBalance: (map['total_balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'phone': phone,
      'total_balance': totalBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? shopId,
    String? name,
    String? phone,
    double? totalBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalBalance: totalBalance ?? this.totalBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
