# WasteWise App - Flutter Project Documentation

## 📝 Project Overview

Welcome to the WasteWise App, a Flutter-based mobile application developed by RVU Team 05 in Sprint 2. This project demonstrates a complete mobile development environment setup and exploration of Flutter's project structure. The app is designed to help users manage and track waste disposal efficiently.

---

## 🏗️ Project Structure Overview

This Flutter project follows the standard Flutter architecture, with clear separation between cross-platform Dart code and platform-specific configurations. For a detailed exploration of each folder and file, refer to **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)**.

### Quick Folder Guide

```
first_flutter_app/
├── lib/                    # ⭐ Core Dart application code
├── android/                # Android-specific build configuration
├── ios/                    # iOS-specific build configuration
├── test/                   # Automated test files
├── assets/                 # Static resources (images, fonts)
├── pubspec.yaml            # Dependency and configuration management
└── PROJECT_STRUCTURE.md    # Detailed folder structure documentation
```

### Key Folders Explained

| Folder | Purpose | Managed By |
|--------|---------|-----------|
| **lib/** | Main application code written in Dart | Developers |
| **android/** | Android SDK configuration and native code | Gradle + Flutter |
| **ios/** | iOS SDK configuration and native code | Xcode + Flutter |
| **assets/** | Images, fonts, JSON files, and static data | Developers |
| **test/** | Unit, widget, and integration tests | Developers |
| **build/** | Auto-generated compiled builds | Flutter (read-only) |
| **.dart_tool/** | Dart/Flutter internal files | Dart (read-only) |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10.7+
- Android Studio / VS Code
- Xcode (for iOS development on macOS)
- Android Emulator or physical device

### Setup Instructions

1. **Clone and Navigate:**
   ```bash
   git clone <repository-url>
   cd first_flutter_app
   ```

2. **Get Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the App:**
   ```bash
   flutter run
   ```

4. **Run Tests:**
   ```bash
   flutter test
   ```

---

## 📂 Understanding the lib/ Folder

The `lib/` directory is the heart of your Flutter application. Here's a recommended structure for the WasteWise App:

```
lib/
├── main.dart                      # App entry point
├── screens/                       # Full-screen pages
│   ├── home_screen.dart
│   ├── waste_tracking_screen.dart
│   └── profile_screen.dart
├── widgets/                       # Reusable UI components
│   ├── custom_app_bar.dart
│   ├── waste_item_card.dart
│   └── bottom_nav_bar.dart
├── models/                        # Data structures
│   ├── waste_item.dart
│   ├── user.dart
│   └── disposal_location.dart
├── services/                      # Business logic & APIs
│   ├── waste_service.dart
│   ├── location_service.dart
│   └── notification_service.dart
└── utils/                         # Helpers and constants
    ├── constants.dart
    └── validators.dart
```

---

## 🛠️ Sprint #1: Environment Setup

**Completed Milestones:**

✅ **Flutter SDK Installation**
- Downloaded and configured Flutter SDK for Windows
- Updated system PATH for global command access
- Verified installation with `flutter doctor`

✅ **Android Studio & SDK Configuration**
- Installed Android Studio with all necessary plugins
- Configured Android SDK and accepted all licenses
- Set up Gradle build system

✅ **Emulator Setup**
- Created Pixel 6 virtual device with Android 14 (API 34)
- Verified device connectivity with `flutter devices`

---

## 💡 Key Insights: Why Project Structure Matters

### **1. Scalability**
A clean folder structure prevents the codebase from becoming unwieldy as the project grows. Each component has a clear home, making it easy to locate and modify features.

### **2. Team Collaboration**
- Multiple developers can work on different screens, services, or widgets simultaneously
- Clearly defined folder purposes reduce merge conflicts
- New team members can quickly understand the codebase organization

### **3. Cross-Platform Support**
Flutter's structure elegantly handles multi-platform development:
- **lib/** contains shared Dart code that runs on all platforms
- **android/**, **ios/**, **web/**, and desktop folders handle platform-specific configurations
- One codebase compiles to APK (Android), IPA (iOS), Web, and Desktop apps

### **4. Maintainability**
- Services are isolated for easy testing and debugging
- Reusable widgets reduce code duplication
- Models centralize data structure definitions
- Utils/helpers keep the codebase DRY (Don't Repeat Yourself)

### **5. Asset Management**
- Centralized **assets/** folder keeps all resources organized
- Declaring assets in `pubspec.yaml` ensures proper inclusion in builds
- Easy versioning and updates to images, fonts, or data files

---

## 🔗 Important Configuration Files

### pubspec.yaml
Manages all dependencies, assets, and app metadata:

```yaml
name: first_flutter_app
version: 1.0.0+1

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/fonts/
```

### android/app/build.gradle.kts
Defines Android-specific settings:
- App name and version
- Min/target SDK versions
- Android-specific dependencies
- Signing configuration

### ios/Runner/Info.plist
Defines iOS-specific settings:
- App name and version
- Permissions (camera, location, etc.)
- App icons and launch screen
- iOS-specific features

---

## 🧪 Testing Structure

The `test/` folder contains automated tests:

```
test/
├── widget_test.dart          # UI widget tests
├── unit_tests/               # Business logic tests
│   ├── waste_service_test.dart
│   └── validators_test.dart
└── integration_tests/        # End-to-end user flow tests
    └── app_flow_test.dart
```

**Run tests with:**
```bash
flutter test
```
---

## 💭 Reflection & Learning Outcomes

### Understanding Project Structure Benefits

**Q: Why is understanding the folder structure important?**

A: The Flutter folder structure is the blueprint for scalable development. Each folder has a specific purpose:
- **lib/** keeps all Dart logic isolated from platform-specific code
- **android/** and **ios/** allow platform customization without duplicating shared code
- **assets/** centralizes resources for easy management
- **test/** ensures code quality through automated testing

This organization is critical for:
- Onboarding new team members quickly
- Scaling the app to handle 100k+ lines of code
- Supporting multi-platform deployment
- Facilitating CI/CD pipelines and automated testing

### Team Collaboration Benefits

**Q: How does clean structure help when working in a team?**

A: With clear folder boundaries:
- **Developer A** can work on authentication services (`services/auth_service.dart`)
- **Developer B** can work on home screen UI (`screens/home_screen.dart`)
- **Developer C** can work on waste tracking widgets (`widgets/waste_tracking/`)

These teams rarely conflict because they're working in different folders. Merge conflicts are minimal, and code reviews are focused on specific components.

### Cross-Platform Advantage

**Q: How does the structure support cross-platform development?**

A: Flutter's genius is that 95% of your code is shared (`lib/`). Platform-specific code is isolated in `android/`, `ios/`, `web/`, etc. This means:
- Write logic once, run on 4+ platforms
- Platform customization is localized and doesn't affect shared code
- Testing shared code benefits all platforms simultaneously
- One PR often enables features across all platforms