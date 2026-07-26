@echo off
setlocal enabledelayedexpansion
set "FILE_ID=13TmvrOHgG3whsuk4ofom_yhxRLzyjJjH"
set "DEST_DIR=i686-elf-tools\libexec\gcc\i686-elf\15.2.0"

if exist "%DEST_DIR%\cc1.exe" (
    echo cc1.exe exists.
) else (
    echo cc1.exe does not exist. Downloading now...
    
    if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"
    curl -c cookies.txt -L "https://drive.google.com/uc?export=download&id=%FILE_ID%" -o warning.html
    set "UUID="
    for /f "tokens=1,* delims==" %%a in ('findstr "name=\"uuid\"" warning.html') do (
        for /f "tokens=1 delims= " %%c in ("%%b") do set "UUID=%%~c"
    )
    
    if defined UUID (
        echo Using UUID: !UUID!
        curl -b cookies.txt -L "https://drive.usercontent.google.com/download?id=%FILE_ID%&export=download&confirm=t&uuid=!UUID!" -o "%DEST_DIR%\cc1.exe"
    ) else (
        echo No UUID found, trying direct download...
        curl -b cookies.txt -L "https://drive.usercontent.google.com/download?id=%FILE_ID%&export=download&confirm=t" -o "%DEST_DIR%\cc1.exe"
    )
    del warning.html 2>nul
    del cookies.txt 2>nul
)

set /p namem="Program name? (default: mykernel): "

if not exist "kernel.asm" (
    echo ERROR: kernel.asm not found!
    exit /b 1
)
if not exist "kernel.c" (
    echo ERROR: kernel.c not found!
    exit /b 1
)
if not exist "linker.ld" (
    echo ERROR: linker.ld not found!
    exit /b 1
)

echo [1/3] Assembling kernel.asm...
".\NASM\nasm.exe" -f elf32 kernel.asm -o k_asm.o
if %errorlevel% neq 0 (
    echo ERROR: Assembly failed!
    exit /b 1
)
echo       Done.

echo [2/3] Compiling kernel.c...
".\i686-elf-tools\bin\i686-elf-gcc.exe" -ffreestanding -c kernel.c -o k_c.o
if %errorlevel% neq 0 (
    echo ERROR: Compilation failed!
    exit /b 1
)
echo       Done.

echo [3/3] Linking kernel...
".\i686-elf-tools\bin\i686-elf-ld" -T linker.ld -o %namem%.elf k_asm.o k_c.o
if %errorlevel% neq 0 (
    echo ERROR: Linking failed!
    exit /b 1
)
echo       Done.

".\i686-elf-tools\bin\i686-elf-objcopy" -O binary %namem%.elf %namem%.bin 2>nul

echo.
echo ===============================
echo   Build successful!
echo   Output: %namem%.elf
echo           %namem%.bin
echo ===============================
echo.

echo Cleaning up build files...
del k_asm.o 2>nul
del k_c.o 2>nul
echo       Done.

set /p RUN="Run in QEMU? (Y/N): "
if /i not "%RUN%"=="Y" goto :eof

set "QEMUPATH=C:\Program Files\qemu"
set /p QEMUPATH="Path to QEMU? (default: %QEMUPATH%): "
if "%QEMUPATH%"=="" set "QEMUPATH=C:\Program Files\qemu"

if exist "%QEMUPATH%\qemu-system-i386.exe" (
    echo Starting QEMU...
    "%QEMUPATH%\qemu-system-i386.exe" -kernel %namem%.elf
) else (
    echo QEMU not found at %QEMUPATH%
)

endlocal