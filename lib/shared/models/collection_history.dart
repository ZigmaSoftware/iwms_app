import 'dart:convert';
import 'package:equatable/equatable.dart';

class CollectionHistorySection extends Equatable {
  final String type;
  final String? weight;
  final String? imagePath;
  final String? imageBase64;

  const CollectionHistorySection({
    required this.type,
    this.weight,
    this.imagePath,
    this.imageBase64,
  });

  String get normalizedType => type.toLowerCase();

  Map<String, dynamic> toJson() => {
        'type': type,
        'weight': weight,
        'imagePath': imagePath,
        'imageBase64': imageBase64,
      };

  factory CollectionHistorySection.fromJson(Map<String, dynamic> json) {
    return CollectionHistorySection(
      type: json['type'] as String? ?? 'unknown',
      weight: json['weight'] as String?,
      imagePath: json['imagePath'] as String?,
      imageBase64: json['imageBase64'] as String?,
    );
  }

  @override
  List<Object?> get props => [type, weight, imagePath, imageBase64];
}

class CollectionHistoryEntry extends Equatable {
  final String customerId;
  final String customerName;
  final DateTime collectedAt;
  final List<CollectionHistorySection> sections;
  final double totalWeight;

  const CollectionHistoryEntry({
    required this.customerId,
    required this.customerName,
    required this.collectedAt,
    required this.sections,
    required this.totalWeight,
  });

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'customerName': customerName,
        'collectedAt': collectedAt.toIso8601String(),
        'sections': sections.map((e) => e.toJson()).toList(),
        'totalWeight': totalWeight,
      };

  factory CollectionHistoryEntry.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'] as List<dynamic>? ?? const [];
    return CollectionHistoryEntry(
      customerId: json['customerId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      collectedAt:
          DateTime.tryParse(json['collectedAt'] as String? ?? '') ??
              DateTime.now(),
      sections: sectionsJson
          .map((item) =>
              CollectionHistorySection.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalWeight: (json['totalWeight'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static String encodeList(List<CollectionHistoryEntry> entries) {
    final data = entries.map((e) => e.toJson()).toList();
    return jsonEncode(data);
  }

  static List<CollectionHistoryEntry> decodeList(String source) {
    final data = jsonDecode(source) as List<dynamic>;
    return data
        .map((item) =>
            CollectionHistoryEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<Object?> get props =>
      [customerId, customerName, collectedAt, sections, totalWeight];
}
