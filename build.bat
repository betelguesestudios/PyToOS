@echo off
setlocal enabledelayedexpansion
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
.\NASM\nasm.exe -f elf32 kernel.asm -o k_asm.o
if %errorlevel% neq 0 (
    echo ERROR: Assembly failed!
    exit /b 1
)
echo       Done.

echo [2/3] Compiling kernel.c...
.\i686-elf-tools\bin\i686-elf-gcc.exe -ffreestanding -c kernel.c -o k_c.o
if %errorlevel% neq 0 (
    echo ERROR: Compilation failed!
    exit /b 1
)
echo       Done.

echo [3/3] Linking kernel...
.\i686-elf-tools\bin\i686-elf-ld -T linker.ld -o mykernel.elf k_asm.o k_c.o
if %errorlevel% neq 0 (
    echo ERROR: Linking failed!
    exit /b 1
)
echo       Done.

.\i686-elf-tools\bin\i686-elf-objcopy -O binary mykernel.elf mykernel.bin 2>nul

echo.
echo ===============================
echo   Build successful!
echo   Output: mykernel.elf
echo           mykernel.bin
echo ===============================
echo.
set /p RUN="Run in QEMU? (Y/N): "
if /i not "%RUN%"=="Y" goto :eof

set "QEMUPATH=C:\Program Files\qemu"
set /p QEMUPATH="Path to QEMU? (default: %QEMUPATH%): "
if "%QEMUPATH%"=="" set "QEMUPATH=C:\Program Files\qemu"

if exist "%QEMUPATH%\qemu-system-i386.exe" (
    echo Starting QEMU...
    "%QEMUPATH%\qemu-system-i386.exe" -kernel mykernel.elf
) else (
    echo QEMU not found at %QEMUPATH%
)

endlocal