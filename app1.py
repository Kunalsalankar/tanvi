from flask import Flask, render_template_string, request, jsonify, Response
from flask_cors import CORS
import cv2
import mediapipe as mp
import numpy as np
import csv
import time
import threading
from queue import Queue

app = Flask(__name__)
# Enable CORS for Flutter web app - allow all origins for development
CORS(app, 
     resources={r"/*": {"origins": "*"}},
     supports_credentials=False,
     methods=["GET", "POST", "OPTIONS", "PUT", "DELETE"],
     allow_headers=["Content-Type", "Authorization"])  # Enable CORS for Flutter app

# Global variables for jump data
jump_count = 0
last_jump_height = 0.0
max_jump_height = 0.0
is_detection_running = False
detection_thread = None
status_message = "Waiting to start..."
user_height = 170.0  # Default height in cm
user_weight = 70.0   # Default weight in kg

# Global variable to store the latest frame for streaming
latest_frame = None
frame_lock = threading.Lock()

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

def calibrate_with_paper(frame, status_callback=None):
    """Calibrate with A4 paper detection. Returns px_per_cm or None."""
    # A4 paper dimensions in cm
    PAPER_WIDTH = 21.0
    PAPER_LENGTH = 29.7
    MIN_AREA = 5000  # Reduced minimum area for easier detection

    h, w = frame.shape[:2]
    vis_frame = frame.copy()

    # Make the box larger and more forgiving - use 60% of frame width instead of 40%
    box_w_cm = 21.0
    box_h_cm = 29.7
    # Estimate pixels per cm for initial box size (more generous sizing)
    px_per_cm_guess = w / 45  # e.g., 1280/45 ≈ 28 px/cm (larger box)
    box_w = int(box_w_cm * px_per_cm_guess)
    box_h = int(box_h_cm * px_per_cm_guess)
    
    # Allow the box to be larger - up to 70% of frame width
    max_box_w = int(w * 0.7)
    max_box_h = int(h * 0.7)
    
    if box_w > max_box_w:
        box_w = max_box_w
        box_h = int(box_w * (box_h_cm / box_w_cm))
    if box_h > max_box_h:
        box_h = max_box_h
        box_w = int(box_h * (box_w_cm / box_h_cm))
    
    # Center the box but leave more margin at top for text
    box_x1 = w // 2 - box_w // 2
    box_y1 = h // 2 - box_h // 2 + 50  # Move down to leave space for instructions
    box_x2 = box_x1 + box_w
    box_y2 = box_y1 + box_h

    # Draw guide box (thicker, bright yellow with better visibility)
    cv2.rectangle(vis_frame, (box_x1, box_y1), (box_x2, box_y2), (0, 255, 255), 6)
    # Draw corner indicators
    corner_size = 15
    for pt in [(box_x1, box_y1), (box_x2, box_y1), (box_x2, box_y2), (box_x1, box_y2)]:
        cv2.circle(vis_frame, pt, corner_size, (0, 0, 255), -1)
        cv2.circle(vis_frame, pt, corner_size, (255, 255, 255), 3)

    # Better instructions with clearer positioning
    cv2.putText(vis_frame, "CALIBRATION: Place A4 paper (21x29.7 cm)", (20, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 1.2, (255, 255, 255), 3)
    cv2.putText(vis_frame, "CALIBRATION: Place A4 paper (21x29.7 cm)", (20, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 0, 0), 2)
    
    cv2.putText(vis_frame, "Hold paper FLAT inside the yellow box", (20, 70),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
    cv2.putText(vis_frame, "Press SPACE when paper is positioned correctly", (20, 110),
                cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

    # Expand detection area slightly beyond the box for more tolerance
    margin = 20
    detect_x1 = max(0, box_x1 - margin)
    detect_y1 = max(0, box_y1 - margin)
    detect_x2 = min(w, box_x2 + margin)
    detect_y2 = min(h, box_y2 + margin)
    
    roi = frame[detect_y1:detect_y2, detect_x1:detect_x2]
    gray = cv2.cvtColor(roi, cv2.COLOR_BGR2GRAY)
    
    # Use multiple detection methods for better reliability
    # Method 1: Adaptive threshold
    binary1 = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                                  cv2.THRESH_BINARY, 11, 2)
    # Method 2: Otsu threshold
    _, binary2 = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    # Method 3: Simple threshold
    _, binary3 = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY)
    
    # Combine methods
    binary = cv2.bitwise_and(binary1, binary2)
    
    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    paper_detected = False
    px_per_cm = None
    best_contour = None
    best_score = 0
    
    if contours:
        contours = sorted(contours, key=cv2.contourArea, reverse=True)
        for contour in contours[:5]:  # Check more contours
            area = cv2.contourArea(contour)
            if area < MIN_AREA:
                continue
                
            # More forgiving aspect ratio check
            rect = cv2.minAreaRect(contour)
            width_px = rect[1][0]
            height_px = rect[1][1]
            if min(width_px, height_px) == 0:
                continue
                
            aspect_ratio = max(width_px, height_px) / min(width_px, height_px)
            # Accept wider range of aspect ratios (A4 is ~1.41)
            if 1.2 < aspect_ratio < 1.8:
                # Check if contour is reasonably rectangular
                hull = cv2.convexHull(contour)
                hull_area = cv2.contourArea(hull)
                solidity = area / hull_area if hull_area > 0 else 0
                
                # Score based on area and solidity
                score = area * solidity
                if score > best_score:
                    best_score = score
                    best_contour = contour
                    paper_detected = True
                    
                    box = cv2.boxPoints(rect)
                    box = np.int32(box)
                    # Offset box points to full frame coordinates
                    box[:, 0] += detect_x1
                    box[:, 1] += detect_y1
                    
                    # Calculate pixels per cm
                    if width_px > height_px:
                        px_per_cm = width_px / PAPER_LENGTH
                    else:
                        px_per_cm = width_px / PAPER_WIDTH

    if paper_detected and best_contour is not None:
        # Draw the detected paper contour
        rect = cv2.minAreaRect(best_contour)
        box = cv2.boxPoints(rect)
        box = np.int32(box)
        box[:, 0] += detect_x1
        box[:, 1] += detect_y1
        cv2.drawContours(vis_frame, [box], 0, (0, 255, 0), 3)
        for point in box:
            cv2.circle(vis_frame, tuple(point), 6, (0, 255, 0), -1)
            
        cv2.putText(vis_frame, "PAPER DETECTED! Press SPACE to confirm", (20, h - 80),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 255, 0), 3)
        cv2.putText(vis_frame, "PAPER DETECTED! Press SPACE to confirm", (20, h - 80),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0, 0, 0), 2)
        
        if px_per_cm:
            cv2.putText(vis_frame, f"Scale: {px_per_cm:.1f} px/cm", (20, h - 40),
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)
    else:
        cv2.putText(vis_frame, "No paper detected - Try adjusting position", (20, h - 80),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
        cv2.putText(vis_frame, "Make sure paper is flat and well-lit", (20, h - 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)

    cv2.imshow("Calibration", vis_frame)
    key = cv2.waitKey(1)

    if key == ord(' ') and paper_detected:
        cv2.putText(vis_frame, "CALIBRATION SUCCESSFUL!", (w//2 - 200, h//2),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 0), 3)
        cv2.putText(vis_frame, "CALIBRATION SUCCESSFUL!", (w//2 - 200, h//2),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 0, 0), 2)
        cv2.imshow("Calibration", vis_frame)
        cv2.waitKey(1500)
        if status_callback:
            status_callback("Calibration successful!")
        return px_per_cm

    return None

def run_jump_detection():
    global jump_count, last_jump_height, max_jump_height, is_detection_running, status_message, user_height, user_weight, latest_frame, frame_lock
    
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        status_message = "ERROR: Camera could not be opened."
        is_detection_running = False
        return

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, FRAME_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, FRAME_HEIGHT)
    WINDOW_NAME = "Vertical Jump Counter"
    cv2.namedWindow(WINDOW_NAME)

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

    # ===== PHASE 0: A4 PAPER CALIBRATION =====
    calibration_done = False
    status_message = "Phase 0: A4 Paper Calibration - Place paper on ground"
    
    while not calibration_done and is_detection_running:
        ret, frame = cap.read()
        if not ret:
            break
        
        px_per_cm = calibrate_with_paper(frame, lambda msg: None)
        
        if px_per_cm:
            calibration_done = True
            status_message = "A4 Calibration complete! Proceed to body calibration."
            cv2.waitKey(1000)
            cv2.destroyWindow("Calibration")
            break
    
    if not calibration_done or not px_per_cm:
        status_message = "Calibration failed. Exiting."
        is_detection_running = False
        cap.release()
        csvfile.close()
        cv2.destroyAllWindows()
        return

    with mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5) as pose:
        while is_detection_running:
            ret, frame = cap.read()
            if not ret:
                break
            h, w = frame.shape[:2]
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(frame_rgb)
            
            # Store frame for streaming (convert back to BGR for display)
            vis_frame = frame.copy()
            
            # Draw pose landmarks on frame
            if results.pose_landmarks:
                mp_drawing.draw_landmarks(vis_frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
            
            # Store latest frame for streaming
            with frame_lock:
                _, buffer = cv2.imencode('.jpg', vis_frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
                latest_frame = buffer.tobytes()

            if not setup_done:
                cv2.putText(vis_frame, "Phase 1: Stand up - Ground detection & body visibility", (40, 60),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2)
                cv2.putText(vis_frame, "Stand upright with full body visible", (40, 100),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2)
                status_message = "Phase 1: Stand upright with full body visible. Prepare to clap."
                if results.pose_landmarks:
                    is_visible = check_body_visible(results.pose_landmarks.landmark, h, w)
                    px_cal, ground_y = calculate_px_per_cm(results.pose_landmarks.landmark, h, user_height)
                    if is_visible and px_cal:
                        cv2.line(vis_frame, (0, int(ground_y)), (w, int(ground_y)), (0, 255, 0), 3)
                        cv2.putText(vis_frame, "Ground Detected", (40, 150),
                                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
                        lm = results.pose_landmarks.landmark
                        left_wrist = lm[mp_pose.PoseLandmark.LEFT_WRIST.value]
                        right_wrist = lm[mp_pose.PoseLandmark.RIGHT_WRIST.value]
                        lw_x, lw_y = int(left_wrist.x * w), int(left_wrist.y * h)
                        rw_x, rw_y = int(right_wrist.x * w), int(right_wrist.y * h)
                        dist = np.linalg.norm([lw_x - rw_x, lw_y - rw_y])
                        if dist < CLAP_DISTANCE_THRESHOLD:
                            clap_frames += 1
                            cv2.putText(vis_frame, "Clap detected!", (40, 210), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
                            if clap_frames >= CLAP_FRAMES_REQUIRED:
                                setup_done = True
                                standing_reach_y = right_wrist.y * h
                                kalman_filter.statePost = np.array([[standing_reach_y], [0]], np.float32)
                                cv2.putText(vis_frame, "Confirmed! Ready to jump!", (40, 250), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)
                                status_message = "Phase 1 complete! Phase 2: Start jumping!"
                        else:
                            clap_frames = 0
                            cv2.putText(vis_frame, "Join (clap) your hands to start jumping.", (40, 210), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
                            status_message = "Join (clap) your hands to start jumping."
                    else:
                        cv2.putText(vis_frame, "Ensure full body & ground is visible.", (40, 150), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
                        status_message = "Ensure full body & ground is visible."
                cv2.imshow(WINDOW_NAME, vis_frame)
                key = cv2.waitKey(10) & 0xFF
                if key == ord('q'):
                    is_detection_running = False
                    break
                continue

            # ===== PHASE 2: JUMP MEASUREMENT WITH CHEAT DETECTION =====
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

                    # Display jump info on frame
                    cv2.putText(vis_frame, f"Phase 2: Jumping | Jumps: {jump_count}", (30, 60),
                                cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 0), 2)
                    cv2.putText(vis_frame, f"Last Jump Height: {jump_height_cm:.2f} cm", (30, 120),
                                cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2)
                    cv2.putText(vis_frame, f"Max Jump Height: {max_jump_height:.2f} cm", (30, 150),
                                cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2)

                    # Display cheat status
                    cheat_text = "CHEAT DETECTED!" if cheat_flag else "No Cheat Detected"
                    cheat_color = (0, 0, 255) if cheat_flag else (0, 255, 0)
                    cv2.putText(vis_frame, f"Cheat Detection: {cheat_text}", (30, 200),
                                cv2.FONT_HERSHEY_SIMPLEX, 1, cheat_color, 2)
                    cv2.putText(vis_frame, "Press 'c' to toggle | 'q' to quit", (30, 240),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 1)

            cv2.imshow(WINDOW_NAME, vis_frame)
            key = cv2.waitKey(10) & 0xFF
            if key == ord('q'):
                is_detection_running = False
                break
            elif key == ord('c'):
                cheat_detection_enabled = not cheat_detection_enabled

    cap.release()
    csvfile.close()
    cv2.destroyAllWindows()
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

@app.route('/', methods=['GET', 'OPTIONS'])
def index():
    global jump_count, last_jump_height, max_jump_height, status_message
    return render_template_string(
        HTML,
        jump_count=jump_count,
        last_jump_height=last_jump_height,
        max_jump_height=max_jump_height,
        status_message=status_message
    )

@app.route('/status', methods=['GET', 'OPTIONS'])
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

@app.route('/video_feed', methods=['GET', 'OPTIONS'])
def video_feed():
    """Stream video frames as MJPEG"""
    def generate():
        global latest_frame, frame_lock
        while True:
            with frame_lock:
                if latest_frame is not None:
                    frame = latest_frame
                else:
                    # Return a black frame if no frame available
                    black_frame = np.zeros((480, 640, 3), dtype=np.uint8)
                    _, buffer = cv2.imencode('.jpg', black_frame)
                    frame = buffer.tobytes()
            
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')
            time.sleep(0.033)  # ~30 FPS
    
    return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == '__main__':
    # Allow external connections (for physical devices)
    # Use host='127.0.0.1' for localhost only, or '0.0.0.0' for all interfaces
    print("Starting Flask server on http://0.0.0.0:5001")
    print("For physical device, use: http://10.117.19.2:5001")
    app.run(host='0.0.0.0', port=5001, debug=True, threaded=True)