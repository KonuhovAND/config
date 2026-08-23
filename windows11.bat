@echo off
setlocal EnableExtensions
title Fresh Windows installation

echo ==========================================
echo   Fresh Windows applications installation
echo ==========================================
echo.

:: Проверка WinGet
where winget >nul 2>&1
if errorlevel 1 (
    echo ERROR: WinGet is not installed or unavailable.
    echo Install/update App Installer from Microsoft Store:
    start "" "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
    pause
    exit /b 1
)

:: Запрос прав администратора
net session >nul 2>&1
if errorlevel 1 (
    echo Requesting administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass ^
        -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Updating WinGet sources...
winget source update

echo.
echo [1/8] Installing Discord...
winget install --id Discord.Discord --exact ^
    --accept-package-agreements --accept-source-agreements

echo.
echo [2/8] Installing Chromium...
winget install --id Hibbiki.Chromium --exact ^
    --accept-package-agreements --accept-source-agreements

echo.
echo [3/8] Installing Spotify...
winget install --id Spotify.Spotify --exact ^
    --accept-package-agreements --accept-source-agreements

echo.
echo [4/8] Installing Roblox...
winget install --name Roblox --source msstore ^
    --accept-package-agreements --accept-source-agreements

echo.
echo [5/8] Installing Prism Launcher...
winget install --id PrismLauncher.PrismLauncher --exact ^
    --accept-package-agreements --accept-source-agreements

echo.
echo [6/8] Installing Steam...
winget install --id Valve.Steam --exact ^
    --accept-package-agreements --accept-source-agreements

echo.
echo [7/8] Downloading zapret 1.10.1...

set "ZAPRET_DIR=%USERPROFILE%\Desktop\zapret-1.10.1"
if not exist "%ZAPRET_DIR%" mkdir "%ZAPRET_DIR%"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='Stop';" ^
 "$api='https://api.github.com/repos/Flowseal/zapret-discord-youtube/releases/tags/1.10.1';" ^
 "$release=Invoke-RestMethod -Uri $api -Headers @{'User-Agent'='Windows-Installer'};" ^
 "$asset=$release.assets | Where-Object {$_.name -match '\.(zip)$'} | Select-Object -First 1;" ^
 "if (-not $asset) { throw 'ZIP asset for zapret 1.10.1 was not found.' };" ^
 "$zip=Join-Path $env:TEMP $asset.name;" ^
 "Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip;" ^
 "Expand-Archive -Path $zip -DestinationPath '%ZAPRET_DIR%' -Force;" ^
 "Write-Host 'zapret extracted to: %ZAPRET_DIR%'"

if errorlevel 1 (
    echo Could not automatically download zapret.
    echo Opening the release page...
    start "" "https://github.com/Flowseal/zapret-discord-youtube/releases/tag/1.10.1"
) else (
    echo zapret was extracted to:
    echo %ZAPRET_DIR%
)

echo.
echo [8/8] Opening Cristalix launcher download page...
start "" "https://cristalix.gg/launcher"

echo.
echo ==========================================
echo Installation process completed.
echo ==========================================
echo.
echo Cristalix must be downloaded from the opened website.
echo For zapret, open the extracted folder and run its installer/configuration
echo file according to the project instructions.
echo.
pause
exit /b
