# 表情包管理应用 (Sticker Share)

一个Flutter开发的表情包管理应用，使用Lottie动画预览，支持GIF动图保持动画效果分享到微信。

## 功能特性

- ✅ Lottie动画预览（流畅高性能）
- ✅ 表情包浏览（网格视图）
- ✅ 收藏功能
- ✅ 分类管理
- ✅ GIF动图分享到微信（保持动画效果）
- ✅ 动态资源加载（自动扫描assets目录）
- ✅ 本地数据库存储
- ✅ 跨平台支持（iOS/Android）

## 技术栈

- **Flutter**: 跨平台UI框架
- **Lottie**: 高性能动画预览
- **Provider**: 状态管理
- **SQLite**: 本地数据库
- **Platform Channels**: 原生功能集成

## 项目结构

```
lib/
├── main.dart                          # 应用入口
├── models/                            # 数据模型
│   ├── emoji_model.dart
│   └── category_model.dart
├── services/                          # 服务层
│   ├── database_service.dart          # 数据库服务
│   ├── wechat_share_service.dart      # 微信分享服务
├── providers/                         # 状态管理
│   └── emoji_provider.dart
├── screens/                           # 页面
│   └── home_screen.dart
ios/Runner/                            # iOS原生代码
│   ├── WeChatSharePlugin.swift        # iOS微信分享插件
│   └── AppDelegate.swift
android/app/src/main/kotlin/           # Android原生代码
    └── WeChatSharePlugin.kt           # Android微信分享插件
```

## 快速开始

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 运行应用

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

## 核心功能实现

### Lottie动画预览

应用使用Lottie JSON格式进行动画预览，提供流畅的UI体验：

```dart
Lottie.asset(
  sticker.localPath,  // Lottie JSON文件路径
  fit: BoxFit.cover,
  animate: !widget.isScrolling,  // 滚动时暂停动画
  frameRate: FrameRate(60),      // 限制帧率为60fps
  renderCache: RenderCache.raster, // 使用光栅缓存
)
```

**优点：**
- ✅ 矢量格式，高清流畅
- ✅ 文件小，加载快
- ✅ 支持复杂动画效果
- ✅ 跨平台一致性好

### 滚动优化 - 智能动画控制

为了保证滚动流畅性和 60fps 的预览体验，应用实现了智能的动画暂停/恢复机制：

#### 工作流程

1. **手指触摸屏幕** → 立即暂停所有 Lottie 动画 ✅
2. **手指离开屏幕** → 标记手指状态为离开，但动画保持暂停 ✅
3. **150ms 延迟后** → 如果手指没有再次触摸，恢复动画播放 ✅
4. **惯性滚动期间** → 因为手指已离开，动画正常播放，不会闪烁 ✅

#### 实现原理

```dart
// 使用 Listener 监听指针事件
Listener(
  onPointerDown: (_) {
    // 手指触摸 - 立即暂停动画
    _resumeAnimationTimer?.cancel();
    setState(() {
      _isFingerDown = true;
      _isScrolling = true;  // 暂停动画
    });
  },
  onPointerUp: (_) {
    // 手指离开 - 延迟恢复动画
    setState(() => _isFingerDown = false);
    
    // 150ms 后恢复动画（避免快速滑动时闪烁）
    _resumeAnimationTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && !_isFingerDown) {
        setState(() => _isScrolling = false);
      }
    });
  },
  child: GridView.builder(...),
)
```

#### 延迟参数调整

可以根据使用体验调整恢复延迟时间：

| 延迟时间 | 适用场景 | 说明 |
|---------|---------|------|
| **100ms** | 快速浏览 | 动画恢复更快，适合快速滑动查看 |
| **150ms** | 平衡选择 | ⭐ **推荐** - 平衡流畅性和响应速度 |
| **200ms** | 避免闪烁 | 更长延迟，确保惯性滚动时动画稳定 |

修改位置：`lib/screens/home_screen.dart` 第 166 行
```dart
_resumeAnimationTimer = Timer(const Duration(milliseconds: 150), () {
  // 调整这里的数值：100, 150, 或 200
});
```

#### 性能优化要点

- ✅ **仅在触摸时暂停** - 避免不必要的性能开销
- ✅ **延迟恢复机制** - 防止快速滑动时动画频繁启停
- ✅ **光栅缓存** - 提升 Lottie 渲染性能
- ✅ **60fps 帧率限制** - 平衡性能和视觉效果
- ✅ **智能状态管理** - 使用 `_isFingerDown` 和 `_isScrolling` 分离控制

#### 用户体验

