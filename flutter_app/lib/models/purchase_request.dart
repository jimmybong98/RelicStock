class PurchaseRequest {
  const PurchaseRequest({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.status,
    required this.createdAt,
    this.itemId,
    this.requestedBy,
    this.notes,
  });

  final int id;
  final String itemName;
  final int quantity;
  final String status;
  final DateTime createdAt;
  final int? itemId;
  final String? requestedBy;
  final String? notes;

  bool get isPending => status == 'pending';

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) {
    return PurchaseRequest(
      id: json['id'] as int,
      itemName: json['item_name'] as String,
      quantity: json['quantity'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      itemId: json['item_id'] as int?,
      requestedBy: json['requested_by'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
