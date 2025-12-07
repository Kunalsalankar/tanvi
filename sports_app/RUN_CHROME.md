# Running Flutter App on Chrome

## ✅ Quick Steps:

### 1. Update Base URL (Already Done!)
The `api_service.dart` is set to: `http://localhost:5000`

### 2. Start Flask Server:
```bash
python app1.py
```
Server should show: `* Running on http://127.0.0.1:5000`

### 3. Run Flutter App on Chrome:
```bash
cd sports_app
flutter run -d chrome
```

Or specify port:
```bash
flutter run -d chrome --web-port=8080
```

## 📝 Base URL Guide:

| Platform | Base URL |
|----------|----------|
| **Chrome/Web** | `http://localhost:5000` ✅ |
| Android Emulator | `http://10.0.2.2:5000` |
| iOS Simulator | `http://localhost:5000` |
| Physical Device | `http://10.235.110.20:5000` |

## 🎯 What You'll See:

1. Chrome browser will open automatically
2. App will load in the browser
3. Go to **Results** tab to see live data
4. Tap **Start** button to begin detection

## 🔧 If Connection Fails:

- Make sure Flask server is running (`python app1.py`)
- Check browser console for errors (F12)
- Try `http://127.0.0.1:5000` instead of `localhost`

---

**For Chrome, use: `http://localhost:5000`** ✅










