@echo off
title %~nx0

cd /d "%~dp0"

set user_prefs=user_prefs.bat
call %user_prefs%
echo set python=%python%>%user_prefs%

echo Current . . .
echo Label Height: %label_height%
echo Label Offset: %label_offset%

echo.
echo Press Enter to skip.
echo.
echo New . . .

set /p label_height=Label Height: 
%python% -c "print(f'{abs(eval('%label_height%')):.4f}')">input.txt 2>nul
if errorlevel 1 (
    echo 0.0000>input.txt
) 
set /p label_height=<input.txt
echo set label_height=%label_height%>>%user_prefs%

set /p label_offset=Label Offset: 
%python% -c "print(f'{abs(eval('%label_offset%')):.4f}')">input.txt 2>nul
if errorlevel 1 (
    echo 0.0000>input.txt
) 
set /p label_offset=<input.txt
echo set label_offset=%label_offset%>>%user_prefs%

del /q input.txt

echo.
echo Saved.
echo.
echo Created by Aaron Oppong
echo https://github.com/aaron-oppong
timeout /t 5 >nul