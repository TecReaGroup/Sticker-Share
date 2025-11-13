# Sticker Share

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

`English` | [中文](README_CN.md)

Sticker Share: Manage and share animated stickers to various messaging platforms.

<p align="center">
  <img src="./assets/images/splashScreen.jpg" width="30%" />
  <img src="./assets/images/homeScreen.jpg" width="30%" />
  <img src="./assets/images/wechat.jpg" width="30%" />
</p>

## Notes

[Telegram Stickers Download](https://github.com/TecReaGroup/telgram_stickers_download)

Currently only tested on Android, the specific situation for Android is as follows:

| App | Status | Notes |
|-----|------|------|
| WeChat | Tested | Send to preview cannot load |
| QQ | Tested | Fully supported |
| Discord | Tested | Fully supported |
| X | Tested | Fully supported |
| Messenger | Tested | Fully supported |
| Telegram | Tested | Automatically converts to image |
| WhatsApp | Untested | To be tested |
| LINE | Untested | To be tested |

## Architecture

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

## Getting Started

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

## Usage

### Managing Sticker Packs

1. **Browse Packs**: Horizontal scrollable pack selector at the top
2. **Switch Packs**: Swipe left/right on the main grid to navigate
3. **Mark Favorites**: Long-press a pack name to toggle favorite status
4. **Filter Favorites**: Tap the heart icon to show only favorite packs

### Sharing Stickers

1. **Tap a Sticker**: Opens the share dialog
2. **Select App**: Choose from installed messaging apps
3. **Share**: Sticker is converted to GIF and shared

## Performance Optimization

For detailed information about the UI/UX optimizations implemented in this project, see the [Performance Documentation](doc/PERFORMANCE.md).

Key highlights:
- Background Lottie preloading
- Smart animation pause/resume during scrolling
- Prioritized pack loading
- Gesture-based navigation
- Memory-efficient rendering
- Clicking on a sticker shows only half of the bottom listTile to hint at scrolling

## Development

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

## TODO List
 - [ ] Local import of Stickers
 - [ ] Cloud backup and download
 - [ ] Multi-language support
 - [ ] Add sticker preview feature (long press to view)
 - [ ] Optimize operation logic and UI/UX for better Sticker management
 - [ ] iOS support
 - [ ] Support sticker editing

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
