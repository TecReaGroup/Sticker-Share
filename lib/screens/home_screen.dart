import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emoji_provider.dart';
import '../models/emoji_model.dart';
import '../services/wechat_share_service.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize provider and load local test emojis
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<EmojiProvider>();
      // Wait for provider to finish initializing from database
      while (provider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      await _loadLocalEmojis();
    });
  }

  Future<void> _loadLocalEmojis() async {
    final provider = context.read<EmojiProvider>();
    
    // Check if emojis already exist in database
    final existingEmojis = provider.emojis;
    if (existingEmojis.isNotEmpty) {
      return;
    }
    
    // Load test emojis from assets only if database is empty
    final testEmojis = [
      EmojiModel(
        id: '1',
        name: 'discard',
        url: 'assets/stickers/discard.gif',
        localPath: 'assets/stickers/discard.gif',
        categoryId: 'default',
        createdAt: DateTime.now(),
      ),
      EmojiModel(
        id: '2',
        name: 'duck',
        url: 'assets/stickers/duck.gif',
        localPath: 'assets/stickers/duck.gif',
        categoryId: 'default',
        createdAt: DateTime.now(),
      ),
    ];

    for (var emoji in testEmojis) {
      await provider.addEmoji(emoji);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('表情包管理'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Consumer<EmojiProvider>(
            builder: (context, provider, child) {
              final showingFavorites = provider.emojis.isNotEmpty &&
                  provider.emojis.every((e) => e.isFavorite);
              return IconButton(
                icon: Icon(
                  showingFavorites ? Icons.favorite : Icons.favorite_border,
                ),
                onPressed: () {
                  if (showingFavorites) {
                    // If showing favorites, reload all emojis
                    provider.loadEmojis();
                  } else {
                    // Otherwise, show only favorites
                    provider.loadFavorites();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<EmojiProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.initialize();
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (provider.emojis.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sentiment_dissatisfied,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无表情包', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadLocalEmojis,
                    child: const Text('加载测试表情包'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: provider.emojis.length,
            itemBuilder: (context, index) {
              final emoji = provider.emojis[index];
              return _EmojiCard(emoji: emoji);
            },
          );
        },
      ),
    );
  }
}

class _EmojiCard extends StatelessWidget {
  final EmojiModel emoji;

  const _EmojiCard({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showShareDialog(context, emoji),
      onLongPress: () => _showOptionsDialog(context, emoji),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                emoji.localPath,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, size: 48),
                  );
                },
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Consumer<EmojiProvider>(
                builder: (context, provider, child) {
                  final currentEmoji = provider.emojis
                      .firstWhere((e) => e.id == emoji.id);
                  final isFavorite = currentEmoji.isFavorite;
                  return GestureDetector(
                    onTap: () {
                      provider.toggleFavorite(emoji.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context, EmojiModel emoji) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.wechat, color: Colors.green, size: 32),
              title: const Text('分享到微信'),
              subtitle: const Text('保持GIF动画效果'),
              onTap: () async {
                Navigator.pop(context);
                await _shareToWeChat(context, emoji);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue, size: 32),
              title: const Text('分享到其他应用'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, EmojiModel emoji) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: Text(emoji.isFavorite ? '取消收藏' : '添加收藏'),
              onTap: () {
                Navigator.pop(context);
                context.read<EmojiProvider>().toggleFavorite(emoji.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, emoji);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToWeChat(BuildContext context, EmojiModel emoji) async {
    try {
      // 检查微信是否安装
      final isInstalled = await WeChatShareService.isWeChatInstalled();
      if (!isInstalled) {
        if (context.mounted) {
          _showError(context, '未安装微信，请先安装微信应用');
        }
        return;
      }

      // 显示加载对话框
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // 读取GIF文件
      final ByteData data = await rootBundle.load(emoji.localPath);
      final Uint8List gifData = data.buffer.asUint8List();

      // 关闭加载对话框
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 分享到微信 (需要替换为真实的AppID)
      final success = await WeChatShareService.shareGifToWeChat(
        gifData: gifData,
        appId: 'YOUR_WECHAT_APPID', // TODO: 替换为真实的微信AppID
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('正在跳转到微信...')),
          );
        } else {
          _showError(context, '分享失败，请重试');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _showError(context, '分享失败: $e');
      }
    }
  }

  void _confirmDelete(BuildContext context, EmojiModel emoji) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除表情包 "${emoji.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<EmojiProvider>().deleteEmoji(emoji.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已删除')),
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('功能即将上线')),
    );
  }
}