// class PendingRecord {
//   final int? id;
//   final String screenId;
//   final String customerId;
//   final String customerName;
//   final String contactNo;
//   final String wasteTypeId;
//   final String weight;
//   final double? latitude;
//   final double? longitude;
//   final String imagePath;
//   final bool isUpdate;
//   final String? uniqueId;
//   final int createdAt;

//   PendingRecord({
//     this.id,
//     required this.screenId,
//     required this.customerId,
//     required this.customerName,
//     required this.contactNo,
//     required this.wasteTypeId,
//     required this.weight,
//     this.latitude,
//     this.longitude,
//     required this.imagePath,
//     this.isUpdate = false,
//     this.uniqueId,
//     int? createdAt,
//   }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

//   Map<String, Object?> toMap() => {
//         'id': id,
//         'screen_id': screenId,
//         'customer_id': customerId,
//         'customer_name': customerName,
//         'contact_no': contactNo,
//         'waste_type_id': wasteTypeId,
//         'weight': weight,
//         'latitude': latitude,
//         'longitude': longitude,
//         'image_path': imagePath,
//         'is_update': isUpdate ? 1 : 0,
//         'unique_id': uniqueId,
//         'created_at': createdAt,
//       };

//   static PendingRecord fromMap(Map<String, Object?> m) => PendingRecord(
//         id: m['id'] as int?,
//         screenId: m['screen_id'] as String,
//         customerId: m['customer_id'] as String,
//         customerName: m['customer_name'] as String,
//         contactNo: m['contact_no'] as String,
//         wasteTypeId: m['waste_type_id'] as String,
//         weight: m['weight'] as String,
//         latitude: m['latitude'] as double?,
//         longitude: m['longitude'] as double?,
//         imagePath: m['image_path'] as String,
//         isUpdate: (m['is_update'] as int? ?? 0) == 1,
//         uniqueId: m['unique_id'] as String?,
//         createdAt: m['created_at'] as int,
//       );

//   // ✅ ADD THIS HERE
//   PendingRecord copyWith({
//     int? id,
//     String? screenId,
//     String? customerId,
//     String? customerName,
//     String? contactNo,
//     String? wasteTypeId,
//     String? weight,
//     double? latitude,
//     double? longitude,
//     String? imagePath,
//     bool? isUpdate,
//     String? uniqueId,
//     int? createdAt,
//   }) {
//     return PendingRecord(
//       id: id ?? this.id,
//       screenId: screenId ?? this.screenId,
//       customerId: customerId ?? this.customerId,
//       customerName: customerName ?? this.customerName,
//       contactNo: contactNo ?? this.contactNo,
//       wasteTypeId: wasteTypeId ?? this.wasteTypeId,
//       weight: weight ?? this.weight,
//       latitude: latitude ?? this.latitude,
//       longitude: longitude ?? this.longitude,
//       imagePath: imagePath ?? this.imagePath,
//       isUpdate: isUpdate ?? this.isUpdate,
//       uniqueId: uniqueId ?? this.uniqueId,
//       createdAt: createdAt ?? this.createdAt,
//     );
//   }
// }


class PendingRecord {
  final int? id;
  final String screenId;
  final String customerId;
  final String customerName;
  final String contactNo;
  final String wasteTypeId;
  final String weight;
  final double? latitude;
  final double? longitude;
  final String imagePath;
  final bool isUpdate;
  final String uniqueId;   // 👈 MAKE NON-NULL
  final int createdAt;

  PendingRecord({
    this.id,
    required this.screenId,
    required this.customerId,
    required this.customerName,
    required this.contactNo,
    required this.wasteTypeId,
    required this.weight,
    this.latitude,
    this.longitude,
    required this.imagePath,
    this.isUpdate = false,
    String? uniqueId,
    int? createdAt,
  })  : uniqueId = uniqueId ??
            "uid_${DateTime.now().millisecondsSinceEpoch}",   // 👈 ALWAYS SET
        createdAt =
            createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, Object?> toMap() => {
        'id': id,
        'screen_id': screenId,
        'customer_id': customerId,
        'customer_name': customerName,
        'contact_no': contactNo,
        'waste_type_id': wasteTypeId,
        'weight': weight,
        'latitude': latitude,
        'longitude': longitude,
        'image_path': imagePath,
        'is_update': isUpdate ? 1 : 0,
        'unique_id': uniqueId,               // 👈 NEVER NULL
        'created_at': createdAt,
      };

  static PendingRecord fromMap(Map<String, Object?> m) => PendingRecord(
        id: m['id'] as int?,
        screenId: m['screen_id'] as String,
        customerId: m['customer_id'] as String,
        customerName: m['customer_name'] as String,
        contactNo: m['contact_no'] as String,
        wasteTypeId: m['waste_type_id'] as String,
        weight: m['weight'] as String,
        latitude: m['latitude'] != null
            ? (m['latitude'] as num).toDouble()
            : null,
        longitude: m['longitude'] != null
            ? (m['longitude'] as num).toDouble()
            : null,
        imagePath: m['image_path'] as String,
        isUpdate: (m['is_update'] as int? ?? 0) == 1,
        uniqueId: m['unique_id']?.toString(),   // 👈 auto-corrected in constructor
        createdAt: m['created_at'] as int,
      );

  PendingRecord copyWith({
    int? id,
    String? screenId,
    String? customerId,
    String? customerName,
    String? contactNo,
    String? wasteTypeId,
    String? weight,
    double? latitude,
    double? longitude,
    String? imagePath,
    bool? isUpdate,
    String? uniqueId,
    int? createdAt,
  }) {
    return PendingRecord(
      id: id ?? this.id,
      screenId: screenId ?? this.screenId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      contactNo: contactNo ?? this.contactNo,
      wasteTypeId: wasteTypeId ?? this.wasteTypeId,
      weight: weight ?? this.weight,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imagePath: imagePath ?? this.imagePath,
      isUpdate: isUpdate ?? this.isUpdate,
      uniqueId: uniqueId ?? this.uniqueId,     // 👈 Always preserved
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
