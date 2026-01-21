# Flutter Environment Setup and First App Run

## 📝 Project Overview

This milestone focuses on establishing a complete mobile development environment. I have successfully installed the Flutter SDK, configured Android Studio, and verified the setup by running the app on a mobile emulator.

## 🛠️ Steps Followed

### 1. Flutter SDK Installation

* **Download:** Downloaded the Flutter SDK for Windows and extracted it to `C:\src\flutter`.
* **PATH Update:** Added the `bin` folder to the System Environment Variables (Path) to enable global terminal commands.
* **Verification:** Ran `flutter doctor` to ensure the toolchain was correctly recognized.

### 2. Android Studio & SDK Configuration

* **Installation:** Installed Android Studio with the "Standard" setup, including the Android SDK and Platform-tools.
* **Plugins:** Installed the Flutter and Dart plugins within Android Studio to support mobile development.
* **Licenses:** Executed `flutter doctor --android-licenses` in the terminal to accept all necessary SDK agreements.

### 3. Emulator Setup

* **Device Creation:** Used the **Virtual Device Manager** to create a Pixel 6 device.
* **System Image:** Downloaded and installed the **Android 14 (API 34)** system image.
* **Connection:** Verified device detection by running `flutter devices` while the emulator was active.

---

## 📸 Setup Verification

### Flutter Doctor Output

> *[Insert your screenshot here showing all green checkmarks in the terminal]*

### Running App on Emulator

>

---

## 💭 Reflection

**What challenges did you face during installation?**
*(Example: "The main challenge was resolving the Android license issue, which required running a specific terminal command. I also had to enable Hardware Virtualization in my BIOS to get the emulator to run smoothly.")*

**How does this setup prepare you for building and testing real mobile apps?**
*(Example: "This setup allows me to test mobile-specific UI elements like the BottomNavigationBar and touch gestures in a realistic environment. It bridges the gap between web development and true mobile engineering.")*
