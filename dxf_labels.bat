@echo off
title %~nx0

set report=pp_report.txt

set queue="%~dp0queue.txt"
set new_queue="%~dp0new_queue.txt"
call "%~dp0user_prefs.bat"

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

%python% "%~dp0dxf_labels.py" "%cd%" %dxf_list% %report_log% %label_height% %label_offset% %stroke_width%
if errorlevel 1 (
    pause >nul
    exit /b
)

del /s /q "*%report%" %dxf_list% %report_log% >nul

if exist %queue% (
    goto auto
)

:end
echo %cd%|clip
echo.
echo Done.
echo.
echo Created by Aaron Oppong
echo https://github.com/aaron-oppong
timeout /t 15 >nul
