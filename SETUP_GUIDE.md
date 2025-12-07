# Complete Setup Guide - Sports App with Jump Detection

## 📋 Overview

This application integrates Python-based jump detection (`standing_vertical_jump.py`) with a Flutter mobile app via a Flask API server (`app1.py`).

## 🚀 Quick Start

### Step 1: Install Python Dependencies

```bash
pip install -r requirements.txt
```

**Required packages:**
- Flask (web server)
- Flask-CORS (for Flutter app access)
- OpenCV (camera and image processing)
- MediaPipe (pose detection)
- NumPy (mathematical operations)

### Step 2: Start the Flask Server

```bash
python app1.py
```

The server will start on `http://0.0.0.0:5000` (accessible from all network interfaces).

**Important:** Make sure your computer and mobile device are on the **same WiFi network**.

### Step 3: Configure Flutter App

The Flutter app is already configured to use IP: `10.235.110.146:5000`

If your IP changes, update `sports_app/lib/api_service.dart`:
```dart
static const String baseUrl = 'http://YOUR_IP:5000';
```

### Step 4: Install Flutter Dependencies

```bash
cd sports_app
flutter pub get
```

### Step 5: Run Flutter App on Physical Device

```bash
flutter run
```

Make sure your device is connected via USB or WiFi debugging.

## 📱 How to Use

### On Flutter App:

1. **Camera Tab**: Shows live camera feed from your device
2. **Results Tab**: 
   - Tap **Start** button (green) to begin jump detection
   - Enter your height (cm) and weight (kg) when prompted
   - View real-time jump count, heights, and status
   - Tap **Stop** button (red) to stop detection
   - Tap **Reset** button (orange) to clear all data

### On Python Server:

- The server runs jump detection in the background
- Camera feed is processed using MediaPipe pose detection
- Jump heights are calculated and sent to Flutter app
- Results are saved to `jump_results.csv`

## 🔧 API Endpoints

- `GET /status` - Get current jump data and status
- `POST /start` - Start jump detection (requires height & weight)
- `POST /stop` - Stop jump detection
- `POST /reset` - Reset all jump data
- `POST /increment` - Manually increment jump count

## 📊 Features

### Jump Detection Features:
- ✅ Real-time pose detection using MediaPipe
- ✅ Automatic jump height calculation
- ✅ Cheat detection using Kalman filter
- ✅ Setup calibration (clap hands to start)
- ✅ CSV export of jump results
- ✅ Real-time status updates

### Flutter App Features:
- ✅ Live camera preview
- ✅ Real-time jump statistics
- ✅ Start/Stop detection controls
- ✅ Data reset functionality
- ✅ Status messages
- ✅ Beautiful UI with cards

## 🐛 Troubleshooting

### Camera Not Working?
- Grant camera permission in device settings
- Check if camera is being used by another app
- Restart the Flask server

### Can't Connect to Flask Server?
1. **Check IP Address:**
   - Windows: `ipconfig` (look for IPv4 Address)
   - Mac/Linux: `ifconfig` or `ip addr`
   - Update `api_service.dart` with correct IP

2. **Check Network:**
   - Ensure computer and phone are on same WiFi
   - Disable VPN if active
   - Check firewall settings (allow port 5000)

3. **Test Connection:**
   - Open browser on phone: `http://YOUR_IP:5000`
   - Should see jump counter page
   - Test API: `http://YOUR_IP:5000/status`

### Flask Server Errors?
- Make sure all dependencies are installed
- Check if port 5000 is already in use
- Ensure camera is not being used by another program

### Flutter Build Errors?
```bash
cd sports_app
flutter clean
flutter pub get
flutter run
```

## 📝 File Structure

```
.
├── app1.py                      # Flask server with jump detection
├── standing_vertical_jump.py    # Original jump detection script
├── requirements.txt             # Python dependencies
├── jump_results.csv            # Generated jump data (created at runtime)
├── sports_app/                 # Flutter application
│   ├── lib/
│   │   ├── main.dart           # Main app entry
│   │   ├── api_service.dart    # API communication
│   │   ├── camera_screen.dart  # Camera preview
│   │   └── results_screen.dart # Jump results display
│   └── pubspec.yaml            # Flutter dependencies
└── SETUP_GUIDE.md              # This file
```

## 🎯 Usage Flow

1. **Start Flask Server** (`python app1.py`)
2. **Open Flutter App** on your physical device
3. **Navigate to Results Tab**
4. **Tap Start Button** → Enter height & weight
5. **Position yourself** in front of camera (on computer)
6. **Clap your hands** to calibrate (when prompted)
7. **Start jumping!** Results appear in real-time on Flutter app
8. **Tap Stop** when done

## 🔐 Security Notes

- The Flask server runs with `debug=True` for development
- For production, set `debug=False` and use proper authentication
- The server accepts connections from any IP on your network
- Consider adding authentication for production use

## 📞 Support

If you encounter issues:
1. Check that both devices are on the same network
2. Verify IP address is correct
3. Ensure all dependencies are installed
4. Check camera permissions
5. Review server console for error messages

---

**Happy Jumping! 🏃‍♂️💨**

