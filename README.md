# Shorebird OTA Code Push — Developer Guide

This guide provides step-by-step instructions for updating your Flutter application, both when publishing **Over-The-Air (OTA) UI/logic patches** directly to users and when releasing **new app versions** to the Google Play Store.

---

## ⚡ Essential Commands Quick Reference

### 📱 1. Build & Install Release APK on Physical Phone
```bash
# Build the initial release APK containing Shorebird Engine
shorebird release android --artifact apk

# Install APK directly onto your USB-connected Android phone
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 📦 2. Build Release App Bundle (AAB for Google Play Store)
```bash
# Build App Bundle for Google Play Console submission
shorebird release android --artifact aab
```

### 🚀 3. Publish Instant OTA Patch (UI / Copy / Dart Updates)
```bash
# Publish OTA patch to live users
shorebird patch android --track stable

# If adding new Dart packages or assets, pass flags:
shorebird patch android --track stable --allow-native-diffs --allow-asset-diffs
```

---

## 🚀 Decision Guide

```
                      What changes did you make?
                                  │
         ┌────────────────────────┴────────────────────────┐
         ▼                                                 ▼
[ UI / Copy / Dart Code / Assets ]              [ Version Bump / Native Code / Plugins ]
         │                                                 │
         ▼                                                 ▼
    SCENARIO A                                        SCENARIO B
  Push OTA Patch                                 New Play Store Release
 (Instant, No Store Review)                    (Upload AAB to Play Console)
```

---

## 🛠️ Scenario A: Updating UI / Copy / Business Logic (OTA Patch)

Use this scenario for **Dart-only updates** (modifying screens, fixing bugs, changing text, colors, state logic, API URLs, or Flutter assets).

### Step 1: Make Your Code Changes
Edit your Dart files in Android Studio (e.g. updating `lib/shorebird_demo_screen.dart`).

### Step 2: Test Locally (Optional)
Run standard tests to make sure your changes pass:
```bash
flutter analyze
flutter test
```

### Step 3: Publish the OTA Patch
Open your terminal in the project root and run:

```bash
# Push patch to production users
shorebird patch android --track stable
```

*If you added a new Dart package or Flutter asset diff, pass:*
```bash
shorebird patch android --track stable --allow-native-diffs --allow-asset-diffs
```

### Step 4: Verify on User App
1. Open the app on your phone.
2. Tap **Check & Download OTA Patch** (or wait for the app to detect it automatically).
3. Tap **Restart App Now (Apply Update)** (or close and reopen the app).
4. The updated UI is now live on the phone!

---

## 📦 Scenario B: Releasing a New App Version (Store Release)

Use this scenario when:
- Bumping the application version number in `pubspec.yaml` (e.g., `1.0.1+2` ➔ `1.0.2+3`).
- Adding or updating native plugins (`Kotlin`, `Java`, `C++`, native Android libraries).
- Modifying `pubspec.yaml` dependency versions that include native code.
- Editing `android/app/build.gradle.kts`, `AndroidManifest.xml`, or permissions.

---

### Step 1: Bump Version Number
Open `pubspec.yaml` and update the version field:

```yaml
# Format: versionName+versionCode
version: 1.0.2+3
```

---

### Step 2: Build & Register the Shorebird Release
In your terminal, run:

```bash
# Generate AAB for Google Play
shorebird release android --artifact aab

# Generate standalone APK for phone testing
shorebird release android --artifact apk
```

> ⚠️ **IMPORTANT**: Always use `shorebird release android` (NOT `flutter build`). This registers the base binary snapshot with Shorebird so future patches can target this version.

---

### Step 3: Test the Release Build on your Phone
Install the generated APK directly onto your USB-connected Android phone:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
*Or use Shorebird preview:*
```bash
shorebird preview --target-version 1.0.2+3
```

---

### Step 4: Upload to Google Play Console
1. Locate the generated App Bundle:
   ```
   build/app/outputs/bundle/release/app-release.aab
   ```
2. Open [Google Play Console](https://play.google.com/console).
3. Select **shorebird** (`com.example.shorebird`).
4. Navigate to **Production** (or **Internal testing**).
5. Upload `app-release.aab` and release the version to users.

---

## 📋 Command Reference Cheatsheet

| Task | Command |
| :--- | :--- |
| **Build release APK for phone** | `shorebird release android --artifact apk` |
| **Install APK via ADB** | `adb install -r build/app/outputs/flutter-apk/app-release.apk` |
| **Build store release (AAB)** | `shorebird release android --artifact aab` |
| **Publish OTA patch** | `shorebird patch android --track stable` |
| **Publish staging patch** | `shorebird patch android --track staging` |
| **Check Shorebird status** | `shorebird doctor` |
| **Log in to Shorebird** | `shorebird login` |
| **List apps & releases** | `shorebird releases list` |

---

## ❓ Frequently Asked Questions

#### Q: Why doesn't my update show up when I press "Debug" in Android Studio?
**A:** Shorebird OTA patching **only works in Release builds** generated by Shorebird. Debug builds run with JIT hot reload where Shorebird's updater service is disabled.

#### Q: Do users need to visit the Google Play Store to get OTA patches?
**A:** No! OTA patches download automatically in the background or via the in-app check button. Users just tap **Restart App** to apply it.

#### Q: What if a patch causes a crash?
**A:** Shorebird automatically detects boot failures and rolls back to the safe base release snapshot on the next launch. You can also disable any patch remotely in the [Shorebird Console](https://console.shorebird.dev).
