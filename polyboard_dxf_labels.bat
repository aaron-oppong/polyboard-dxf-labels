@echo off

set report=pp_report.txt
set user_prefs="%~dp0user_prefs.json"

if not "%1" == "" (
    goto %1
)

title Setup . . .

cd /d "%~dp0"

set installer=python_installer.exe
set version=3.13.1

py -V >nul 2>nul
if not %errorlevel% == 0 (
    echo Downloading python . . .
    curl -# -o %installer% https://www.python.org/ftp/python/%version%/python-%version%-amd64.exe
    echo.
    echo Starting installer . . .
    %installer% /passive PrependPath=1
    del /q %installer%
    echo Installation complete.
    echo.
    "%windir%\py.exe" -m pip install ezdxf shapely
    exit /b
) else (
    py -m pip install ezdxf shapely
)
timeout /t 1 >nul

if not exist %user_prefs% (
    echo {}>%user_prefs%
)

set shortcut=shortcut.vbs
echo Set shortcut = WScript.CreateObject("WScript.Shell").CreateShortcut("%~dp0..\1. Labels....lnk")>%shortcut%
echo shortcut.TargetPath = "%~f0">>%shortcut%
echo shortcut.Arguments = "-labels">>%shortcut%
echo shortcut.WorkingDirectory = "%~dp0">>%shortcut%
echo shortcut.Save>>%shortcut%

cscript %shortcut% >nul

echo Set shortcut = WScript.CreateObject("WScript.Shell").CreateShortcut("%~dp0..\2. Options....lnk")>%shortcut%
echo shortcut.TargetPath = "%~f0">>%shortcut%
echo shortcut.Arguments = "-prefs">>%shortcut%
echo shortcut.WorkingDirectory = "%~dp0">>%shortcut%
echo shortcut.Save>>%shortcut%

cscript %shortcut% >nul

del /q %shortcut%

attrib +h "%cd%"

echo.
echo Adding registration entries . . .

set reg_file=pp_report_file.reg
echo Windows Registry Editor Version 5.00>%reg_file%
echo.>>%reg_file%
echo [HKEY_CURRENT_USER\SOFTWARE\Boole ^& Partners\PolyBoard 7\Cutting List]>>%reg_file%
echo "Flags"=dword:00000402>>%reg_file%
echo.>>%reg_file%
echo [HKEY_CURRENT_USER\SOFTWARE\Boole ^& Partners\PolyBoard 7\Export]>>%reg_file%
echo "CvtEpsilon"=hex:9a,99,99,99,99,99,a9,3f>>%reg_file%
echo "ReportFilename"="%report%">>%reg_file%
echo "ReportFormat"="\"^<f^>\":{\"number\":\"^<num^>\", \"cabinet\":\"^<c^>\", \"project\":\"^<p^>\"}">>%reg_file%

reg import %reg_file%
del /q %reg_file%
timeout /t 1 >nul

goto end

:-prefs
title Options . . .

py "%~dpn0%1.py"

goto end

:-labels
title Labels . . .

set queue="%~dp0queue.txt"
set new_queue="%~dp0new_queue.txt"

cd /d "%~dp0..\"

if exist %queue% (
    del /q %queue%
)
for /r %%T in ("%report%") do (
    if exist %%T (
        echo %%~dpT>>%queue%
    )
)
if exist %queue% (
    set /p queue_0=<%queue%
    goto auto
)

:input
echo Input folder path . . .
set /p folder=
cd /d "%folder%"
if errorlevel 1 (
    cls
    goto input
)
if not exist "%report%" (
    goto end
)
goto begin

:auto
set /p folder=<%queue%
cd /d "%folder%"

if not exist "%report%" (
    del /q %queue%
    goto end
)

more +1 %queue% >%new_queue%
move /y %new_queue% %queue% >nul

if "%folder%" == "%queue_0%" (
    echo Folder path . . .
    echo "%cd%"
) else (
    echo.
    echo Folder path . . .
    echo "%cd%"
    timeout /t 5 /nobreak >nul
)

:begin
set dxf_list="%~dp0dxf_list.csv"
type nul >%dxf_list%

for /r %%D in ("*.dxf") do (
    echo %%~D,%%~dpD,%%~nxD>>%dxf_list%
)

set report_log="%~dp0report_log.txt"
type nul >%report_log%

for /r %%T in ("*_%report%") do (
    echo %%~dpnT>>%report_log%
)

py "%~dpn0.py" %user_prefs% "%cd%" %dxf_list% %report_log%
if errorlevel 1 (
    pause >nul
    exit /b
)

del /s /q "*%report%" %dxf_list% %report_log% >nul

if exist %queue% (
    goto auto
)

:end
echo.
if "%1" == "-prefs" (
    echo Saved.
) else (
    echo Done.
)
echo.
echo Created by Aaron Oppong
set github=https://github.com/aaron-oppong
echo %github%
if "%1" == "-labels" (
    echo %cd%|clip
    timeout /t 15 >nul
) else (
    timeout /t 5 >nul
)
if "%1" == "" (
    start %github%
)
