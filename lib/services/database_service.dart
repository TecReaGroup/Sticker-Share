import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sticker_model.dart';
import '../models/theme_model.dart';

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
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE stickers(
            id TEXT PRIMARY KEY,
            name TEXT,
            localPath TEXT,
            gifPath TEXT,
            themeId TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE themes(
            id TEXT PRIMARY KEY,
            name TEXT,
            isFavorite INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Always drop and recreate for clean slate
        await db.execute('DROP TABLE IF EXISTS stickers');
        await db.execute('DROP TABLE IF EXISTS themes');
        await db.execute('DROP TABLE IF EXISTS emojis');
        await db.execute('DROP TABLE IF EXISTS categories');
        
        await db.execute('''
          CREATE TABLE stickers(
            id TEXT PRIMARY KEY,
            name TEXT,
            localPath TEXT,
            gifPath TEXT,
            themeId TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE themes(
            id TEXT PRIMARY KEY,
            name TEXT,
            isFavorite INTEGER
          )
        ''');
      },
    );
  }

  // Sticker operations
  Future<List<StickerModel>> getStickers({String? themeId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stickers',
      where: themeId != null ? 'themeId = ?' : null,
      whereArgs: themeId != null ? [themeId] : null,
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

  Future<void> deleteStickersByTheme(String themeId) async {
    final db = await database;
    await db.delete(
      'stickers',
      where: 'themeId = ?',
      whereArgs: [themeId],
    );
  }

  // Theme operations
  Future<List<ThemeModel>> getThemes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('themes');
    return maps.map((map) => ThemeModel.fromMap(map)).toList();
  }

  Future<List<ThemeModel>> getFavoriteThemes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'themes',
      where: 'isFavorite = ?',
      whereArgs: [1],
    );
    return maps.map((map) => ThemeModel.fromMap(map)).toList();
  }

  Future<void> insertTheme(ThemeModel theme) async {
    final db = await database;
    await db.insert(
      'themes',
      theme.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTheme(ThemeModel theme) async {
    final db = await database;
    await db.update(
      'themes',
      theme.toMap(),
      where: 'id = ?',
      whereArgs: [theme.id],
    );
  }

  Future<void> toggleThemeFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'themes',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTheme(String id) async {
    final db = await database;
    await db.delete(
      'themes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('stickers');
    await db.delete('themes');
  }
}