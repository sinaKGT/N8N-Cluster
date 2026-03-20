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

🔗 **Automatic Web Routing**  
Using Nginx, the system listens on port 80 and makes sure that going to `/n8n-projectA/` takes you to the right place without needing to remember port numbers.

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
1. `Start System`: Turns on all your n8n workspaces.
2. `Restart Specific Container`: Pick one specific workspace to restart.
3. `Restart Entire System`: Reboots everything.
4. `Open Main Portal`: Opens the Web Dashboard in your browser.
5. `Add New Service Instance`: Creates a brand new, separate n8n workspace. It automatically builds the folders, settings, and web links for you.
6. `Remove Service Instance`: Completely deletes an n8n workspace and perfectly cleans up the files.
7. `Exit`: Closes the manager.

---

## 🧩 Adding Custom Databases (Sidecars)

Each n8n workspace you create gets its own personal configuration folder located in `service-docker-files/`. The master `docker-compose.yml` stays clean, so everything is easy to find.

If you want to add a database (like Postgres) to a specific workspace, you just edit that workspace's file.

### Step 1: Find your workspace's file
If you want to add a database to a workspace called `n8n-projectA`, open this file:
`service-docker-files/n8n-projectA/docker-compose.yml`

### Step 2: Add the database code
Add your database code directly under your n8n workspace code. Be sure to link them together using `depends_on`.

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
Because your master `docker-compose.yml` automatically reads this personal folder, you are already done! Your n8n workspace can now connect to your new database by simply typing `n8n-projectA-postgres` as the database host name inside your n8n workflow.

Apply your changes by running:
```bash
docker compose up -d
```

---

## 🛠 Advanced Architecture
To learn more about how the background script runs, read our [System Architecture Guide](SYSTEM_ARCHITECTURE.md).

## 🤝 Contribution
Engineered for ease of use and stability. Feel free to open an issue or pull request if you have ideas on how to make it even better!
