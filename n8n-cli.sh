#!/bin/bash

# Navigate to the script's directory
cd "$(dirname "$0")" || exit

show_menu() {
    clear
    echo "==================================="
    echo "      N8N CLUSTER MANAGER CLI      "
    echo "==================================="
    echo "1.  Start Entire System"
    echo "2.  Stop Entire System"
    echo "3.  Restart Entire System"
    echo "4.  Stop Specific Service"
    echo "5.  Restart Specific Service"
    echo "6.  Open Main Portal"
    echo "7.  Add New Service Instance"
    echo "8.  Remove Service Instance"
    echo "9.  Export Workflows"
    echo "10. Backup"
    echo "11. Update N8N to Latest Version"
    echo "12. Restore Full System"
    echo "13. Exit"
    echo "===================================="
}

# ── Shared: export workflows & credentials from all running services ─────────
# $1 = "silent" skips the header (used internally by backup)

run_export() {
    local silent=$1
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')

    if [ "$silent" != "silent" ]; then
        clear
        echo "============================================"
        echo "       EXPORT — Workflows & Credentials     "
        echo "============================================"
        echo ""
        echo "Exporting from every running n8n service..."
        echo ""
    fi

    services=$(docker ps --format '{{.Names}}' | grep '^n8n-' | sort)

    if [ -z "$services" ]; then
        echo "⚠  No running n8n containers found. Start the system first."
        echo ""
        [ "$silent" != "silent" ] && read -p "Press Enter to continue..."
        return 1
    fi

    local success_count=0
    local fail_count=0

    for container in $services; do
        vol_path="./volumes/${container}"
        echo "──────────────────────────────────────────"
        echo "▶  Service: $container"

        # Export workflows
        echo "   Exporting workflows..."
        if docker exec "$container" n8n export:workflow \
            --all \
            --output=/home/node/.n8n/workflows_backup.json \
            --pretty 2>/dev/null; then
            echo "   ✔ workflows_backup.json saved"
        else
            echo "   ✘ Workflow export failed (container may not be ready)"
            ((fail_count++))
            continue
        fi

        # Export credentials
        echo "   Exporting credentials..."
        if docker exec "$container" n8n export:credentials \
            --all \
            --output=/home/node/.n8n/credentials_backup.json \
            --pretty 2>/dev/null; then
            echo "   ✔ credentials_backup.json saved"
        else
            echo "   ✘ Credential export failed"
        fi

        # Keep a timestamped copy in a backups/ subfolder
        backup_dir="${vol_path}/backups"
        mkdir -p "$backup_dir"
        cp "${vol_path}/workflows_backup.json"   "${backup_dir}/workflows_${timestamp}.json"   2>/dev/null
        cp "${vol_path}/credentials_backup.json" "${backup_dir}/credentials_${timestamp}.json" 2>/dev/null
        echo "   ✔ Timestamped copy → ${backup_dir}/"
        ((success_count++))
    done

    echo ""
    echo "============================================"
    echo "  Export done: $success_count succeeded, $fail_count failed"
    echo "============================================"

    # Return the timestamp so callers can use it in commit messages
    echo "$timestamp" > /tmp/n8n_last_export_ts
    return 0
}

# ── Option 9: Export (standalone, no git push) ───────────────────────────────

do_export() {
    run_export
    echo ""
    read -p "Press Enter to continue..."
}

# ── Backup helpers ───────────────────────────────────────────────────────────

backup_workflows_and_push() {
    clear
    echo "============================================"
    echo "   BACKUP — Workflows + Git Push to GitHub  "
    echo "============================================"
    echo ""
    echo "Step 1/2 — Exporting workflows & credentials..."
    echo ""

    run_export "silent"
    export_status=$?

    if [ $export_status -ne 0 ]; then
        read -p "Press Enter to continue..."
        return
    fi

    timestamp=$(cat /tmp/n8n_last_export_ts 2>/dev/null || date '+%Y-%m-%d_%H-%M-%S')

    echo ""
    echo "Step 2/2 — Committing & pushing to GitHub..."
    echo ""

    git add volumes/
    if git diff --cached --quiet; then
        echo "  (No new workflow changes to commit)"
    else
        git commit -m "Backup: Workflow & credential export — ${timestamp}"
        echo "  ✔ Committed."
    fi

    echo "  Pushing to GitHub (origin/main)..."
    if git push origin main; then
        echo "  ✔ Pushed successfully to GitHub."
    else
        echo "  ✘ Push failed. Check your GitHub credentials / token."
    fi

    echo ""
    git log --oneline -3
    echo ""
    read -p "Press Enter to continue..."
}

