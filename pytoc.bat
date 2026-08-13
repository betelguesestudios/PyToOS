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

:: Check if variable operations are needed
set "NEEDS_VARS=0"
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
            )
        )
    )
)

:: Add vars plugin if needed
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

if "!NEEDS_VARS!"=="1" (
    echo     init_vars^(^); >> "%OUTPUT_FILE%"
)

for /f "usebackq tokens=*" %%a in ("%ROOT_DIR%main.py") do (
    set "line=%%a"
    
    :: Skip empty lines
    if not "!line!"=="" (
        :: Skip # comments
        set "firstchar=!line:~0,1!"
        if not "!firstchar!"=="#" (
            :: Skip // comments
            set "secondchar=!line:~0,2!"
            if not "!secondchar!"=="//" (
                :: Remove leading spaces
                for /f "tokens=*" %%c in ("!line!") do set "line=%%c"
                
                :: Remove inline // comments
                for /f "tokens=1 delims=/" %%c in ("!line!") do set "line=%%c"
                
                set "outline=!line!"
                
                :: Simple variable assignment detection
                echo !outline! | findstr /c:"=" >nul
                if not errorlevel 1 (
                    echo !outline! | findstr /c:"==" >nul
                    if errorlevel 1 (
                        echo !outline! | findstr /c:"(" >nul
                        if errorlevel 1 (
                            :: Simple assignment without function call
                            for /f "tokens=1,* delims==" %%v in ("!outline!") do (
                                set "varname=%%v"
                                set "varvalue=%%w"
                                set "varname=!varname: =!"
                                set "varvalue=!varvalue: =!"
                                set "outline=set_var("!varname!", !varvalue!);"
                            )
                        ) else (
                            :: Assignment with function call
                            for /f "tokens=1,* delims==" %%v in ("!outline!") do (
                                set "varname=%%v"
                                set "varexpr=%%w"
                                set "varname=!varname: =!"
                                set "varexpr=!varexpr: =!"
                                
                                :: Extract function name
                                for /f "tokens=1 delims=(" %%f in ("!varexpr!") do (
                                    set "funcname=%%f"
                                    
                                    if "!funcname!"=="add" (
                                        set "args=!varexpr:*add(=!"
                                        set "args=!args:)=!"
                                        for /f "tokens=1,* delims=," %%x in ("!args!") do (
                                            set "arg1=%%x"
                                            set "arg2=%%y"
                                            set "arg1=!arg1: =!"
                                            set "arg2=!arg2: =!"
                                            set "outline=set_var("!varname!", add_int(get_var("!arg1!"), get_var("!arg2!")));"
                                        )
                                    ) else if "!funcname!"=="sub" (
                                        set "args=!varexpr:*sub(=!"
                                        set "args=!args:)=!"
                                        for /f "tokens=1,* delims=," %%x in ("!args!") do (
                                            set "arg1=%%x"
                                            set "arg2=%%y"
                                            set "arg1=!arg1: =!"
                                            set "arg2=!arg2: =!"
                                            set "outline=set_var("!varname!", sub_int(get_var("!arg1!"), get_var("!arg2!")));"
                                        )
                                    ) else if "!funcname!"=="mul" (
                                        set "args=!varexpr:*mul(=!"
                                        set "args=!args:)=!"
                                        for /f "tokens=1,* delims=," %%x in ("!args!") do (
                                            set "arg1=%%x"
                                            set "arg2=%%y"
                                            set "arg1=!arg1: =!"
                                            set "arg2=!arg2: =!"
                                            set "outline=set_var("!varname!", mul_int(get_var("!arg1!"), get_var("!arg2!")));"
                                        )
                                    ) else if "!funcname!"=="divide" (
                                        set "args=!varexpr:*divide(=!"
                                        set "args=!args:)=!"
                                        for /f "tokens=1,* delims=," %%x in ("!args!") do (
                                            set "arg1=%%x"
                                            set "arg2=%%y"
                                            set "arg1=!arg1: =!"
                                            set "arg2=!arg2: =!"
                                            set "outline=set_var("!varname!", div_int(get_var("!arg1!"), get_var("!arg2!")));"
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
                
                :: Handle printvar
                echo !outline! | findstr /c:"printvar" >nul
                if not errorlevel 1 (
                    set "content=!outline!"
                    set "content=!content:*printvar(=!"
                    set "content=!content:~0,-1!"
                    set "content=!content: =!"
                    set "outline=print_int(get_var("!content!"));"
                    set "outline=!outline! print_char('^\n');"
                )
                
                :: Handle print
                echo !outline! | findstr /c:"print(" >nul
                if not errorlevel 1 (
                    set "content=!outline!"
                    set "content=!content:*print(=!"
                    set "content=!content:~0,-1!"
                    
                    :: Check if content is a variable name
                    set "testcontent=!content!"
                    set "testcontent=!testcontent:"=!"
                    echo !testcontent! | findstr /r /c:"^[a-zA-Z_][a-zA-Z0-9_]*$" >nul
                    if not errorlevel 1 (
                        set "outline=print_int(get_var("!content!"));"
                        set "outline=!outline! print_char('^\n');"
                    ) else (
                        set "content=!content:"=###QUOTE###!"
                        set "content=!content:###QUOTE###="!
                        set "outline=print_string(!content!\n"^)"
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

if defined python_code (
    echo // plugs for %plug% >> "%OUTPUT_FILE%"
    echo void %plug%(const char* args^) { >> "%OUTPUT_FILE%"
    echo     !python_code!; >> "%OUTPUT_FILE%"
    echo } >> "%OUTPUT_FILE%"
    echo. >> "%OUTPUT_FILE%"
)
exit /b