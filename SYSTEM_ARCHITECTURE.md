# N8N Cluster Architecture

Welcome to the N8N Cluster Manager. This system helps you easily create and manage multiple [n8n](https://n8n.io/) workspaces on a single server without writing complex code.

## 1. System Components
- **Nginx Proxy (`nginx/nginx.conf`)**: This is the front door of your cluster. It listens for web traffic on Port 80 and uses **subdomain routing** to direct each request to the correct n8n workspace (for example, `projectA.localhost` goes to `n8n-projectA`).
- **Web Dashboard (`nginx/html/index.html`)**: A visual menu you can open in your browser at `http://localhost`. It automatically displays a card for every active workspace in your cluster so you can easily click and open them.
- **Main Config File (`docker-compose.yml`)**: This is the main file that boots up the cluster. Instead of being hundreds of lines long, it stays clean by automatically `including` the individual configuration files stored inside your `service-docker-files/` folder.

## 2. The Automation Script (`manage.js`)
At the heart of the system is the `manage.js` tool. When you use the terminal menu (CLI) to add or remove a workspace, this script runs automatically in the background.

It safely handles the hard work for you:
- It creates the specific `docker-compose.yml` file for your new workspace.
- It adds a new Nginx `server` block so your subdomain (e.g. `myproject.localhost`) works immediately.
- It updates the Web Dashboard so you can see your new workspace.
- It correctly sets up file permissions so you don't run into data errors.

## 3. The Terminal Menu (`n8n-cli.bat` / `n8n-cli.sh`)
These are the menu scripts you run to interact with your cluster. You can just type a number to tell the system what you want to do:
- **Options 1-3:** Start, stop, or restart your containers.
- **Options 4-5:** Stop or restart a specific service.
- **Option 6:** Open the visual Web Dashboard.
- **Options 7-8:** Automatically create a new workspace, or delete an old one.
- **Option 9:** Close the menu.

## 4. Subdomain Routing
Each workspace runs at root `/` on its own subdomain (e.g. `phd.localhost`, `demo.localhost`). This avoids a known n8n bug where subpath routing (`/n8n-name/`) causes 404 errors when navigating folders. Modern browsers resolve `*.localhost` automatically, so no hosts file edits are needed.
