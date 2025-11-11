# 表情包管理应用 (Sticker Share)

一个Flutter开发的表情包管理应用，支持GIF动图保持动画效果分享到微信。

## 功能特性

- ✅ 表情包浏览（网格视图）
- ✅ 收藏功能
- ✅ 分类管理
- ✅ GIF动图分享到微信（保持动画效果）
- ✅ 本地数据库存储
- ✅ 跨平台支持（iOS/Android）

## 技术栈

- **Flutter**: 跨平台UI框架
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

### 2. 配置微信AppID

在 `lib/screens/home_screen.dart` 中替换微信AppID：

```dart
final success = await WeChatShareService.shareGifToWeChat(
  gifData: gifData,
  appId: 'YOUR_WECHAT_APPID', // 替换为真实的微信AppID
);
```

### 3. 运行应用

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

## 核心功能实现

### 微信分享（iOS）

iOS使用PropertyList + 剪贴板方式实现GIF分享：

1. 构造PropertyList数据包（objectType = "8"）
2. 写入剪贴板（type: "content"）
3. 跳转微信（weixin://app/{appId}/sendreq/?）

关键代码：
```swift
let messageDict: [String: Any] = [
    "objectType": "8",  // GIF类型标识
    "fileData": gifData.data,
    "thumbData": getThumbnail(from: gifData.data),
    // ...
]
```

### 微信分享（Android）

Android使用Intent分享：

```kotlin
val intent = Intent(Intent.ACTION_SEND).apply {
    type = "image/gif"
    putExtra(Intent.EXTRA_STREAM, gifUri)
    setPackage("com.tencent.mm")
}
```

## 测试数据

应用包含两个测试GIF表情包：
- `assets/stickers/discard.gif`
- `assets/stickers/duck.gif`

点击"加载测试表情包"按钮即可加载。

## 使用说明

1. **浏览表情包**: 主页显示所有表情包的网格视图
2. **收藏表情包**: 点击表情包右上角的心形图标
3. **分享到微信**: 
   - 点击表情包打开分享菜单
   - 选择"分享到微信"
   - 应用会跳转到微信，保持GIF动画效果
4. **删除表情包**: 长按表情包，选择删除选项

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

1. **微信AppID**: 需要在微信开放平台注册应用获取AppID
2. **测试环境**: 需要安装微信才能测试分享功能
3. **GIF格式**: 确保GIF文件格式正确，大小适中
4. **权限申请**: 首次运行需要授予相应权限

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
