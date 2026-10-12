import 'package:uuid/uuid.dart';

class Shop {
  final String id;
  final String name;
  final String? tagline;
  final String? address;
  final String? phone;
  final String receiptHeader;
  final String receiptFooter;
  final DateTime createdAt;

  Shop({
    String? id,
    required this.name,
    this.tagline,
    this.address,
    this.phone,
    String? receiptHeader,
    String? receiptFooter,
    DateTime? createdAt,
  })  : id = id ?? '00000000-0000-0000-0000-000000000001',
        receiptHeader = receiptHeader ?? '*** MASHALLAH CROCKERY ***\nShop #14, Main Crockery Bazaar\nTel: 0300-8451234',
        receiptFooter = receiptFooter ?? 'Thank you for shopping with us!\nExchange within 3 days with bill.',
        createdAt = createdAt ?? DateTime.now();

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'] as String,
      name: map['name'] as String,
      tagline: map['tagline'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      receiptHeader: map['receipt_header'] as String?,
      receiptFooter: map['receipt_footer'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'address': address,
      'phone': phone,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ShopMember {
  final String id;
  final String shopId;
  final String name;
  final String? phone;
  final String role;
  final String? pinCode;
  final bool isActive;

  ShopMember({
    String? id,
    required this.shopId,
    required this.name,
    this.phone,
    this.role = 'shopkeeper',
    this.pinCode,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4();

  factory ShopMember.fromMap(Map<String, dynamic> map) {
    return ShopMember(
      id: map['id'] as String,
      shopId: map['shop_id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      role: map['role'] as String? ?? 'shopkeeper',
      pinCode: map['pin_code'] as String?,
      isActive: (map['is_active'] as num?)?.toInt() == 1 || map['is_active'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'phone': phone,
      'role': role,
      'pin_code': pinCode,
      'is_active': isActive ? 1 : 0,
    };
  }
}
