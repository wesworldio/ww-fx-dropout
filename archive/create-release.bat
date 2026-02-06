@echo off
REM Script to create a new release version and trigger build

setlocal enabledelayedexpansion

echo ==================================
echo WesWorld FX Desktop - Release Tool
echo ==================================
echo.

REM Check if we're in a git repository
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo Error: Not in a git repository
    exit /b 1
)

REM Check for uncommitted changes
git status -s >nul 2>&1
if not errorlevel 0 (
    echo Warning: You have uncommitted changes
    git status -s
    echo.
    set /p CONTINUE="Continue anyway? (y/n): "
    if /i not "!CONTINUE!"=="y" exit /b 1
)

REM Get current version from package.json
for /f "tokens=2 delims=:, " %%a in ('findstr /r "\"version\":" package.json') do (
    set CURRENT_VERSION=%%~a
)
echo Current version: !CURRENT_VERSION!
echo.

REM Ask for new version
set /p NEW_VERSION="Enter new version (e.g., 1.0.1, 1.1.0, 2.0.0): "

echo.
echo You are about to:
echo   1. Update package.json to version !NEW_VERSION!
echo   2. Commit the version change
echo   3. Create and push git tag v!NEW_VERSION!
echo   4. Trigger GitHub Actions to build and create release
echo.
set /p CONTINUE="Continue? (y/n): "
if /i not "!CONTINUE!"=="y" (
    echo Cancelled.
    exit /b 0
)

REM Update version in package.json
echo.
echo Updating package.json...
call npm version !NEW_VERSION! --no-git-tag-version

REM Commit version change
echo Committing version change...
git add package.json package-lock.json 2>nul
git commit -m "Release v!NEW_VERSION!"

REM Create and push tag
echo Creating git tag v!NEW_VERSION!...
git tag -a "v!NEW_VERSION!" -m "Release v!NEW_VERSION!"

echo Pushing to GitHub...
git push origin main
git push origin "v!NEW_VERSION!"

echo.
echo [OK] Release initiated!
echo.
echo GitHub Actions will now:
echo   * Build for macOS (Intel + ARM64)
echo   * Build for Windows (x64 + x86)
echo   * Build for Linux (AppImage + DEB)
echo   * Create GitHub Release with all installers
echo.
echo Check build progress in GitHub Actions
echo Release will be available in GitHub Releases
echo.
echo Done!

endlocal
