@echo off
setlocal

:: Navigate to the directory where the script is located
cd /d "%~dp0"

:menu
cls
echo ===================================
echo     N8N CLUSTER MANAGER CLI
echo ===================================
echo 1. Start Entire System
echo 2. Stop Entire System
echo 3. Restart Entire System
echo 4. Stop Specific Service
echo 5. Restart Specific Service
echo 6. Open Main Portal
echo 7. Add New Service Instance
echo 8. Remove Service Instance
echo 9. Exit
echo ===================================

set /p choice="Select an option [1-9]: "

if "%choice%"=="1" (
    echo Starting N8N Cluster...
    docker compose up -d
    pause
    goto menu
)

if "%choice%"=="2" (
    echo Stopping Entire System...
    docker compose stop
    pause
    goto menu
)

if "%choice%"=="3" (
    echo Restarting Entire System...
    docker compose restart
    pause
    goto menu
)

if "%choice%"=="4" (
    goto stop_service
)

if "%choice%"=="5" (
    goto restart_service
)

if "%choice%"=="6" (
    echo Opening Main Portal...
    start http://localhost
    goto menu
)

if "%choice%"=="7" (
    goto add_service
)

if "%choice%"=="8" (
    goto remove_service
)

if "%choice%"=="9" exit

echo Invalid option. Please select 1-9.
pause
goto menu

:stop_service
cls
echo --- Available Custom Services ---
docker ps -a --format "{{.Names}}" | findstr n8n-
echo ---------------------------------
set /p servicename="Enter service suffix to stop (e.g. personal): "
echo Stopping service n8n-%servicename%...
docker stop "n8n-%servicename%"
pause
goto menu

:restart_service
cls
echo --- Available Custom Services ---
docker ps -a --format "{{.Names}}" | findstr n8n-
echo ---------------------------------
set /p servicename="Enter service suffix to restart (e.g. personal): "
echo Restarting service n8n-%servicename%...
docker restart "n8n-%servicename%"
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
docker ps -a --format "{{.Names}}" | findstr n8n-
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
