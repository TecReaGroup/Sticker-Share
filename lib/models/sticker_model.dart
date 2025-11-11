class StickerModel {
  final String id;
  final String name;
  final String localPath; // Path for Lottie preview
  final String gifPath;   // Path for GIF sharing to WeChat
  final String themeId;

  StickerModel({
    required this.id,
    required this.name,
    required this.localPath,
    required this.gifPath,
    required this.themeId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'localPath': localPath,
        'gifPath': gifPath,
        'themeId': themeId,
      };

  factory StickerModel.fromMap(Map<String, dynamic> map) => StickerModel(
        id: map['id'] as String,
        name: map['name'] as String,
        localPath: map['localPath'] as String,
        gifPath: map['gifPath'] as String? ?? map['localPath'] as String, // Fallback to localPath if null
        themeId: map['themeId'] as String,
      );

  StickerModel copyWith({
    String? id,
    String? name,
    String? localPath,
    String? gifPath,
    String? themeId,
  }) {
    return StickerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      gifPath: gifPath ?? this.gifPath,
      themeId: themeId ?? this.themeId,
    );
  }
}