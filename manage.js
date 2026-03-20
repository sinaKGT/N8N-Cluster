const fs = require('fs');
const path = require('path');

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
    fs.mkdirSync(volumePath, { recursive: true });
    try { fs.chownSync(volumePath, 1000, 1000); } catch(e) { console.error("Chown failed:", e); }
    
    // Simple proven cross-platform npm package install
    const dockerfileContent = `FROM n8nio/n8n:latest\nUSER root\nRUN npm install -g uuid\nUSER node\n`;
    fs.writeFileSync(dockerfilePath, dockerfileContent);
    
    let compose = fs.readFileSync(composePath, 'utf8');
    if (!compose.includes(`n8n-${name}:`)) {
        const serviceBlock = `\n  n8n-${name}:\n    build: ./volumes/n8n-${name}/\n    container_name: n8n-${name}\n    restart: always\n    environment:\n      - N8N_PORT=5678\n      - WEBHOOK_URL=http://localhost/n8n-${name}/\n      - N8N_PATH=/n8n-${name}/\n    volumes:\n      - ./volumes/n8n-${name}:/home/node/.n8n\n`;
        fs.appendFileSync(composePath, serviceBlock);
    }
    
    let nginx = fs.readFileSync(nginxPath, 'utf8');
    if (!nginx.includes(`location /n8n-${name}/`)) {
        const nginxBlock = `
        # n8n-${name} environment
        location /n8n-${name}/ {
            proxy_pass http://n8n-${name}:5678/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_read_timeout 90;
        }
`;
        const regex = /([ \t]*)\}\n\}\s*$/;
        nginx = nginx.replace(regex, `${nginxBlock}$1}\n}\n`);
        fs.writeFileSync(nginxPath, nginx);
    }
    
    let html = fs.readFileSync(htmlPath, 'utf8');
    if (!html.includes(`n8n-${name}`)) {
        const gridEndIndex = html.indexOf('</div>\n    \n    <div class="footer">');
        if (gridEndIndex !== -1) {
            const emojis = ['🔮', '⚡', '🧩', '📡', '💾', '🛰️', '🧬', '🚀', '🤖', '🌀', '🌐'];
            const randomEmoji = emojis[Math.floor(Math.random() * emojis.length)];
            const cardHtml = `
        <a href="/n8n-${name}/" class="env-card ${name} custom-node" target="_blank">
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
} else if (action === 'remove') {
    fs.rmSync(path.join(__dirname, 'volumes', `n8n-${name}`), { recursive: true, force: true });
    
    let compose = fs.readFileSync(composePath, 'utf8');
    
    // 1. Remove the service block itself
    const composeRegex = new RegExp(`[\\r\\n]+[ \\t]*n8n-${name}:(?:[\\r\\n]+[ \\t]{3,}[^\\r\\n]*)*`, 'g');
    compose = compose.replace(composeRegex, '\n');
    
    // 2. Remove references from any depends_on blocks in other containers
    const depItemRegex = new RegExp(`[\\r\\n]+[ \\t]*-[ \\t]*n8n-${name}(?=[\\r\\n]|$)`, 'g');
    compose = compose.replace(depItemRegex, '');
    
    // 3. Clean up any left-over empty depends_on keys perfectly safely
    compose = compose.replace(/[ \\t]*depends_on:[ \\t]*[\\r\\n]+(?=[ \\t]*[a-zA-Z]+:)/g, '');
    
    fs.writeFileSync(composePath, compose);
    
    let nginx = fs.readFileSync(nginxPath, 'utf8');
    const nginxRegex = new RegExp(`\\s*# n8n-${name} environment\\s*location /n8n-${name}/ \\{[\\s\\S]*?\\n\\s*\\}`, 'g');
    nginx = nginx.replace(nginxRegex, '');
    fs.writeFileSync(nginxPath, nginx);
    
    let html = fs.readFileSync(htmlPath, 'utf8');
    const cardRegex = new RegExp(`\\s*<a href="/n8n-${name}/"[\\s\\S]*?</a>`, 'g');
    html = html.replace(cardRegex, '');
    
    const cssRegex = new RegExp(`\\n\\s*\\.env-card\\.${name} \\{[^}]*\\}`, 'g');
    html = html.replace(cssRegex, '');
    
    const sphereRegex = new RegExp(`(?:,\\s*)?new NeuralSphere[^\\n]*// SPHERE_${name}`, 'g');
    html = html.replace(sphereRegex, '');
    
    fs.writeFileSync(htmlPath, html);
    
    console.log(`Successfully deregistered and removed n8n-${name} from the cluster.`);
} else {
    console.error("Command unrecognized.");
}
