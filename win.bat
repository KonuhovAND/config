@echo off
setlocal EnableExtensions
title Lightweight setup (no games)

echo ==========================================
echo   Lightweight Windows + Debian WSL setup
echo ==========================================
echo.

:: ---- WinGet check ----
where winget >nul 2>&1
if errorlevel 1 (
    echo ERROR: WinGet is not installed or unavailable.
    start "" "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
    pause
    exit /b 1
)

:: ---- Admin elevation ----
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Updating WinGet sources...
winget source update

echo.
echo [1/6] Removing games...
winget uninstall -e --id Valve.Steam
winget uninstall -e --id PrismLauncher.PrismLauncher
winget uninstall -e --id Roblox.Roblox
winget uninstall Roblox
echo Note: Steam game libraries (steamapps folders) are NOT deleted automatically.

echo.
echo [2/6] Installing apps...
winget install -e --id Hibbiki.Chromium --accept-package-agreements --accept-source-agreements
winget install -e --id Happ.Happ --accept-package-agreements --accept-source-agreements
winget install -e --id Telegram.TelegramDesktop --accept-package-agreements --accept-source-agreements
winget install -e --id Zettlr.Zettlr --accept-package-agreements --accept-source-agreements

echo.
echo [3/6] Running Chris Titus Tech WinUtil...
echo (Close the WinUtil window when you are done to continue)
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://christitus.com/win' | iex"

echo.
echo [4/6] Debian WSL...
wsl --status >nul 2>&1
if errorlevel 1 (
    echo WSL is not enabled yet. Installing base WSL...
    wsl --install --no-distribution
    echo.
    echo *** A REBOOT IS REQUIRED. After reboot, run this script again. ***
    pause
    exit /b 0
)
wsl --install -d Debian --no-launch
echo.
echo A Debian terminal will now open.
echo Create your Linux username + password, then type: exit
echo (to return to this installer)
wsl -d Debian

echo.
echo [5/6] Running Debian dev setup (nvim, lazygit, lazysql, tmux, zsh, uv, node, python)...
if not exist "%~dp0debian-setup.sh" (
    echo ERROR: debian-setup.sh was not found next to this script!
    pause
    exit /b 1
)
copy /y "%~dp0debian-setup.sh" "%SystemDrive%\debian-setup.sh" >nul

set "WSLUSER="
for /f "delims=" %%u in ('wsl -d Debian --exec whoami') do set "WSLUSER=%%u"
if not defined WSLUSER set "WSLUSER=root"

wsl -d Debian -u root --exec bash -c "sed -i 's/\r$//' /mnt/c/debian-setup.sh && bash /mnt/c/debian-setup.sh %WSLUSER%"

del /q "%SystemDrive%\debian-setup.sh" >nul 2>&1

echo.
echo ==========================================
echo [6/6] Done!
echo   - Open Debian: type "wsl" in terminal
echo   - Default shell is zsh, editor is nvim (LazyVim)
echo   - Happ needs your own subscription/config link
echo ==========================================
pause
exit /b