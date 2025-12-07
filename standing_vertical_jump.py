import cv2
import mediapipe as mp
import numpy as np
import csv
import time

OUTPUT_CSV = "jump_results.csv"
FRAME_WIDTH = 1280
FRAME_HEIGHT = 720
mp_drawing = mp.solutions.drawing_utils
mp_pose = mp.solutions.pose

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

def get_user_input():
    try:
        height = float(input("Enter your height in cm: "))
        weight = float(input("Enter your weight in kg: "))
        return height, weight
    except Exception:
        print("Invalid input. Try again.")
        return get_user_input()

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

def main():
    user_height, user_weight = get_user_input()
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("ERROR: Camera could not be opened.")
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
    jump_count = 0
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
        while True:
            ret, frame = cap.read()
            if not ret:
                break
            h, w = frame.shape[:2]
            vis_frame = frame.copy()
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(frame_rgb)

            if not setup_done:
                cv2.putText(vis_frame, "Step 1: Adjust camera so full body is visible", (40, 60),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2)
                cv2.putText(vis_frame, "Stand so feet touch ground line", (40, 100),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2)
                if results.pose_landmarks:
                    is_visible = check_body_visible(results.pose_landmarks.landmark, h, w)
                    px_cal, ground_y = calculate_px_per_cm(results.pose_landmarks.landmark, h, user_height)
                    if is_visible and px_cal:
                        px_per_cm = px_cal
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
                                kalman_filter.statePost = np.array([[standing_reach_y], [0]], np.float32)  # Init kalman with standing reach
                                cv2.putText(vis_frame, "Confirmed! Start jumping.", (40, 250), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 0), 2)
                        else:
                            clap_frames = 0
                            cv2.putText(vis_frame, "Join (clap) your hands to start.", (40, 210), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
                    else:
                        cv2.putText(vis_frame, "Ensure full body & ground is visible.", (40, 150), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
                cv2.imshow(WINDOW_NAME, vis_frame)
                key = cv2.waitKey(10)
                if key == ord('q'):
                    break
                continue

            # Jump measurement with cheat detection
            cheat_flag = False
            if results.pose_landmarks:
                mp_drawing.draw_landmarks(vis_frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
                lm = results.pose_landmarks.landmark
                wrist = lm[mp_pose.PoseLandmark.RIGHT_WRIST.value]
                if wrist.visibility < 0.5:
                    cv2.putText(vis_frame, "Wrist not visible", (30, 250), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
                    # Optionally skip kalman update this frame
                else:
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
                            last_jump_time = current_time
                            csvw.writerow([time.strftime('%Y-%m-%d %H:%M:%S'), f"{jump_height_cm:.2f}"])
                            in_air = False

                    # Display jump info
                    cv2.putText(vis_frame, f"Jumps: {jump_count}", (30, 60), cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 0), 2)
                    cv2.putText(vis_frame, f"Last Jump Height: {jump_height_cm:.2f} cm", (30, 120), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2)

                    # Display cheat status
                    cheat_text = "CHEAT DETECTED!" if cheat_flag else "No Cheat Detected"
                    cheat_color = (0, 0, 255) if cheat_flag else (0, 255, 0)
                    cv2.putText(vis_frame, f"Cheat Detection: {cheat_text}", (30, 180), cv2.FONT_HERSHEY_SIMPLEX, 1, cheat_color, 2)
                    cv2.putText(vis_frame, "Press 'c' to toggle cheat detection", (30, 210), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 0), 1)

            cv2.imshow(WINDOW_NAME, vis_frame)
            key = cv2.waitKey(10) & 0xFF
            if key == ord('q'):
                break
            elif key == ord('c'):
                cheat_detection_enabled = not cheat_detection_enabled

    cap.release()
    csvfile.close()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()


