import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sticker_model.dart';
import '../models/sticker_pack_model.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'sticker_share.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE stickers(
            id TEXT PRIMARY KEY,
            name TEXT,
            localPath TEXT,
            gifPath TEXT,
            packId TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE sticker_packs(
            id TEXT PRIMARY KEY,
            name TEXT,
            isFavorite INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Always drop and recreate for clean slate
        await db.execute('DROP TABLE IF EXISTS stickers');
        await db.execute('DROP TABLE IF EXISTS sticker_packs');
        await db.execute('DROP TABLE IF EXISTS themes');
        await db.execute('DROP TABLE IF EXISTS emojis');
        await db.execute('DROP TABLE IF EXISTS categories');
        
        await db.execute('''
          CREATE TABLE stickers(
            id TEXT PRIMARY KEY,
            name TEXT,
            localPath TEXT,
            gifPath TEXT,
            packId TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE sticker_packs(
            id TEXT PRIMARY KEY,
            name TEXT,
            isFavorite INTEGER
          )
        ''');
      },
    );
  }

  // Sticker operations
  Future<List<StickerModel>> getStickers({String? packId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stickers',
      where: packId != null ? 'packId = ?' : null,
      whereArgs: packId != null ? [packId] : null,
    );
    return maps.map((map) => StickerModel.fromMap(map)).toList();
  }

  Future<void> insertSticker(StickerModel sticker) async {
    final db = await database;
    await db.insert(
      'stickers',
      sticker.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSticker(String id) async {
    final db = await database;
    await db.delete(
      'stickers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteStickersByPack(String packId) async {
    final db = await database;
    await db.delete(
      'stickers',
      where: 'packId = ?',
      whereArgs: [packId],
    );
  }

  // Sticker Pack operations
  Future<List<StickerPackModel>> getStickerPacks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('sticker_packs');
    return maps.map((map) => StickerPackModel.fromMap(map)).toList();
  }

  Future<List<StickerPackModel>> getFavoriteStickerPacks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sticker_packs',
      where: 'isFavorite = ?',
      whereArgs: [1],
    );
    return maps.map((map) => StickerPackModel.fromMap(map)).toList();
  }

  Future<void> insertStickerPack(StickerPackModel pack) async {
    final db = await database;
    await db.insert(
      'sticker_packs',
      pack.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateStickerPack(StickerPackModel pack) async {
    final db = await database;
    await db.update(
      'sticker_packs',
      pack.toMap(),
      where: 'id = ?',
      whereArgs: [pack.id],
    );
  }

  Future<void> toggleStickerPackFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'sticker_packs',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteStickerPack(String id) async {
    final db = await database;
    await db.delete(
      'sticker_packs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('stickers');
    await db.delete('sticker_packs');
  }
}