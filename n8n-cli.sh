#!/bin/bash

# Navigate to the script's directory
cd "$(dirname "$0")" || exit

show_menu() {
    clear
    echo "==================================="
    echo "      N8N CLUSTER MANAGER CLI      "
    echo "==================================="
    echo "1. Start System"
    echo "2. Restart Specific Container"
    echo "3. Restart Entire System"
    echo "4. Open Main Portal"
    echo "5. Add New Service Instance"
    echo "6. Remove Service Instance"
    echo "7. Exit"
    echo "============================"
}

while true; do
    show_menu
    read -p "Select an option [1-7]: " choice
    case $choice in
        1)
            echo "Starting N8N Cluster..."
            docker compose up -d
            read -p "Press Enter to continue..."
            ;;
        2)
            while true; do
                clear
                echo "--- Select Container to Restart ---"
                echo "1. n8n-phd"
                echo "2. n8n-sandbox"
                echo "3. n8n-demo"
                echo "4. n8n-utility"
                echo "5. nginx-proxy"
                echo "6. Back to Main Menu"
                echo "-----------------------------------"
                read -p "Select container [1-6]: " subchoice
                case $subchoice in
                    1) docker restart n8n-phd; read -p "Press Enter to continue..."; break ;;
                    2) docker restart n8n-sandbox; read -p "Press Enter to continue..."; break ;;
                    3) docker restart n8n-demo; read -p "Press Enter to continue..."; break ;;
                    4) docker restart n8n-utility; read -p "Press Enter to continue..."; break ;;
                    5) docker restart nginx-proxy; read -p "Press Enter to continue..."; break ;;
                    6) break ;;
                    *) echo "Invalid option."; read -p "Press Enter to continue..." ;;
                esac
            done
            ;;
        3)
            echo "Restarting Entire System..."
            docker compose restart
            read -p "Press Enter to continue..."
            ;;
        4)
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
        5)
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
        6)
            clear
            echo "--- Available Custom Services ---"
            echo "(Tip: Type ONLY the suffix. Example: for 'n8n-student1', type 'student1')"
            echo ""
            docker ps --format '{{.Names}}' | grep n8n-
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
        7)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select 1-7."
            read -p "Press Enter to continue..."
            ;;
    esac
done
