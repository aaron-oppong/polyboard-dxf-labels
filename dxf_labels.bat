@echo off

set report=pp_report
set user_prefs=user_prefs.bat

cd /d "%~dp0"

if not "%1" == "" (
    call %user_prefs%
    goto %1
)

title Setup . . .

set python=%localappdata%\Programs\Python\Python313\python.exe
set pip=%localappdata%\Programs\Python\Python313\Scripts\pip.exe
set url=https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe

if not exist %user_prefs% (
    echo set python=%python%>%user_prefs%
    echo set label_height=0.0000>>%user_prefs%
    echo set label_offset=0.0000>>%user_prefs%
    echo set stroke_width=0.0000>>%user_prefs%
)

set shortcut=shortcut.vbs
echo Set shortcut = WScript.CreateObject("WScript.Shell").CreateShortcut("%~dp0..\1. Labels....lnk")>%shortcut%
echo shortcut.TargetPath = "%~dp0dxf_labels.bat">>%shortcut%
echo shortcut.Arguments = "-labels">>%shortcut%
echo shortcut.Save>>%shortcut%

cscript %shortcut% >nul

echo Set shortcut = WScript.CreateObject("WScript.Shell").CreateShortcut("%~dp0..\2. Options....lnk")>%shortcut%
echo shortcut.TargetPath = "%~dp0dxf_labels.bat">>%shortcut%
echo shortcut.Arguments = "-prefs">>%shortcut%
echo shortcut.Save>>%shortcut%

cscript %shortcut% >nul

del /q %shortcut%

attrib +h "%cd%"

set installer=python_installer.exe

if not exist %python% (
    echo Downloading python . . .
    curl -# -o %installer% %url%
    echo.
    echo Starting installer . . .
    %installer% /passive PrependPath=1
    echo.
    echo Installation complete.
    del /q %installer%
    echo.
)

%pip% install ezdxf shapely
timeout /t 1 >nul

set reg_file=pp_report_file.reg
echo Windows Registry Editor Version 5.00>%reg_file%
echo.>>%reg_file%
echo [HKEY_CURRENT_USER\SOFTWARE\Boole ^& Partners\PolyBoard 7\Cutting List]>>%reg_file%
echo "Flags"=dword:00000402>>%reg_file%
echo.>>%reg_file%
echo [HKEY_CURRENT_USER\SOFTWARE\Boole ^& Partners\PolyBoard 7\Export]>>%reg_file%
echo "CvtEpsilon"=hex:9a,99,99,99,99,99,a9,3f>>%reg_file%
echo "ReportFilename"="%report%.txt">>%reg_file%
echo "ReportFormat"="\"^<f^>\":{\"number\":\"^<num^>\", \"cabinet\":\"^<c^>\", \"project\":\"^<p^>\"}">>%reg_file%

echo.
echo Adding registration entries . . .
reg import %reg_file%
del /q %reg_file%
timeout /t 1 >nul

goto end

:-prefs
title Options . . .

setlocal enabledelayedexpansion

echo set python=%python%>%user_prefs%

echo Current . . .
echo Label Height: %label_height%
echo Label Offset: %label_offset%
echo Stroke Width: %stroke_width%
echo Tool Diameter: %tool_diameter%
echo Tool Clearance: %tool_clearance%
echo Minimum Extrusion: %min_extrusion%

echo.
echo Press Enter to skip.
echo.
echo New . . .
goto prefs_begin

:prefs_input
set current=!%1!
set /p "%1=%~2: "
%python% -c "print(f'{abs(eval('!%1!')):.4f}')">input.txt 2>nul
if errorlevel 1 (
    echo %current%>input.txt
)
set /p %1=<input.txt
echo set %1=!%1!>>%user_prefs%
exit /b

:prefs_begin
call :prefs_input label_height "Label Height"
call :prefs_input label_offset "Label Offset"
call :prefs_input stroke_width "Stroke Width"

del /q input.txt

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
    goto labels_auto
)

:labels_input
echo Input folder path . . .
set /p folder=
cd /d "%folder%"
if errorlevel 1 (
    cls
    goto labels_input
)
if not exist "%report%" (
    goto end
)
goto labels_begin

:labels_auto
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

:labels_begin
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

%python% "%~dp0dxf_labels.py" "%cd%" %dxf_list% %report_log% %label_height% %label_offset% %stroke_width%
if errorlevel 1 (
    pause >nul
    exit /b
)

del /s /q "*%report%" %dxf_list% %report_log% >nul

if exist %queue% (
    goto labels_auto
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
