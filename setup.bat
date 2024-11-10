@echo off
title %~nx0

set python=%localappdata%\Programs\Python\Python313\python.exe
set pip=%localappdata%\Programs\Python\Python313\Scripts\pip.exe
set url=https://www.python.org/ftp/python/3.13.0/python-3.13.0-amd64.exe

cd /d "%~dp0"

set user_prefs=user_prefs.bat
if not exist %user_prefs% (
    echo set python=%python%>%user_prefs%
    echo set label_height=0.0000>>%user_prefs%
    echo set label_offset=0.0000>>%user_prefs%
    echo set stroke_width=0.0000>>%user_prefs%
)

echo Set shortcut = WScript.CreateObject("WScript.Shell").CreateShortcut("%~dp0..\1. Labels....lnk")>create_shortcut.vbs
echo shortcut.TargetPath = "%~dp0dxf_labels.bat">>create_shortcut.vbs
echo shortcut.Save>>create_shortcut.vbs

cscript create_shortcut.vbs >nul

echo Set shortcut = WScript.CreateObject("WScript.Shell").CreateShortcut("%~dp0..\2. Options....lnk")>create_shortcut.vbs
echo shortcut.TargetPath = "%~dp0prefs.bat">>create_shortcut.vbs
echo shortcut.Save>>create_shortcut.vbs

cscript create_shortcut.vbs >nul

del /q create_shortcut.vbs

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

echo.
echo Adding registration entries . . .
reg import pp_report_file.reg
timeout /t 1 >nul

echo.
echo Done.
echo.
echo Created by Aaron Oppong
set github=https://github.com/aaron-oppong
echo %github%
timeout /t 5 >nul
start %github%
