<p align="center">
  <img src="https://raw.githubusercontent.com/optiwater/opticraft/main/assets/opticraft_logo.png" alt="OptiCraft Logo" width="300">
</p>

<h1 align="center">🧱 OptiCraft</h1>
<p align="center">
  <b>Ein vollautomatisches CraftAttack-Style Minecraft Server Setup</b><br>
  <sub>by optiwater · GitHub: <a href="https://github.com/optiwater">optiwater</a></sub>
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
wget https://raw.githubusercontent.com/optiwater/opticraft/main/installer/opticraft_installer.sh
chmod +x opticraft_installer.sh
sudo ./opticraft_installer.sh
