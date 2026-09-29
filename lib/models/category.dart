class ProductCategory {
  final String id;
  final String name;
  final String? icon;

  const ProductCategory({
    required this.id,
    required this.name,
    this.icon,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json, {String? id}) {
    return ProductCategory(
      id: id ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (icon != null) 'icon': icon,
    };
  }
}
