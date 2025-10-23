class InventorySnapshot {
  const InventorySnapshot({
    required this.totalItems,
    required this.lowStockItems,
    required this.pendingRequests,
  });

  final int totalItems;
  final int lowStockItems;
  final int pendingRequests;

  factory InventorySnapshot.fromJson(Map<String, dynamic> json) {
    return InventorySnapshot(
      totalItems: json['total_items'] as int,
      lowStockItems: json['low_stock_items'] as int,
      pendingRequests: json['pending_requests'] as int,
    );
  }
}
