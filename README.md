<div align="center">
  
# 🚀 N8N Cluster Manager

**An easy-to-use manager for running multiple [n8n](https://n8n.io) workspaces on a single server.**

[![Docker](https://img.shields.io/badge/docker-dynamic%20clustering-blue?style=for-the-badge&logo=docker)]()
[![NodeJS](https://img.shields.io/badge/node.js-v18%20engine-success?style=for-the-badge&logo=nodedotjs)]()
[![Nginx](https://img.shields.io/badge/nginx-reverse%20proxy-success?style=for-the-badge&logo=nginx)]()
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)]()

</div>

---

## 🌌 Overview

The **N8N Cluster Manager** lets you spin up separate, independent n8n environments with just a few clicks in your terminal. It includes a custom terminal menu, an automated script that organizes everything in the background, and a visual Web Dashboard so you can see all your active projects.

Instead of writing long setup files by hand, you just use the menu. The system automatically creates isolated folders, sets up web links, and turns them on for you.

## ✨ Key Features

🎨 **Visual Web Dashboard**  
A beautiful webpage that acts as your main menu. Every time you create a new n8n workspace, a link to it automatically appears here.

⚡ **Terminal Menu (CLI)**  
Easy scripts (`.sh` for Linux/Mac, `.bat` for Windows) that give you a numbered menu to control everything safely.

🧠 **Automated Setup Engine**  
A background tool that safely edits complicated configuration files for you. Because it runs on NodeJS inside Docker, it works perfectly on any operating system without installing extra software.

🔗 **Subdomain Routing**  
Using Nginx, each workspace gets its own subdomain (e.g. `projectA.localhost`). This means every workspace runs cleanly at the root path — no subpath bugs, no 404 errors when navigating folders.

---

## 📦 Quick Start Guide

**1. Clone the repository:**
```bash
git clone https://github.com/sinaKGT/N8N-Cluster.git
cd N8N-Cluster
```

**2. Open the menu:**
- **Windows:** Double click `n8n-cli.bat`
- **Linux/Mac:** Run `./n8n-cli.sh` *(Make sure to run `chmod +x n8n-cli.sh` first)*

**3. Menu Options:**
1. `Start Entire System`: Turns on all your n8n workspaces.
2. `Stop Entire System`: Gracefully shuts down all active containers.
3. `Restart Entire System`: Reboots everything.
4. `Stop Specific Service`: Shuts down a single n8n workspace.
5. `Restart Specific Service`: Restarts a single workspace.
6. `Open Main Portal`: Opens the Web Dashboard in your browser.
7. `Add New Service Instance`: Creates a brand new n8n workspace.
8. `Remove Service Instance`: Deletes a workspace completely.
9. `Exit`: Closes the manager.

---

## 🌐 How Routing Works

Each n8n workspace gets its own **subdomain** on `localhost`:

| Workspace | URL |
|-----------|-----|
| Portal Dashboard | `http://localhost` |
| n8n-phd | `http://phd.localhost` |
| n8n-sandbox | `http://sandbox.localhost` |
| n8n-demo | `http://demo.localhost` |
| n8n-personal | `http://personal.localhost` |

When you add a new workspace called `myproject`, the system automatically:
- Creates `myproject.localhost` subdomain routing
- Adds a card to the dashboard linking to the new subdomain
- Sets up all the internal Docker networking

> **Note:** Modern browsers (Chrome, Edge, Firefox) automatically resolve `*.localhost` subdomains to `127.0.0.1`, so no hosts file changes are needed.

---

## 🧩 Adding Custom Dependencies (Sidecars)

Each n8n workspace you create gets its own configuration folder in `service-docker-files/`. The master `docker-compose.yml` stays clean, so everything is easy to find.

If you want to add a database (like Postgres) to a specific workspace, you just edit that workspace's file.

### Step 1: Find your workspace's file
If you want to add a database to a workspace called `n8n-projectA`, open this file:
`service-docker-files/n8n-projectA/docker-compose.yml`

### Step 2: Add the database code
Add your database directly under your n8n workspace. Link them using `depends_on`.

```yaml
services:
  n8n-projectA:
    build: .
    container_name: n8n-projectA
    depends_on:                 # <--- Link it to the new database!
      - n8n-projectA-postgres
    restart: always
    environment:
      # ...

  n8n-projectA-postgres:      # <--- Your new database!
    image: postgres:15-alpine
    container_name: n8n-projectA-postgres
    restart: always
    environment:
      - POSTGRES_PASSWORD=your_secure_password
    volumes:
      - ../../volumes/n8n-projectA-postgres:/var/lib/postgresql/data
```

### Step 3: Turn it on
Because your master `docker-compose.yml` automatically reads this folder, you are already done! Your n8n workspace can now connect to your new database by typing `n8n-projectA-postgres` as the database host name inside your n8n workflow.

Apply your changes by running:
```bash
docker compose up -d
```

---

## 🛠 Advanced Architecture
To learn more about how the background script runs, read our [System Architecture Guide](SYSTEM_ARCHITECTURE.md).

## 🤝 Contribution
Engineered for ease of use and stability. Feel free to open an issue or pull request if you have ideas on how to make it even better!
