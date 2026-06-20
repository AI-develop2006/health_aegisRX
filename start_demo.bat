@echo off
echo ===================================================
echo   SovereignShield Hybrid Network Demo Bootstrapper
echo ===================================================
echo.
echo Starting backend server in a separate window...
start "SovereignShield Backend Server" cmd /k "cd backend && npm install && node server.js"

echo.
echo Starting Flutter Mobile App client...
echo (Ensure you have a simulator/emulator running or device connected)
echo.
flutter run
pause
