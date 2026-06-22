@echo off
REM ============================================================
REM  Streak Tracker - One-Click Installer (FINAL)
REM  Double-click this file. It does everything.
REM  If something fails, it shows the error and tries to fix it.
REM ============================================================

setlocal enabledelayedexpansion
title Streak Tracker - Installer
cd /d "%~dp0"

echo.
echo ============================================
echo   Streak Tracker - Installer
echo ============================================
echo.
echo This installs Streak Tracker. Takes 2-3 minutes.
echo Just wait - do not close this window.
echo.
echo Press any key to start, or close this window to cancel.
pause >nul

set "PYDIR=%LOCALAPPDATA%\Programs\Python\Python312"
set "APPDIR=%LOCALAPPDATA%\StreakTracker"
set "PYEXE=%PYDIR%\python.exe"
set "PYWEXE=%PYDIR%\pythonw.exe"
set "INSTALLER=%TEMP%\python-3.12.3-amd64.exe"

echo.
echo [1/8] Downloading Python 3.12 installer...
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe' -OutFile '%INSTALLER%' } catch { exit 1 }"
if not exist "%INSTALLER%" (
    echo   FAILED to download Python. Check your internet.
    pause
    exit /b 1
)
echo   OK

echo.
echo [2/8] Installing Python 3.12 with ALL features (tkinter included)...
echo   This takes about 1 minute. Please wait...
"%INSTALLER%" /quiet InstallAllUsers=0 PrependPath=0 Include_tcltk=1 Include_pip=1 InstallLauncherAllUsers=0 TargetDir="%PYDIR%"
REM Wait for installer to finish (check every 2 seconds if python.exe exists)
set /p=Waiting for Python install...<nul
:wait_python
if exist "%PYEXE%" goto :python_done
timeout /t 2 >nul
set /p=.<nul
goto :wait_python
:python_done
echo  OK
if not exist "%PYWEXE%" (
    echo   FAILED: pythonw.exe not found at %PYDIR%
    echo   Trying repair install with default options...
    "%INSTALLER%" /quiet InstallAllUsers=0 PrependPath=0 Include_tcltk=1
    timeout /t 15 >nul
)
if not exist "%PYWEXE%" (
    echo.
    echo ============================================
    echo   ERROR: Python install failed.
    echo ============================================
    echo Please install Python 3.12 manually from:
    echo   https://www.python.org/downloads/
    echo Make sure to CHECK "Add Python to PATH".
    echo Then re-run this installer.
    pause
    exit /b 1
)
echo   Python installed at: %PYDIR%

echo.
echo [3/8] Testing tkinter...
"%PYEXE%" -c "import tkinter; root = tkinter.Tk(); root.destroy(); print('tkinter', tkinter.TkVersion, 'OK')" 2>nul
if errorlevel 1 (
    echo   Initial test failed. Trying to repair Python...
    "%INSTALLER%" /quiet InstallAllUsers=0 PrependPath=0 Include_tcltk=1 Include_pip=1 Include_lib=1 Include_extensions=1 InstallLauncherAllUsers=0 TargetDir="%PYDIR%" SimpleInstall=0
    timeout /t 20 >nul
    echo   Retesting tkinter...
    "%PYEXE%" -c "import tkinter; root = tkinter.Tk(); root.destroy(); print('tkinter', tkinter.TkVersion, 'OK')" 2>nul
    if errorlevel 1 (
        echo.
        echo ============================================
        echo   ERROR: tkinter still not working.
        echo ============================================
        echo Detailed error:
        "%PYEXE%" -c "import tkinter"
        echo.
        echo Manual fix attempt - searching for tcl DLLs...
        if not exist "%PYDIR%\DLLs" mkdir "%PYDIR%\DLLs"
        for /r "%PYDIR%" %%f in (tcl86t.dll) do copy /Y "%%f" "%PYDIR%\DLLs\" >nul 2>&1
        for /r "%PYDIR%" %%f in (tk86t.dll) do copy /Y "%%f" "%PYDIR%\DLLs\" >nul 2>&1
        for /r "%PYDIR%" %%f in (_tkinter.pyd) do copy /Y "%%f" "%PYDIR%\DLLs\" >nul 2>&1
        echo   Retesting after manual fix...
        "%PYEXE%" -c "import tkinter; root = tkinter.Tk(); root.destroy(); print('tkinter', tkinter.TkVersion, 'OK')"
        if errorlevel 1 (
            echo.
            echo FAILED. Please report this error:
            "%PYEXE%" -c "import _tkinter"
            pause
            exit /b 1
        )
    )
)
echo   tkinter works!

