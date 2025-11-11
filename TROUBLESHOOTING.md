# 故障排除指南 (Troubleshooting Guide)

## 常见编译错误及解决方案

### ❌ 错误 1: Kotlin 编译缓存错误

**错误信息:**
```
e: Daemon compilation failed: null
java.lang.Exception: Could not close incremental caches
Caused by: java.lang.IllegalArgumentException: this and base files have different roots
```

**原因:**
- Kotlin 增量编译缓存损坏
- 项目路径与依赖包路径不在同一驱动器（如项目在 D: 盘，依赖在 C: 盘）
- Gradle 构建缓存问题

**解决方案:**

#### 方法 1: 清理构建缓存（推荐）
```bash
# 清理 Flutter 缓存
flutter clean

# 获取依赖
flutter pub get

# 重新运行
flutter run
```

#### 方法 2: 清理 Gradle 缓存
```bash
# Windows
cd android
gradlew clean
cd ..

# macOS/Linux
cd android
./gradlew clean
cd ..
```

#### 方法 3: 完全清理（如果方法1和2不起作用）
```bash
# 删除构建目录
rmdir /s /q build          # Windows
rm -rf build               # macOS/Linux

# 删除 Android 构建缓存
rmdir /s /q android\build  # Windows
rm -rf android/build       # macOS/Linux

# 删除 Gradle 缓存
rmdir /s /q %USERPROFILE%\.gradle\caches  # Windows
rm -rf ~/.gradle/caches                   # macOS/Linux

# 重新构建
flutter pub get
flutter run
```

---

### ⚠️ 警告 1: Java 版本过时警告

**警告信息:**
```
warning: [options] source value 8 is obsolete and will be removed in a future release
warning: [options] target value 8 is obsolete and will be removed in a future release
```

**原因:**
- 某些依赖包仍使用 Java 8
- 这是依赖包的问题，不是项目本身的问题

**影响:**
- ⚠️ **不影响应用运行**
- 只是编译时的警告

**解决方案（可选）:**

当前项目已配置使用 Java 11:
```kotlin
// android/app/build.gradle.kts
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_11
    targetCompatibility = JavaVersion.VERSION_11
}

kotlinOptions {
    jvmTarget = JavaVersion.VERSION_11.toString()
}
```

如果警告持续出现，可以在 [`android/app/build.gradle.kts`](android/app/build.gradle.kts:8) 添加：

```kotlin
android {
    // ... 其他配置 ...
    
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
        // 抑制警告
        freeCompilerArgs += listOf(
            "-Xlint:deprecation",
            "-Xlint:unchecked"
        )
    }
}
```

---

### ❌ 错误 2: 微信分享失败

**错误信息:**
```
分享失败
```

**原因:**
1. 未安装微信
2. 微信 AppID 未配置或错误
3. iOS/Android 应用签名未提交到微信开放平台
4. 权限配置问题

**解决方案:**

#### 检查清单:

1. **确认微信已安装**
   ```dart
   final isInstalled = await WeChatShareService.isWeChatInstalled();
   print('微信安装状态: $isInstalled');
   ```

2. **检查 AppID 配置**
   
   在 [`lib/screens/home_screen.dart:309`](lib/screens/home_screen.dart:309):
   ```dart
   final success = await WeChatShareService.shareGifToWeChat(
     gifData: gifData,
     appId: 'YOUR_WECHAT_APPID', // 确保替换为真实的 AppID
   );
   ```

3. **iOS 配置检查**
   
   检查 [`ios/Runner/Info.plist`](ios/Runner/Info.plist):
   ```xml
   <key>LSApplicationQueriesSchemes</key>
   <array>
       <string>weixin</string>
       <string>weixinULAPI</string>
   </array>
   ```

