# Flutter Project Structure Guide

## 📚 Introduction

Understanding the Flutter project folder structure is fundamental to building scalable, maintainable mobile applications. When you create a new Flutter project using `flutter create`, the framework automatically generates a well-organized directory structure that accommodates both Android and iOS platforms while keeping your Dart code organized in a central location. This structure ensures clean separation of concerns, supports team collaboration, and facilitates efficient app development across multiple platforms.

---

## 📁 Project Folder Hierarchy

```
first_flutter_app/
├── lib/                          # Core Dart application code
│   ├── main.dart                # App entry point
│   ├── screens/                 # UI screens/pages (optional subdirectory)
│   ├── widgets/                 # Reusable custom widgets (optional subdirectory)
│   ├── models/                  # Data models (optional subdirectory)
│   └── services/                # Business logic and APIs (optional subdirectory)
├── android/                      # Android-specific configuration
│   ├── app/
│   │   ├── build.gradle.kts     # Android app build configuration
│   │   └── src/                 # Android source code and manifest
│   ├── build.gradle.kts         # Project-level build configuration
│   └── gradle/                  # Gradle wrapper files
├── ios/                          # iOS-specific configuration
│   ├── Runner/                  # Main iOS app folder
│   │   ├── Info.plist           # iOS app metadata and permissions
│   │   ├── AppDelegate.swift    # iOS app lifecycle handling
│   │   └── Assets.xcassets/     # iOS-specific assets
│   └── Runner.xcworkspace/      # Xcode workspace
├── web/                          # Web platform files (Flutter web)
│   ├── index.html               # Web app entry point
│   ├── manifest.json            # Web app manifest
│   └── icons/                   # Web app icons
├── windows/                      # Windows desktop platform files
├── macos/                        # macOS desktop platform files
├── linux/                        # Linux desktop platform files
├── test/                         # Automated test files
│   └── widget_test.dart         # Default widget test
├── assets/                       # Static resources (manual creation)
│   ├── images/                  # App images and icons
│   ├── fonts/                   # Custom fonts
│   └── data/                    # JSON files or other data
├── pubspec.yaml                 # Dart package dependency management
├── pubspec.lock                 # Locked dependency versions
├── analysis_options.yaml        # Dart lint rules configuration
├── build/                       # Generated build output (auto-generated)
├── .dart_tool/                  # Dart/Flutter internal files (auto-generated)
├── .idea/                       # Android Studio IDE configuration
├── .gitignore                   # Git ignore rules
└── README.md                    # Project documentation
```

---

## 📋 Folder and File Descriptions

### **lib/** - Application Core
| Item | Purpose |
|------|---------|
| `main.dart` | Entry point of the application; contains `main()` function and root widget |
| `screens/` | Organizes full-screen page widgets (e.g., HomeScreen, ProfileScreen) |
| `widgets/` | Contains reusable custom widgets to avoid code duplication |
| `models/` | Defines data structures and classes representing app entities |
| `services/` | Contains business logic, API calls, and external integrations |

**Why organize this way?** 
- **Scalability**: As your app grows, this structure prevents the lib folder from becoming cluttered
- **Reusability**: Shared widgets and services can be easily accessed across screens
- **Testing**: Each component can be unit tested independently
- **Team Collaboration**: Clear separation makes it easier for multiple developers to work simultaneously

---

### **android/** - Android Platform Configuration
| Item | Purpose |
|------|---------|
| `app/build.gradle.kts` | Defines app name, version, and Android-specific dependencies |
| `app/src/` | Contains Android manifest and native Java/Kotlin code |
| `build.gradle.kts` | Project-level build configuration for Gradle |
| `gradle/wrapper/` | Gradle build tool version specification |

**Key Points:**
- You rarely modify these files directly; Flutter handles most configuration
- Update `app/build.gradle.kts` to add Android-specific plugins or libraries
- The `AndroidManifest.xml` (in `app/src/main/`) defines permissions and app metadata

---

### **ios/** - iOS Platform Configuration
| Item | Purpose |
|------|---------|
| `Runner/Info.plist` | iOS app metadata (app name, version, permissions, icons) |
| `Runner/AppDelegate.swift` | iOS app lifecycle and initialization code |
| `Runner.xcworkspace/` | Xcode workspace file (open this, not .xcodeproj) |
| `Runner/Assets.xcassets/` | iOS-specific image assets and icons |

**Key Points:**
- Modify `Info.plist` to request iOS permissions (camera, location, etc.)
- The `AppDelegate.swift` handles plugin registration for native iOS code
- Always open the `.xcworkspace` file in Xcode, not `.xcodeproj`

---

### **test/** - Automated Testing
| Item | Purpose |
|------|---------|
| `widget_test.dart` | Default test file for testing UI widgets |

**Common Test Types:**
- **Unit Tests**: Test individual functions/methods in isolation
- **Widget Tests**: Test UI widgets and interactions
- **Integration Tests**: Test complete user workflows across the app

---

