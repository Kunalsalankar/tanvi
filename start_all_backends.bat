@echo off
REM Start all three backend servers for the Sports App

echo Starting all backend servers...
echo.

REM Open three separate terminal windows for each backend

start cmd /k "cd C:\Users\kunal salankar\Downloads\purva\sih && python app1.py"
timeout /t 2 /nobreak

start cmd /k "cd C:\Users\kunal salankar\Downloads\purva\sih && python squat_app.py"
timeout /t 2 /nobreak

start cmd /k "cd C:\Users\kunal salankar\Downloads\purva\sih && python situps_app.py"

echo.
echo All three backend servers are starting:
echo - Port 5001: Jump Detection (app1.py)
echo - Port 5002: Squat Detection (squat_app.py)
echo - Port 5003: Sit-ups Detection (situps_app.py)
echo.
echo Keep all windows open while using the Flutter app!
echo.
pause
