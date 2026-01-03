@echo off
REM Clean and rebuild script for Juno Leaderboard GDExtension (Windows)
REM This script cleans all build artifacts and rebuilds from scratch

echo Cleaning previous build artifacts...
echo.

REM Navigate to rust directory
cd "%~dp0rust"

REM Clean build artifacts
echo Running cargo clean...
cargo clean

if %ERRORLEVEL% NEQ 0 (
    echo Failed to clean build artifacts!
    pause
    exit /b %ERRORLEVEL%
)

echo Cleaned successfully
echo.

REM Build in release mode
echo Building Juno Leaderboard GDExtension (release)...
cargo build --release

if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Copying library to bin directory...
copy /Y target\release\juno_leaderboard.dll ..\bin\

if %ERRORLEVEL% NEQ 0 (
    echo Failed to copy DLL!
    pause
    exit /b %ERRORLEVEL%
)

REM Show file size
for %%A in (..\bin\juno_leaderboard.dll) do (
    set SIZE=%%~zA
)

echo.
echo ===================================
echo Build complete: juno_leaderboard.dll
echo ===================================
echo.
echo Tip: Run 'cargo clean' in the rust folder
echo      to free up disk space after building.
echo      You only need the DLL in bin\
echo.
echo Restart Godot to load the new library.
echo.
pause
