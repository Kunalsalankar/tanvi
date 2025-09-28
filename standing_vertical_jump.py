import cv2
import mediapipe as mp
import numpy as np
import csv
import requests
import time

OUTPUT_CSV = "jump_results.csv"
FRAME_WIDTH = 1280
FRAME_HEIGHT = 720

mp_drawing = mp.solutions.drawing_utils
mp_pose = mp.solutions.pose

A4_HEIGHT_CM = 29.7  # Height of A4 paper in centimeters


def detect_a4_paper(frame):
    """Detects the largest rectangle (A4 paper) and returns its height in pixels."""
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    edged = cv2.Canny(blurred, 50, 150)
    contours, _ = cv2.findContours(edged, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    max_area = 0
    best_rect = None
    for cnt in contours:
        approx = cv2.approxPolyDP(cnt, 0.02 * cv2.arcLength(cnt, True), True)
        if len(approx) == 4:
            area = cv2.contourArea(approx)
            if area > max_area:
                max_area = area
                best_rect = approx
    if best_rect is not None:
        pts = best_rect.reshape(4, 2)
        # Sort points to get top-left, top-right, bottom-right, bottom-left
        pts = sorted(pts, key=lambda x: x[1])  # sort by y
        top_pts = sorted(pts[:2], key=lambda x: x[0])
        bottom_pts = sorted(pts[2:], key=lambda x: x[0])
        # Height is average of left and right vertical distances
        height1 = np.linalg.norm(top_pts[0] - bottom_pts[0])
        height2 = np.linalg.norm(top_pts[1] - bottom_pts[1])
        a4_height_px = (height1 + height2) / 2
        return a4_height_px, best_rect
    return None, None


def main():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("ERROR: Camera could not be opened.")
        return

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, FRAME_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, FRAME_HEIGHT)

    WINDOW_NAME = "Vertical Jump Counter (press 'q' to quit, 'r' to reset)"
    cv2.namedWindow(WINDOW_NAME)

    csvfile = open(OUTPUT_CSV, "w", newline="")
    csvw = csv.writer(csvfile)
    csvw.writerow(["timestamp", "jump_height_px"])

    standing_reach_y = None
    peak_jump_y = None
    jump_height_px = 0.0
    jump_height_cm = 0.0  # <-- Add this line
    jump_count = 0
    in_air = False
    jump_cooldown = 1.0  # seconds
    last_jump_time = 0

    clap_frames = 0
    CLAP_FRAMES_REQUIRED = 5
    CLAP_DISTANCE_THRESHOLD = 60

    clap_done = False
    a4_height_px = None
    pixel_to_cm = None

    with mp_pose.Pose(min_detection_confidence=0.5, min_tracking_confidence=0.5) as pose:
        while True:
            ret, frame = cap.read()
            if not ret:
                print("Camera read failed. Exiting.")
                break

            h, w = frame.shape[:2]
            vis_frame = frame.copy()

            # Detect A4 paper once at the start
            if pixel_to_cm is None:
                a4_height_px, rect = detect_a4_paper(frame)
                if a4_height_px:
                    pixel_to_cm = A4_HEIGHT_CM / a4_height_px
                    cv2.polylines(vis_frame, [rect], True, (0, 255, 255), 3)
                    cv2.putText(vis_frame, f"A4 Detected: {a4_height_px:.1f}px = {A4_HEIGHT_CM}cm", (30, 40),
                                cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 255), 2)
                else:
                    cv2.putText(vis_frame, "Place A4 paper in yellow box", (30, 40),
                                cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 0, 255), 2)
                cv2.imshow(WINDOW_NAME, vis_frame)
                if cv2.waitKey(5) == ord('q'):
                    break
                continue

            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(frame_rgb)

            if not clap_done:
                if results.pose_landmarks:
                    lm = results.pose_landmarks.landmark
                    left_wrist = lm[mp_pose.PoseLandmark.LEFT_WRIST.value]
                    right_wrist = lm[mp_pose.PoseLandmark.RIGHT_WRIST.value]
                    lw_x, lw_y = int(left_wrist.x * w), int(left_wrist.y * h)
                    rw_x, rw_y = int(right_wrist.x * w), int(right_wrist.y * h)
                    dist = np.linalg.norm([lw_x - rw_x, lw_y - rw_y])
                    if dist < CLAP_DISTANCE_THRESHOLD:
                        clap_frames += 1
                        cv2.putText(vis_frame, "Clap detected!", (30, 100),
                                    cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 255), 2)
                        if clap_frames >= CLAP_FRAMES_REQUIRED:
                            standing_reach_y = right_wrist.y * h
                            clap_done = True
                            print(f"Standing reach set at y={standing_reach_y:.2f} px (by clap)")
                    else:
                        clap_frames = 0
                    if clap_frames == 0:
                        cv2.putText(vis_frame, "Clap hands to set standing reach", (30, 100),
                                    cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 0, 255), 2)
                cv2.imshow(WINDOW_NAME, vis_frame)
                if cv2.waitKey(5) == ord('q'):
                    break
                continue

            if clap_done and results.pose_landmarks:
                mp_drawing.draw_landmarks(vis_frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
                lm = results.pose_landmarks.landmark
                wrist = lm[mp_pose.PoseLandmark.RIGHT_WRIST.value]
                wrist_y_px = wrist.y * h

                current_time = time.time()
                if wrist_y_px < standing_reach_y - 30:
                    if not in_air and (current_time - last_jump_time > jump_cooldown):
                        in_air = True
                        peak_jump_y = wrist_y_px
                    elif in_air:
                        peak_jump_y = min(peak_jump_y, wrist_y_px)
                else:
                    if in_air:
                        jump_height_px = standing_reach_y - peak_jump_y
                        jump_height_cm = jump_height_px * pixel_to_cm
                        jump_count += 1
                        last_jump_time = current_time
                        print(f"Jump {jump_count}: {jump_height_cm:.2f} cm")

                        try:
                            requests.post("http://127.0.0.1:5000/increment", json={"jump_height": jump_height_cm})
                        except Exception as e:
                            print("Could not update counter:", e)

                        csvw.writerow([time.strftime('%Y-%m-%d %H:%M:%S'), f"{jump_height_cm:.2f}"])
                        in_air = False

                # UI overlay
                cv2.putText(vis_frame, f"Jumps: {jump_count}", (30, 60),
                            cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 0), 2)
                cv2.putText(vis_frame, f"Last Jump Height: {jump_height_cm:.2f} cm", (30, 120),
                            cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2)

            cv2.imshow(WINDOW_NAME, vis_frame)
            key = cv2.waitKey(5)
            if key == ord('q'):
                break
            elif key == ord('r'):
                jump_count = 0
                jump_height_px = 0.0

    cap.release()
    csvfile.close()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
