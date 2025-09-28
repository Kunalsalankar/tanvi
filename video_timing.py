"""
video_timing.py

Auto-detect sprint start and finish using ArUco markers + MediaPipe Pose.
Works for side-view video where athletes cross vertical lines (start/finish).
Change LINE_ORIENTATION to 'horizontal' if your lines run horizontally in the frame.

Usage:
    python video_timing.py --video path/to/video.mp4
    python video_timing.py              # uses webcam
"""

import cv2
import mediapipe as mp
import numpy as np
import argparse
import time
from collections import deque

# ---------- CONFIG ----------
ARUCO_DICT = cv2.aruco.getPredefinedDictionary(cv2.aruco.DICT_4X4_50)
ARUCO_PARAMS = cv2.aruco.DetectorParameters()
LINE_ORIENTATION = 'vertical'   # 'vertical' -> compare x coords; 'horizontal' -> compare y coords
DEBOUNCE_FRAMES = 3            # require consistent crossing for N frames to avoid blips
MIN_FRAME_GAP = 3              # minimal frames between start and finish to ignore tiny noise
# ----------------------------

mp_pose = mp.solutions.pose
pose = mp_pose.Pose(static_image_mode=False,
                    model_complexity=1,
                    enable_segmentation=False,
                    min_detection_confidence=0.5,
                    min_tracking_confidence=0.5)

def detect_aruco_markers(gray):
    corners, ids, rejected = cv2.aruco.detectMarkers(gray, ARUCO_DICT, parameters=ARUCO_PARAMS)
    if ids is None:
        return []
    # returns list of tuples: (id, corners) where corners is 4x2 array
    markers = []
    for i, c in enumerate(corners):
        markers.append((int(ids[i][0]), c.reshape((4, 2))))
    return markers

def marker_center_and_orientation(corners):
    # returns center (x, y) and orientation vector
    center = np.mean(corners, axis=0)
    # orientation: vector from corner 0 to corner 1 (roughly top edge)
    orient = corners[1] - corners[0]
    return center, orient

def line_position_from_marker(corners):
    # If LINE_ORIENTATION == 'vertical' we compute an x coordinate
    center, orient = marker_center_and_orientation(corners)
    if LINE_ORIENTATION == 'vertical':
        # Vertical line coordinate is the center x
        return float(center[0])
    else:
        return float(center[1])

def get_landmark_coords(results, img_w, img_h):
    # returns dict of landmark_name -> (x_px, y_px)
    if not results.pose_landmarks:
        return {}
    lm = results.pose_landmarks.landmark
    # Important landmarks we'll use:
    # 0: nose (approx torso top), 11 left shoulder, 12 right shoulder
    # 23 left hip, 24 right hip
    # 27 left ankle, 28 right ankle
    names = {
        'nose': 0, 'left_shoulder': 11, 'right_shoulder': 12,
        'left_hip': 23, 'right_hip': 24, 'left_ankle': 27, 'right_ankle': 28
    }
    coords = {}
    for name, idx in names.items():
        lm_item = lm[idx]
        coords[name] = (int(lm_item.x * img_w), int(lm_item.y * img_h))
    return coords

