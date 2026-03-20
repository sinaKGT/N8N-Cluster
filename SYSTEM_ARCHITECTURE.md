# N8N Cluster Architecture

Welcome to the automated N8N Cluster Manager. This system provides a dynamic, self-hosted, scalable environment for managing multiple isolated [n8n](https://n8n.io/) instances simultaneously from a single host.

## 1. System Components
- **Nginx Proxy (`nginx/nginx.conf`)**: Acts as the master gateway. It listens globally on Port 80 and automatically parses incoming routes (`/n8n-phd/`, `/n8n-student1/`) channeling them down to isolated internal Docker networks over port 5678.
- **3D Dashboard (`nginx/html/index.html`)**: A lightweight dynamic web interface acting as a universal portal. It automatically generates glowing interactive cards and live 3D physics spheres for every active node mapped within the cluster.
- **Docker Compose (`docker-compose.yml`)**: The master record of the system's infrastructure. It tracks the exact state of every n8n instance and recursively attached sidecar dependencies.

## 2. The Orchestration Engine (`manage.js`)
At the core of the cluster is the automation engine. Because traditional Bash or Windows Batch shell scripts struggle to safely parse complex YAML configuration trees or deeply nested HTML physics frameworks without corrupting them, this system utilizes a headless asynchronous NodeJS engine (`manage.js`).

When you instruct the CLI to execute dynamic tasks, it spawns a temporary `node:18-alpine` Docker container which securely mounts the host scripts and fires up `manage.js`. This engine intelligently scans your infrastructure footprint to safely inject YAML composite blocks, upgrade Nginx routing tables, force-mount Linux volume `/volumes/` permissions correctly utilizing UID 1000 standard masking, and structurally reconstruct UI cards directly inside JavaScript matrices.

## 3. The CLI Interface (`n8n-cli.bat` / `n8n-cli.sh`)
These terminal scripts serve as the unified user interface layer, effectively driving the underlying Node orchestrator smoothly beneath simple dialog prompts.
- **Options 1-3:** Allow basic Docker Compose lifecycle controls.
- **Option 4 & 5:** Dynamically create fully functioning standard n8n container environments, routing domains, or recursively tear them down.
- **Option 6:** Gracefully exit the CLI interface manager.
