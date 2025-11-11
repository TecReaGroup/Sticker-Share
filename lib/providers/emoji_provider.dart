import 'package:flutter/material.dart';
import '../models/emoji_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';

class EmojiProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<EmojiModel> _emojis = [];
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  String? _error;

  List<EmojiModel> get emojis => _emojis;
  List<CategoryModel> get categories => _categories;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<EmojiModel> get favoriteEmojis =>
      _emojis.where((emoji) => emoji.isFavorite).toList();

  List<EmojiModel> get filteredEmojis {
    if (_selectedCategoryId == null) {
      return _emojis;
    }
    return _emojis
        .where((emoji) => emoji.categoryId == _selectedCategoryId)
        .toList();
  }

  // Initialize - load data from database
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await loadCategories();
      await loadEmojis();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all emojis
  Future<void> loadEmojis({String? categoryId}) async {
    try {
      _emojis = await _databaseService.getEmojis(categoryId: categoryId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load emojis: $e';
      notifyListeners();
    }
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _databaseService.getCategories();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load categories: $e';
      notifyListeners();
    }
  }

  // Load favorite emojis
  Future<void> loadFavorites() async {
    try {
      final favorites = await _databaseService.getFavoriteEmojis();
      _emojis = favorites;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load favorites: $e';
      notifyListeners();
    }
  }

  // Add emoji
  Future<void> addEmoji(EmojiModel emoji) async {
    try {
      await _databaseService.insertEmoji(emoji);
      _emojis.add(emoji);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add emoji: $e';
      notifyListeners();
    }
  }

  // Update emoji
  Future<void> updateEmoji(EmojiModel emoji) async {
    try {
      await _databaseService.updateEmoji(emoji);
      final index = _emojis.indexWhere((e) => e.id == emoji.id);
      if (index != -1) {
        _emojis[index] = emoji;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update emoji: $e';
      notifyListeners();
    }
  }

  // Delete emoji
  Future<void> deleteEmoji(String id) async {
    try {
      await _databaseService.deleteEmoji(id);
      _emojis.removeWhere((emoji) => emoji.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete emoji: $e';
      notifyListeners();
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(String id) async {
    try {
      final index = _emojis.indexWhere((emoji) => emoji.id == id);
      if (index != -1) {
        final emoji = _emojis[index];
        final updatedEmoji = emoji.copyWith(isFavorite: !emoji.isFavorite);
        await _databaseService.toggleFavorite(id, updatedEmoji.isFavorite);
        _emojis[index] = updatedEmoji;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to toggle favorite: $e';
      notifyListeners();
    }
  }

  // Add category
  Future<void> addCategory(CategoryModel category) async {
    try {
      await _databaseService.insertCategory(category);
      _categories.add(category);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add category: $e';
      notifyListeners();
    }
  }

  // Update category
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _databaseService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update category: $e';
      notifyListeners();
    }
  }

  // Delete category
  Future<void> deleteCategory(String id) async {
    try {
      await _databaseService.deleteCategory(id);
      _categories.removeWhere((category) => category.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete category: $e';
      notifyListeners();
    }
  }

  // Select category for filtering
  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}