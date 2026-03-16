# WeBuddhist App

A modern Flutter app for learning, sharing, and live collaboration.

## 🚀 Project Goal
WeBuddhist App is designed to help users learn, live, and share knowledge interactively. It features a beautiful UI, supports both light and dark themes, and is built with best Flutter practices.

## 🛠 Features
- Light and Dark theme support with toggle
- Modern Flutter architecture
- Easy to customize and extend

## 📦 Getting Started

### 1. Clone the Repository
```sh
git clone https://github.com/your-username/flutter_pecha.git
cd flutter_pecha
```

### 2. Install Dependencies
```sh
flutter pub get
```

### 3. Environment Setup
Create environment files from the template:
```sh
cp .env.example .env.dev
cp .env.example .env.staging
cp .env.example .env.prod
```
Edit each file with the appropriate values for that environment.

### 4. Run the App

**Android**
```sh
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart
```

Build APK:
```sh
flutter build apk --flavor dev -t lib/main_dev.dart
flutter build apk --flavor staging -t lib/main_staging.dart
flutter build apk --flavor prod -t lib/main_prod.dart
```

Build App Bundle:
```sh
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

**iOS**
```sh
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart
```

Build IPA:
```sh
flutter build ios --flavor prod -t lib/main_prod.dart
```

> **Note:**
> - For iOS, ensure you have Xcode installed and have granted the necessary permissions (see [Flutter macOS setup](https://docs.flutter.dev/get-started/install/macos)).
> - For Android, ensure Android Studio and an emulator/device are set up.

## ⚙️ Project Structure
```
lib/
  main.dart                # App entry point
  theme/app_theme.dart     # Light & dark theme config
  ui/screens/              # UI screens
```

## 🤝 Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## 📄 License
[MIT](LICENSE)





**Table of Contents Screen**
- Browse through organized text content lists with ease
- View all available versions of each text in one convenient location

**Reader Screen**
- Immersive reading experience with optimized formatting

