# DoseTime 💊

A beautiful, reliable medication reminder app built with Flutter. Never miss a dose again!

![Flutter](https://img.shields.io/badge/Flutter-3.24-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)

## Features

- 📱 **Track Medications** - Add all your medications with custom schedules
- ⏰ **Smart Reminders** - Reliable notifications, even in battery-saving mode
- 📊 **Adherence Tracking** - View your medication history with calendar view and PDF reports
- 🌙 **Dark Mode** - Beautiful light and dark themes
- 🔒 **Privacy First** - All data stored locally on your device
- 💎 **Pro Features** - Unlimited medications with Pro upgrade
- 📞 **Contacts** - Manage doctors and pharmacies directly in the app
- ✨ **Polished UI** - Haptic feedback, accessibility support, and 3D design elements

## Screenshots

*Coming soon*

## Getting Started

### Prerequisites

- Flutter SDK 3.24+
- Android Studio / VS Code
- Android SDK (API 23+) for Android
- Xcode (for iOS development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Hubert24hrs/DoseTime.git
   cd DoseTime
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase** (optional, for analytics)
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase
   flutterfire configure
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Release

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

## Architecture

```
lib/
├── core/
│   ├── database/       # SQLite database helper
│   ├── router/         # GoRouter navigation
│   ├── services/       # Core services (analytics, permissions, storage)
│   ├── theme/          # App theming
│   ├── utils/          # Utilities and validators
│   └── widgets/        # Shared widgets
├── features/
│   ├── history/        # Medication history
│   ├── medication/     # Medication CRUD
│   ├── onboarding/     # User onboarding
│   ├── reminders/      # Notification service
│   └── settings/       # App settings
├── firebase_options.dart
└── main.dart
```

### Tech Stack

- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Local Storage**: SQLite + Secure Storage
- **Notifications**: flutter_local_notifications
- **Analytics**: Firebase Analytics & Crashlytics
- **In-App Purchases**: RevenueCat

## Configuration

### Environment Variables

Create `android/key.properties` for release signing:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path/to/keystore.jks
```

### Firebase Setup

Replace `lib/firebase_options.dart` with your Firebase configuration using:
```bash
flutterfire configure
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Legal

- [Privacy Policy](docs/privacy_policy.md)
- [Terms of Service](docs/terms_of_service.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter team for the amazing framework
- All open-source contributors

---

**Made with ❤️ by Hubert**
