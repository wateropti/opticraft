<p align="center">
  <img src="https://github.com/wateropti/opticraft/main/assets/opticraft_logo.png" alt="OptiCraft Logo" width="300">
</p>

<h1 align="center">🧱 OptiCraft</h1>
<p align="center">
  <b>Ein vollautomatisches CraftAttack-Style Minecraft Server Setup</b><br>
  <sub>by wateropti · GitHub: <a href="https://github.com/wateropti">wateropti</a></sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Minecraft-Fabric%20Server-orange?style=flat-square&logo=minecraft&logoColor=white">
  <img src="https://img.shields.io/badge/Debian-12-blue?style=flat-square&logo=debian&logoColor=white">
  <img src="https://img.shields.io/badge/Web-Interface%20Included-green?style=flat-square&logo=python&logoColor=white">
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=flat-square">
</p>

---

## 🌍 Projektbeschreibung

**OptiCraft** ist ein CraftAttack-inspiriertes Minecraft-Serverprojekt mit:
- 🧩 Fabric-Mod-Unterstützung (Vanilla+ Experience)
- 🧱 Automatisch generiertem Spawn bei `0 / 256 / 0`
- 🖥️ Eigenem Webinterface zur Serververwaltung
- 🧑‍🤝‍🧑 Whitelist- und Benutzerverwaltung
- 💾 Automatischen täglichen Backups
- ⚙️ Vollständigem Systemd-Autostart (LXC-ready)

Das Setup ist für **Proxmox-LXC Container (Debian 12)** optimiert und kann mit einem einzigen Befehl installiert werden.

---

## 🚀 Installation

### 🧰 Voraussetzungen
- Debian 12 LXC oder VM  
- Root-Zugriff  
- Internetverbindung  

### 🪄 1. Installationsbefehl

```bash
wget https://raw.githubusercontent.com/wateropti/opticraft/main/installer/opticraft_installer.sh
chmod +x opticraft_installer.sh
sudo ./opticraft_installer.sh
```

### 💾 2. Nach der Installation
| Funktion            | Beschreibung                                  |
| ------------------- | --------------------------------------------- |
| 🌐 **Webinterface** | `http://<LXC-IP>:8080`                        |
| 🎮 **Serverport**   | `25565`                                       |
| 📦 **Backups**      | Täglich 03:00 Uhr in `/opt/minecraft/backups` |
| 🔁 **Autostart**    | Aktiv für Server & Webinterface               |
| 🗺️ **Spawn**       | Automatisch bei `0 / 256 / 0`                 |
| ⚡ **Mods**          | Sodium, Lithium, Fabric API, Voice Chat, etc. |


### 💡 Tipps

- Logo im Minecraft MOTD aktivieren - in server.properties:
```ini
motd=§6§lOptiCraft §7- §aWillkommen auf dem Server!
```
- Favicon fürs Webinterface:
```bash
cp assets/opticraft_logo.png /opt/minecraft/webadmin/static/favicon.png
```

### 🧑‍💻 Autor

wateropti

- GitHub: <a href="https://github.com/wateropti">wateropti</a></sub>

### 📜 Lizenz

Dieses Projekt steht unter der MIT License.<br>
Siehe <a href="https://github.com/wateropti/LICENSE">LICENSE</a></sub> für Details.

© 2025 wateropti · OptiCraft Project