def detect_notebook_lines(frame):
    # Convert to HSV for color detection
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    # Define color range for notebook (adjust these values)
    lower = np.array([0, 0, 200])   # Example: white notebook
    upper = np.array([180, 30, 255])
    mask = cv2.inRange(hsv, lower, upper)
    # Find contours
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    lines = []
    for cnt in contours:
        x, y, w, h = cv2.boundingRect(cnt)
        # Filter by size to avoid noise
        if w > 50 and h > 100:  # Adjust as needed
            center = (x + w // 2, y + h // 2)
            lines.append(center)
            cv2.rectangle(frame, (x, y), (x + w, y + h), (0, 255, 0), 2)
    return lines

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", type=str, help="path to video file (optional). If not given, uses webcam.")
    args = parser.parse_args()

    cap = cv2.VideoCapture(0 if args.video is None else args.video)
    if not cap.isOpened():
        print("ERROR: cannot open video source")
        return

    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    frame_idx = 0
    start_frame = None
    finish_frame = None

    # Buffers for debouncing
    start_deque = deque(maxlen=DEBOUNCE_FRAMES)
    finish_deque = deque(maxlen=DEBOUNCE_FRAMES)

    # We'll store last observed marker positions (ids -> pos)
    marker_positions = {}

    print("Press 'q' to quit. Waiting for markers to be visible in the frame...")

    while True:
        ret, frame = cap.read()
        if not ret:
            break
        frame_idx += 1
        h, w = frame.shape[:2]

        # 1) Detect notebook lines (replace ArUco marker detection)
        notebook_lines = detect_notebook_lines(frame)
        marker_positions = {}
        if len(notebook_lines) >= 2:
            # Sort by x or y depending on orientation
            notebook_lines = sorted(notebook_lines, key=lambda c: c[0] if LINE_ORIENTATION == 'vertical' else c[1])
            start_pos = notebook_lines[0][0] if LINE_ORIENTATION == 'vertical' else notebook_lines[0][1]
            finish_pos = notebook_lines[-1][0] if LINE_ORIENTATION == 'vertical' else notebook_lines[-1][1]
            # Draw lines
            if LINE_ORIENTATION == 'vertical':
                cv2.line(frame, (int(start_pos), 0), (int(start_pos), h), (0,255,0), 2)
                cv2.line(frame, (int(finish_pos), 0), (int(finish_pos), h), (0,255,0), 2)
            else:
                cv2.line(frame, (0, int(start_pos)), (w, int(start_pos)), (0,255,0), 2)
                cv2.line(frame, (0, int(finish_pos)), (w, int(finish_pos)), (0,255,0), 2)
        else:
            start_pos = None
            finish_pos = None

        # 2) Pose detection
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(rgb)
        coords = get_landmark_coords(results, w, h)

        # draw landmarks for debugging
        if coords:
            for name, (x,y) in coords.items():
                cv2.circle(frame, (x,y), 4, (255,0,0), -1)
                cv2.putText(frame, name, (x+5, y+5), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (255,0,0), 1)

        # 3) Decide which point to use for start & finish triggers.
        # Start: use leading ankle (the ankle closer to start side before run)
        # Finish: use torso y defined by average of shoulders+hips (more stable than nose)
        if coords and start_pos is not None and finish_pos is not None:
            # compute torso center x,y
            shoulder_x = (coords['left_shoulder'][0] + coords['right_shoulder'][0]) / 2
            shoulder_y = (coords['left_shoulder'][1] + coords['right_shoulder'][1]) / 2
            hip_x = (coords['left_hip'][0] + coords['right_hip'][0]) / 2
            hip_y = (coords['left_hip'][1] + coords['right_hip'][1]) / 2
            torso_x = (shoulder_x + hip_x) / 2
            torso_y = (shoulder_y + hip_y) / 2

            # choose ankle that is leading in movement direction:
            left_ankle_x, left_ankle_y = coords['left_ankle']
            right_ankle_x, right_ankle_y = coords['right_ankle']
            # leading ankle = one with smaller x if start is left, or larger x if start is right
            # We'll infer start/finish side: start_pos < finish_pos => runner moves left->right
            moving_left_to_right = (start_pos < finish_pos)
            if moving_left_to_right:
                leading_ankle_x = max(left_ankle_x, right_ankle_x)
                leading_ankle_y = left_ankle_y if left_ankle_x >= right_ankle_x else right_ankle_y
            else:
                leading_ankle_x = min(left_ankle_x, right_ankle_x)
                leading_ankle_y = left_ankle_y if left_ankle_x <= right_ankle_x else right_ankle_y

            # Check crossing condition according to orientation
            if LINE_ORIENTATION == 'vertical':
                # Start trigger: leading ankle crosses start_pos moving away from start
                if moving_left_to_right:
                    # before crossing: ankle_x < start_pos; after: ankle_x >= start_pos
                    is_start_cross = (leading_ankle_x >= start_pos)
                    is_finish_cross = (torso_x >= finish_pos)
                else:
                    is_start_cross = (leading_ankle_x <= start_pos)
                    is_finish_cross = (torso_x <= finish_pos)
            else:
                # horizontal orientation (athlete moves top->bottom or bottom->top)
                if start_pos < finish_pos:
                    is_start_cross = (leading_ankle_y >= start_pos)
                    is_finish_cross = (torso_y >= finish_pos)
                else:
                    is_start_cross = (leading_ankle_y <= start_pos)
                    is_finish_cross = (torso_y <= finish_pos)

            # Debounce using small frame-window
            start_deque.append(1 if is_start_cross else 0)
            finish_deque.append(1 if is_finish_cross else 0)

            start_consistent = sum(start_deque) >= DEBOUNCE_FRAMES
            finish_consistent = sum(finish_deque) >= DEBOUNCE_FRAMES

            if start_consistent and start_frame is None:
                start_frame = frame_idx
                start_time = start_frame / fps
                print(f"[EVENT] Start detected at frame {start_frame}, time {start_time:.3f}s")
                cv2.putText(frame, f"START @ {start_time:.3f}s", (50, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0,0,255), 3)

            if finish_consistent and start_frame is not None and finish_frame is None:
                # ensure finish is at least a few frames after start
                if frame_idx - start_frame >= MIN_FRAME_GAP:
                    finish_frame = frame_idx
                    finish_time = finish_frame / fps
                    total_time = finish_time - (start_frame / fps)
                    print(f"[EVENT] Finish detected at frame {finish_frame}, time {finish_time:.3f}s. Total = {total_time:.3f}s")
                    cv2.putText(frame, f"FINISH @ {finish_time:.3f}s", (50, 110), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0,0,255), 3)
                    cv2.putText(frame, f"TIME = {total_time:.3f}s", (50, 140), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0,165,255), 3)

        # overlay FPS and frame index
        cv2.putText(frame, f"Frame: {frame_idx}", (10, h-20), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255,255,255), 1)
        cv2.putText(frame, f"FPS: {fps:.1f}", (w-120, h-20), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255,255,255), 1)

        cv2.imshow("Timing", frame)
        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

    if start_frame and finish_frame:
        total_time = (finish_frame - start_frame) / fps
        print("=== RESULT ===")
        print(f"Start frame:  {start_frame}")
        print(f"Finish frame: {finish_frame}")
        print(f"FPS:          {fps:.2f}")
        print(f"Total time:   {total_time:.4f} sec")
    else:
        print("No complete start/finish pair detected.")

if __name__ == "__main__":
    main()
