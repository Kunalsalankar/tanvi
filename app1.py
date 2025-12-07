from flask import Flask, render_template_string, request, jsonify
from flask_cors import CORS
import cv2
import mediapipe as mp
import numpy as np
import csv
import time
import threading
from queue import Queue

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app

# Global variables for jump data
jump_count = 0
last_jump_height = 0.0
max_jump_height = 0.0
is_detection_running = False
detection_thread = None
status_message = "Waiting to start..."
user_height = 170.0  # Default height in cm
user_weight = 70.0   # Default weight in kg

# MediaPipe setup
mp_drawing = mp.solutions.drawing_utils
mp_pose = mp.solutions.pose

OUTPUT_CSV = "jump_results.csv"
FRAME_WIDTH = 1280
FRAME_HEIGHT = 720

# Kalman filter for 1D vertical position tracking
class KalmanFilter1D:
    def __init__(self):
        self.kalman = cv2.KalmanFilter(2, 1)  # State: [position, velocity], Measure: [position]
        self.kalman.transitionMatrix = np.array([[1, 1], [0, 1]], np.float32)
        self.kalman.measurementMatrix = np.array([[1, 0]], np.float32)
        self.kalman.processNoiseCov = np.array([[1e-4, 0], [0, 1e-4]], np.float32)
        self.kalman.measurementNoiseCov = np.array([[1e-2]], np.float32)
        self.kalman.errorCovPost = np.array([[1, 0], [0, 1]], np.float32)
        self.kalman.statePost = np.array([[0], [0]], np.float32)

    def predict(self):
        pred = self.kalman.predict()
        return pred[0][0]

    def correct(self, measurement):
        measurement = np.array([[np.float32(measurement)]])
        corrected = self.kalman.correct(measurement)
        return corrected[0][0]

def calculate_px_per_cm(landmarks, h, user_height_cm):
    try:
        head = landmarks[mp_pose.PoseLandmark.NOSE.value]
        left_ankle = landmarks[mp_pose.PoseLandmark.LEFT_ANKLE.value]
        right_ankle = landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE.value]
        ankle_y = max(left_ankle.y, right_ankle.y) * h
        head_y = head.y * h
        px_height = abs(ankle_y - head_y)
        px_per_cm = px_height / user_height_cm
        return px_per_cm, ankle_y
    except Exception:
        return None, None

def check_body_visible(landmarks, h, w):
    try:
        keypoints = [
            mp_pose.PoseLandmark.NOSE.value,
            mp_pose.PoseLandmark.LEFT_ANKLE.value,
            mp_pose.PoseLandmark.RIGHT_ANKLE.value,
            mp_pose.PoseLandmark.LEFT_WRIST.value,
            mp_pose.PoseLandmark.RIGHT_WRIST.value,
        ]
        for idx in keypoints:
            lm = landmarks[idx]
            x, y = int(lm.x * w), int(lm.y * h)
            if x < 0 or x > w or y < 0 or y > h:
                return False
        return True
    except:
        return False

def run_jump_detection():
    global jump_count, last_jump_height, max_jump_height, is_detection_running, status_message, user_height, user_weight
    
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        status_message = "ERROR: Camera could not be opened."
        is_detection_running = False
        return

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, FRAME_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, FRAME_HEIGHT)

    csvfile = open(OUTPUT_CSV, "w", newline="")
    csvw = csv.writer(csvfile)
    csvw.writerow(["timestamp", "jump_height_cm"])

    standing_reach_y = None
    px_per_cm = None
    jump_height_cm = 0.0
    setup_done = False
    clap_frames = 0
    CLAP_FRAMES_REQUIRED = 5
    CLAP_DISTANCE_THRESHOLD = 60  # pixels

    in_air = False
    last_jump_time = 0
    jump_cooldown = 1.0  # seconds

    cheat_detection_enabled = True
    cheat_flag = False
    kalman_filter = KalmanFilter1D()
    KALMAN_CHEAT_THRESHOLD_PX = 40  # pixel difference threshold

    with mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5) as pose:
        while is_detection_running:
            ret, frame = cap.read()
            if not ret:
                break
            h, w = frame.shape[:2]
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(frame_rgb)

            if not setup_done:
                status_message = "Step 1: Adjust camera so full body is visible. Stand so feet touch ground line."
                if results.pose_landmarks:
                    is_visible = check_body_visible(results.pose_landmarks.landmark, h, w)
                    px_cal, ground_y = calculate_px_per_cm(results.pose_landmarks.landmark, h, user_height)
                    if is_visible and px_cal:
                        px_per_cm = px_cal
                        lm = results.pose_landmarks.landmark
                        left_wrist = lm[mp_pose.PoseLandmark.LEFT_WRIST.value]
                        right_wrist = lm[mp_pose.PoseLandmark.RIGHT_WRIST.value]
                        lw_x, lw_y = int(left_wrist.x * w), int(left_wrist.y * h)
                        rw_x, rw_y = int(right_wrist.x * w), int(right_wrist.y * h)
                        dist = np.linalg.norm([lw_x - rw_x, lw_y - rw_y])
                        if dist < CLAP_DISTANCE_THRESHOLD:
                            clap_frames += 1
                            if clap_frames >= CLAP_FRAMES_REQUIRED:
                                setup_done = True
                                standing_reach_y = right_wrist.y * h
                                kalman_filter.statePost = np.array([[standing_reach_y], [0]], np.float32)
                                status_message = "Setup complete! Start jumping."
                        else:
                            clap_frames = 0
                            status_message = "Join (clap) your hands to start."
                    else:
                        status_message = "Ensure full body & ground is visible."
                continue

            # Jump measurement with cheat detection
            cheat_flag = False
            if results.pose_landmarks:
                lm = results.pose_landmarks.landmark
                wrist = lm[mp_pose.PoseLandmark.RIGHT_WRIST.value]
                if wrist.visibility >= 0.5:
                    wrist_y_px = wrist.y * h
                    predicted_y = kalman_filter.predict()
                    corrected_y = kalman_filter.correct(wrist_y_px)
                    if cheat_detection_enabled and abs(wrist_y_px - predicted_y) > KALMAN_CHEAT_THRESHOLD_PX:
                        cheat_flag = True

                    current_time = time.time()

                    if wrist_y_px < standing_reach_y - 30:
                        if not in_air and (current_time - last_jump_time > jump_cooldown):
                            if not cheat_flag:
                                in_air = True
                                peak_jump_y = wrist_y_px
                        elif in_air:
                            peak_jump_y = min(peak_jump_y, wrist_y_px)
                    else:
                        if in_air:
                            jump_height_px = standing_reach_y - peak_jump_y
                            jump_height_cm = jump_height_px / px_per_cm
                            jump_count += 1
                            last_jump_height = jump_height_cm
                            if jump_height_cm > max_jump_height:
                                max_jump_height = jump_height_cm
                            last_jump_time = current_time
                            csvw.writerow([time.strftime('%Y-%m-%d %H:%M:%S'), f"{jump_height_cm:.2f}"])
                            in_air = False
                            status_message = f"Jump detected! Height: {jump_height_cm:.2f} cm"

    cap.release()
    csvfile.close()
    is_detection_running = False
    status_message = "Detection stopped."

