const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

function reloadNginx() {
    try {
        execSync('docker exec nginx-proxy nginx -s reload', { stdio: 'inherit' });
        console.log('✔ Nginx reloaded — routing updated.');
    } catch (e) {
        console.warn('⚠ Nginx reload failed (is nginx-proxy running?):', e.message);
    }
}

function composeUp(name) {
    try {
        execSync(`docker compose up -d n8n-${name}`, { stdio: 'inherit', cwd: __dirname });
        console.log(`✔ Container n8n-${name} started.`);
    } catch (e) {
        console.warn(`⚠ docker compose up failed for n8n-${name}:`, e.message);
    }
}

function composeDown(name) {
    try {
        execSync(`docker compose stop n8n-${name} && docker compose rm -f n8n-${name}`, { stdio: 'inherit', cwd: __dirname, shell: true });
        console.log(`✔ Container n8n-${name} stopped and removed.`);
    } catch (e) {
        console.warn(`⚠ docker compose down failed for n8n-${name}:`, e.message);
    }
}

const action = process.argv[2];
const serviceNameRaw = process.argv[3];
const arg4 = process.argv.slice(4).join(' ').replace(/^["']|["']$/g, '').trim();

if (!action || !serviceNameRaw) {
    console.error("Usage: node manage.js <add/remove> <serviceName>");
    process.exit(1);
}

const name = serviceNameRaw.toLowerCase().replace(/[^a-z0-9-]/g, '');
if(!name) process.exit(1);
const Name = name.charAt(0).toUpperCase() + name.slice(1);

const composePath = path.join(__dirname, 'docker-compose.yml');
const nginxPath = path.join(__dirname, 'nginx', 'nginx.conf');
const htmlPath = path.join(__dirname, 'nginx', 'html', 'index.html');
const dockerfilePath = path.join(__dirname, 'volumes', `n8n-${name}`, 'Dockerfile');
const volumePath = path.join(__dirname, 'volumes', `n8n-${name}`);

if (action === 'add') {
    let serviceDesc = arg4 || "Custom CLI-generated integrated node";
    
    const configPath = path.join(__dirname, 'service-docker-files', `n8n-${name}`);
    fs.mkdirSync(volumePath, { recursive: true });
    fs.mkdirSync(configPath, { recursive: true });
    try { fs.chownSync(volumePath, 1000, 1000); } catch(e) { console.error("Chown failed:", e); }
    
    const dockerfileContent = `FROM n8nio/n8n:latest\nUSER root\nRUN npm install -g uuid\nUSER node\n`;
    fs.writeFileSync(path.join(configPath, 'Dockerfile'), dockerfileContent);
    
    const moduleComposeContent = `services:\n  n8n-${name}:\n    image: n8nio/n8n:latest\n    container_name: n8n-${name}\n    restart: always\n    environment:\n      - N8N_PORT=5678\n      - N8N_SECURE_COOKIE=false\n      - N8N_HOST=${name}.dtbros.co.uk\n      - N8N_PROTOCOL=https\n      - N8N_URL=https://${name}.dtbros.co.uk\n      - N8N_WEBHOOK_URL=https://${name}.dtbros.co.uk\n      - N8N_EDITOR_BASE_URL=https://${name}.dtbros.co.uk\n      - N8N_ALLOWED_ORIGINS=*\n      - NODE_FUNCTION_ALLOW_BUILTIN=*\n    volumes:\n      - ../../volumes/n8n-${name}:/home/node/.n8n\n    networks:\n      - default\n`;
    fs.writeFileSync(path.join(configPath, 'docker-compose.yml'), moduleComposeContent);
    
    let compose = fs.readFileSync(composePath, 'utf8');
    if (!compose.includes(`- ./service-docker-files/n8n-${name}/docker-compose.yml`)) {
        if (compose.includes('include:')) {
            compose = compose.replace('include:', `include:\n  - ./service-docker-files/n8n-${name}/docker-compose.yml`);
        } else {
            compose = `include:\n  - ./service-docker-files/n8n-${name}/docker-compose.yml\n\n` + compose;
        }
        
        const nginxDep = `depends_on:`;
        if (compose.includes('  nginx:') && compose.includes(nginxDep)) {
            compose = compose.replace(nginxDep, `depends_on:\n      - n8n-${name}`);
        }
        fs.writeFileSync(composePath, compose);
    }
    
    let nginx = fs.readFileSync(nginxPath, 'utf8');
    if (!nginx.includes(`server_name ${name}.localhost`)) {
        const nginxBlock = `
    # n8n-${name} environment — served at ${name}.dtbros.co.uk
    server {
        listen 80;
        server_name ${name}.localhost ${name}.dtbros.co.uk;

        location / {
            proxy_pass http://n8n-${name}:5678;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
            proxy_set_header X-Forwarded-Host $host;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_read_timeout 3600;
            proxy_send_timeout 3600;
            proxy_buffering off;
        }
    }
`;
        // Insert new server block before the closing } of http block
        const regex = /\n\}\s*$/;
        nginx = nginx.replace(regex, `${nginxBlock}}\n`);
        fs.writeFileSync(nginxPath, nginx);
    }
    
    let html = fs.readFileSync(htmlPath, 'utf8');
    if (!html.includes(`class="env-card ${name} `)) {
        const gridEndIndex = html.indexOf('</div>\n    \n    <div class="footer">');
        if (gridEndIndex !== -1) {
            const emojis = ['🔮', '⚡', '🧩', '📡', '💾', '🛰️', '🧬', '🚀', '🤖', '🌀', '🌐'];
            const randomEmoji = emojis[Math.floor(Math.random() * emojis.length)];
            const cardHtml = `
        <a href="https://${name}.dtbros.co.uk/" class="env-card ${name} custom-node" target="_blank">
            <div class="icon-container">${randomEmoji}</div>
            <div class="card-title">${Name} Environment</div>
            <div class="card-desc">${serviceDesc}</div>
        </a>\n    `;
            html = html.slice(0, gridEndIndex) + cardHtml + html.slice(gridEndIndex);
            
            const cssColor = `${Math.floor(Math.random()*155+100)}, ${Math.floor(Math.random()*155+100)}, ${Math.floor(Math.random()*155+100)}`;
            const cssBlock = `\n        .env-card.${name} { --hover-color: rgb(${cssColor}); border-top: 2px solid rgb(${cssColor}); }\n        .env-card:hover {`;
            html = html.replace('.env-card:hover {', cssBlock);
            
            // Place comma on new line to evade javascript single-line comments //
            const sphereBlock = `\n        ,\n        new NeuralSphere("${cssColor}", 160, 0.006, 0.35, Math.random() * Math.PI * 2, 0.25) // SPHERE_${name}\n    ];`;
            html = html.replace(/\n\s*\];/, sphereBlock);
            
            // Clean up any potential valid/invalid syntax artifacts from prior appends
            html = html.replace(/,\s*,/g, ',');
            
            fs.writeFileSync(htmlPath, html);
        }
    }
    console.log(`Successfully mapped and added new n8n-${name} architecture!`);
    composeUp(name);
    reloadNginx();
} else if (action === 'remove') {
    let compose = fs.readFileSync(composePath, 'utf8');
    
    const includeRegex = new RegExp(`[\\r\\n]+[ \\t]*-[ \\t]*\\./service-docker-files/n8n-${name}/docker-compose\\.yml(?=[\\r\\n]|$)`, 'g');
    compose = compose.replace(includeRegex, '');
    
    const depItemRegex = new RegExp(`[\\r\\n]+[ \\t]*-[ \\t]*n8n-${name}(?=[\\r\\n]|$)`, 'g');
    compose = compose.replace(depItemRegex, '');
    
    compose = compose.replace(/include:[ \t]*[\r\n]+(?!(?:[ \t]*-|\w))/g, '');
    compose = compose.replace(/[ \t]*depends_on:[ \t]*[\r\n]+(?=[ \t]*[a-zA-Z]+:)/g, '');
    
    fs.writeFileSync(composePath, compose);
    
    try { fs.rmSync(volumePath, { recursive: true, force: true }); } catch(e){}
    try { fs.rmSync(path.join(__dirname, 'service-docker-files', `n8n-${name}`), { recursive: true, force: true }); } catch(e){}
    
    let nginx = fs.readFileSync(nginxPath, 'utf8');
    const nginxRegex = new RegExp(`\\s*# n8n-${name} environment[\\s\\S]*?server_name ${name}\\.localhost ${name}\\.dtbros\\.co\\.uk;[\\s\\S]*?\\n    \\}`, 'g');
    nginx = nginx.replace(nginxRegex, '');
    fs.writeFileSync(nginxPath, nginx);
    
    let html = fs.readFileSync(htmlPath, 'utf8');
    const cardRegex = new RegExp(`\\s*<a href="[^"]*//${name}\\.dtbros\\.co\\.uk/" class="env-card ${name} custom-node"[\\s\\S]*?</a>`, 'g');
    html = html.replace(cardRegex, '');
    
    const cssRegex = new RegExp(`\\n\\s*\\.env-card\\.${name} \\{[^}]*\\}`, 'g');
    html = html.replace(cssRegex, '');
    
    const sphereRegex = new RegExp(`(?:,\\s*)?new NeuralSphere[^\\n]*// SPHERE_${name}`, 'g');
    html = html.replace(sphereRegex, '');
    
    fs.writeFileSync(htmlPath, html);
    
    composeDown(name);
    reloadNginx();
    console.log(`Successfully deregistered and removed n8n-${name} from the cluster.`);
} else {
    console.error("Command unrecognized.");
}
