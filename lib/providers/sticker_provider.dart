import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../models/sticker_model.dart';
import '../models/sticker_pack_model.dart';
import '../services/database_service.dart';

class StickerProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<StickerModel> _stickers = [];
  List<StickerPackModel> _stickerPacks = [];
  String? _selectedPackId;
  bool _showFavoritesOnly = false;
  bool _isLoading = false;
  String? _error;
  
  // Background loading state
  bool _isBackgroundLoading = false;
  final Set<String> _loadedLotties = {}; // Cache of loaded Lottie paths
  bool _backgroundLoadingCancelled = false;

  List<StickerModel> get stickers => _stickers;
  List<StickerPackModel> get stickerPacks => _stickerPacks;
  String? get selectedPackId => _selectedPackId;
  bool get showFavoritesOnly => _showFavoritesOnly;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<StickerPackModel> get favoriteStickerPacks =>
      _stickerPacks.where((pack) => pack.isFavorite).toList();

  List<StickerModel> get filteredStickers {
    // If showing favorites only, filter by favorite packs
    if (_showFavoritesOnly) {
      final favoritePackIds = favoriteStickerPacks.map((p) => p.id).toSet();
      final favStickers = _stickers
          .where((sticker) => favoritePackIds.contains(sticker.packId))
          .toList();
      
      // If a specific pack is selected, further filter by that pack
      if (_selectedPackId != null) {
        return favStickers
            .where((sticker) => sticker.packId == _selectedPackId)
            .toList();
      }
      return favStickers;
    }
    
    // If not showing favorites, just filter by selected pack if any
    if (_selectedPackId == null) {
      return _stickers;
    }
    
    return _stickers
        .where((sticker) => sticker.packId == _selectedPackId)
        .toList();
  }

  // Initialize - load data from database
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await loadStickerPacks();
      await loadStickers();
      
      // Auto-select first pack if available
      if (_stickerPacks.isNotEmpty && _selectedPackId == null) {
        _selectedPackId = _stickerPacks.first.id;
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
  Future<void> loadStickers({String? packId}) async {
    try {
      _stickers = await _databaseService.getStickers(packId: packId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load stickers: $e';
      notifyListeners();
    }
  }

  // Load sticker packs
  Future<void> loadStickerPacks() async {
    try {
      _stickerPacks = await _databaseService.getStickerPacks();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load sticker packs: $e';
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

  // Add sticker pack
  Future<void> addStickerPack(StickerPackModel pack) async {
    try {
      await _databaseService.insertStickerPack(pack);
      _stickerPacks.add(pack);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add sticker pack: $e';
      notifyListeners();
    }
  }

  // Toggle sticker pack favorite
  Future<void> toggleStickerPackFavorite(String packId) async {
    try {
      final index = _stickerPacks.indexWhere((pack) => pack.id == packId);
      if (index != -1) {
        final pack = _stickerPacks[index];
        final updatedPack = pack.copyWith(isFavorite: !pack.isFavorite);
        await _databaseService.toggleStickerPackFavorite(packId, updatedPack.isFavorite);
        _stickerPacks[index] = updatedPack;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to toggle sticker pack favorite: $e';
      notifyListeners();
    }
  }

  // Delete sticker pack
  Future<void> deleteStickerPack(String id) async {
    try {
      await _databaseService.deleteStickerPack(id);
      await _databaseService.deleteStickersByPack(id);
      _stickerPacks.removeWhere((pack) => pack.id == id);
      _stickers.removeWhere((sticker) => sticker.packId == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete sticker pack: $e';
      notifyListeners();
    }
  }

  // Select sticker pack for filtering
  void selectStickerPack(String? packId) {
    // Only allow switching to a different pack, not deselecting
    if (packId != null && packId != _selectedPackId) {
      _selectedPackId = packId;
      notifyListeners();
      // Prioritize loading current pack stickers
      _prioritizePackLoading(packId);
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

  // Prioritize loading for specific pack
  void _prioritizePackLoading(String packId) {
    debugPrint('🎯 Prioritizing pack: $packId');
    
    // Cancel current background loading
    _backgroundLoadingCancelled = true;
    
    // Restart with new priority
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_selectedPackId == packId) {
        _isBackgroundLoading = false;
        startBackgroundLoading();
      }
    });
  }

  // Load Lottie animations one by one in background
  Future<void> _loadLottiesInBackground() async {
    // Get stickers sorted by priority: current pack first, then others
    final currentPackStickers = _stickers
        .where((s) => s.packId == _selectedPackId)
        .where((s) => !_loadedLotties.contains(s.localPath))
        .toList();
    
    final otherStickers = _stickers
        .where((s) => s.packId != _selectedPackId)
        .where((s) => !_loadedLotties.contains(s.localPath))
        .toList();
    
    final orderedStickers = [...currentPackStickers, ...otherStickers];
    
    debugPrint('📊 Loading queue: ${orderedStickers.length} Lotties '
        '(${currentPackStickers.length} from current pack)');
    
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

  // Scan assets directory and load sticker packs/stickers
  Future<void> scanAndLoadAssets() async {
    try {
      debugPrint('Starting asset scan...');
      
      // Load AssetManifest.json to get all asset paths
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Parse asset paths to extract pack names and sticker file names
      final Map<String, Set<String>> stickersData = {};
      final RegExp stickerPattern = RegExp(
        r'assets/stickers/([^/]+)/lottie/(.+)\.json$'
      );
      
      for (final assetPath in manifestMap.keys) {
        final match = stickerPattern.firstMatch(assetPath);
        if (match != null) {
          final packName = match.group(1)!;
          final fileName = match.group(2)!;
          
          stickersData.putIfAbsent(packName, () => <String>{});
          stickersData[packName]!.add(fileName);
        }
      }
      
      debugPrint('Found ${stickersData.length} sticker packs from AssetManifest.json');
      for (final entry in stickersData.entries) {
        debugPrint('Pack: ${entry.key}, Stickers: ${entry.value.length}');
      }
      
      for (final entry in stickersData.entries) {
        final packFolder = entry.key;
        final fileNames = entry.value;
        
        debugPrint('Processing pack: $packFolder');
        final dbPacks = await _databaseService.getStickerPacks();
        if (!dbPacks.any((p) => p.id == packFolder)) {
          await _databaseService.insertStickerPack(StickerPackModel(
            id: packFolder,
            name: packFolder,
            isFavorite: false,
          ));
        }

        final dbStickers = await _databaseService.getStickers(packId: packFolder);
        
        // Check if we need to update old records (those not pointing to Lottie JSON)
        final needsUpdate = dbStickers.any((s) => !s.localPath.endsWith('.json'));
        
        if (dbStickers.isEmpty || needsUpdate) {
          // Delete old stickers for this pack
          if (needsUpdate) {
            debugPrint('Updating old stickers for $packFolder');
            for (final oldSticker in dbStickers) {
              await _databaseService.deleteSticker(oldSticker.id);
            }
          }
          
          debugPrint('Adding ${fileNames.length} stickers for $packFolder');
          for (final fileName in fileNames) {
            // Use Lottie JSON for preview, GIF for sharing
            final sticker = StickerModel(
              id: '${packFolder}_$fileName',
              name: fileName,
              localPath: 'assets/stickers/$packFolder/lottie/$fileName.json',
              gifPath: 'assets/stickers/$packFolder/gif/$fileName.gif',
              packId: packFolder,
            );
            await _databaseService.insertSticker(sticker);
          }
        }
      }
      
      debugPrint('Loading sticker packs and stickers...');
      await loadStickerPacks();
      await loadStickers();
      
      debugPrint('Loaded ${_stickerPacks.length} packs and ${_stickers.length} stickers');
      
      if (_stickerPacks.isNotEmpty && _selectedPackId == null) {
        _selectedPackId = _stickerPacks.first.id;
      }
    } catch (e, stackTrace) {
      _error = 'Failed to scan assets: $e';
      debugPrint('Scan error: $e\n$stackTrace');
      notifyListeners();
    }
  }
}