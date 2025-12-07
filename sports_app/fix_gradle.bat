@echo off
echo ========================================
echo Fixing Gradle Build Issues
echo ========================================
echo.

echo Step 1: Stopping Gradle daemon...
call gradlew --stop
if exist android\.gradle rmdir /s /q android\.gradle
echo.

echo Step 2: Cleaning Flutter build...
cd ..
call flutter clean
echo.

echo Step 3: Getting Flutter dependencies...
call flutter pub get
echo.

echo Step 4: Cleaning Android build...
cd android
call gradlew clean
cd ..
echo.

echo Step 5: Invalidating caches...
if exist android\build rmdir /s /q android\build
if exist build rmdir /s /q build
echo.

echo ========================================
echo Cleanup complete!
echo Now try: flutter run
echo ========================================
pause


















