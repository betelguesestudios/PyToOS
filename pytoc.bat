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
            if not "!line:~0,2!"=="//" (
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
)
echo !PLUGS_TO_PROCESS! | find " cls " >nul
if errorlevel 1 (
    if exist "%PLUGS_DIR%\cls.plgs" (
        set "PLUGS_TO_PROCESS= cls !PLUGS_TO_PROCESS!"
    )
)

set "NEEDS_VARS=0"
set "NEEDS_INPUT=0"
for /f "usebackq tokens=*" %%a in ("%ROOT_DIR%main.py") do (
    set "line=%%a"
    for /f "tokens=* delims= " %%b in ("!line!") do set "line=%%b"
    for /f "tokens=1 delims=#" %%b in ("!line!") do set "line=%%b"
    set "line=!line: =!"
    if not "!line!"=="" (
        if not "!line:~0,1!"=="#" (
            if not "!line:~0,2!"=="//" (
                echo !line! | findstr /c:"=" >nul
                if not errorlevel 1 (
                    echo !line! | findstr /c:"==" >nul
                    if errorlevel 1 (
                        set "NEEDS_VARS=1"
                    )
                )
                echo !line! | findstr /c:"input(" >nul
                if not errorlevel 1 (
                    set "NEEDS_INPUT=1"
                )
            )
        )
    )
)

if "!NEEDS_VARS!"=="1" (
    echo !PLUGS_TO_PROCESS! | find " var " >nul
    if errorlevel 1 (
        if exist "%PLUGS_DIR%\var.plgs" (
            set "PLUGS_TO_PROCESS=!PLUGS_TO_PROCESS! var "
        )
    )
    echo !PLUGS_TO_PROCESS! | find " math " >nul
    if errorlevel 1 (
        if exist "%PLUGS_DIR%\math.plgs" (
            set "PLUGS_TO_PROCESS=!PLUGS_TO_PROCESS! math "
        )
    )
)

if "!NEEDS_INPUT!"=="1" (
    echo !PLUGS_TO_PROCESS! | find " input " >nul
    if errorlevel 1 (
        if exist "%PLUGS_DIR%\input.plgs" (
            set "PLUGS_TO_PROCESS=!PLUGS_TO_PROCESS! input "
        )
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
    if "%%p"=="input" (
        echo char* %%p(const char* args^); >> "%OUTPUT_FILE%"
    ) else (
        echo void %%p(const char* args^); >> "%OUTPUT_FILE%"
    )
)
echo. >> "%OUTPUT_FILE%"

echo void kernel_main() { >> "%OUTPUT_FILE%"
echo     cls(""); >> "%OUTPUT_FILE%"

if "!NEEDS_VARS!"=="1" (
    echo     init_vars^(^); >> "%OUTPUT_FILE%"
)

if "!NEEDS_INPUT!"=="1" (
    echo     keyboard_init^(^); >> "%OUTPUT_FILE%"
)

for /f "usebackq tokens=*" %%a in ("%ROOT_DIR%main.py") do (
    set "line=%%a"
    if not "!line!"=="" (
        set "firstchar=!line:~0,1!"
        if not "!firstchar!"=="#" (
            set "secondchar=!line:~0,2!"
            if not "!secondchar!"=="//" (
                for /f "tokens=*" %%c in ("!line!") do set "line=%%c"
                
                set "outline=!line!"
                
                echo !outline! | findstr /c:"=" >nul
                if not errorlevel 1 (
                    echo !outline! | findstr /c:"==" >nul
                    if errorlevel 1 (
                        echo !outline! | findstr /c:"input(" >nul
                        if not errorlevel 1 (
                            for /f "tokens=1,* delims==" %%v in ("!outline!") do (
                                set "varname=%%v"
                                set "varname=!varname: =!"
                                set "outline=char* !varname! = input("hello"); set_var_string("!varname!", !varname!);"
                            )
                        ) else (
                            for /f "tokens=1,* delims==" %%v in ("!outline!") do (
                                set "varname=%%v"
                                set "varvalue=%%w"
                                set "varname=!varname: =!"
                                set "varvalue=!varvalue: =!"
                                
                                echo !varvalue! | findstr /c:"parse_int(" >nul
                                if not errorlevel 1 (
                                    set "outline=set_var("!varname!", !varvalue!);"
                                ) else (
                                    set "testval=!varvalue!"
                                    set "testval=!testval:"=X!"
                                    if not "!testval!"=="!varvalue!" (
                                        set "outline=set_var_string("!varname!", !varvalue!);"
                                    ) else (
                                        if "!varvalue!"=="True" (
                                            set "outline=set_var("!varname!", 1);"
                                        ) else if "!varvalue!"=="False" (
                                            set "outline=set_var("!varname!", 0);"
                                        ) else (
                                            echo !varvalue! | findstr /c:"." >nul
                                            if not errorlevel 1 (
                                                set "outline=set_var_float("!varname!", !varvalue!);"
                                            ) else (
                                                set "outline=set_var("!varname!", !varvalue!);"
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
                
                echo !outline! | findstr /c:"print(" >nul
                if not errorlevel 1 (
                    set "content=!outline!"
                    set "content=!content:*print(=!"
                    set "content=!content:~0,-1!"
                    set "content=!content: =!"
                    
                    set "c_expr=!content!"
                    
                    set "temp=!content!"
                    set "vars="
                    :loop
                    for /f "tokens=1,* delims=+ " %%x in ("!temp!") do (
                        set "var=%%x"
                        if not "!var!"=="" (
                            set "vars=!vars! !var!"
                            set "temp=%%y"
                            goto :loop
                        )
                    )
                    
                    for %%v in (!vars!) do (
                        echo !c_expr! | findstr /c:"parse_int(%%v" >nul
                        if errorlevel 1 (
                            set "c_expr=!c_expr:%%v=(float)get_var("%%v")!"
                        )
                    )
                    
                    set "outline=float temp = !c_expr!; print_float(temp); print_char('\n');"
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
            if defined python_code (
                set "python_code=!python_code! !code!"
            ) else (
                set "python_code=!code!"
            )
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

if defined python_code (
    echo // plugs for %plug% >> "%OUTPUT_FILE%"
    if "%~1"=="input" (
        echo char* %plug%(const char* args^) { >> "%OUTPUT_FILE%"
    ) else (
        echo void %plug%(const char* args^) { >> "%OUTPUT_FILE%"
    )
    echo     !python_code!; >> "%OUTPUT_FILE%"
    echo } >> "%OUTPUT_FILE%"
    echo. >> "%OUTPUT_FILE%"
)
exit /b