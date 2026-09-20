# N8N Cluster Architecture

Welcome to the N8N Cluster Manager. This system helps you easily create and manage multiple [n8n](https://n8n.io/) workspaces on a single server without writing complex code.

## 1. System Components
- **Nginx Proxy (`nginx/nginx.conf`)**: This is the front door of your cluster. It listens for web traffic on Port 80 and directs users to their correct n8n workspace (for example, `/n8n-projectA/`).
- **Web Dashboard (`nginx/html/index.html`)**: A visual menu you can open in your browser. It automatically displays a card for every active workspace in your cluster so you can easily click and open them.
- **Main Config File (`docker-compose.yml`)**: This is the main file that boots up the cluster. Instead of being hundreds of lines long, it stays clean by automatically `including` the individual configuration files stored inside your `service-docker-files/` folder.

## 2. The Automation Script (`manage.js`)
At the heart of the system is the `manage.js` tool. When you use the terminal menu (CLI) to add or remove a workspace, this script runs automatically in the background.

It safely handles the hard work for you:
- It creates the specific `docker-compose.yml` file for your new workspace.
- It updates the Nginx routes so your URL works immediately.
- It updates the Web Dashboard so you can see your new workspace.
- It correctly sets up file permissions so you don't run into data errors.

## 3. The Terminal Menu (`n8n-cli.bat` / `n8n-cli.sh`)
These are the menu scripts you run to interact with your cluster. You can just type a number to tell the system what you want to do:
- **Options 1-3:** Start, stop, or restart your containers.
- **Option 4:** Open the visual Web Dashboard.
- **Option 5 & 6:** Automatically create a brand new n8n workspace, or completely delete an old one.
- **Option 7:** Close the menu.
