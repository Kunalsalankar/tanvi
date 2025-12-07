# How to See Live Data in Your App

## ✅ Quick Steps:

### 1. **Start Flask Server** (Required!)
```bash
python app1.py
```
The server should start on `http://0.0.0.0:5000`

### 2. **On Your Phone App:**

#### **Option A: View Results Tab**
1. Open the app on your phone
2. Tap the **"Results"** tab at the bottom
3. You should see:
   - Jump Count
   - Last Jump Height
   - Highest Jump
   - Status message
   - **Start/Stop buttons**

#### **Option B: Start Jump Detection**
1. Go to **Results** tab
2. Tap the green **"Start"** button
3. Enter your height (cm) and weight (kg)
4. Go to your computer camera and:
   - Stand in front of it
   - Clap your hands to calibrate
   - Start jumping!

### 3. **What You'll See:**
- **On Computer:** Camera window with jump detection
- **On Phone (Results Tab):** Live updates every second showing:
  - Jump count
  - Jump heights
  - Status messages

## 🔍 Troubleshooting:

### If Results Tab Shows Error:
- **Check:** Flask server is running (`python app1.py`)
- **Check:** Phone and computer are on same WiFi
- **Check:** IP address is correct (10.235.110.146:5000)

### If No Data Updates:
- Tap the **refresh icon** (↻) in the Results tab
- Make sure you tapped **"Start"** button
- Check Flask server console for errors

## 📱 Camera Tab vs Results Tab:

- **Camera Tab:** Shows your phone's camera (for viewing)
- **Results Tab:** Shows live jump data from Flask server (THIS IS WHERE LIVE DATA IS!)

---

**Remember:** The jump detection runs on your **computer's camera**, not your phone's camera. The phone app shows the **results**!

