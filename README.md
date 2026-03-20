<div align="center">
  
# 🚀 N8N Cluster Manager

**An automated, self-hosted, scalable orchestrator for managing multi-tenant [n8n](https://n8n.io) environments globally from a single host system.**

[![Docker](https://img.shields.io/badge/docker-dynamic%20clustering-blue?style=for-the-badge&logo=docker)]()
[![NodeJS](https://img.shields.io/badge/node.js-v18%20engine-success?style=for-the-badge&logo=nodedotjs)]()
[![Nginx](https://img.shields.io/badge/nginx-reverse%20proxy-success?style=for-the-badge&logo=nginx)]()
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)]()

</div>

---

## 🌌 Overview

The **N8N Cluster Manager** transforms a standard Docker deployment into an infinitely scalable, multi-tenant workspace. It offers a **Custom CLI interface**, a **Headless NodeJS Automation Engine**, and a **Dynamic 3D Web Dashboard** to instantly visualize and administrate your active instances.

Instead of writing YAML configuration code by hand, this engine structurally compiles entirely isolated `n8n` environments—creating secure volumes, establishing background reverse proxy targets, and injecting realtime UX assets directly—all in single commands!

## ✨ Key Features

🎨 **Dynamic 3D Portal**  
Features an interactive `index.html` frontend physics grid acting as a unified navigational jumping-off point. Every active cluster securely injects its own distinct URL-routed card element instantly upon deployment.

⚡ **Interactive Terminal Interfaces (CLI)**  
Unified dual-CLI structures (`.sh` for Unix, `.bat` for Windows) grant administrators point-and-click control over cluster synchronization, teardown, and granular node restarts securely right from the shell.

🧠 **Headless Execution Engine (`manage.js`)**  
Eliminates structural corruption by ignoring generic Bash/Powershell string-manipulation, routing all complex YAML/HTML/Nginx parsing workloads asynchronously into an ephemeral cross-platform Node.JS pipeline automatically spawned via Docker!

🔗 **Automated Network Proxy (`Nginx`)**  
Listens universally on port 80 and transparently splits traffic safely to backend ephemeral webhooks ensuring port 5678 isolation seamlessly utilizing sub-route forwarding (e.g. `/n8n-student1/`).

---

## 📦 Quick Start Guide

**1. Clone the repository natively:**
```bash
git clone https://github.com/sinaKGT/N8N-Cluster.git
cd N8N-Cluster
```

**2. Execute the CLI orchestrator:**
- **Windows:** Run `n8n-cli.bat`
- **Linux/Mac:** Run `./n8n-cli.sh` *(Ensure it has execute rights: `chmod +x`)*

**3. Command Line Control Options:**
Once the menu runs, you can fully operate the cluster without writing code:
1. `Start System`: Syncs the generic core modules globally.
2. `Restart Specific Container`: Select target containers seamlessly without tracking Docker IDs.
3. `Restart Entire System`: Purges caching and reasserts live images automatically.
4. `Open Main Portal`: Immediately redirects the localized browser into the unified UI grid.
5. `Add New Service Instance`: Instantly spins up an isolated n8n node, assigns custom structural properties, maps localized data layers automatically inside `/volumes/`, and auto-generates Nginx subpaths safely!
6. `Remove Service Instance`: Surgically extracts the specific cluster array from the stack without destabilizing operations.

---

## 🛠 Advanced Architecture
To explore how the Node automation engine mathematically rewrites operational infrastructure natively, consult the [System Architecture Guide](SYSTEM_ARCHITECTURE.md).

## 🤝 Contribution
Engineered for scale and stability. Please open an issue to recommend architectural improvements or pull requests directly matching dynamic containerization strategies!

<div align="center">
  <i>Supercharge your Workflow Automations.</i>
</div>
