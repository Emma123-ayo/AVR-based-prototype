@echo off
REM Start the Nyero AVR System backend and open the app in a browser
cd /d "%~dp0"

setlocal enabledelayedexpansion

REM Color codes for output
for /F %%A in ('copy /Z "%~f0" nul') do set "BS=%%A"

REM Check if Node is installed
where node >nul 2>nul
if errorlevel 1 (
    color 0C
    echo.
    echo   ERROR: Node.js is not installed!
    echo.
    echo   Please download and install Node.js from:
    echo   https://nodejs.org (LTS version recommended)
    echo.
    echo   After installation, re-run this script.
    color 07
    pause
    exit /b 1
)

REM Check if dependencies are installed
if not exist "node_modules" (
    color 0B
    echo.
    echo   Installing dependencies... Please wait...
    echo.
    color 07
    call npm install
    if errorlevel 1 (
        color 0C
        echo.
        echo   ERROR: Failed to install dependencies!
        color 07
        pause
        exit /b 1
    )
)

REM Check if port 8000 is in use
netstat -ano | findstr ":8000" >nul 2>&1
if not errorlevel 1 (
    color 0E
    echo.
    echo   WARNING: Port 8000 may already be in use!
    echo.
    echo   If another instance is running, the server will fail to start.
    echo   You can access the app at: http://localhost:8000
    echo.
    color 07
)

REM Start the server
color 0A
echo.
echo   =========================================
echo   Nyero AVR System - Starting Backend
echo   =========================================
echo.
echo   Server URL: http://localhost:8000
echo   App URL:    http://localhost:8000/app.html
echo.
echo   Close this window to stop the server.
echo.
color 07

REM Wait a moment then open browser
timeout /t 2 /nobreak >nul
start http://localhost:8000/app.html

REM Start the Node server
node server.js

REM If server stops, show a message
color 0C
echo.
echo   Server stopped!
echo.
color 07
pause
