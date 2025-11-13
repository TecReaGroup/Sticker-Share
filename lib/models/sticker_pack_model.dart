class StickerPackModel {
  final String id;
  final String name;
  final bool isFavorite;

  StickerPackModel({
    required this.id,
    required this.name,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isFavorite': isFavorite ? 1 : 0,
      };

  factory StickerPackModel.fromMap(Map<String, dynamic> map) => StickerPackModel(
        id: map['id'],
        name: map['name'],
        isFavorite: map['isFavorite'] == 1,
      );

  StickerPackModel copyWith({
    String? id,
    String? name,
    bool? isFavorite,
  }) {
    return StickerPackModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
