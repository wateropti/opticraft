#!/bin/bash
# ==========================================================
# OptiCraft - CraftAttack Style Fabric Server Installer
# Author: wateropti
# ==========================================================
set -e

SERVER_NAME="OptiCraft"

echo "=== 🌍 $SERVER_NAME Fabric Server Installation ==="

# --- Input ---
read -p "📁 Server-Verzeichnis (z.B. /opt/minecraft): " SERVER_DIR
SERVER_DIR=${SERVER_DIR:-/opt/minecraft}

read -p "🎮 Minecraft-Version (z.B. 1.21.1): " MC_VERSION
MC_VERSION=${MC_VERSION:-1.21.1}

read -p "💾 RAM (z.B. 4G): " RAM
RAM=${RAM:-4G}

read -p "✅ EULA akzeptieren? (yes/no): " EULA
if [[ "$EULA" != "yes" ]]; then
  echo "❌ Du musst der EULA zustimmen."
  exit 1
fi

# --- Systempakete ---
echo "=== 📦 Installiere Abhängigkeiten ==="
apt update -y
apt install -y openjdk-21-jre-headless python3 python3-pip screen wget curl unzip tar cron sudo

# --- Benutzer & Verzeichnisse ---
if ! id "minecraft" &>/dev/null; then
  useradd -m -r -d "$SERVER_DIR" -s /bin/bash minecraft
  echo "✅ Benutzer 'minecraft' erstellt."
fi
mkdir -p "$SERVER_DIR"
chown -R minecraft:minecraft "$SERVER_DIR"

# --- Fabric-Server installieren ---
sudo -u minecraft bash <<EOF
cd "$SERVER_DIR"
echo "=== 🌐 Lade Fabric Installer ==="
wget -O fabric-installer.jar https://meta.fabricmc.net/v2/versions/installer/1.0.1/fabric-installer.jar

echo "=== ⚙️ Installiere Fabric Server für Version $MC_VERSION ==="
java -jar fabric-installer.jar server -mcversion $MC_VERSION -downloadMinecraft
echo "eula=true" > eula.txt

# --- Mods (CraftAttack Style) ---
mkdir -p mods
echo "=== 📦 Lade Mods ==="
MODS_URLS=(
  "https://cdn.modrinth.com/data/P7dR8mSH/versions/latest/fabric-api.jar"
  "https://cdn.modrinth.com/data/AANobbMI/versions/latest/sodium-fabric.jar"
  "https://cdn.modrinth.com/data/gvQqBUqZ/versions/latest/lithium-fabric.jar"
  "https://cdn.modrinth.com/data/H8CaAYZC/versions/latest/starlight-fabric.jar"
  "https://cdn.modrinth.com/data/9eGKb6K1/versions/latest/simple-voice-chat.jar"
  "https://cdn.modrinth.com/data/1bokaNcj/versions/latest/xaeros-minimap.jar"
  "https://cdn.modrinth.com/data/1eAoo2KR/versions/latest/xaeros-worldmap.jar"
  "https://cdn.modrinth.com/data/YL57xq9U/versions/latest/modmenu-fabric.jar"
  "https://cdn.modrinth.com/data/YL57xq9U/versions/latest/iris-shaders.jar"
)
for URL in "\${MODS_URLS[@]}"; do
  wget -q "\$URL" -P mods/ || echo "⚠️ Fehler bei: \$URL"
done

# --- server.properties ---
cat > server.properties <<EOPROP
motd=§6§l$SERVER_NAME §7- §aWillkommen auf dem Server!
enable-command-block=true
gamemode=survival
difficulty=3
spawn-protection=0
view-distance=12
max-players=20
online-mode=true
server-port=25565
EOPROP

# --- Start Script ---
cat > start.sh <<EOSTART
#!/bin/bash
cd "\$(dirname "\$0")"
java -Xmx$RAM -Xms$RAM -jar fabric-server-launch.jar nogui
EOSTART
chmod +x start.sh

# --- Spawn Setup (Datapack) ---
mkdir -p world/datapacks/optispawn/data/optispawn/functions
cat > world/datapacks/optispawn/data/optispawn/functions/spawn_setup.mcfunction <<'EOSPAWN'
setworldspawn 0 256 0
fill -3 255 -3 3 255 3 minecraft:stone
title @a title {"text":"Willkommen auf OptiCraft!","color":"gold"}
tellraw @a {"text":"Spawnpunkt gesetzt bei 0 256 0","color":"yellow"}
EOSPAWN
cat > world/datapacks/optispawn/pack.mcmeta <<'EOMETA'
{
  "pack": {
    "pack_format": 15,
    "description": "OptiCraft Auto Spawn Setup"
  }
}
EOMETA
EOF

