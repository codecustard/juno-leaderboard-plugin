@echo off
REM Clean build artifacts to free disk space (Windows)
REM Keeps only the final library in bin\

echo Cleaning Rust build artifacts...
echo.

cd "%~dp0rust"

if not exist "target\" (
    echo No target\ directory found - already clean
    pause
    exit /b 0
)

echo Running cargo clean...
cargo clean

if %ERRORLEVEL% NEQ 0 (
    echo Failed to clean!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Clean complete! Freed approximately 500MB
echo.
echo Note: The compiled library in bin\ was preserved.
echo       Run rebuild.bat if you need to rebuild.
echo.
pause
