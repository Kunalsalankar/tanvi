# Complete Step-by-Step Guide: Flutter App with Live Camera and Results

This guide will help you set up a Flutter application that displays:
1. **Live camera feed** from your device
2. **Jump counter results** from your Flask backend

---

## 📋 Prerequisites

Before starting, ensure you have:

1. **Flutter SDK** (3.0.0 or higher)
   - Download: https://flutter.dev/docs/get-started/install
   - Verify: Run `flutter doctor` in terminal

2. **Android Studio** or **VS Code** with Flutter extensions

3. **Android Emulator** or **Physical Android/iOS Device**

4. **Python** with Flask installed

---

## 🚀 Step 1: Install Flask CORS Support

Your Flask app needs to allow cross-origin requests from Flutter:

```bash
cd sih
pip install flask-cors
```

Or add to `requirements.txt` and install:
```bash
pip install -r requirements.txt
```

---

## 🚀 Step 2: Update Flask Server

The Flask server (`app1.py`) has been updated to:
- Allow external connections (`host='0.0.0.0'`)
- Enable CORS for Flutter app

**Start your Flask server:**
```bash
cd sih
python app1.py
```

You should see:
```
 * Running on http://0.0.0.0:5000
```

**Test the API:**
Open browser: `http://localhost:5000/status`
Should return JSON with jump data.

---

## 🚀 Step 3: Set Up Flutter Project

### 3.1 Navigate to Flutter App
```bash
cd sih/flutter_app
```

### 3.2 Install Dependencies
```bash
flutter pub get
```

This installs:
- `camera` - For live camera feed
- `http` - For API calls
- `permission_handler` - For camera permissions

---

## 🚀 Step 4: Configure API URL

**IMPORTANT:** You need to set the correct API URL based on your device.

### Open `lib/api_service.dart`

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:5000';
```
*(10.0.2.2 is the special IP that points to your host machine from Android emulator)*

**For iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:5000';
```

**For Physical Device (Android/iOS):**
1. Find your computer's IP address:
   - **Windows:** Open CMD, type `ipconfig`, look for "IPv4 Address"
   - **Mac/Linux:** Open Terminal, type `ifconfig` or `ip addr`
   
2. Update the URL:
   ```dart
   static const String baseUrl = 'http://192.168.1.XXX:5000';
   ```
   *(Replace XXX with your actual IP)*

3. **Important:** Make sure your phone and computer are on the **same WiFi network**

---

## 🚀 Step 5: Run the Flutter App

### Option A: Android Studio
1. Open Android Studio
2. File → Open → Select `sih/flutter_app` folder
3. Wait for indexing to complete
4. Select device/emulator from dropdown
5. Click Run (▶️) button

### Option B: VS Code
1. Open VS Code
2. File → Open Folder → Select `sih/flutter_app`
3. Press `F5` or Run → Start Debugging
4. Select your device

### Option C: Command Line
```bash
cd sih/flutter_app
flutter run
```

---

## 🚀 Step 6: Grant Permissions

When the app opens:

1. **Camera Permission:**
   - App will request camera permission
   - Tap **"Allow"** or **"While using the app"**
   - If denied, go to device Settings → Apps → Jump Counter → Permissions → Camera → Allow

---

## 📱 Step 7: Using the App

### Camera Tab (First Tab)
- Shows **live camera feed** from your device
- Camera preview fills the screen
- Overlay shows "Live Camera Feed" status

### Results Tab (Second Tab)
- Displays three metrics:
  - **Jump Count:** Total number of jumps
  - **Last Jump Height:** Height of most recent jump (cm)
  - **Highest Jump:** Maximum jump height recorded (cm)
- **Auto-refresh:** Updates every 1 second
- **Manual refresh:** Pull down or tap refresh icon

---

## 🔧 Troubleshooting

### ❌ Camera Not Working

**Symptoms:**
- Black screen or "Camera permission required" message

**Solutions:**
1. Check device Settings → Apps → Jump Counter → Permissions
2. Grant camera permission manually
3. Restart the app
4. Make sure no other app is using the camera

---

### ❌ Cannot Connect to Flask Server

**Symptoms:**
- "Error: Failed to load status" in Results tab
- Red error message

**Solutions:**

1. **Verify Flask is running:**
   ```bash
   # Check if Flask is running
   # Open browser: http://localhost:5000/status
   ```

2. **Check IP Address:**
   - Make sure `baseUrl` in `api_service.dart` matches your setup
   - For physical device, verify computer IP is correct

3. **Check Network:**
   - Physical device and computer must be on same WiFi
   - Try disabling VPN if active
   - Check firewall isn't blocking port 5000

4. **Test Connection:**
   - On your phone's browser, try: `http://YOUR_IP:5000/status`
   - Should show JSON data

5. **Flask Server Settings:**
   - Make sure Flask runs with `host='0.0.0.0'` (already updated in app1.py)
   - Check Flask console for any errors

---

### ❌ Build Errors

**Symptoms:**
- Red errors in IDE
- App won't build

**Solutions:**
```bash
cd sih/flutter_app
flutter clean
flutter pub get
flutter run
```

**Check Flutter setup:**
```bash
flutter doctor
```
Fix any issues shown.

---

### ❌ Dependencies Not Found

**Symptoms:**
- "Package not found" errors

**Solutions:**
```bash
cd sih/flutter_app
flutter pub get
```

If still failing:
```bash
flutter pub upgrade
```

---

## 📁 Project Structure

```
sih/
├── app1.py                    # Flask backend (updated with CORS)
├── flutter_app/
│   ├── lib/
│   │   ├── main.dart          # App entry point
│   │   ├── api_service.dart   # Flask API communication
│   │   ├── camera_screen.dart # Live camera screen
│   │   └── results_screen.dart # Results display screen
│   ├── android/               # Android configuration
│   ├── ios/                   # iOS configuration
│   ├── pubspec.yaml           # Dependencies
│   └── README.md              # Detailed documentation
└── requirements.txt           # Python dependencies
```

---

## 🎯 Quick Start Checklist

- [ ] Flutter SDK installed (`flutter doctor`)
- [ ] Flask server running (`python app1.py`)
- [ ] Flask-CORS installed (`pip install flask-cors`)
- [ ] API URL configured in `api_service.dart`
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Device/emulator connected
- [ ] Camera permission granted
- [ ] App running successfully

---

## 🔄 How It Works

1. **Flask Backend (`app1.py`):**
   - Tracks jump count and heights
   - Provides `/status` endpoint with JSON data
   - Allows external connections for mobile devices

2. **Flutter App:**
   - **Camera Screen:** Uses `camera` package to show live feed
   - **Results Screen:** Uses `http` package to fetch data from Flask
   - Polls Flask API every 1 second for updates
   - Displays data in beautiful card UI

3. **Communication:**
   - Flutter app sends HTTP GET requests to Flask
   - Flask responds with JSON containing jump data
   - Flutter parses and displays the data

---

## 🚀 Next Steps

1. **Integrate Jump Detection:**
   - Send camera frames to Flask backend
   - Process frames with MediaPipe (like `standing_vertical_jump.py`)
   - Update jump count automatically

2. **Add Features:**
   - Video recording
   - Jump history/charts
   - User profiles
   - Export data

3. **Improve UI:**
   - Add animations
   - Custom themes
   - Better error handling

---

## 📞 Need Help?

1. Check Flutter logs: `flutter logs`
2. Check Flask server console for errors
3. Verify network connectivity
4. Test API in browser: `http://localhost:5000/status`

---

**You're all set!** 🎉

Your Flutter app should now display:
- ✅ Live camera feed
- ✅ Real-time jump counter results from Flask


