@echo off
setlocal
title SKYSPACE MEM - Live Aircraft Feed
cd /d "%~dp0"
where py >nul 2>&1
if %errorlevel%==0 (
  set "PYTHON=py -3"
) else (
  where python >nul 2>&1
  if errorlevel 1 (
    echo Python not found. Install Python 3 from https://www.python.org/downloads/
    pause
    exit /b 1
  )
  set "PYTHON=python"
)
echo ==========================================
echo    SKYSPACE MEM - LIVE AIRCRAFT FEED
echo ==========================================
echo 1. Live on this PC only (fast, recommended)
echo 2. Also publish a 5-minute-delayed GitHub snapshot
echo.
choice /c 12 /n /m "Choose 1 or 2: "
if errorlevel 2 (
  %PYTHON% skyspace_feed.py --publish
) else (
  %PYTHON% skyspace_feed.py
)
echo.
echo Server stopped.
pause
