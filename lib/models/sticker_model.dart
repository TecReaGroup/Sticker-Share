class StickerModel {
  final String id;
  final String name;
  final String localPath;
  final String themeId;

  StickerModel({
    required this.id,
    required this.name,
    required this.localPath,
    required this.themeId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'localPath': localPath,
        'themeId': themeId,
      };

  factory StickerModel.fromMap(Map<String, dynamic> map) => StickerModel(
        id: map['id'],
        name: map['name'],
        localPath: map['localPath'],
        themeId: map['themeId'],
      );

  StickerModel copyWith({
    String? id,
    String? name,
    String? localPath,
    String? themeId,
  }) {
    return StickerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      themeId: themeId ?? this.themeId,
    );
  }
}