### **assets/** - Static Resources (Manual Creation)
This folder must be created manually. Declare all assets in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/fonts/
```

| Subfolder | Purpose |
|-----------|---------|
| `images/` | PNG, JPEG, SVG images used throughout the app |
| `fonts/` | Custom TTF or OTF font files |
| `data/` | JSON files, configuration files, or static data |

---

### **pubspec.yaml** - Dependency and Configuration Management
The most critical file in a Flutter project.

**Key Sections:**
```yaml
name: first_flutter_app                    # App package name
version: 1.0.0+1                          # Version + build number

environment:
  sdk: ^3.10.7                            # Dart SDK version requirement

dependencies:
  flutter:
    sdk: flutter                          # Flutter framework
  provider: ^6.0.0                        # Example: state management package
  http: ^1.1.0                            # Example: HTTP client

dev_dependencies:
  flutter_test:
    sdk: flutter                          # Testing framework
  flutter_lints: ^6.0.0                   # Linting rules

flutter:
  uses-material-design: true              # Use Material Design
  assets:
    - assets/images/
    - assets/fonts/
```

---

### **Supporting Files**

| File | Purpose |
|------|---------|
| `pubspec.lock` | Auto-generated lock file specifying exact dependency versions |
| `analysis_options.yaml` | Dart static analyzer configuration for code quality |
| `.gitignore` | Specifies files/folders Git should ignore (build/ .dart_tool/ etc.) |
| `README.md` | Project documentation and setup instructions |
| `build/` | Auto-generated folder with compiled builds (do NOT edit manually) |
| `.dart_tool/` | Internal Dart/Flutter files (auto-generated, ignore this folder) |
| `.idea/` | Android Studio/IntelliJ IDE configuration (can be ignored in git) |

---

## 🏗️ Recommended Project Structure for Scalability

For larger projects, organize your `lib/` folder hierarchically:

```
lib/
├── main.dart
├── config/
│   ├── theme.dart
│   └── constants.dart
├── models/
│   ├── user_model.dart
│   └── post_model.dart
├── screens/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── home_view_model.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── auth/
│       └── login_screen.dart
├── widgets/
│   ├── common/
│   │   ├── custom_app_bar.dart
│   │   └── custom_button.dart
│   └── home/
│       └── home_card_widget.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── storage_service.dart
├── providers/
│   ├── user_provider.dart
│   └── theme_provider.dart
└── utils/
    ├── helpers.dart
    └── validators.dart
```

---

## 💡 Why This Structure Matters

### **1. Scalability**
- As your app grows from 10,000 to 100,000+ lines of code, a well-organized structure prevents chaos
- Each folder has a clear responsibility, making navigation intuitive
- New team members can quickly understand the codebase

### **2. Team Collaboration**
- Different developers can work on different screens or services simultaneously
- Clear separation reduces merge conflicts
- Code reviews are more effective when changes are localized to specific folders

### **3. Platform Management**
- Separate `android/` and `ios/` folders allow platform-specific customization
- The `lib/` folder remains shared code, reducing duplication
- Makes it easy to manage platform-specific permissions, APIs, or features

### **4. Testing & Maintenance**
- Easy to write focused unit tests for services or models
- Widget tests can target specific screens
- Modular structure makes refactoring less risky

### **5. Asset Management**
- Centralized `assets/` folder keeps all resources organized
- Declaring assets in `pubspec.yaml` ensures they're included in builds
- Version control stays clean with proper `.gitignore` configuration

---

## 🔄 Cross-Platform Build System

Flutter's folder structure elegantly supports cross-platform development:

```
┌─────────────────────────────────────────┐
│     lib/ (Shared Dart Code)             │
│  - UI widgets, business logic, services │
└─────────────┬───────────────────────────┘
              │
    ┌─────────┴─────────┬────────────┬──────────┐
    │                   │            │          │
┌───▼────┐      ┌──────▼────┐  ┌────▼───┐  ┌──▼──┐
│Android  │      │    iOS    │  │  Web   │  │Desk-│
│Platform │      │ Platform  │  │Platform│  │top  │
│(android/│      │(ios/)     │  │(web/)  │  │(win/│
│ gradle) │      │(Xcode)    │  │(HTML)  │  │mac/ │
└────┬────┘      └──────┬────┘  └────┬───┘  │lin) │
     │                  │            │      └─────┘
     └──────────────────┴────────────┘
           One codebase, four platforms!
```

This unified approach means:
- Write logic once in Dart, run everywhere
- Platform-specific code is isolated in respective folders
- Updates to shared code automatically benefit all platforms

---

## ✅ Getting Started Checklist

- [ ] Understand the role of `lib/` as your main development folder
- [ ] Know that `android/` and `ios/` handle platform-specific builds
- [ ] Create an `assets/` folder for images, fonts, and data files
- [ ] Update `pubspec.yaml` when adding new dependencies or assets
- [ ] Use `test/` folder for writing automated tests
- [ ] Keep `.gitignore` to exclude build files from version control
- [ ] Document project setup and folder structure in `README.md`

---

## 📖 References

- [Flutter Documentation - Project Structure](https://flutter.dev/docs)
- [Dart Package Structure](https://dart.dev/guides/packages)
- [Flutter Best Practices](https://flutter.dev/docs/testing/best-practices)

---

**Last Updated**: January 20, 2026  
**Project**: WasteWise App - Sprint 2  
**Team**: RVU Team 05
