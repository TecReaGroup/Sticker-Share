class ThemeModel {
  final String id;
  final String name;
  final bool isFavorite;

  ThemeModel({
    required this.id,
    required this.name,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isFavorite': isFavorite ? 1 : 0,
      };

  factory ThemeModel.fromMap(Map<String, dynamic> map) => ThemeModel(
        id: map['id'],
        name: map['name'],
        isFavorite: map['isFavorite'] == 1,
      );

  ThemeModel copyWith({
    String? id,
    String? name,
    bool? isFavorite,
  }) {
    return ThemeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}