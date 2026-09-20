<div align="center">
  <h1>🌌 N8N Cluster Manager</h1>
  <p>A powerful, fully-automated CLI and Dashboard for managing isolated N8N workspaces.</p>

[![Node.js](https://img.shields.io/badge/Node.js-automation-339933?style=for-the-badge&logo=node.js)]()
[![Docker](https://img.shields.io/badge/docker-isolated%20containers-2496ED?style=for-the-badge&logo=docker)]()
[![Nginx](https://img.shields.io/badge/nginx-reverse%20proxy-success?style=for-the-badge&logo=nginx)]()
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)]()

</div>

---

## 🌌 Overview

The **N8N Cluster Manager** lets you spin up separate, independent n8n environments with just a few clicks in your terminal. It includes a custom terminal menu, an automated script that organizes everything in the background, and a highly premium visual Web Dashboard so you can see all your active projects.

Instead of writing long setup files by hand, you just use the menu. The system automatically creates isolated folders, sets up web links, and turns them on for you.

## ✨ Key Features

🎨 **Premium Web Dashboard**  
A beautiful, highly-responsive web dashboard (built with a sleek cyberpunk/glassmorphism aesthetic). Every time you create a new n8n workspace, a link to it automatically appears here.

⚡ **Terminal Menu (CLI)**  
Easy scripts (`.sh` for Linux/Mac, `.bat` for Windows) that give you a numbered menu to safely control your instances, create backups, or wipe out instances.

🧠 **Automated Setup Engine**  
A background tool (`manage.js`) that safely edits complicated Nginx and Docker configurations for you. Because it runs on NodeJS, it works perfectly on any operating system without installing extra software.

🔗 **Automatic Web Routing**  
Using Nginx, the system listens on port 80 and makes sure that going to `http://<workspace>.yourdomain.com/` takes you to the right container instantly without dealing with ports.

---

## 📦 Quick Start Guide

**1. Clone the repository:**
```bash
git clone https://github.com/sinaKGT/N8N-Cluster.git
cd N8N-Cluster
```

**2. Set Your Domain Name:**
By default, the cluster is configured for local testing (using `.localhost`). If you want to put this on a live server, follow the [Domain Configuration Guide](#-domain-configuration-guide-cloudflaredns) below.

**3. Open the menu:**
- **Linux/Mac:** Run `./n8n-cli.sh` *(Make sure to run `chmod +x n8n-cli.sh` first)*
- **Windows:** Double click `n8n-cli.bat`

**4. Menu Options:**
- **Add New Service Instance**: Creates a brand new, automatically routed n8n workspace.
- **Start / Stop / Restart**: Manage your entire cluster or specific containers.
- **Backup & Restore**: Easily package your entire setup into `.tar.gz` archives or restore them.

---

## 🌍 Domain Configuration Guide (Cloudflare/DNS)

If you are running this cluster on a live cloud server (like AWS, DigitalOcean, or Hetzner), you will want to route a real domain (e.g., `my-automation.com`) to your containers.

### Step 1: Update the Automation Script
Open `manage.js` and find the domain suffix variable (near the top). Change it from `.localhost` to your actual domain:
```javascript
const DOMAIN_SUFFIX = '.yourdomain.com';
```
*(Now, whenever you use the CLI to create an instance named `marketing`, it will automatically configure `http://marketing.yourdomain.com`!)*

### Step 2: Configure Your DNS / Cloudflare Tunnels
Point your domain to your server. The easiest and most secure way is to use **Cloudflare Tunnels**:
1. In Cloudflare Zero Trust, create a tunnel pointing to your server.
2. For the public hostname, set `*.yourdomain.com` (Wildcard) to point to your server's local IP on port `80` (e.g., `http://localhost:80`).
3. Since Nginx handles the reverse-proxying internally, Cloudflare will hit Nginx, and Nginx will intelligently route traffic to the correct Docker container based on the subdomain!

### Step 3: Mandatory Environment Variables
If you are manually creating or migrating N8N instances, ensure OAuth callbacks and webhooks route successfully through your public domain by explicitly overriding the N8N variables inside your container's `docker-compose.yml`:
```yaml
    environment:
      - N8N_URL=https://<workspace>.yourdomain.com
      - WEBHOOK_URL=https://<workspace>.yourdomain.com/
      - N8N_EDITOR_BASE_URL=https://<workspace>.yourdomain.com/
```

> [!TIP]
> **DNS Propagation Delay (`NXDOMAIN` Error)**
> If you just added a new `A` or `CNAME` record in Cloudflare, but your browser throws a `DNS_PROBE_FINISHED_NXDOMAIN` error (even if online DNS checkers say the domain is live!), it simply means your local ISP or computer hasn't updated its network records yet. To fix this instantly on Windows, open command prompt and run `ipconfig /flushdns`, or bypass your slow ISP entirely by changing your computer's IPv4 DNS to `1.1.1.1` (Cloudflare) or `8.8.8.8` (Google).

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

## 🤝 Contribution
Engineered for ease of use and stability. Feel free to open an issue or pull request if you have ideas on how to make it even better!
