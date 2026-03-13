class Category {
  const Category({required this.id, required this.name});

  final int? id;
  final String name;

  Category copyWith({int? id, String? name}) {
    return Category(id: id ?? this.id, name: name ?? this.name);
  }
}
