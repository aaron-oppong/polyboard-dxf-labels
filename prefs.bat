@echo off
title %~nx0

setlocal enabledelayedexpansion

cd /d "%~dp0"

set user_prefs=user_prefs.bat
call %user_prefs%
echo set python=%python%>%user_prefs%

echo Current . . .
echo Label Height: %label_height%
echo Label Offset: %label_offset%
echo Stroke Width: %stroke_width%

echo.
echo Press Enter to skip.
echo.
echo New . . .
goto begin

:input
set current=!%1!
set /p "%1=%~2: "
%python% -c "print(f'{abs(eval('!%1!')):.4f}')">input.txt 2>nul
if errorlevel 1 (
    echo %current%>input.txt
)
set /p %1=<input.txt
echo set %1=!%1!>>%user_prefs%
exit /b

:begin
call :input label_height "Label Height"
call :input label_offset "Label Offset"
call :input stroke_width "Stroke Width"

del /q input.txt

echo.
echo Saved.
echo.
echo Created by Aaron Oppong
echo https://github.com/aaron-oppong
timeout /t 5 >nul
