# Quick Fix for Network Timeout

## Problem
Gradle can't download dependencies due to network timeout connecting to dl.google.com

## Quick Solutions (Try in order):

### Solution 1: Use Offline Mode (If you have cached dependencies)
```bash
cd sports_app
flutter build apk --offline
```

### Solution 2: Skip Validation and Retry
```bash
cd sports_app
flutter run --android-skip-build-dependency-validation
```

### Solution 3: Clean and Retry with Increased Timeout
```bash
cd sports_app
flutter clean
cd android
./gradlew clean --refresh-dependencies
cd ..
flutter pub get
flutter run
```

### Solution 4: Use VPN or Check Firewall
- If you're behind a firewall/proxy, configure it in `gradle.properties`
- Or use a VPN to access Google's servers

### Solution 5: Manual Gradle Download
If network keeps failing, manually download Gradle:
1. Download from: https://gradle.org/releases/
2. Extract to: `C:\Users\kunal salankar\.gradle\wrapper\dists\gradle-8.7-all\`

## For Web (No Gradle needed):
```bash
cd sports_app
flutter run -d chrome
```

This bypasses all Android/Gradle issues!













