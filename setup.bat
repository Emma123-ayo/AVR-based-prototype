@echo off
REM Setup script for Nyero AVR System on Windows
REM This script installs Node.js dependencies

cd /d "%~dp0"

setlocal enabledelayedexpansion

echo.
echo   =========================================
echo   Nyero AVR System - Windows Setup
echo   =========================================
echo.

REM Check if Node is installed
where node >nul 2>nul
if errorlevel 1 (
    echo   ERROR: Node.js is not installed!
    echo.
    echo   Please download and install Node.js from:
    echo   https://nodejs.org (LTS version recommended)
    echo.
    echo   After installation, run this script again.
    echo.
    pause
    exit /b 1
)

REM Check Node version
for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
echo   Node.js version: %NODE_VERSION%
echo.

REM Install dependencies
echo   Installing npm dependencies...
echo.
call npm install

if errorlevel 1 (
    echo.
    echo   ERROR: Failed to install dependencies!
    echo.
    pause
    exit /b 1
)

echo.
echo   =========================================
echo   Setup complete!
echo   =========================================
echo.
echo   You can now run: start_local.bat
echo.
pause
