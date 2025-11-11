import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/emoji_model.dart';
import '../models/category_model.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'emoji.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE emojis(
            id TEXT PRIMARY KEY,
            name TEXT,
            url TEXT,
            localPath TEXT,
            categoryId TEXT,
            createdAt TEXT,
            isFavorite INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE categories(
            id TEXT PRIMARY KEY,
            name TEXT,
            icon TEXT
          )
        ''');
      },
    );
  }

  // Emoji operations
  Future<List<EmojiModel>> getEmojis({String? categoryId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emojis',
      where: categoryId != null ? 'categoryId = ?' : null,
      whereArgs: categoryId != null ? [categoryId] : null,
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => EmojiModel.fromMap(map)).toList();
  }

  Future<List<EmojiModel>> getFavoriteEmojis() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emojis',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => EmojiModel.fromMap(map)).toList();
  }

  Future<void> insertEmoji(EmojiModel emoji) async {
    final db = await database;
    await db.insert(
      'emojis',
      emoji.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateEmoji(EmojiModel emoji) async {
    final db = await database;
    await db.update(
      'emojis',
      emoji.toMap(),
      where: 'id = ?',
      whereArgs: [emoji.id],
    );
  }

  Future<void> deleteEmoji(String id) async {
    final db = await database;
    await db.delete(
      'emojis',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'emojis',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Category operations
  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<void> insertCategory(CategoryModel category) async {
    final db = await database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('emojis');
    await db.delete('categories');
  }
}