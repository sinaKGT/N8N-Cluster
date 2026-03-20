#!/bin/bash

# Navigate to the script's directory
cd "$(dirname "$0")" || exit

show_menu() {
    clear
    echo "==================================="
    echo "      N8N CLUSTER MANAGER CLI      "
    echo "==================================="
    echo "1. Start Entire System"
    echo "2. Stop Entire System"
    echo "3. Restart Entire System"
    echo "4. Stop Specific Service"
    echo "5. Restart Specific Service"
    echo "6. Open Main Portal"
    echo "7. Add New Service Instance"
    echo "8. Remove Service Instance"
    echo "9. Exit"
    echo "============================"
}

while true; do
    show_menu
    read -p "Select an option [1-9]: " choice
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
            echo "Building custom image and starting container..."
            docker compose up -d --build
            echo "Restarting Nginx route..."
            docker restart nginx-proxy
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
            docker restart nginx-proxy
            read -p "Press Enter to continue..."
            ;;
        9)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select 1-9."
            read -p "Press Enter to continue..."
            ;;
    esac
done
