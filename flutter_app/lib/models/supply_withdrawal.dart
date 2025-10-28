import 'item.dart';

class SupplyWithdrawal {
  const SupplyWithdrawal({
    required this.id,
    required this.item,
    required this.quantityWithdrawn,
    required this.quantityReturned,
    required this.withdrawnAt,
    this.dueAt,
    this.returnedAt,
    this.note,
  });

  final int id;
  final Item item;
  final int quantityWithdrawn;
  final int quantityReturned;
  final DateTime withdrawnAt;
  final DateTime? dueAt;
  final DateTime? returnedAt;
  final String? note;

  int get pendingQuantity => quantityWithdrawn - quantityReturned;

  bool get isPending => pendingQuantity > 0;

  bool get isOverdue {
    if (!isPending || dueAt == null) {
      return false;
    }
    return DateTime.now().isAfter(dueAt!);
  }

  factory SupplyWithdrawal.fromJson(Map<String, dynamic> json) {
    return SupplyWithdrawal(
      id: json['id'] as int,
      item: Item.fromJson(json['item'] as Map<String, dynamic>),
      quantityWithdrawn: json['quantity_withdrawn'] as int,
      quantityReturned: json['quantity_returned'] as int,
      withdrawnAt: DateTime.parse(json['withdrawn_at'] as String),
      dueAt: json['due_at'] != null ? DateTime.parse(json['due_at'] as String) : null,
      returnedAt:
          json['returned_at'] != null ? DateTime.parse(json['returned_at'] as String) : null,
      note: json['note'] as String?,
    );
  }
}
