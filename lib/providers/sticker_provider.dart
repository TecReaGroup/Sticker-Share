import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
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
  
  // Background loading state
  bool _isBackgroundLoading = false;
  final Set<String> _loadedLotties = {}; // Cache of loaded Lottie paths
  bool _backgroundLoadingCancelled = false;

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
      // Prioritize loading current theme stickers
      _prioritizeThemeLoading(themeId);
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

  // Start background loading of Lottie animations one by one
  void startBackgroundLoading() {
    if (_isBackgroundLoading || _stickers.isEmpty) return;
    
    _isBackgroundLoading = true;
    _backgroundLoadingCancelled = false;
    
    debugPrint('🎨 Starting background Lottie loading...');
    
    // Load current theme first, then others
    _loadLottiesInBackground();
  }

  // Prioritize loading for specific theme
  void _prioritizeThemeLoading(String themeId) {
    debugPrint('🎯 Prioritizing theme: $themeId');
    
    // Cancel current background loading
    _backgroundLoadingCancelled = true;
    
    // Restart with new priority
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_selectedThemeId == themeId) {
        _isBackgroundLoading = false;
        startBackgroundLoading();
      }
    });
  }

  // Load Lottie animations one by one in background
  Future<void> _loadLottiesInBackground() async {
    // Get stickers sorted by priority: current theme first, then others
    final currentThemeStickers = _stickers
        .where((s) => s.themeId == _selectedThemeId)
        .where((s) => !_loadedLotties.contains(s.localPath))
        .toList();
    
    final otherStickers = _stickers
        .where((s) => s.themeId != _selectedThemeId)
        .where((s) => !_loadedLotties.contains(s.localPath))
        .toList();
    
    final orderedStickers = [...currentThemeStickers, ...otherStickers];
    
    debugPrint('📊 Loading queue: ${orderedStickers.length} Lotties '
        '(${currentThemeStickers.length} from current theme)');
    
    // Load one by one with delay to avoid overwhelming the system
    for (int i = 0; i < orderedStickers.length; i++) {
      if (_backgroundLoadingCancelled) {
        debugPrint('🛑 Background loading cancelled');
        break;
      }
      
      final sticker = orderedStickers[i];
      
      try {
        // Load the Lottie composition (this caches it)
        await AssetLottie(sticker.localPath).load();
        _loadedLotties.add(sticker.localPath);
        
        if ((i + 1) % 5 == 0) {
          debugPrint('✅ Loaded ${i + 1}/${orderedStickers.length} Lotties');
        }
        
        // Small delay between loads to keep UI responsive
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        debugPrint('❌ Failed to load ${sticker.localPath}: $e');
      }
    }
    
    if (!_backgroundLoadingCancelled) {
      debugPrint('🎉 Background loading complete! Total cached: ${_loadedLotties.length}');
    }
    
    _isBackgroundLoading = false;
  }

  // Check if a Lottie is already loaded
  bool isLottieLoaded(String path) => _loadedLotties.contains(path);

  @override
  void dispose() {
    _backgroundLoadingCancelled = true;
    super.dispose();
  }

  // Scan assets directory and load themes/stickers
  Future<void> scanAndLoadAssets() async {
    try {
      debugPrint('Starting asset scan...');
      
      // Load AssetManifest.json to get all asset paths
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Parse asset paths to extract theme names and sticker file names
      final Map<String, Set<String>> stickersData = {};
      final RegExp stickerPattern = RegExp(
        r'assets/stickers/([^/]+)/lottie/(.+)\.json$'
      );
      
      for (final assetPath in manifestMap.keys) {
        final match = stickerPattern.firstMatch(assetPath);
        if (match != null) {
          final themeName = match.group(1)!;
          final fileName = match.group(2)!;
          
          stickersData.putIfAbsent(themeName, () => <String>{});
          stickersData[themeName]!.add(fileName);
        }
      }
      
      debugPrint('Found ${stickersData.length} themes from AssetManifest.json');
      for (final entry in stickersData.entries) {
        debugPrint('Theme: ${entry.key}, Stickers: ${entry.value.length}');
      }
      
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
            // Use Lottie JSON for preview, GIF for sharing
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