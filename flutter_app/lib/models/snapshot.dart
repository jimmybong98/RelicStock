class InventorySnapshot {
  const InventorySnapshot({
    required this.totalItems,
    required this.lowStockItems,
    required this.pendingRequests,
    required this.overdueReturns,
  });

  final int totalItems;
  final int lowStockItems;
  final int pendingRequests;
  final int overdueReturns;

  factory InventorySnapshot.fromJson(Map<String, dynamic> json) {
    return InventorySnapshot(
      totalItems: json['total_items'] as int,
      lowStockItems: json['low_stock_items'] as int,
      pendingRequests: json['pending_requests'] as int,
      overdueReturns: json['overdue_returns'] as int? ?? 0,
    );
  }
}
