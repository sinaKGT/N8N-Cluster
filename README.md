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
1. `Start Entire System`: Turns on all your n8n workspaces natively.
2. `Stop Entire System`: Gracefully shuts down all active containers safely in the background.
3. `Restart Entire System`: Reboots everything globally.
4. `Stop Specific Service`: Dynamically shuts down an explicit n8n background node organically.
5. `Restart Specific Service`: Select any single exact node to intelligently reboot instantly.
6. `Open Main Portal`: Opens the Web Dashboard visually in your browser.
7. `Add New Service Instance`: Creates a brand new, separately automated n8n workspace natively.
8. `Remove Service Instance`: Completely deletes an older environment workspace directly extracted from disk.
9. `Exit`: Closes the manager seamlessly.

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

## 🏙️ Current Cluster Architecture

This active cluster is strongly bonded to **n8ncluster.co.uk** with four distinct workspaces dynamically routed via the Nginx Reverse Proxy mapped on port 80:
1. **n8n-phd** (`http://phd.n8ncluster.co.uk`)
2. **n8n-sandbox** (`http://sandbox.n8ncluster.co.uk`)
3. **n8n-demo** (`http://demo.n8ncluster.co.uk`)
4. **n8n-personal** (`http://personal.n8ncluster.co.uk`)

*(All workspaces automatically adapt links if accessed via `http://localhost` instead of the public domain!)*

### 🧠 Internal Machine Learning API
An exclusive Python ML predictable server (`sleep-stress-prediction`) runs as a direct dependency.
Due to strict Docker Network isolation bounds (`demo_internal`), the ML Prediction server is logically isolated and *only* accessible by the **Demo** workspace inside the cluster at `http://sleep-stress-prediction:5000`.

---

## 🏗️ Creating a New N8N Workspace (Best Practices)

When initializing a completely new N8N instance within this cluster, there are **three critical configurations** you must include:

### 1. The `Dockerfile` (Custom NPM Packages)
If your new workflows require specific NodeJS native libraries (e.g., `uuid`, cryptographic wrappers), you cannot use the vanilla N8N image. Inside your new service folder, create a custom `Dockerfile` so your container permanently has those binaries:
```dockerfile
FROM n8nio/n8n:latest
USER root
# Install any specific node packages your custom workflows require!
RUN npm install -g uuid 
USER node
```
*Then in your `docker-compose.yml`, switch `image: n8nio/n8n:latest` to `build: .`*

### 2. Mandatory Environment Variables
To ensure OAuth callbacks, the Visual Editor, and incoming Webhooks route successfully through the public domain proxy, your child `docker-compose.yml` **must** explicitly override the root URL settings:
```yaml
    environment:
      - N8N_URL=http://<new-name>.n8ncluster.co.uk
      - WEBHOOK_URL=http://<new-name>.n8ncluster.co.uk/
      - N8N_EDITOR_BASE_URL=http://<new-name>.n8ncluster.co.uk/
```

### 3. Nginx Gateway Registration
Finally, to expose your new node safely to the internet:
1. Add a new `server {}` block linking your container name to `nginx/nginx.conf`.
2. Add your new YAML file path to the `include:` list in the root `docker-compose.yml`.
3. Add a new clickable UI card inside `nginx/html/index.html`.

> [!TIP]
> **DNS Propagation Delay (`NXDOMAIN` Error)**
> If you just added a new `A` or `CNAME` record in Cloudflare, but your browser throws a `DNS_PROBE_FINISHED_NXDOMAIN` error (even if online DNS checkers say the domain is live!), it simply means your local ISP or computer hasn't updated its network records yet. To fix this instantly on Windows, open command prompt and run `ipconfig /flushdns`, or bypass your slow ISP entirely by changing your computer's IPv4 DNS to `1.1.1.1` (Cloudflare) or `8.8.8.8` (Google).

---

## 🚀 Running, Refreshing & Rebuilding the System

If you adjust any environment variables (`.yml`), domain links, or Nginx configurations, use the native docker command to forcefully recreate everything so it syncs up smoothly:
```bash
docker compose down
docker compose up -d --build --force-recreate
```

---

## 💾 System Backup (Git)

The entire cluster (including crucial `volumes`, UI html designs, proxy configurations, and internal settings) is actively tracked by Git. 

To safely snapshot and backup your latest workflows and node setups to your personal GitHub (`sinaKGT/personal_n8n_cluster`), execute these exactly in your terminal:

```bash
# 1. Stage all new changes and volumes
git add .

# 2. Commit the changes locally
git commit -m "Backup: Saved the latest N8N workflows and configurations"

# 3. Push to your secure remote repository branch
git push -u origin main
```

---

## 🤝 Contribution
Engineered for ease of use and stability. Feel free to open an issue or pull request if you have ideas on how to make it even better!