# --- Backup Script ---
cat > "$SERVER_DIR/backup.sh" <<'EOBACK'
#!/bin/bash
BACKUP_DIR="/opt/minecraft/backups"
SERVER_DIR="/opt/minecraft"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/minecraft_backup_$TIMESTAMP.tar.gz"
mkdir -p "$BACKUP_DIR"
tar --exclude="$BACKUP_DIR" -czf "$BACKUP_FILE" -C "$SERVER_DIR" .
find "$BACKUP_DIR" -type f -mtime +7 -name "*.tar.gz" -delete
echo "✅ Backup erstellt: $BACKUP_FILE"
EOBACK
chmod +x "$SERVER_DIR/backup.sh"
(crontab -l 2>/dev/null; echo "0 3 * * * /opt/minecraft/backup.sh >> /opt/minecraft/backup.log 2>&1") | crontab -

# --- WebInterface Installation ---
echo "=== 🌐 Installiere WebInterface ($SERVER_NAME Control Panel) ==="
pip install flask mcstatus
mkdir -p "$SERVER_DIR/webadmin/templates" "$SERVER_DIR/webadmin/static"

# === Flask App ===
cat > "$SERVER_DIR/webadmin/app.py" <<'EOFWEB'
#!/usr/bin/env python3
from flask import Flask, render_template, request, redirect, url_for, flash
import json, os, subprocess, datetime
from mcstatus import JavaServer

app = Flask(__name__)
app.secret_key = "opticraft_secret"

BASE_DIR = "/opt/minecraft"
WHITELIST_FILE = os.path.join(BASE_DIR, "whitelist.json")
LOG_FILE = os.path.join(BASE_DIR, "logs/latest.log")

def load_whitelist():
    if not os.path.exists(WHITELIST_FILE):
        with open(WHITELIST_FILE, "w") as f: json.dump([], f)
    with open(WHITELIST_FILE) as f: return json.load(f)
def save_whitelist(data):
    with open(WHITELIST_FILE, "w") as f: json.dump(data, f, indent=4)

@app.route("/")
def index(): return render_template("index.html")

@app.route("/status")
def status():
    try:
        server = JavaServer.lookup("localhost:25565")
        st = server.status()
        players = [p.name for p in st.players.sample] if st.players.sample else []
        return {"online": True, "motd": st.description, "players_online": st.players.online,
                "players": players, "latency": st.latency,
                "time": datetime.datetime.now().strftime("%H:%M:%S")}
    except Exception: return {"online": False}

@app.route("/start")
def start_server():
    subprocess.Popen(["sudo", "-u", "minecraft", "bash", os.path.join(BASE_DIR, "start.sh")])
    flash("Server gestartet!", "success")
    return redirect(url_for("index"))
@app.route("/stop")
def stop_server():
    subprocess.call(["pkill", "-f", "fabric-server-launch.jar"])
    flash("Server gestoppt!", "warning")
    return redirect(url_for("index"))
@app.route("/restart")
def restart_server():
    subprocess.call(["pkill", "-f", "fabric-server-launch.jar"])
    subprocess.Popen(["sudo", "-u", "minecraft", "bash", os.path.join(BASE_DIR, "start.sh")])
    flash("Server neugestartet!", "info")
    return redirect(url_for("index"))

@app.route("/whitelist")
def whitelist(): return render_template("whitelist.html", players=load_whitelist())

@app.route("/whitelist/add", methods=["POST"])
def whitelist_add():
    name = request.form.get("playername")
    if not name: flash("Name darf nicht leer sein.", "danger")
    else:
        wl = load_whitelist(); wl.append({"name": name, "uuid": ""}); save_whitelist(wl)
        flash(f"{name} hinzugefügt.", "success")
    return redirect(url_for("whitelist"))

@app.route("/whitelist/remove/<name>")
def whitelist_remove(name):
    wl = [p for p in load_whitelist() if p["name"] != name]
    save_whitelist(wl)
    flash(f"{name} entfernt.", "warning")
    return redirect(url_for("whitelist"))

