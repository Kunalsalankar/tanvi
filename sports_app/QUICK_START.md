# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### 1. Install Flask CORS
```bash
cd sih
pip install flask-cors
```

### 2. Start Flask Server
```bash
python app1.py
```
Server runs on: `http://0.0.0.0:5000`

### 3. Configure API URL
Edit `lib/api_service.dart`:
- **Emulator:** `http://10.0.2.2:5000`
- **Physical Device:** `http://YOUR_COMPUTER_IP:5000`

### 4. Install Flutter Dependencies
```bash
cd flutter_app
flutter pub get
```

### 5. Run App
```bash
flutter run
```

## 📱 App Features

- **Camera Tab:** Live camera feed
- **Results Tab:** Jump count, heights (updates every 1 second)

## ⚙️ API URL by Device

| Device Type | URL |
|------------|-----|
| Android Emulator | `http://10.0.2.2:5000` |
| iOS Simulator | `http://localhost:5000` |
| Physical Device | `http://192.168.x.x:5000` |

*Find your IP: Windows (`ipconfig`), Mac/Linux (`ifconfig`)*

## 🔧 Troubleshooting

**Camera not working?**
- Grant camera permission in device settings

**Can't connect to Flask?**
- Check Flask is running
- Verify IP address is correct
- Ensure same WiFi network (for physical devices)
- Test in browser: `http://localhost:5000/status`

**Build errors?**
```bash
flutter clean
flutter pub get
```

## 📖 Full Guide

See `FLUTTER_SETUP_GUIDE.md` for detailed instructions.