backup_full_system() {
    clear
    echo "============================================"
    echo "   BACKUP — Full System Archive             "
    echo "============================================"
    echo ""
    echo "Creates a compressed tarball of the ENTIRE cluster:"
    echo "  • All config files (nginx, docker-compose, manage.js)"
    echo "  • All volume data (SQLite databases, workflow exports)"
    echo "  • All service definitions"
    echo ""
    echo "⚠  WARNING: Credentials & encryption keys are included."
    echo "   Store the archive securely."
    echo ""

    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    backup_dir="./system-backups"
    archive_name="n8n_cluster_full_${timestamp}.tar.gz"
    archive_path="${backup_dir}/${archive_name}"

    mkdir -p "$backup_dir"

    echo "Stopping containers gracefully (clean SQLite state)..."
    docker compose stop
    echo ""

    echo "Creating archive: $archive_name ..."
    tar --exclude='./.git' \
        --exclude='./system-backups' \
        --exclude='./node_modules' \
        -czf "$archive_path" \
        . 2>/dev/null
    exit_code=$?

    echo "Restarting containers..."
    docker compose up -d
    echo ""

    if [ $exit_code -eq 0 ]; then
        size=$(du -sh "$archive_path" | cut -f1)
        echo "============================================"
        echo "  ✔ Full backup complete!"
        echo "  File : $archive_path"
        echo "  Size : $size"
        echo "============================================"
    else
        echo "  ✘ Archive creation failed (exit code: $exit_code)"
    fi

    echo ""
    echo "Existing system backups:"
    ls -lh "$backup_dir" 2>/dev/null || echo "  (none)"
    echo ""
    read -p "Press Enter to continue..."
}

backup_git_commit() {
    clear
    echo "==============================="
    echo "   BACKUP — Git Commit         "
    echo "==============================="
    echo ""
    echo "Current status:"
    git status --short
    echo ""
    read -p "Enter commit message (or press Enter for default): " commitmsg
    if [ -z "$commitmsg" ]; then
        commitmsg="Backup: Saved the latest N8N workflows and configurations"
    fi
    echo ""
    echo "Staging all changes..."
    git add .
    echo "Committing..."
    git commit -m "$commitmsg"
    echo ""
    echo "Pushing to GitHub (origin/main)..."
    if git push origin main; then
        echo "✔ Pushed to GitHub."
    else
        echo "✘ Push failed. Check your GitHub credentials / token."
    fi
    echo ""
    git log --oneline -3
    echo ""
    read -p "Press Enter to continue..."
}

show_backup_menu() {
    clear
    echo "==================================="
    echo "         BACKUP OPTIONS            "
    echo "==================================="
    echo "1. Workflows Backup + GitHub Push"
    echo "   └─ Exports JSONs from each service,"
    echo "      auto-commits & pushes to GitHub."
    echo ""
    echo "2. Full System Archive"
    echo "   └─ Creates a .tar.gz of the entire"
    echo "      cluster (configs + all databases)."
    echo "      Stops containers briefly for clean backup."
    echo ""
    echo "3. Git Commit & Push"
    echo "   └─ Stage all changes, commit with"
    echo "      a message, and push to GitHub."
    echo ""
    echo "4. Back to Main Menu"
    echo "==================================="
}

