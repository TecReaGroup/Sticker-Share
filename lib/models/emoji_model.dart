class EmojiModel {
  final String id;
  final String name;
  final String url;
  final String localPath;
  final String categoryId;
  final DateTime createdAt;
  final bool isFavorite;

  EmojiModel({
    required this.id,
    required this.name,
    required this.url,
    required this.localPath,
    required this.categoryId,
    required this.createdAt,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'url': url,
        'localPath': localPath,
        'categoryId': categoryId,
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite ? 1 : 0,
      };

  factory EmojiModel.fromMap(Map<String, dynamic> map) => EmojiModel(
        id: map['id'],
        name: map['name'],
        url: map['url'],
        localPath: map['localPath'],
        categoryId: map['categoryId'],
        createdAt: DateTime.parse(map['createdAt']),
        isFavorite: map['isFavorite'] == 1,
      );

  EmojiModel copyWith({
    String? id,
    String? name,
    String? url,
    String? localPath,
    String? categoryId,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return EmojiModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      localPath: localPath ?? this.localPath,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}