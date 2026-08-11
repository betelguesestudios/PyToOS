@echo off
setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
set "PLUGS_DIR=%ROOT_DIR%plugs"
set "PREQ_DIR=%PLUGS_DIR%\preq"
set "OUTPUT_FILE=%ROOT_DIR%kernel.c"

if exist "%OUTPUT_FILE%" del /f "%OUTPUT_FILE%"

echo // PyToC generated file > "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

if not exist "%ROOT_DIR%main.py" (
    echo Error: main.py not found!
    exit /b 1
)

set "PLUGS_TO_PROCESS="
for /f "usebackq tokens=*" %%a in ("%ROOT_DIR%main.py") do (
    set "line=%%a"
    for /f "tokens=* delims= " %%b in ("!line!") do set "line=%%b"
    for /f "tokens=1 delims=#" %%b in ("!line!") do set "line=%%b"
    set "line=!line: =!"
    if not "!line!"=="" (
        if not "!line:~0,1!"=="#" (
            for /f "tokens=1 delims=(" %%b in ("!line!") do (
                if exist "%PLUGS_DIR%\%%b.plgs" (
                    echo !PLUGS_TO_PROCESS! | find " %%b " >nul
                    if errorlevel 1 (
                        set "PLUGS_TO_PROCESS=!PLUGS_TO_PROCESS! %%b "
                    )
                )
            )
        )
    )
)
echo !PLUGS_TO_PROCESS! | find " cls " >nul
if errorlevel 1 (
    if exist "%PLUGS_DIR%\cls.plgs" (
        set "PLUGS_TO_PROCESS= cls !PLUGS_TO_PROCESS!"
    )
)

set "ALL_PREQS="
for %%p in (%PLUGS_TO_PROCESS%) do (
    call :GetPreqs "%%p"
)

for %%p in (%ALL_PREQS%) do (
    set "preqfile=%PREQ_DIR%\%%p.preq"
    if exist "!preqfile!" (
        echo // Including preq: %%p.preq >> "%OUTPUT_FILE%"
        type "!preqfile!" >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
    )
)

echo // actual stuff >> "%OUTPUT_FILE%"
for %%p in (%PLUGS_TO_PROCESS%) do (
    echo void %%p(const char* args^); >> "%OUTPUT_FILE%"
)
echo. >> "%OUTPUT_FILE%"

echo void kernel_main() { >> "%OUTPUT_FILE%"
echo     cls(""); >> "%OUTPUT_FILE%"

for /f "usebackq tokens=*" %%a in ("%ROOT_DIR%main.py") do (
    set "line=%%a"
    for /f "tokens=* delims= " %%b in ("!line!") do set "line=%%b"
    for /f "tokens=1 delims=#" %%b in ("!line!") do set "line=%%b"
    if not "!line!"=="" (
        set "firstchar=!line:~0,1!"
        if not "!firstchar!"=="#" (
            set "outline=!line!"
            for /f "tokens=*" %%c in ("!outline!") do set "outline=%%c"
            for /f "tokens=1 delims=(" %%d in ("!outline!") do (
                set "funcname=%%d"
                set "funcname=!funcname: =!"
                
                if "!funcname!"=="print" (
                    if exist "%PLUGS_DIR%\print.plgs" (
                        set "content=!outline!"
                        set "content=!content:*print(=!"
                        set "content=!content:~0,-1!"
                        
                        echo !content! | findstr /c:"\r" >nul
                        if not errorlevel 1 (
                            set "content=!content:\r=!"
                            set "outline=print_string(!content!)"
                        ) else (
                            set "content=!content:"=###QUOTE###!"
                            set "content=!content:###QUOTE###="!
                            set "outline=print_string(!content!\n"^)"
                        )
                    )
                )
                set "testline=!outline: =!"
                if "!testline!"=="!funcname!()" (
                    if exist "%PLUGS_DIR%\!funcname!.plgs" (
                        set "outline=!funcname!("""")"
                    )
                )
            )
            set "lastchar=!outline:~-1!"
            if not "!lastchar!"==";" (
                if not "!lastchar!"=="{" (
                    if not "!lastchar!"=="}" (
                        set "outline=!outline!;"
                    )
                )
            )
            
            echo     !outline! >> "%OUTPUT_FILE%"
        )
    )
)

echo } >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

for %%p in (%PLUGS_TO_PROCESS%) do (
    call :WriteFunction "%%p"
)
echo Success!
type "%OUTPUT_FILE%"
pause
exit /b 0

:GetPreqs
set "plug=%~1"
set "plugfile=%PLUGS_DIR%\%plug%.plgs"
if not exist "%plugfile%" exit /b

for /f "usebackq tokens=*" %%a in ("%plugfile%") do (
    set "line=%%a"
    echo !line! | findstr /c:"req:" >nul
    if not errorlevel 1 (
        for /f "tokens=1,* delims=:" %%x in ("!line!") do (
            set "reqpart=%%y"
            set "reqpart=!reqpart:preq/=!"
            set "reqpart=!reqpart:.preq=!"
            set "reqpart=!reqpart: =!"
            
            if not "!reqpart!"=="" (
                echo !ALL_PREQS! | find " !reqpart! " >nul
                if errorlevel 1 (
                    set "ALL_PREQS=!ALL_PREQS! !reqpart! "
                    call :GetPreqs "!reqpart!"
                )
            )
        )
    )
)
exit /b

:WriteFunction
set "plug=%~1"
set "plugfile=%PLUGS_DIR%\%plug%.plgs"
if not exist "%plugfile%" exit /b

set "python_code="
set "inside_py=0"

for /f "usebackq tokens=*" %%a in ("%plugfile%") do (
    set "line=%%a"
    
    echo !line! | findstr /c:"py:" >nul
    if not errorlevel 1 (
        set "inside_py=1"
        set "code=!line:*py:=!"
        if not "!code!"=="" (
            set "python_code=!code!"
        )
    ) else if "!inside_py!"=="1" (
        if not "!line!"=="" (
            set "code=!line!"
            if defined python_code (
                set "python_code=!python_code! !code!"
            ) else (
                set "python_code=!code!"
            )
        )
    )
)

set "python_code=!python_code:"args"=args!"

if defined python_code (
    echo // plugs for %plug% >> "%OUTPUT_FILE%"
    echo void %plug%(const char* args^) { >> "%OUTPUT_FILE%"
    echo     !python_code!; >> "%OUTPUT_FILE%"
    echo } >> "%OUTPUT_FILE%"
    echo. >> "%OUTPUT_FILE%"
)
exit /b