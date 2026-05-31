import 'category.dart';

class Facility {
  final int id;
  final String code;
  final String name;
  final String? description;
  final int capacity;
  final String? location;
  final String? floor;
  final String status;
  final bool requiresApproval;
  final int price;
  final bool isPaid;
  final double? latitude;
  final double? longitude;
  final String? primaryImageUrl;
  final Category? category;

  Facility({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.capacity,
    this.location,
    this.floor,
    required this.status,
    this.requiresApproval = false,
    this.price = 0,
    this.isPaid = false,
    this.latitude,
    this.longitude,
    this.primaryImageUrl,
    this.category,
  });

  factory Facility.fromJson(Map<String, dynamic> json) => Facility(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        capacity: json['capacity'] as int? ?? 0,
        location: json['location'] as String?,
        floor: json['floor'] as String?,
        status: json['status'] as String? ?? 'available',
        requiresApproval: json['requires_approval'] as bool? ?? false,
        price: json['price'] as int? ?? 0,
        isPaid: json['is_paid'] as bool? ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        primaryImageUrl: json['primary_image_url'] as String?,
        category: json['category'] is Map<String, dynamic>
            ? Category.fromJson(json['category'] as Map<String, dynamic>)
            : null,
      );
}
