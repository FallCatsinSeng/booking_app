class Category {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? description;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        slug: json['slug'] as String,
        icon: json['icon'] as String?,
        description: json['description'] as String?,
      );
}