4. **Android 配置检查**
   
   检查 [`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml):
   ```xml
   <queries>
       <package android:name="com.tencent.mm"/>
   </queries>
   ```

5. **应用签名**
   
   - iOS: Bundle ID 必须与微信开放平台注册的一致
   - Android: 应用签名（MD5）必须提交到微信开放平台

---

### ❌ 错误 3: GIF 图片不显示

**错误信息:**
```
Unable to load asset: assets/stickers/xxx.gif
```

**原因:**
- assets 未在 pubspec.yaml 中配置
- 文件路径错误
- 文件不存在

**解决方案:**

1. **检查 pubspec.yaml**
   
   确认 [`pubspec.yaml:61`](pubspec.yaml:61) 包含:
   ```yaml
   flutter:
     assets:
       - assets/stickers/
   ```

2. **运行 pub get**
   ```bash
   flutter pub get
   ```

3. **验证文件存在**
   ```bash
   # Windows
   dir assets\stickers

   # macOS/Linux
   ls -la assets/stickers
   ```

4. **重新启动应用**
   ```bash
   flutter run
   ```

---

### ❌ 错误 4: 数据库错误

**错误信息:**
```
Database is locked
DatabaseException: table not found
```

**原因:**
- 数据库文件损坏
- 应用卸载后数据库未清理
- 数据库迁移问题

**解决方案:**

1. **卸载应用重新安装**
   ```bash
   # Android
   adb uninstall com.example.sticker_share
   flutter run

   # iOS
   # 在设备上长按应用图标 → 删除应用
   flutter run
   ```

2. **清除应用数据（Android）**
   ```bash
   adb shell pm clear com.example.sticker_share
   ```

3. **代码中清理数据库（开发调试用）**
   
   在 [`lib/services/database_service.dart`](lib/services/database_service.dart:144) 调用:
   ```dart
   await DatabaseService().clearAllData();
   ```

---

### ❌ 错误 5: iOS 真机调试失败

**错误信息:**
```
Code signing error
Provisioning profile not found
```

**原因:**
- 未配置开发者证书
- Bundle ID 不匹配
- 设备未信任开发者

**解决方案:**

1. **在 Xcode 中配置签名**
   ```bash
   open ios/Runner.xcworkspace
   ```
   - 选择 Runner target
   - Signing & Capabilities
   - 选择 Team
   - 勾选 "Automatically manage signing"

2. **信任开发者证书**
   
   在 iOS 设备上:
   ```
   设置 → 通用 → 设备管理 → [你的开发者账号] → 信任
   ```

3. **检查 Bundle ID**
   
   确保 Xcode 中的 Bundle ID 与微信开放平台注册的一致

---

## 性能问题

### 问题: 应用启动慢

**原因:**
- 首次启动需要初始化数据库
- 加载大量 GIF 图片

**解决方案:**

1. **使用启动画面**（已实现）

2. **延迟加载**
   
   修改 [`lib/screens/home_screen.dart`](lib/screens/home_screen.dart) 使用分页加载

3. **压缩 GIF**
   
   建议 GIF 文件大小 < 500KB

---

### 问题: 应用卡顿

**原因:**
- 同时加载过多大 GIF
- 内存不足

**解决方案:**

1. **限制同时显示的 GIF 数量**
   ```dart
   GridView.builder(
     cacheExtent: 200, // 限制缓存范围
     // ...
   )
   ```

2. **使用缓存**
   ```dart
   CachedNetworkImage(
     maxWidthDiskCache: 400,
     maxHeightDiskCache: 400,
     // ...
   )
   ```

---

## 调试技巧

### 查看详细日志

```bash
# Flutter 日志
flutter logs

# 带过滤的日志
flutter logs | findstr "Error"    # Windows
flutter logs | grep "Error"       # macOS/Linux
```

### Android 调试

```bash
# 查看 Android 日志
adb logcat | findstr "flutter"    # Windows
adb logcat | grep "flutter"       # macOS/Linux

# 查看崩溃日志
adb logcat | findstr "FATAL"      # Windows
adb logcat | grep "FATAL"         # macOS/Linux
```

### iOS 调试

```bash
# 在 Xcode 中查看日志
Window → Devices and Simulators → 选择设备 → Open Console
```

---

## 构建优化

### 减少 APK 大小

```bash
# 构建 release 版本
flutter build apk --release --split-per-abi

# 会生成 3 个 APK:
# - app-armeabi-v7a-release.apk
# - app-arm64-v8a-release.apk
# - app-x86_64-release.apk
```

### 加快编译速度

在 [`android/gradle.properties`](android/gradle.properties) 添加:
```properties
org.gradle.jvmargs=-Xmx4096m
org.gradle.parallel=true
org.gradle.daemon=true
kotlin.incremental=true
```

---

## 获取帮助

如果以上方法都无法解决问题:

1. 查看 [Flutter 官方文档](https://flutter.dev/docs)
2. 查看 [微信开放平台文档](https://developers.weixin.qq.com/doc/)
3. 在项目中提交 Issue
4. 在 Stack Overflow 提问并添加 `flutter` 标签

---

## 重要提示

✅ **应用正常运行的标志:**
- 应用能启动并显示主页
- 能看到 GIF 表情包动画
- 点击表情包能弹出分享菜单

⚠️ **可以忽略的警告:**
- Java 版本过时警告（不影响运行）
- Kotlin 编译警告（不影响运行）
- Gradle 构建缓存警告（不影响运行）

❌ **必须修复的错误:**
- 应用崩溃
- 无法启动
- 分享功能完全无法使用