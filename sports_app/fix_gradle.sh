#!/bin/bash

echo "========================================"
echo "Fixing Gradle Build Issues"
echo "========================================"
echo ""

echo "Step 1: Stopping Gradle daemon..."
cd android
./gradlew --stop
rm -rf .gradle
cd ..
echo ""

echo "Step 2: Cleaning Flutter build..."
flutter clean
echo ""

echo "Step 3: Getting Flutter dependencies..."
flutter pub get
echo ""

echo "Step 4: Cleaning Android build..."
cd android
./gradlew clean
cd ..
echo ""

echo "Step 5: Invalidating caches..."
rm -rf android/build
rm -rf build
echo ""

echo "========================================"
echo "Cleanup complete!"
echo "Now try: flutter run"
echo "========================================"


