echo.
echo [4/8] Installing pip and dependencies...
"%PYEXE%" -m pip install --upgrade pip --quiet 2>nul
"%PYEXE%" -m pip install pystray Pillow pyttsx3 win11toast --quiet 2>&1 | findstr /v "already.satisfied.WARNING"
"%PYEXE%" -c "import pystray; import PIL; import pyttsx3; import win11toast; print('deps OK')"
if errorlevel 1 (
    echo   FAILED to install dependencies.
    echo   Trying with verbose output:
    "%PYEXE%" -m pip install pystray Pillow pyttsx3 win11toast
    if errorlevel 1 (
        pause
        exit /b 1
    )
)
echo   OK

echo.
echo [5/8] Creating app folder and downloading app...
REM Kill any running instances first so we can wipe the folder
taskkill /FI "IMAGENAME eq pythonw.exe" /F >nul 2>&1
taskkill /FI "IMAGENAME eq python.exe" /F >nul 2>&1
timeout /t 1 >nul
REM IMPORTANT: wipe the folder first to remove any broken files from previous installs
if exist "%APPDIR%" rmdir /S /Q "%APPDIR%"
mkdir "%APPDIR%"
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://paste.rs/ILgQw' -OutFile '%APPDIR%\streak_tracker.pyw' } catch { exit 1 }"
if not exist "%APPDIR%\streak_tracker.pyw" (
    echo   FAILED to download app. Check your internet.
    pause
    exit /b 1
)
echo   OK

echo.
echo [6/8] Final test - launching app to confirm it works...
start "" "%PYWEXE%" "%APPDIR%\streak_tracker.pyw"
echo   Waiting 4 seconds for app to start...
timeout /t 4 >nul
tasklist /FI "IMAGENAME eq pythonw.exe" 2>nul | findstr /i pythonw >nul
if errorlevel 1 (
    echo   App did not start. Running with console to see error...
    "%PYEXE%" "%APPDIR%\streak_tracker.pyw"
    echo.
    echo Exit code: !ERRORLEVEL!
    echo.
    echo If you see an error above, please copy and report it.
    pause
    exit /b 1
)
echo   App is running!
taskkill /FI "IMAGENAME eq pythonw.exe" /F >nul 2>&1
timeout /t 1 >nul

echo.
echo [7/8] Creating launcher and shortcuts...

REM Create launcher .bat
(
    echo @echo off
    echo start "" "%PYWEXE%" "%APPDIR%\streak_tracker.pyw"
) > "%APPDIR%\StreakTracker.bat"

REM Desktop shortcut
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $desktop = [Environment]::GetFolderPath('Desktop'); $s = $ws.CreateShortcut(\"$desktop\Streak Tracker.lnk\"); $s.TargetPath = '%APPDIR%\StreakTracker.bat'; $s.WorkingDirectory = '%APPDIR%'; $s.Description = 'Streak Tracker'; $s.WindowStyle = 7; $s.IconLocation = '%PYWEXE%,0'; $s.Save()"

REM Start Menu shortcut
powershell -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $startdir = \"$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Streak Tracker\"; New-Item -ItemType Directory -Force -Path $startdir | Out-Null; $s = $ws.CreateShortcut(\"$startdir\Streak Tracker.lnk\"); $s.TargetPath = '%APPDIR%\StreakTracker.bat'; $s.WorkingDirectory = '%APPDIR%'; $s.Description = 'Streak Tracker'; $s.WindowStyle = 7; $s.IconLocation = '%PYWEXE%,0'; $s.Save()"

REM Autostart
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "Streak Tracker" /t REG_SZ /d "\"%APPDIR%\StreakTracker.bat\"" /f >nul

echo   OK

echo.
echo [8/8] Launching Streak Tracker...
start "" "%APPDIR%\StreakTracker.bat"

echo.
echo ============================================
echo   SUCCESS! Streak Tracker installed.
echo ============================================
echo.
echo  Python:        %PYDIR%
echo  App folder:    %APPDIR%
echo  Data file:     %APPDATA%\StreakTracker\data.json
echo  Desktop icon:  Streak Tracker
echo  Start menu:    Streak Tracker
echo  Auto-start:    ENABLED
echo.
echo  The app is now running. Look for the flame icon
echo  in your system tray (bottom-right of screen).
echo.
echo  If you don't see it, click the ^ arrow to show
echo  hidden icons. Click the flame -^> Open.
echo.
pause
