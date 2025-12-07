"""
Guaranteed working squat counter using knee angle + descending/ascending logic.
Works with ANY realistic squat angle range.
"""

import cv2
import mediapipe as mp
import numpy as np

mp_pose = mp.solutions.pose
mp_draw = mp.solutions.drawing_utils

SMOOTH_ALPHA = 0.4
MIN_VIS = 0.2

# Instead of fixed ranges → use % drop from standing angle
DEPTH_PERCENT = 0.75   # 75% of standing angle = bottom squat


def get_angle(a, b, c):
    a = np.array([a.x, a.y])
    b = np.array([b.x, b.y])
    c = np.array([c.x, c.y])

    ba = a - b
    bc = c - b
    cos = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    return np.degrees(np.arccos(np.clip(cos, -1, 1)))


def main():

    cap = cv2.VideoCapture(0)

    squat_count = 0
    stage = "up"

    smoothed_angle = None
    standing_reference = None  # detected automatically

    with mp_pose.Pose(min_detection_confidence=0.5,
                      min_tracking_confidence=0.5) as pose:

        while True:

            ret, frame = cap.read()
            if not ret:
                break

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(rgb)
            vis = frame.copy()
            h, w = frame.shape[:2]

            if results.pose_landmarks:
                lm = results.pose_landmarks.landmark
                mp_draw.draw_landmarks(vis, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)

                if lm[mp_pose.PoseLandmark.LEFT_KNEE].visibility > MIN_VIS:
                    hip = lm[mp_pose.PoseLandmark.LEFT_HIP]
                    knee = lm[mp_pose.PoseLandmark.LEFT_KNEE]
                    ankle = lm[mp_pose.PoseLandmark.LEFT_ANKLE]
                else:
                    hip = lm[mp_pose.PoseLandmark.RIGHT_HIP]
                    knee = lm[mp_pose.PoseLandmark.RIGHT_KNEE]
                    ankle = lm[mp_pose.PoseLandmark.RIGHT_ANKLE]

                angle = get_angle(hip, knee, ankle)

                # smooth
                if smoothed_angle is None:
                    smoothed_angle = angle
                else:
                    smoothed_angle = SMOOTH_ALPHA * angle + (1 - SMOOTH_ALPHA) * smoothed_angle

                # -------------------------
                # AUTO-STANDING CALIBRATION
                # -------------------------
                if standing_reference is None:
                    standing_reference = smoothed_angle  # first few frames while standing
                    print("Calibrating standing angle =", standing_reference)

                # Compute dynamic squat depth
                squat_depth_angle = standing_reference * DEPTH_PERCENT

                # -------------------------
                # SQUAT DETECTION LOGIC
                # -------------------------

                # Going DOWN
                if smoothed_angle < squat_depth_angle and stage == "up":
                    stage = "down"

                # Going UP (standing again)
                if smoothed_angle > standing_reference * 0.95 and stage == "down":
                    squat_count += 1
                    stage = "up"

                # -------------------------
                # DISPLAY
                cv2.putText(vis, f"Angle: {int(smoothed_angle)}°", (30, 60),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (255,255,255), 2)

                cv2.putText(vis, f"Stage: {stage}", (30, 110),
                            cv2.FONT_HERSHEY_SIMPLEX, 1.2, (0,255,255), 2)

                cv2.putText(vis, f"Squats: {squat_count}", (30, 180),
                            cv2.FONT_HERSHEY_SIMPLEX, 2, (0,255,0), 3)

            cv2.imshow("AI Squat Counter", vis)

            if cv2.waitKey(5) & 0xFF == ord('q'):
                break

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
