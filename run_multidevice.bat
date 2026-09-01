@echo off
echo =======================================================
echo ParaFlight Device Launcher Menu
echo =======================================================
echo.
echo Connected Devices:
call flutter devices

echo.
echo Select the device to launch ParaFlight:
echo [S] - Smartphone (Pixel 5)
echo [T] - Tablet (X7)
echo [E] - Emulator
echo [Q] - Quit / Exit
echo.

choice /C STEQ /M "Press a key:"

if errorlevel 4 goto quit
if errorlevel 3 goto emulator
if errorlevel 2 goto tablet
if errorlevel 1 goto smartphone

:smartphone
echo.
echo Launching on Smartphone (Pixel 5)...
call flutter run -d 12261FDD4002BC
goto end

:tablet
echo.
echo Launching on Tablet (X7)...
call flutter run -d 202307001a
goto end

:emulator
echo.
echo Launching on Emulator...
call flutter run -d emulator-5554
goto end

:quit
echo.
echo Aborted.

:end
pause
