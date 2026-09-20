# Linux Server Migration Notes

## Pre-Transfer Checklist (on Windows)

- [x] Stop the entire cluster via CLI option 2 (`docker compose stop`) — cleans up SQLite WAL files safely
- [ ] Copy the full project folder to the Linux server (rsync, SCP, or git clone)

---

## First Steps on Linux (after copy)

### 1. Make the CLI executable
```bash
chmod +x n8n-cli.sh
```

### 2. Start the cluster
```bash
./n8n-cli.sh
# Select option 1 — Start Entire System
```

---

## Things to Watch Out For

### Port 80
Docker needs port 80 free. If the Linux server already has Apache or another Nginx running, stop it first:
```bash
sudo systemctl stop apache2   # or nginx
```

### Volume Ownership
n8n runs as user `node` (UID 1000) inside the container. If you see permission errors on startup, fix with:
```bash
sudo chown -R 1000:1000 volumes/
```

### Firewall
Open port 80 (and 443 if using HTTPS directly) if the server has a firewall:
```bash
sudo ufw allow 80
sudo ufw allow 443
```

---

## What Is NOT Wired Into the Main Stack

`dependency/sleep_stress_prediction/` — a standalone Flask ML app with its own Dockerfile. It does **not** start with `docker compose up`. Deploy it separately if needed.

---

## New Services Added via CLI on Linux

When you use CLI option 7 to add a new workspace, `manage.js` generates `http://` URLs (not `https://`). The original four workspaces (phd, sandbox, demo, personal) use `https://` with Cloudflare. Keep this in mind if you add new services and want HTTPS on them too.

---

## Verifying the Cluster is Healthy

After starting, check all containers are running:
```bash
docker ps
```

Expected containers:
- `nginx-proxy`
- `n8n-phd`
- `n8n-sandbox`
- `n8n-demo`
- `n8n-personal`

Then open `http://<server-ip>` or `http://localhost` to confirm the dashboard loads.
