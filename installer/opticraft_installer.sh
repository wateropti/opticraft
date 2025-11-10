#!/bin/bash
# ==========================================================
# OptiCraft - Fabric Server Installer (light)
# lädt WebUI + Templates direkt von GitHub
# ==========================================================
set -euo pipefail

REPO_BASE="https://raw.githubusercontent.com/wateropti/opticraft/main"
SERVER_DIR="/opt/minecraft"
SERVER_NAME="OptiCraft"

echo "=== 🌍 $SERVER_NAME Fabric Server Installation ==="

# --- Eingaben
read -p "Minecraft-Version (z.B. 1.21.1) [1.21.1]: " MC_VERSION
MC_VERSION=${MC_VERSION:-1.21.1}

read -p "RAM (z.B. 4G) [4G]: " RAM
RAM=${RAM:-4G}

read -p "EULA akzeptieren? (yes/no): " EULA
[[ "$EULA" == "yes" ]] || { echo "❌ Du musst der EULA zustimmen."; exit 1; }

# --- Pakete
apt update -y
apt install -y openjdk-17-jre-headless python3 python3-pip screen wget curl unzip tar cron sudo jq

# --- Benutzer + Verzeichnis
if ! id "minecraft" &>/dev/null; then
  useradd -m -r -d "$SERVER_DIR" -s /bin/bash minecraft
  echo "✅ Benutzer 'minecraft' erstellt."
fi
mkdir -p "$SERVER_DIR"
chown -R minecraft:minecraft "$SERVER_DIR"

# --- Fabric-Server
sudo -u minecraft bash <<EOF
set -e
cd "$SERVER_DIR"
wget -q -O fabric-installer.jar "https://meta.fabricmc.net/v2/versions/installer/1.0.1/fabric-installer.jar"
java -jar fabric-installer.jar server -mcversion $MC_VERSION -downloadMinecraft
echo "eula=true" > eula.txt
EOF

# --- Mods
sudo -u minecraft bash <<'EOF'
cd /opt/minecraft
mkdir -p mods
for u in \
  "https://cdn.modrinth.com/data/P7dR8mSH/versions/latest/fabric-api.jar" \
  "https://cdn.modrinth.com/data/AANobbMI/versions/latest/sodium-fabric.jar" \
  "https://cdn.modrinth.com/data/gvQqBUqZ/versions/latest/lithium-fabric.jar" \
  "https://cdn.modrinth.com/data/H8CaAYZC/versions/latest/starlight-fabric.jar" \
  "https://cdn.modrinth.com/data/9eGKb6K1/versions/latest/simple-voice-chat.jar"; do
  wget -q -P mods "$u"
done
EOF

# --- Startscript
cat > "$SERVER_DIR/start.sh" <<EOSTART
#!/bin/bash
cd "\$(dirname "\$0")"
exec java -Xmx$RAM -Xms$RAM -jar fabric-server-launch.jar nogui
EOSTART
chmod +x "$SERVER_DIR/start.sh"

# --- Backup
cat > "$SERVER_DIR/backup.sh" <<'EOBACK'
#!/bin/bash
BACKUP_DIR="/opt/minecraft/backups"
mkdir -p "$BACKUP_DIR"
TS=$(date +"%Y-%m-%d_%H-%M-%S")
tar --exclude="$BACKUP_DIR" -czf "$BACKUP_DIR/minecraft_$TS.tar.gz" -C /opt/minecraft .
find "$BACKUP_DIR" -type f -mtime +7 -delete
EOBACK
chmod +x "$SERVER_DIR/backup.sh"
(crontab -l 2>/dev/null; echo "0 3 * * * /opt/minecraft/backup.sh >> /opt/minecraft/backup.log 2>&1") | crontab -

# --- Webinterface herunterladen
echo "=== 🌐 Lade Webinterface von GitHub ($REPO_BASE/webadmin) ==="
mkdir -p "$SERVER_DIR/webadmin/templates" "$SERVER_DIR/webadmin/static"
wget -q -O "$SERVER_DIR/webadmin/app.py" "$REPO_BASE/webadmin/app.py"
for tpl in index.html whitelist.html status.html diagnose.html; do
  wget -q -O "$SERVER_DIR/webadmin/templates/$tpl" "$REPO_BASE/webadmin/templates/$tpl"
done
wget -q -O "$SERVER_DIR/webadmin/static/opticraft_logo.png" "$REPO_BASE/webadmin/static/opticraft_logo.png"

pip install flask mcstatus psutil >/dev/null

# --- systemd Dienste
cat > /etc/systemd/system/minecraft.service <<EOSVC
[Unit]
Description=$SERVER_NAME Server
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

echo "✅ Installation abgeschlossen!"
echo "➡️ Server starten: systemctl start minecraft"
echo "➡️ Webinterface:   systemctl start minecraft-webadmin"
echo "🌐 Dashboard: http://<LXC-IP>:8080"