- 🎯 **流畅滚动** - 滚动时暂停动画，确保 60fps
- 🎯 **快速响应** - 手指离开后短暂延迟即恢复
- 🎯 **无闪烁** - 惯性滚动期间动画正常播放
- 🎯 **自然过渡** - 延迟机制让交互更自然

### 动态资源管理

应用自动扫描`assets/stickers/`目录结构：

```
assets/stickers/
├── DonutTheDog/
│   ├── lottie/      # Lottie JSON文件（UI预览）
│   └── gif/         # GIF文件（微信分享）
└── LovelyPeachy/
    ├── lottie/
    └── gif/
```

- **预览**: 使用Lottie JSON文件
- **分享**: 使用GIF文件（保持动画效果）

### 平台差异说明

| 特性 | iOS | Android |
|------|-----|---------|
| 分享方式 | URL Scheme + 剪贴板 | Intent 系统分享 |
| 是否需要配置 | ❌ **不需要** | ❌ **不需要** |
| 是否需要注册微信开放平台 | ❌ 否 | ❌ 否 |
| GIF 动画保持 | ✅ 是 | ✅ 是 |
| 实现复杂度 | 简单 | 简单 |

### 微信分享（Android）

Android 使用 Intent 系统分享，**无需任何配置**即可使用：

```kotlin
val intent = Intent(Intent.ACTION_SEND).apply {
    type = "image/gif"
    putExtra(Intent.EXTRA_STREAM, gifUri)
    setPackage("com.tencent.mm") // 指定微信包名
}
```

**优点：**
- ✅ 不需要微信开放平台注册
- ✅ 开箱即用
- ✅ GIF 动画完美保持

### 微信分享（iOS）

iOS 使用 PropertyList + 剪贴板方式，**无需配置**即可使用：

1. 构造 PropertyList 数据包（objectType = "8"）
2. 写入剪贴板（type: "content"）
3. 跳转微信（weixin://app/[identifier]/sendreq/?）

关键代码：
```swift
let messageDict: [String: Any] = [
    "objectType": "8",  // GIF类型标识
    "fileData": gifData.data,
    "thumbData": getThumbnail(from: gifData.data),
    "command": "1010",
    "scene": sceneValue,
    // ...
]
```

**优点：**
- ✅ 不需要微信开放平台注册
- ✅ 开箱即用
- ✅ GIF 动画完美保持

## 资源文件

应用动态扫描并加载`assets/stickers/`目录下的所有主题：

- **DonutTheDog**: 30个表情包
- **LovelyPeachy**: 23个表情包

每个表情包包含：
- Lottie JSON文件（用于UI预览）
- GIF文件（用于微信分享）

## 使用说明

1. **浏览表情包**: 主页显示所有表情包的Lottie动画预览
2. **切换主题**: 顶部标签栏切换不同主题
3. **收藏主题**: 长按主题标签收藏
4. **筛选收藏**: 点击右上角心形图标仅显示收藏的主题
5. **分享到微信**:
   - 点击表情包打开分享菜单
   - 选择"分享到微信"
   - 应用会自动使用GIF格式跳转到微信，保持动画效果

## 权限配置

### iOS (Info.plist)

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>weixin</string>
    <string>weixinULAPI</string>
</array>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册保存表情包</string>
```

### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<queries>
    <package android:name="com.tencent.mm"/>
</queries>
```

## 注意事项

### 平台特定

**Android (开箱即用)**
1. ✅ **无需任何配置** - 直接使用即可
2. ✅ **无需注册微信开放平台**
3. ✅ **测试环境**: 只需安装微信
4. ✅ **GIF格式**: 自动保持动画效果

**iOS (开箱即用)**
1. ✅ **无需任何配置** - 直接使用即可
2. ✅ **无需注册微信开放平台**
3. ✅ **测试环境**: 需要真机 + 微信
4. ✅ **GIF格式**: 自动保持动画效果

### 通用注意事项

1. **测试环境**: 需要安装微信才能测试分享功能
2. **预览格式**: UI使用Lottie JSON格式预览
3. **分享格式**: 微信分享使用GIF格式，确保GIF文件格式正确，大小适中（建议 < 500KB）
4. **权限申请**: 首次运行需要授予相应权限
5. **网络环境**: 无需网络连接即可分享本地GIF

## 开发计划

- [ ] 支持从网络下载表情包
- [ ] 支持表情包搜索
- [ ] 支持多种分享方式
- [ ] 支持表情包编辑
- [ ] 云端同步功能

## 许可证

MIT License

## 联系方式

如有问题或建议，欢迎提Issue。
