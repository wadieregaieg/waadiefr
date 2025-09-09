/// Represents the status of an order in the system.
enum OrderStatus {
  /// Order has been placed but not yet processed
  pending,

  /// Order is currently being processed
  processing,

  /// Order is out for delivery
  out_for_delivery,

  /// Order has been delivered to the customer
  delivered,

  /// Order has been completed
  completed,

  /// Order has been canceled
  cancelled,

  /// Order has been returned by the customer
  returned;

  /// Converts a string to an OrderStatus enum value
  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }

  /// Converts the enum value to a string
  String toJson() => name;
}
