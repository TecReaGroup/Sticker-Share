import 'package:flutter/material.dart';
import '../models/sticker_model.dart';
import '../models/theme_model.dart';
import '../services/database_service.dart';

class StickerProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<StickerModel> _stickers = [];
  List<ThemeModel> _themes = [];
  String? _selectedThemeId;
  bool _showFavoritesOnly = false;
  bool _isLoading = false;
  String? _error;

  List<StickerModel> get stickers => _stickers;
  List<ThemeModel> get themes => _themes;
  String? get selectedThemeId => _selectedThemeId;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ThemeModel> get favoriteThemes =>
      _themes.where((theme) => theme.isFavorite).toList();

  List<StickerModel> get filteredStickers {
    // If showing favorites only, filter by favorite themes
    if (_showFavoritesOnly) {
      final favoriteThemeIds = favoriteThemes.map((t) => t.id).toSet();
      final favStickers = _stickers
          .where((sticker) => favoriteThemeIds.contains(sticker.themeId))
          .toList();
      
      // If a specific theme is selected, further filter by that theme
      if (_selectedThemeId != null) {
        return favStickers
            .where((sticker) => sticker.themeId == _selectedThemeId)
            .toList();
      }
      return favStickers;
    }
    
    // If not showing favorites, just filter by selected theme if any
    if (_selectedThemeId == null) {
      return _stickers;
    }
    
    return _stickers
        .where((sticker) => sticker.themeId == _selectedThemeId)
        .toList();
  }

  // Initialize - load data from database
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await loadThemes();
      await loadStickers();
      
      // Auto-select first theme if available
      if (_themes.isNotEmpty && _selectedThemeId == null) {
        _selectedThemeId = _themes.first.id;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all stickers
  Future<void> loadStickers({String? themeId}) async {
    try {
      _stickers = await _databaseService.getStickers(themeId: themeId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load stickers: $e';
      notifyListeners();
    }
  }

  // Load themes
  Future<void> loadThemes() async {
    try {
      _themes = await _databaseService.getThemes();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load themes: $e';
      notifyListeners();
    }
  }

  // Add sticker
  Future<void> addSticker(StickerModel sticker) async {
    try {
      await _databaseService.insertSticker(sticker);
      _stickers.add(sticker);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add sticker: $e';
      notifyListeners();
    }
  }

  // Delete sticker
  Future<void> deleteSticker(String id) async {
    try {
      await _databaseService.deleteSticker(id);
      _stickers.removeWhere((sticker) => sticker.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete sticker: $e';
      notifyListeners();
    }
  }

  // Add theme
  Future<void> addTheme(ThemeModel theme) async {
    try {
      await _databaseService.insertTheme(theme);
      _themes.add(theme);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add theme: $e';
      notifyListeners();
    }
  }

  // Toggle theme favorite
  Future<void> toggleThemeFavorite(String themeId) async {
    try {
      final index = _themes.indexWhere((theme) => theme.id == themeId);
      if (index != -1) {
        final theme = _themes[index];
        final updatedTheme = theme.copyWith(isFavorite: !theme.isFavorite);
        await _databaseService.toggleThemeFavorite(themeId, updatedTheme.isFavorite);
        _themes[index] = updatedTheme;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to toggle theme favorite: $e';
      notifyListeners();
    }
  }

  // Delete theme
  Future<void> deleteTheme(String id) async {
    try {
      await _databaseService.deleteTheme(id);
      await _databaseService.deleteStickersByTheme(id);
      _themes.removeWhere((theme) => theme.id == id);
      _stickers.removeWhere((sticker) => sticker.themeId == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete theme: $e';
      notifyListeners();
    }
  }

  // Select theme for filtering
  void selectTheme(String? themeId) {
    // Only allow switching to a different theme, not deselecting
    if (themeId != null && themeId != _selectedThemeId) {
      _selectedThemeId = themeId;
      notifyListeners();
    }
  }

  // Toggle favorites filter
  void toggleFavoritesFilter() {
    _showFavoritesOnly = !_showFavoritesOnly;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Scan assets directory and load themes/stickers
  Future<void> scanAndLoadAssets() async {
    try {
      final themeFolders = ['DonutTheDog', 'LovelyPeachy'];
      
      for (final themeFolder in themeFolders) {
        // Check if theme already exists in database
        final dbThemes = await _databaseService.getThemes();
        final existingTheme = dbThemes.where((t) => t.id == themeFolder).firstOrNull;
        if (existingTheme == null) {
          final theme = ThemeModel(
            id: themeFolder,
            name: themeFolder,
            isFavorite: false,
          );
          await _databaseService.insertTheme(theme);
        }

        // Check if stickers for this theme already exist in database
        final dbStickers = await _databaseService.getStickers(themeId: themeFolder);
        if (dbStickers.isEmpty) {
          final gifPaths = await _getGifPathsForTheme(themeFolder);
          for (final gifPath in gifPaths) {
            final fileName = gifPath.split('/').last;
            final stickerId = '${themeFolder}_${fileName.replaceAll('.gif', '')}';
            final sticker = StickerModel(
              id: stickerId,
              name: fileName.replaceAll('.gif', ''),
              localPath: gifPath,
              themeId: themeFolder,
            );
            await _databaseService.insertSticker(sticker);
          }
        }
      }
      
      // After scanning, reload all data from database
      await loadThemes();
      await loadStickers();
      
      // Auto-select first theme if none is selected
      if (_themes.isNotEmpty && _selectedThemeId == null) {
        _selectedThemeId = _themes.first.id;
      }
      
    } catch (e) {
      _error = 'Failed to scan assets: $e';
      notifyListeners();
    }
  }

  Future<List<String>> _getGifPathsForTheme(String themeName) async {
    // Return actual GIF file paths from assets directory
    if (themeName == 'DonutTheDog') {
      return [
        'assets/stickers/DonutTheDog/gif/41+hand_wave_waving.gif',
        'assets/stickers/DonutTheDog/gif/42+hand_ok.gif',
        'assets/stickers/DonutTheDog/gif/43++1_thumbs_thumbsup_up.gif',
        'assets/stickers/DonutTheDog/gif/44+a_blowing_face_heart_kiss_kissing.gif',
        'assets/stickers/DonutTheDog/gif/45+face_fearful.gif',
        'assets/stickers/DonutTheDog/gif/46+heart_red.gif',
        'assets/stickers/DonutTheDog/gif/47+star_struck.gif',
        'assets/stickers/DonutTheDog/gif/48+face_hearts_smiling_three.gif',
        'assets/stickers/DonutTheDog/gif/49+1_down_thumbs_thumbsdown.gif',
        'assets/stickers/DonutTheDog/gif/50+face_horns_imp_smiling.gif',
        'assets/stickers/DonutTheDog/gif/51+face_partying.gif',
        'assets/stickers/DonutTheDog/gif/52+angry_face.gif',
        'assets/stickers/DonutTheDog/gif/53+face_smiling_sunglasses.gif',
        'assets/stickers/DonutTheDog/gif/54+hand_v_victory.gif',
        'assets/stickers/DonutTheDog/gif/55+eyes.gif',
        'assets/stickers/DonutTheDog/gif/56+face_hands_hugging_hugs_open_smiling.gif',
        'assets/stickers/DonutTheDog/gif/57+face_thinking.gif',
        'assets/stickers/DonutTheDog/gif/58+hankey_of_pile_poo_poop_shit.gif',
        'assets/stickers/DonutTheDog/gif/59+crying_face_loudly_sob.gif',
        'assets/stickers/DonutTheDog/gif/60+face_sleepy.gif',
        'assets/stickers/DonutTheDog/gif/61+crossed_dizzy_eyes_face_knocked_out.gif',
      ];
    } else if (themeName == 'LovelyPeachy') {
      return [
        'assets/stickers/LovelyPeachy/gif/71+face_joy_of_tears.gif',
        'assets/stickers/LovelyPeachy/gif/72+hand_wave_waving.gif',
        'assets/stickers/LovelyPeachy/gif/73+broken_heart.gif',
        'assets/stickers/LovelyPeachy/gif/74+face_fearful.gif',
        'assets/stickers/LovelyPeachy/gif/75+a_blowing_face_heart_kiss_kissing.gif',
        'assets/stickers/LovelyPeachy/gif/76++1_thumbs_thumbsup_up.gif',
        'assets/stickers/LovelyPeachy/gif/77+gesturing_good_no_person.gif',
        'assets/stickers/LovelyPeachy/gif/78+face_vomiting.gif',
        'assets/stickers/LovelyPeachy/gif/79+extended_finger_fu_hand_middle_reversed.gif',
        'assets/stickers/LovelyPeachy/gif/80+gift_wrapped.gif',
        'assets/stickers/LovelyPeachy/gif/81+face_horns_imp_smiling.gif',
        'assets/stickers/LovelyPeachy/gif/82+down_face_upside.gif',
        'assets/stickers/LovelyPeachy/gif/83+face_flushed.gif',
        'assets/stickers/LovelyPeachy/gif/84+facepalming_man.gif',
        'assets/stickers/LovelyPeachy/gif/85+star_struck.gif',
        'assets/stickers/LovelyPeachy/gif/86+drooling_face.gif',
        'assets/stickers/LovelyPeachy/gif/87+face_sleeping.gif',
        'assets/stickers/LovelyPeachy/gif/88+enraged_face_pout_rage.gif',
        'assets/stickers/LovelyPeachy/gif/89+face_hearts_smiling_three.gif',
        'assets/stickers/LovelyPeachy/gif/90+crossed_dizzy_eyes_face_knocked_out.gif',
        'assets/stickers/LovelyPeachy/gif/91+star_struck.gif',
        'assets/stickers/LovelyPeachy/gif/92+crying_face_loudly_sob.gif',
        'assets/stickers/LovelyPeachy/gif/93+face_partying.gif',
      ];
    }
    return [];
  }
}