@app.route("/logs")
def logs():
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE) as f: return "<pre>" + "".join(f.readlines()[-100:]) + "</pre>"
    return "Keine Logs gefunden."

if __name__ == "__main__": app.run(host="0.0.0.0", port=8080)
EOFWEB

# === HTML Templates ===
cat > "$SERVER_DIR/webadmin/templates/index.html" <<'EOHTML'
<!DOCTYPE html><html lang="de"><head>
<meta charset="UTF-8"><title>OptiCraft Admin</title>
<link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
</head><body>
<h1>🧱 OptiCraft Admin Panel</h1>
<img src="/static/opticraft_logo.png" alt="OptiCraft Logo" width="200" style="margin-bottom:10px;">
<p><a href="/status">Server Status</a> |
<a href="/start">Start</a> |
<a href="/stop">Stop</a> |
<a href="/restart">Restart</a> |
<a href="/whitelist">Whitelist</a> |
<a href="/logs">Logs</a></p>
{% with messages = get_flashed_messages(with_categories=true) %}
{% if messages %}<ul>{% for category, message in messages %}
<li><b>{{ category }}:</b> {{ message }}</li>{% endfor %}</ul>{% endif %}{% endwith %}
</body></html>
EOHTML

cat > "$SERVER_DIR/webadmin/templates/whitelist.html" <<'EOHTML'
<!DOCTYPE html><html lang="de"><head>
<meta charset="UTF-8"><title>Whitelist</title>
<link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
</head><body>
<h1>Whitelist</h1>
<form action="/whitelist/add" method="POST">
<input type="text" name="playername" placeholder="Spielername">
<button type="submit">Hinzufügen</button></form>
<ul>{% for p in players %}
<li>{{ p.name }} <a href="/whitelist/remove/{{ p.name }}">❌ Entfernen</a></li>
{% endfor %}</ul>
<a href="/">⬅ Zurück</a></body></html>
EOHTML

cat > "$SERVER_DIR/webadmin/templates/status.html" <<'EOHTML'
<!DOCTYPE html><html lang="de"><head>
<meta charset="UTF-8"><title>OptiCraft Dashboard</title>
<link rel="stylesheet" href="https://cdn.simplecss.org/simple.min.css">
<script>
async function updateStatus(){
 const res=await fetch('/status');const data=await res.json();
 const out=document.getElementById('out');
 if(data.online){
  out.innerHTML=`<b>Status:</b> 🟢 Online<br>
  <b>MotD:</b> ${data.motd}<br>
  <b>Spieler:</b> ${data.players_online}<br>
  <b>Namen:</b> ${data.players.join(', ')||'-'}<br>
  <b>Latenz:</b> ${data.latency} ms<br>
  <b>Letzte Abfrage:</b> ${data.time}`;
 }else{out.innerHTML='<b>Status:</b> 🔴 Offline';}}
setInterval(updateStatus,5000);window.onload=updateStatus;
</script></head><body>
<h1>🌍 OptiCraft Server Dashboard</h1>
<div id="out">Lade Status...</div>
<p><a href="/">⬅ Zurück</a></p>
</body></html>
EOHTML

# --- Systemd Services ---
cat > /etc/systemd/system/minecraft.service <<EOSVC
[Unit]
Description=$SERVER_NAME Fabric Server
After=network.target
[Service]
User=minecraft
WorkingDirectory=$SERVER_DIR
ExecStart=/bin/bash $SERVER_DIR/start.sh
Restart=always
[Install]
WantedBy=multi-user.target
EOSVC

cat > /etc/systemd/system/minecraft-webadmin.service <<EOSVC
[Unit]
Description=$SERVER_NAME WebAdmin
After=network.target
[Service]
ExecStart=/usr/bin/python3 $SERVER_DIR/webadmin/app.py
Restart=always
User=root
WorkingDirectory=$SERVER_DIR/webadmin
[Install]
WantedBy=multi-user.target
EOSVC

systemctl daemon-reload
systemctl enable minecraft minecraft-webadmin

echo "✅ $SERVER_NAME erfolgreich installiert!"
echo "➡️ Starte Dienste:"
echo "   systemctl start minecraft"
echo "   systemctl start minecraft-webadmin"
echo "🌐 Webinterface: http://<LXC-IP>:8080"
