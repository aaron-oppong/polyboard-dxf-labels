@echo off
title %~nx0

set choice="%systemroot%\System32\choice.exe"
set clip="%systemroot%\System32\clip.exe"
set findstr="%systemroot%\System32\findstr.exe"
set timeout="%systemroot%\System32\timeout.exe"

set user_prefs="%~dp0user_prefs.bat"
set new_queue="%~dp0new_queue.txt"
set queue="%~dp0queue.txt"

set report=pp_report

cd /d "%~dp0..\"

if exist %queue% (
    del /q %queue%
)
for /r %%T in ("%report%.txt") do (
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
set /p path=
cd /d "%path%"
if errorlevel 1 (
    cls
    goto input
)
if not exist "%report%.txt" (
    goto end
)
goto begin

:auto
set /p path=<%queue%
cd /d "%path%"

if not exist "%report%.txt" (
    del /q %queue%
    goto end
)

%findstr% /v /c:"%cd%" %queue% >%new_queue%
move /y %new_queue% %queue% >nul

if "%path%" == "%queue_0%" (
    echo Folder path . . .
    echo "%cd%"
) else (
    echo.
    echo Folder path . . .
    echo "%cd%"
    %timeout% /t 5 /nobreak >nul
)

:begin
set dxf_list="%~dp0dxf_list.csv"
type nul >%dxf_list%

for /r %%D in ("*.dxf") do (
    echo %%~D,%%~dpD,%%~nxD>>%dxf_list%
)

set report_log="%~dp0report_log.txt"
type nul >%report_log%

for /r %%T in ("*_%report%.txt") do (
    echo %%~dpnT>>%report_log%
)

call %user_prefs%

%python% "%~dp0dxf_labels.py" "%cd%" %dxf_list% %report_log% %label_height% %label_offset% %stroke_width%

del /s /q "*.bat" "*%report%.txt" %dxf_list% %report_log% >nul

if exist %queue% (
    goto auto
)

:end
echo %cd%|%clip%
echo.
echo Done.
echo.
echo Created by Aaron Oppong
echo https://github.com/aaron-oppong
%timeout% /t 15 >nul