update_n8n() {
    clear
    echo "============================================"
    echo "   UPDATE — N8N to Latest Version           "
    echo "============================================"
    echo ""
    echo "This will:"
    echo "  1. Export all workflows & credentials (safety backup)"
    echo "  2. Create a full system archive (.tar.gz)"
    echo "  3. Pull the latest n8n image from Docker Hub"
    echo "  4. Recreate all n8n containers with the new version"
    echo ""

    # Show current version
    current_ver=$(docker exec n8n-phd n8n --version 2>/dev/null || echo "unknown")
    echo "  Current n8n version: $current_ver"
    echo ""

    read -p "Continue with update? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Update cancelled."
        read -p "Press Enter to continue..."
        return
    fi

    echo ""
    echo "══════════════════════════════════════════"
    echo "  STEP 1/4 — Exporting workflows & credentials..."
    echo "══════════════════════════════════════════"
    run_export "silent"

    timestamp=$(cat /tmp/n8n_last_export_ts 2>/dev/null || date '+%Y-%m-%d_%H-%M-%S')

    echo ""
    echo "  Committing workflow exports to git..."
    git add volumes/
    if git diff --cached --quiet; then
        echo "  (No new workflow changes to commit)"
    else
        git commit -m "Pre-update backup: Workflow export before n8n upgrade — ${timestamp}"
        echo "  ✔ Committed."
    fi

    echo "  Pushing to GitHub..."
    git push origin main 2>/dev/null && echo "  ✔ Pushed." || echo "  ⚠ Push failed — continuing with update anyway."

    echo ""
    echo "══════════════════════════════════════════"
    echo "  STEP 2/4 — Creating full system archive..."
    echo "══════════════════════════════════════════"
    backup_dir="./system-backups"
    archive_name="n8n_cluster_pre_update_${timestamp}.tar.gz"
    archive_path="${backup_dir}/${archive_name}"
    mkdir -p "$backup_dir"

    echo "  Stopping containers for clean snapshot..."
    docker compose stop

    tar --exclude='./.git' \
        --exclude='./system-backups' \
        --exclude='./node_modules' \
        -czf "$archive_path" \
        . 2>/dev/null

    if [ $? -eq 0 ]; then
        size=$(du -sh "$archive_path" | cut -f1)
        echo "  ✔ Archive saved: $archive_path ($size)"
    else
        echo "  ✘ Archive failed — aborting update to be safe."
        docker compose up -d
        read -p "Press Enter to continue..."
        return
    fi

    echo ""
    echo "══════════════════════════════════════════"
    echo "  STEP 3/4 — Pulling latest n8n image..."
    echo "══════════════════════════════════════════"
    if docker pull n8nio/n8n:latest; then
        echo "  ✔ Latest image downloaded."
    else
        echo "  ✘ Image pull failed. Check internet connection."
        docker compose up -d
        read -p "Press Enter to continue..."
        return
    fi

    echo ""
    echo "══════════════════════════════════════════"
    echo "  STEP 4/4 — Recreating containers..."
    echo "══════════════════════════════════════════"
    docker compose up -d --force-recreate

    echo ""
    sleep 5
    new_ver=$(docker exec n8n-phd n8n --version 2>/dev/null || echo "unknown")

    echo ""
    echo "============================================"
    echo "  ✔ Update complete!"
    echo "  Previous version : $current_ver"
    echo "  New version      : $new_ver"
    echo "  Backup archive   : $archive_path"
    echo "============================================"
    echo ""
    read -p "Press Enter to continue..."
}

