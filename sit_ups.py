import cv2
import mediapipe as mp
import numpy as np
import csv
import requests
import time

OUTPUT_CSV = "situp_results.csv"
FRAME_WIDTH = 1280
FRAME_HEIGHT = 720

mp_drawing = mp.solutions.drawing_utils
mp_pose = mp.solutions.pose

def angle(a, b, c):
    ba = np.array([a.x - b.x, a.y - b.y])
    bc = np.array([c.x - b.x, c.y - b.y])
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    return np.degrees(np.arccos(np.clip(cosine_angle, -1.0, 1.0)))

def main():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("ERROR: Camera could not be opened.")
        return
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, FRAME_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, FRAME_HEIGHT)

    WINDOW_NAME = "Sit-up Counter (press 'q' to quit)"
    cv2.namedWindow(WINDOW_NAME)

    csvfile = open(OUTPUT_CSV, "w", newline="")
    csvw = csv.writer(csvfile)
    csvw.writerow(["timestamp", "rep_count"])

    rep_count = 0
    phase = "down"
    last_rep_time = 0

    DOWN_ANGLE = 160
    UP_ANGLE = 100
    SHOULDER_GROUND_Y = 0.85  # Adjust based on camera setup
    SHOULDER_UP_Y = 0.6       # Adjust based on camera setup

    with mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5) as pose:
        while True:
            ret, frame = cap.read()
            if not ret:
                print("Camera read failed. Exiting.")
                break

            h, w = frame.shape[:2]
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(frame_rgb)
            vis_frame = frame.copy()

            if results.pose_landmarks:
                mp_drawing.draw_landmarks(vis_frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
                lm = results.pose_landmarks.landmark

                left_shoulder = lm[mp_pose.PoseLandmark.LEFT_SHOULDER.value]
                left_hip = lm[mp_pose.PoseLandmark.LEFT_HIP.value]
                left_knee = lm[mp_pose.PoseLandmark.LEFT_KNEE.value]
                left_elbow = lm[mp_pose.PoseLandmark.LEFT_ELBOW.value]
                right_knee = lm[mp_pose.PoseLandmark.RIGHT_KNEE.value]
                left_wrist = lm[mp_pose.PoseLandmark.LEFT_WRIST.value]
                right_wrist = lm[mp_pose.PoseLandmark.RIGHT_WRIST.value]
                nose = lm[mp_pose.PoseLandmark.NOSE.value]

                # Angles
                abdomen_angle = angle(left_shoulder, left_hip, left_knee)
                knee_angle = angle(left_hip, left_knee, lm[mp_pose.PoseLandmark.LEFT_ANKLE.value])

                # Elbow-Knee Distance
                elbow_knee_dist = np.linalg.norm([
                    left_elbow.x - left_knee.x,
                    left_elbow.y - left_knee.y
                ])

                # Distance (shoulder to knee, approx in pixels)
                distance = np.linalg.norm([
                    left_shoulder.x - left_knee.x,
                    left_shoulder.y - left_knee.y
                ]) * w

                # Hands behind head check
                hands_behind_head = (
                    left_wrist.y < nose.y and right_wrist.y < nose.y
                )

                # Display posture feedback
                cv2.putText(vis_frame, "Posture: Place both hands behind your head!", (30, 100),
                            cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0,0,255), 2)
                cv2.putText(vis_frame, f"Abdomen Angle: {int(abdomen_angle)}", (30, 140),
                            cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0,255,255), 2)
                cv2.putText(vis_frame, f"Knee Angle: {int(knee_angle)}", (30, 180),
                            cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0,255,255), 2)
                cv2.putText(vis_frame, f"Elbow-Knee Dist.: {elbow_knee_dist:.3f}", (30, 220),
                            cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0,255,255), 2)
                cv2.putText(vis_frame, f"Distance: {distance:.2f} (approx)", (30, 260),
                            cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0,255,255), 2)
                cv2.putText(vis_frame, f"Hands Behind Head: {'True' if hands_behind_head else 'False'}", (30, 300),
                            cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0,255,255) if hands_behind_head else (0,0,255), 2)

                # Sit-up logic:
                sh_hip_knee_angle = angle(left_shoulder, left_hip, left_knee)
                shoulder_y = left_shoulder.y

                # Debug print for calibration
                # print(f"Angle: {sh_hip_knee_angle:.1f}, Shoulder Y: {shoulder_y:.2f}, Phase: {phase}")

                # Only count sit-up if hands are behind head
                if hands_behind_head:
                    if phase == "down":
                        if sh_hip_knee_angle < UP_ANGLE and shoulder_y < SHOULDER_UP_Y:
                            phase = "up"
                    elif phase == "up":
                        if sh_hip_knee_angle > DOWN_ANGLE and shoulder_y > SHOULDER_GROUND_Y:
                            # Add cooldown to avoid double counting
                            if time.time() - last_rep_time > 0.5:
                                rep_count += 1
                                last_rep_time = time.time()
                                print(f"Sit-up rep counted! Total: {rep_count}")
                                csvw.writerow([time.strftime('%Y-%m-%d %H:%M:%S'), rep_count])
                                try:
                                    requests.post("http://127.0.0.1:5000/increment")
                                except Exception as e:
                                    print("Could not update counter:", e)
                            phase = "down"

            cv2.putText(vis_frame, f"Sit-ups: {rep_count}", (30,60),
                        cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0,255,0), 2, cv2.LINE_AA)
            cv2.imshow(WINDOW_NAME, vis_frame)

            key = cv2.waitKey(5)
            if key == ord('q'):
                break

    cap.release()
    csvfile.close()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
    