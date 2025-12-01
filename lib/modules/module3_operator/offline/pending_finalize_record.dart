class PendingFinalizeRecord {
  final int? id;
  final String screenId;
  final String customerId;
  final double totalWeight;
  final String entryType;
  final int createdAt;

  PendingFinalizeRecord({
    this.id,
    required this.screenId,
    required this.customerId,
    required this.totalWeight,
    this.entryType = "app",
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, Object?> toMap() => {
        'id': id,
        'screen_id': screenId,
        'customer_id': customerId,
        'total_weight': totalWeight,
        'entry_type': entryType,
        'created_at': createdAt,
      };

  static PendingFinalizeRecord fromMap(Map<String, Object?> m) =>
      PendingFinalizeRecord(
        id: m['id'] as int?,
        screenId: m['screen_id'] as String,
        customerId: m['customer_id'] as String,
        totalWeight: (m['total_weight'] as num).toDouble(),
        entryType: m['entry_type'] as String,
        createdAt: m['created_at'] as int,
      );
}
