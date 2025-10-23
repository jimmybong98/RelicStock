import 'locker.dart';

class Item {
  const Item({
    required this.id,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.minimumQuantity,
    this.description,
    this.locker,
  });

  final int id;
  final String name;
  final String sku;
  final int quantity;
  final int minimumQuantity;
  final String? description;
  final Locker? locker;

  bool get isLowStock => quantity <= minimumQuantity;

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String,
      quantity: json['quantity'] as int,
      minimumQuantity: json['minimum_quantity'] as int? ?? json['minimumQuantity'] as int? ?? 0,
      description: json['description'] as String?,
      locker: json['locker'] != null ? Locker.fromJson(json['locker'] as Map<String, dynamic>) : null,
    );
  }
}