restore_full_system() {
    clear
    echo "============================================"
    echo "   RESTORE — Full System Archive            "
    echo "============================================"
    echo ""

    backup_dir="./system-backups"
    if [ ! -d "$backup_dir" ]; then
        echo "  ✘ No system-backups directory found."
        read -p "Press Enter to continue..."
        return
    fi

    # Get list of tar.gz files, sorted by newest first
    mapfile -t backups < <(ls -1t "$backup_dir"/*.tar.gz 2>/dev/null)

    if [ ${#backups[@]} -eq 0 ]; then
        echo "  ✘ No backup archives found in $backup_dir."
        read -p "Press Enter to continue..."
        return
    fi

    echo "Available Backups:"
    for i in "${!backups[@]}"; do
        filename=$(basename "${backups[$i]}")
        size=$(du -sh "${backups[$i]}" | cut -f1)
        echo "  $((i+1)). $filename ($size)"
    done
    echo "  0. Cancel"
    echo ""

    read -p "Select a backup to restore [0-$(( ${#backups[@]} ))]: " sel
    if [[ ! "$sel" =~ ^[0-9]+$ ]] || [ "$sel" -eq 0 ] || [ "$sel" -gt "${#backups[@]}" ]; then
        echo "Restore cancelled."
        read -p "Press Enter to continue..."
        return
    fi

    selected_file="${backups[$((sel-1))]}"
    
    echo ""
    echo "⚠ WARNING: This will OVERWRITE your entire cluster configuration,"
    echo "databases, and workflows with the state from this archive."
    echo "Current unsaved data will be permanently lost."
    echo ""
    read -p "Are you absolutely sure you want to restore? (Type 'yes' to confirm): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Restore cancelled."
        read -p "Press Enter to continue..."
        return
    fi

    echo ""
    echo "  Stopping all containers..."
    docker compose stop

    echo "  Extracting archive $(basename "$selected_file")..."
    tar -xzf "$selected_file" -C .

    echo "  Recreating containers..."
    docker compose up -d --force-recreate

    echo "  Reloading Nginx..."
    docker exec nginx-proxy nginx -s reload 2>/dev/null || true

    echo ""
    echo "============================================"
    echo "  ✔ Restore Complete!"
    echo "============================================"
    read -p "Press Enter to continue..."
}

# ── Main loop ────────────────────────────────────────────────────────────────

while true; do
    show_menu
    read -p "Select an option [1-11]: " choice
    case $choice in
        1)
            echo "Starting N8N Cluster..."
            docker compose up -d
            read -p "Press Enter to continue..."
            ;;
        2)
            echo "Stopping Entire System..."
            docker compose stop
            read -p "Press Enter to continue..."
            ;;
        3)
            echo "Restarting Entire System..."
            docker compose restart
            read -p "Press Enter to continue..."
            ;;
        4)
            clear
            echo "--- Available Custom Services ---"
            docker ps -a --format '{{.Names}}' | grep n8n-
            echo "---------------------------------"
            read -p "Enter service suffix to stop (e.g. personal): " servicename
            echo "Stopping service n8n-$servicename..."
            docker stop "n8n-$servicename"
            read -p "Press Enter to continue..."
            ;;
        5)
            clear
            echo "--- Available Custom Services ---"
            docker ps -a --format '{{.Names}}' | grep n8n-
            echo "---------------------------------"
            read -p "Enter service suffix to restart (e.g. personal): " servicename
            echo "Restarting service n8n-$servicename..."
            docker restart "n8n-$servicename"
            read -p "Press Enter to continue..."
            ;;
        6)
            echo "Opening Main Portal..."
            if command -v xdg-open > /dev/null; then
                xdg-open http://localhost
            elif command -v open > /dev/null; then
                open http://localhost
            else
                echo "Cannot detect web browser. Please open http://localhost manually."
            fi
            read -p "Press Enter to continue..."
            ;;
        7)
            read -p "Enter new service name (e.g. clientA): " servicename
            read -p "Enter short description for card: " servicedesc
            echo "Adding service: $servicename..."
            docker run --rm -v "$(pwd)":/app -w /app node:18-alpine node manage.js add "$servicename" "$servicedesc"
            echo "Starting container..."
            docker compose up -d
            echo "Reloading Nginx routes..."
            docker exec nginx-proxy nginx -s reload
            read -p "Press Enter to continue..."
            ;;
        8)
            clear
            echo "--- Available Custom Services ---"
            echo "(Tip: Type ONLY the suffix. Example: for 'n8n-student1', type 'student1')"
            echo ""
            docker ps -a --format '{{.Names}}' | grep n8n-
            echo "---------------------------------"
            read -p "Enter service suffix to remove: " servicename
            echo "Stopping and removing n8n-$servicename..."
            docker stop "n8n-$servicename"
            docker rm "n8n-$servicename"
            docker run --rm -v "$(pwd)":/app -w /app node:18-alpine node manage.js remove "$servicename"
            echo "Redeploying architecture..."
            docker compose up -d --remove-orphans
            docker exec nginx-proxy nginx -s reload
            read -p "Press Enter to continue..."
            ;;
        9)
            do_export
            ;;
        10)
            while true; do
                show_backup_menu
                read -p "Select backup type [1-4]: " bchoice
                case $bchoice in
                    1) backup_workflows_and_push ;;
                    2) backup_full_system ;;
                    3) backup_git_commit ;;
                    4) break ;;
                    *) echo "Invalid option."; sleep 1 ;;
                esac
            done
            ;;
        11)
            update_n8n
            ;;
        12)
            restore_full_system
            ;;
        13)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select 1-13."
            read -p "Press Enter to continue..."
            ;;
    esac
done
