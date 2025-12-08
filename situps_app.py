from flask import Flask, jsonify, request
from flask_cors import CORS
import cv2
import mediapipe as mp
import numpy as np
import threading
import time

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=False, methods=["GET", "POST", "OPTIONS", "PUT", "DELETE"], allow_headers=["Content-Type", "Authorization"])

mp_drawing = mp.solutions.drawing_utils
mp_pose = mp.solutions.pose

# Global variables for sit-up tracking
situp_count = 0
current_stage = "down"
current_angle = 0
status_message = "Idle"
detection_active = False
camera = None
pose = None

def get_angle(a, b, c):
    """Calculate angle between three points"""
    ba = np.array([a.x - b.x, a.y - b.y])
    bc = np.array([c.x - b.x, c.y - b.y])
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    return np.degrees(np.arccos(np.clip(cosine_angle, -1.0, 1.0)))

def situp_detection_loop():
    """Main detection loop for sit-ups"""
    global situp_count, current_stage, current_angle, status_message, detection_active, camera, pose
    
    try:
        camera = cv2.VideoCapture(0)
        if not camera.isOpened():
            status_message = "Error: Camera not available"
            return
        
        # Set camera resolution
        camera.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        
        pose = mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5)
        
        DOWN_ANGLE = 160
        UP_ANGLE = 100
        SHOULDER_GROUND_Y = 0.85
        SHOULDER_UP_Y = 0.6
        last_rep_time = 0
        
        status_message = "Sit-up detection started"
        
        while detection_active:
            ret, frame = camera.read()
            if not ret:
                break
            
            h, w = frame.shape[:2]
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(frame_rgb)
            
            # Draw landmarks on frame
            if results.pose_landmarks:
                mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
                
                lm = results.pose_landmarks.landmark
                
                left_shoulder = lm[mp_pose.PoseLandmark.LEFT_SHOULDER.value]
                left_hip = lm[mp_pose.PoseLandmark.LEFT_HIP.value]
                left_knee = lm[mp_pose.PoseLandmark.LEFT_KNEE.value]
                left_wrist = lm[mp_pose.PoseLandmark.LEFT_WRIST.value]
                right_wrist = lm[mp_pose.PoseLandmark.RIGHT_WRIST.value]
                nose = lm[mp_pose.PoseLandmark.NOSE.value]
                
                # Calculate angles
                sh_hip_knee_angle = get_angle(left_shoulder, left_hip, left_knee)
                shoulder_y = left_shoulder.y
                
                current_angle = sh_hip_knee_angle
                
                # Check if hands are behind head
                hands_behind_head = (left_wrist.y < nose.y and right_wrist.y < nose.y)
                
                # Sit-up logic
                if hands_behind_head:
                    if current_stage == "down":
                        if sh_hip_knee_angle < UP_ANGLE and shoulder_y < SHOULDER_UP_Y:
                            current_stage = "up"
                    elif current_stage == "up":
                        if sh_hip_knee_angle > DOWN_ANGLE and shoulder_y > SHOULDER_GROUND_Y:
                            if time.time() - last_rep_time > 0.5:
                                situp_count += 1
                                last_rep_time = time.time()
                                status_message = f"Rep {situp_count} completed!"
                            current_stage = "down"
            
            # Display UI elements on frame
            cv2.putText(frame, f"Sit-ups: {situp_count}", (30, 60),
                        cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 0), 2, cv2.LINE_AA)
            cv2.putText(frame, f"Stage: {current_stage.upper()}", (30, 120),
                        cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 255), 2)
            cv2.putText(frame, f"Angle: {current_angle:.1f}°", (30, 160),
                        cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 255), 2)
            cv2.putText(frame, status_message, (30, 200),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
            
            # Display the frame
            cv2.imshow("Sit-up Detection", frame)
            
            # Press 'q' to quit from the display window
            if cv2.waitKey(1) & 0xFF == ord('q'):
                detection_active = False
            
            time.sleep(0.03)
        
        cv2.destroyAllWindows()
        camera.release()
        pose.close()
        status_message = "Detection stopped"
    
    except Exception as e:
        status_message = f"Error: {str(e)}"
        print(f"Error in detection loop: {str(e)}")
    finally:
        cv2.destroyAllWindows()
        if camera:
            camera.release()
        if pose:
            pose.close()

@app.route('/situp/start', methods=['POST'])
def start_situp_detection():
    """Start sit-up detection"""
    global situp_count, current_stage, status_message, detection_active
    
    try:
        data = request.get_json() or {}
        height = data.get('height', 170.0)
        weight = data.get('weight', 70.0)
        
        if detection_active:
            return jsonify(success=False, message="Detection already running")
        
        situp_count = 0
        current_stage = "down"
        status_message = "Detection in progress"
        detection_active = True
        
        # Start detection in background thread
        detection_thread = threading.Thread(target=situp_detection_loop, daemon=True)
        detection_thread.start()
        
        return jsonify(success=True, message="Sit-up detection started", count=situp_count)
    
    except Exception as e:
        return jsonify(success=False, message=str(e)), 500

@app.route('/situp/status', methods=['GET'])
def get_situp_status():
    """Get current sit-up detection status"""
    return jsonify(
        success=True,
        count=situp_count,
        angle=round(current_angle, 2),
        stage=current_stage,
        message=status_message,
        active=detection_active
    )

@app.route('/situp/stop', methods=['POST'])
def stop_situp_detection():
    """Stop sit-up detection"""
    global detection_active, status_message
    
    try:
        detection_active = False
        status_message = "Detection stopped by user"
        
        return jsonify(success=True, message="Detection stopped", count=situp_count)
    
    except Exception as e:
        return jsonify(success=False, message=str(e)), 500

@app.route('/situp/reset', methods=['POST'])
def reset_situp():
    """Reset sit-up counter"""
    global situp_count, current_stage, status_message
    
    try:
        situp_count = 0
        current_stage = "down"
        status_message = "Reset complete"
        
        return jsonify(success=True, message="Sit-up count reset")
    
    except Exception as e:
        return jsonify(success=False, message=str(e)), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5003)
