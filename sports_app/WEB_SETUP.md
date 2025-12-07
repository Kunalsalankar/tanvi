# Running Flutter App on Web

## 🚀 Quick Start

### Step 1: Enable Web Support (if not already enabled)
```bash
cd sports_app
flutter config --enable-web
```

### Step 2: Run on Web
```bash
flutter run -d chrome
```

Or for release mode:
```bash
flutter build web
```

### Step 3: Serve the Web App
After building, you can serve it using:
```bash
# Option 1: Using Flutter's built-in server
flutter run -d chrome --web-port=8080

# Option 2: Using Python's HTTP server (after build)
cd build/web
python -m http.server 8080
```

## 📝 Important Notes

### Camera on Web
- The **Camera tab** on web will try to access your browser's camera
- However, **jump detection runs on the Flask server** using your **computer's camera**, not the browser camera
- The web app is primarily for viewing **Results** (jump count, heights, status)

### API Connection
- Make sure your Flask server is running: `python app1.py`
- The web app connects to: `http://10.235.110.146:5000`
- Update `api_service.dart` if your IP changes

### CORS
- Flask server already has CORS enabled, so web requests will work

## 🌐 Accessing the Web App

Once running, you can access it at:
- **Local:** `http://localhost:8080` (or the port you specified)
- **Network:** `http://YOUR_COMPUTER_IP:8080` (accessible from other devices on same network)

## 🔧 Troubleshooting

### Camera Not Working on Web?
- Browser camera permissions are required
- The camera tab is mainly for mobile devices
- **Results tab works perfectly on web** - this is the main feature

### Build Errors?
```bash
flutter clean
flutter pub get
flutter build web
```

### Port Already in Use?
```bash
# Use a different port
flutter run -d chrome --web-port=8081
```

## 📱 Recommended Usage

**For Web:**
- Use the **Results tab** to view jump statistics
- Start/Stop jump detection from the Flask server or via API
- Camera tab may have limited functionality on web

**For Mobile:**
- Full functionality including camera preview
- Both Camera and Results tabs work perfectly

## 🎯 Quick Commands

```bash
# Development mode (hot reload)
flutter run -d chrome

# Production build
flutter build web --release

# Serve production build
cd build/web
python -m http.server 8080
```

---

**Note:** The jump detection camera runs on your computer (Flask server), not in the browser. The web app is best for viewing results and controlling the detection.

