class CatalogItem {
  final String id;
  String name;
  String category;
  String imageUrl;
  String description;
  bool isSaved;

  CatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    this.description = '',
    this.isSaved = false,
  });

  CatalogItem copyWith({
    String? id,
    String? name,
    String? category,
    String? imageUrl,
    String? description,
    bool? isSaved,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
