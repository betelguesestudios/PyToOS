@echo off
setlocal enabledelayedexpansion

echo [1/3] Running DeleteAllBuildFiles.bat...
call ".\DeleteAllBuildFiles.bat"
if %errorlevel% neq 0 (
    echo ERROR: DeleteAllBuildFiles.bat failed with exit code %errorlevel%
    pause
    exit /b 1
)
echo [1/3] Done.

echo [2/3] Running pytoc.bat...
call ".\pytoc.bat"
if %errorlevel% neq 0 (
    echo ERROR: pytoc.bat failed with exit code %errorlevel%
    pause
    exit /b 1
)
echo [2/3] Done.

echo [3/3] Running build.bat...
call ".\build.bat"
if %errorlevel% neq 0 (
    echo ERROR: build.bat failed with exit code %errorlevel%
    pause
    exit /b 1
)
echo [3/3] Done.

echo.
echo Finished successfully!
pause
