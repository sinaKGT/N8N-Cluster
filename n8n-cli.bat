@echo off
setlocal EnableDelayedExpansion

:: Navigate to the directory where the script is located
cd /d "%~dp0"

:menu
cls
echo ===================================
echo     N8N CLUSTER MANAGER CLI
echo ===================================
echo 1.  Start Entire System
echo 2.  Stop Entire System
echo 3.  Restart Entire System
echo 4.  Stop Specific Service
echo 5.  Restart Specific Service
echo 6.  Open Main Portal
echo 7.  Add New Service Instance
echo 8.  Remove Service Instance
echo 9.  Export Workflows
echo 10. Backup Menu
echo 11. Update N8N to Latest Version
echo 12. Restore Full System
echo 13. Exit
echo ===================================

set /p choice="Select an option [1-13]: "

if "%choice%"=="1" goto start_all
if "%choice%"=="2" goto stop_all
if "%choice%"=="3" goto restart_all
if "%choice%"=="4" goto stop_service
if "%choice%"=="5" goto restart_service
if "%choice%"=="6" goto open_portal
if "%choice%"=="7" goto add_service
if "%choice%"=="8" goto remove_service
if "%choice%"=="9" goto export_workflows
if "%choice%"=="10" goto backup_menu
if "%choice%"=="11" goto update_system
if "%choice%"=="12" goto restore_system
if "%choice%"=="13" exit

echo Invalid option. Please select 1-13.
pause
goto menu

:start_all
echo Starting N8N Cluster...
docker compose up -d
pause
goto menu

:stop_all
echo Stopping Entire System...
docker compose stop
pause
goto menu

:restart_all
echo Restarting Entire System...
docker compose restart
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

:open_portal
echo Opening Main Portal...
start http://localhost
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

:export_workflows
cls
echo ============================================
echo   EXPORTING WORKFLOWS ^& CREDENTIALS
echo ============================================
for /f "tokens=*" %%i in ('docker ps --format "{{.Names}}" ^| findstr n8n-') do (
    echo.
    echo Processing %%i...
    docker exec %%i n8n export:workflow --backup --output=/home/node/.n8n/workflows_backup.json
    docker exec %%i n8n export:credentials --backup --output=/home/node/.n8n/credentials_backup.json
)
echo.
echo Exports successfully mapped to your /volumes directories!
pause
goto menu

:backup_menu
cls
echo ===================================
echo        BACKUP ^& SYNC MENU
echo ===================================
echo 1. Workflows Backup + GitHub Push
echo 2. Full System Archive
echo 3. Git Commit ^& Push
echo 4. Back to Main Menu
echo ===================================
set /p bchoice="Select backup type [1-4]: "

if "%bchoice%"=="1" goto backup_push
if "%bchoice%"=="2" goto backup_archive
if "%bchoice%"=="3" goto backup_git
if "%bchoice%"=="4" goto menu
goto backup_menu

:backup_push
echo Step 1: Exporting data from active containers...
for /f "tokens=*" %%i in ('docker ps --format "{{.Names}}" ^| findstr n8n-') do (
    echo Processing %%i...
    docker exec %%i n8n export:workflow --backup --output=/home/node/.n8n/workflows_backup.json
    docker exec %%i n8n export:credentials --backup --output=/home/node/.n8n/credentials_backup.json
)
echo Step 2: Syncing to GitHub...
git add .
git commit -m "Auto-backup: Workflows and credentials"
git push origin main
pause
goto backup_menu

:backup_archive
echo Creating system backup folder...
if not exist system-backups mkdir system-backups
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set mytime=%mytime: =0%
set ARCHIVE_NAME=n8n_hard_backup_%mydate%_%mytime%.tar.gz
echo Compressing architecture into system-backups\%ARCHIVE_NAME%...
tar -czf system-backups\%ARCHIVE_NAME% --exclude=system-backups .
echo Hard backup complete!
pause
goto backup_menu

:backup_git
echo Staging files...
git add .
git commit -m "Manual System Backup via CLI"
git push origin main
pause
goto backup_menu

:update_system
cls
echo ============================================
echo   UPDATE — Upgrade N8N to Latest Version
echo ============================================
echo WARNING: This will stop all n8n containers, take a full archive backup,
echo pull the latest n8n image, and recreate the containers.
echo.
set /p confirm="Are you sure you want to proceed? (yes/no): "
if /i not "%confirm%"=="yes" (
    echo Update cancelled.
    pause
    goto menu
)
echo Step 1: Exporting current data...
for /f "tokens=*" %%i in ('docker ps --format "{{.Names}}" ^| findstr n8n-') do (
    docker exec %%i n8n export:workflow --backup --output=/home/node/.n8n/workflows_backup.json
    docker exec %%i n8n export:credentials --backup --output=/home/node/.n8n/credentials_backup.json
)
echo Step 2: Stopping containers...
docker compose stop
echo Step 3: Taking failsafe archive...
if not exist system-backups mkdir system-backups
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
set ARCHIVE_NAME=n8n_update_failsafe_%mydate%.tar.gz
tar -czf system-backups\%ARCHIVE_NAME% --exclude=system-backups .
echo Step 4: Pulling latest n8n image...
docker pull n8nio/n8n:latest
echo Step 5: Recreating containers...
docker compose up -d --force-recreate
echo Update complete!
pause
goto menu

:restore_system
cls
echo ============================================
echo   RESTORE — Full System Archive            
echo ============================================
if not exist system-backups (
    echo No system-backups directory found.
    pause
    goto menu
)
echo Available Backups in \system-backups:
dir /b /o-d system-backups\*.tar.gz
echo.
set /p selected_file="Type the EXACT filename of the backup to restore (or 'cancel'): "
if "%selected_file%"=="cancel" goto menu
if not exist "system-backups\%selected_file%" (
    echo File not found!
    pause
    goto menu
)
echo WARNING: This will OVERWRITE your entire cluster configuration!
set /p confirm="Type 'yes' to confirm: "
if /i not "%confirm%"=="yes" goto menu
echo Stopping all containers...
docker compose stop
echo Extracting archive...
tar -xzf "system-backups\%selected_file%" -C .
echo Recreating containers...
docker compose up -d --force-recreate
echo Reloading Nginx...
docker restart nginx-proxy
echo Restore Complete!
pause
goto menu