HTML = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Vertical Jump Counter</title>
    <link rel="stylesheet" href="/static/style.css">
</head>
<body>
    <div class="container">
        <h1>Vertical Jump Counter</h1>
        <p id="count">Jump Count: <span>{{ jump_count }}</span></p>
        <p id="height">Last Jump Height: <span>{{ '{:.2f}'.format(last_jump_height) }}</span> cm</p>
        <p id="max-height">Highest Jump: <span>{{ '{:.2f}'.format(max_jump_height) }}</span> cm</p>
        <p id="status">Status: <span>{{ status_message }}</span></p>
    </div>
    <script>
        setInterval(function() {
            fetch('/status').then(r => r.json()).then(data => {
                document.querySelector("#count span").textContent = data.jump_count;
                document.querySelector("#height span").textContent = Number(data.last_jump_height).toFixed(2);
                document.querySelector("#max-height span").textContent = Number(data.max_jump_height).toFixed(2);
                document.querySelector("#status span").textContent = data.status_message;
            });
        }, 1000);
    </script>
</body>
</html>
"""

@app.route('/')
def index():
    global jump_count, last_jump_height, max_jump_height, status_message
    return render_template_string(
        HTML,
        jump_count=jump_count,
        last_jump_height=last_jump_height,
        max_jump_height=max_jump_height,
        status_message=status_message
    )

@app.route('/status')
def status():
    global jump_count, last_jump_height, max_jump_height, status_message, is_detection_running
    return jsonify(
        jump_count=jump_count,
        last_jump_height=last_jump_height,
        max_jump_height=max_jump_height,
        status_message=status_message,
        is_running=is_detection_running
    )

@app.route('/start', methods=['POST'])
def start_detection():
    global is_detection_running, detection_thread, user_height, user_weight
    
    data = request.get_json() or {}
    user_height = float(data.get('height', 170.0))
    user_weight = float(data.get('weight', 70.0))
    
    if not is_detection_running:
        is_detection_running = True
        detection_thread = threading.Thread(target=run_jump_detection, daemon=True)
        detection_thread.start()
        return jsonify(success=True, message="Detection started")
    return jsonify(success=False, message="Detection already running")

@app.route('/stop', methods=['POST'])
def stop_detection():
    global is_detection_running
    is_detection_running = False
    return jsonify(success=True, message="Detection stopped")

@app.route('/reset', methods=['POST'])
def reset():
    global jump_count, last_jump_height, max_jump_height
    jump_count = 0
    last_jump_height = 0.0
    max_jump_height = 0.0
    return jsonify(success=True, message="Data reset")

@app.route('/increment', methods=['POST'])
def increment():
    global jump_count, last_jump_height, max_jump_height
    data = request.get_json()
    jump_count += 1
    if data and "jump_height" in data:
        last_jump_height = data["jump_height"]
        if last_jump_height > max_jump_height:
            max_jump_height = last_jump_height
    return jsonify(success=True)

if __name__ == '__main__':
    # Allow external connections (for physical devices)
    # Use host='127.0.0.1' for localhost only, or '0.0.0.0' for all interfaces
    print("Starting Flask server on http://0.0.0.0:5000")
    print("For physical device, use: http://10.235.110.146:5000")
    app.run(host='0.0.0.0', port=5000, debug=True, threaded=True)
