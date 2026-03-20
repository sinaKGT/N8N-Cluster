@echo off
setlocal

:: Navigate to the directory where the script is located
cd /d "%~dp0"

:menu
cls
echo ===================================
echo     N8N CLUSTER MANAGER CLI
echo ===================================
echo 1. Start System
echo 2. Restart Specific Container
echo 3. Restart Entire System
echo 4. Open Main Portal
echo 5. Add New Service Instance
echo 6. Remove Service Instance
echo 7. Exit
echo ===================================

set /p choice="Select an option [1-7]: "

if "%choice%"=="1" (
    echo Starting N8N Cluster...
    docker compose up -d
    pause
    goto menu
)

if "%choice%"=="2" (
    goto restart_menu
)

if "%choice%"=="3" (
    echo Restarting Entire System...
    docker compose restart
    pause
    goto menu
)

if "%choice%"=="4" (
    echo Opening Main Portal...
    start http://localhost
    goto menu
)

if "%choice%"=="5" (
    goto add_service
)

if "%choice%"=="6" (
    goto remove_service
)

if "%choice%"=="7" exit

echo Invalid option. Please select 1-7.
pause
goto menu

:add_service
cls
set /p servicename="Enter new service name (e.g. clientA): "
set /p servicedesc="Enter short description for card: "
echo Adding service: %servicename%...
docker run --rm -v "%cd%":/app -w /app node:18-alpine node manage.js add "%servicename%" "%servicedesc%"
echo Building custom image and starting container...
docker compose up -d --build
echo Restarting Nginx route...
docker restart nginx-proxy
pause
goto menu

:remove_service
cls
echo --- Available Custom Services ---
echo (Tip: Type ONLY the suffix. Example: for 'n8n-student1', type 'student1')
echo.
docker ps --format "{{.Names}}" | findstr n8n-
echo ---------------------------------
set /p servicename="Enter service suffix to remove: "
echo Stopping and removing n8n-%servicename%...
docker stop "n8n-%servicename%"
docker rm "n8n-%servicename%"
docker run --rm -v "%cd%":/app -w /app node:18-alpine node manage.js remove "%servicename%"
echo Redeploying architecture...
docker compose up -d --remove-orphans
docker restart nginx-proxy
pause
goto menu

:restart_menu
cls
echo --- Select Container to Restart ---
echo 1. n8n-phd
echo 2. n8n-sandbox
echo 3. n8n-demo
echo 4. n8n-utility
echo 5. nginx-proxy
echo 6. Back to Main Menu
echo -----------------------------------

set /p subchoice="Select container [1-6]: "

if "%subchoice%"=="1" docker restart n8n-phd & pause & goto menu
if "%subchoice%"=="2" docker restart n8n-sandbox & pause & goto menu
if "%subchoice%"=="3" docker restart n8n-demo & pause & goto menu
if "%subchoice%"=="4" docker restart n8n-utility & pause & goto menu
if "%subchoice%"=="5" docker restart nginx-proxy & pause & goto menu
if "%subchoice%"=="6" goto menu

echo Invalid option.
pause
goto restart_menu
