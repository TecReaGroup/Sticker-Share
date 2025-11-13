# Sticker Share

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A high-performance Flutter application for managing and sharing animated stickers across messaging platforms. Features smooth Lottie animations, intelligent background loading, and optimized gesture handling.

[中文文档](README_CN.md)

## ✨ Features

- 🎨 **Animated Stickers**: Beautiful Lottie animations with smooth rendering
- 📦 **Sticker Pack Management**: Organize stickers into categorized packs
- ⭐ **Favorites System**: Mark favorite sticker packs for quick access
- 🚀 **Performance Optimized**: Smart background loading and animation pausing
- 📱 **Multi-Platform Sharing**: Share to WeChat, WhatsApp, Telegram, and more
- 🎯 **Gesture Navigation**: Swipe to switch between sticker packs
- 💾 **Local Database**: SQLite-based persistent storage
- 🎭 **Smooth UX**: Optimized scroll performance and animation handling

## 🏗️ Architecture

### Project Structure

```
lib/
├── models/              # Data models
│   ├── sticker_model.dart
│   └── sticker_pack_model.dart
├── providers/           # State management
│   └── sticker_provider.dart
├── screens/            # UI screens
│   ├── home_screen.dart
│   └── splash_screen.dart
├── services/           # Business logic
│   ├── database_service.dart
│   └── messaging_share_service.dart
└── main.dart           # App entry point
```

### Key Technologies

- **State Management**: Provider pattern
- **Local Storage**: SQLite (sqflite)
- **Animations**: Lottie
- **Image Processing**: GIF conversion for sharing
- **Platform Integration**: Method channels for native messaging apps

## 🚀 Getting Started

### Prerequisites

- Flutter SDK: >= 3.9.2
- Dart SDK: >= 3.9.2
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/sticker_share.git
cd sticker_share
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

### Building

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

#### Windows
```bash
flutter build windows --release
```

## 📱 Usage

### Managing Sticker Packs

1. **Browse Packs**: Horizontal scrollable pack selector at the top
2. **Switch Packs**: Swipe left/right on the main grid to navigate
3. **Mark Favorites**: Long-press a pack name to toggle favorite status
4. **Filter Favorites**: Tap the heart icon to show only favorite packs

### Sharing Stickers

1. **Tap a Sticker**: Opens the share dialog
2. **Select App**: Choose from installed messaging apps
3. **Share**: Sticker is converted to GIF and shared

## ⚡ Performance Optimizations

For detailed information about the UI/UX optimizations implemented in this project, see the [Performance Documentation](doc/PERFORMANCE.md).

Key highlights:
- Background Lottie preloading
- Smart animation pause/resume during scrolling
- Prioritized pack loading
- Gesture-based navigation
- Memory-efficient rendering

## 🛠️ Development

### Adding New Sticker Packs

1. Create a new folder in `assets/stickers/[PackName]/`
2. Add Lottie JSON files to `[PackName]/lottie/`
3. Add GIF files to `[PackName]/gif/` (same names as Lottie files)
4. The app will automatically scan and load new packs on next launch

### Database Schema

**sticker_packs**
- id (TEXT): Unique pack identifier
- name (TEXT): Display name
- isFavorite (INTEGER): Favorite status (0/1)

**stickers**
- id (TEXT): Unique sticker identifier
- name (TEXT): Display name
- localPath (TEXT): Lottie JSON asset path
- gifPath (TEXT): GIF asset path
- packId (TEXT): Foreign key to sticker_packs

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📧 Contact

Project Link: [https://github.com/yourusername/sticker_share](https://github.com/yourusername/sticker_share)
