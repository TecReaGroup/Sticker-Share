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
    } catch (e, stackTrace) {
      _error = 'Initialize error: $e';
      debugPrint('Initialize error: $e\n$stackTrace');
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
      debugPrint('Starting asset scan...');
      // List only files that exist in the GIF directory
      final stickersData = {
        'DonutTheDog': [
          '40+face_joy_of_tears', '41+hand_wave_waving', '42+hand_ok',
          '43++1_thumbs_thumbsup_up', '44+a_blowing_face_heart_kiss_kissing',
          '45+face_fearful', '46+heart_red', '47+star_struck',
          '48+face_hearts_smiling_three', '49+1_down_thumbs_thumbsdown',
          '50+face_horns_imp_smiling', '51+face_partying', '52+angry_face',
          '53+face_smiling_sunglasses', '54+hand_v_victory', '55+eyes',
          '56+face_hands_hugging_hugs_open_smiling', '57+face_thinking',
          '58+hankey_of_pile_poo_poop_shit', '59+crying_face_loudly_sob',
          '60+face_sleepy', '61+crossed_dizzy_eyes_face_knocked_out',
          '62+biceps_flexed_muscle', '63+face_pleading', '64+face_out_stuck_tongue',
          '65+rose', '66+gesturing_good_man_ng_no', '67+face_hot',
          '68+face_sleeping', '69+biceps_flexed_muscle', '70++1_thumbs_thumbsup_up',
        ],
        'LovelyPeachy': [
          '71+face_joy_of_tears', '72+hand_wave_waving', '73+broken_heart',
          '74+face_fearful', '75+a_blowing_face_heart_kiss_kissing',
          '76++1_thumbs_thumbsup_up', '77+gesturing_good_no_person',
          '78+face_vomiting', '79+extended_finger_fu_hand_middle_reversed',
          '80+gift_wrapped', '81+face_horns_imp_smiling', '82+down_face_upside',
          '83+face_flushed', '84+facepalming_man', '85+star_struck',
          '86+drooling_face', '87+face_sleeping', '88+enraged_face_pout_rage',
          '89+face_hearts_smiling_three', '90+crossed_dizzy_eyes_face_knocked_out',
          '91+star_struck', '92+crying_face_loudly_sob', '93+face_partying',
        ],
      };
      
      for (final entry in stickersData.entries) {
        final themeFolder = entry.key;
        final fileNames = entry.value;
        
        debugPrint('Processing theme: $themeFolder');
        final dbThemes = await _databaseService.getThemes();
        if (!dbThemes.any((t) => t.id == themeFolder)) {
          await _databaseService.insertTheme(ThemeModel(
            id: themeFolder,
            name: themeFolder,
            isFavorite: false,
          ));
        }

        final dbStickers = await _databaseService.getStickers(themeId: themeFolder);
        
        // Check if we need to update old records (those not pointing to Lottie JSON)
        final needsUpdate = dbStickers.any((s) => !s.localPath.endsWith('.json'));
        
        if (dbStickers.isEmpty || needsUpdate) {
          // Delete old stickers for this theme
          if (needsUpdate) {
            debugPrint('Updating old stickers for $themeFolder');
            for (final oldSticker in dbStickers) {
              await _databaseService.deleteSticker(oldSticker.id);
            }
          }
          
          debugPrint('Adding ${fileNames.length} stickers for $themeFolder');
          for (final fileName in fileNames) {
            // Use Lottie JSON for preview, GIF for WeChat sharing
            final sticker = StickerModel(
              id: '${themeFolder}_$fileName',
              name: fileName,
              localPath: 'assets/stickers/$themeFolder/lottie/$fileName.json',
              gifPath: 'assets/stickers/$themeFolder/gif/$fileName.gif',
              themeId: themeFolder,
            );
            await _databaseService.insertSticker(sticker);
          }
        }
      }
      
      debugPrint('Loading themes and stickers...');
      await loadThemes();
      await loadStickers();
      
      debugPrint('Loaded ${_themes.length} themes and ${_stickers.length} stickers');
      
      if (_themes.isNotEmpty && _selectedThemeId == null) {
        _selectedThemeId = _themes.first.id;
      }
    } catch (e, stackTrace) {
      _error = 'Failed to scan assets: $e';
      debugPrint('Scan error: $e\n$stackTrace');
      notifyListeners();
    }
  }
}