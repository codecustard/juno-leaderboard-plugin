@echo off
REM Build script for Juno Leaderboard GDExtension (Windows)
REM Builds the Rust library and copies it to the bin directory

echo Building Juno Leaderboard GDExtension...
echo.

REM Navigate to rust directory
cd "%~dp0rust"

REM Build in release mode
echo Compiling Rust code...
cargo build --release

if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    pause
    exit /b %ERRORLEVEL%
)

REM Copy DLL to bin directory
echo Copying library to bin directory...
copy /Y target\release\juno_leaderboard.dll ..\bin\

if %ERRORLEVEL% NEQ 0 (
    echo Failed to copy DLL!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Build complete: juno_leaderboard.dll
echo You can now enable the plugin in Godot.
echo.
pause
