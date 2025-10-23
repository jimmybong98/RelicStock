class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.itemId,
    required this.quantity,
    required this.movementType,
    required this.createdAt,
    this.note,
  });

  final int id;
  final int itemId;
  final int quantity;
  final String movementType;
  final DateTime createdAt;
  final String? note;

  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: json['id'] as int,
      itemId: json['item_id'] as int,
      quantity: json['quantity'] as int,
      movementType: json['movement_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      note: json['note'] as String?,
    );
  }
}
