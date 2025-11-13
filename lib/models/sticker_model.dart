class StickerModel {
  final String id;
  final String name;
  final String localPath; // Path for Lottie preview
  final String gifPath;   // Path for GIF sharing to messaging apps
  final String packId;

  StickerModel({
    required this.id,
    required this.name,
    required this.localPath,
    required this.gifPath,
    required this.packId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'localPath': localPath,
        'gifPath': gifPath,
        'packId': packId,
      };

  factory StickerModel.fromMap(Map<String, dynamic> map) => StickerModel(
        id: map['id'] as String,
        name: map['name'] as String,
        localPath: map['localPath'] as String,
        gifPath: map['gifPath'] as String? ?? map['localPath'] as String, // Fallback to localPath if null
        packId: map['packId'] as String,
      );

  StickerModel copyWith({
    String? id,
    String? name,
    String? localPath,
    String? gifPath,
    String? packId,
  }) {
    return StickerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      gifPath: gifPath ?? this.gifPath,
      packId: packId ?? this.packId,
    );
  }
}