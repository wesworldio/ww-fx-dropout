@echo off
REM WesWorld FX Desktop - Installation Script for Windows

echo.
echo ==============================
echo WesWorld FX Desktop Setup
echo ==============================
echo.

REM Check for Node.js
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [X] Node.js is not installed
    echo Please install Node.js from https://nodejs.org/
    echo Recommended version: 18.x or later
    exit /b 1
)

for /f "tokens=*" %%i in ('node -v') do set NODE_VERSION=%%i
echo [OK] Node.js found: %NODE_VERSION%
echo.

REM Check for npm
where npm >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [X] npm is not installed
    exit /b 1
)

for /f "tokens=*" %%i in ('npm -v') do set NPM_VERSION=%%i
echo [OK] npm found: %NPM_VERSION%
echo.

REM Install dependencies
echo Installing dependencies...
call npm install

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [OK] Installation complete!
    echo.
    echo Quick Start:
    echo   * Run app:      npm start
    echo   * Development:  npm run dev
    echo   * Build Mac:    npm run build:mac
    echo   * Build Win:    npm run build:win
    echo   * Build Both:   npm run build:all
    echo.
    echo For more information, see electron\README.md
) else (
    echo.
    echo [X] Installation failed
    echo Please check the error messages above
    exit /b 1
)
