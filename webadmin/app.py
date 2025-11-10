#!/usr/bin/env python3
# ==========================================================
# OptiCraft WebAdmin
# Flask Webinterface mit Whitelist, Logs, Diagnose, Start/Stop
# ==========================================================
from flask import Flask, render_template, request, redirect, url_for, flash
import json, os, subprocess, datetime, time
from mcstatus import JavaServer
import psutil

app = Flask(__name__)
app.secret_key = "opticraft_secret"

BASE_DIR = "/opt/minecraft"
WHITELIST_FILE = os.path.join(BASE_DIR, "whitelist.json")
LOG_FILE = os.path.join(BASE_DIR, "logs/latest.log")


def load_whitelist():
    if not os.path.exists(WHITELIST_FILE):
        with open(WHITELIST_FILE, "w") as f:
            json.dump([], f)
    with open(WHITELIST_FILE) as f:
        return json.load(f)


def save_whitelist(data):
    with open(WHITELIST_FILE, "w") as f:
        json.dump(data, f, indent=4)


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/status")
def status():
    try:
        server = JavaServer.lookup("localhost:25565")
        st = server.status()
        players = [p.name for p in (st.players.sample or [])]
        return {
            "online": True,
            "motd": st.description,
            "players_online": st.players.online,
            "players": players,
            "latency": st.latency,
            "time": datetime.datetime.now().strftime("%H:%M:%S"),
        }
    except Exception:
        return {"online": False}


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
def whitelist():
    return render_template("whitelist.html", players=load_whitelist())


@app.route("/whitelist/add", methods=["POST"])
def whitelist_add():
    name = request.form.get("playername", "").strip()
    if not name:
        flash("Name darf nicht leer sein.", "danger")
    else:
        wl = load_whitelist()
        if not any(p.get("name") == name for p in wl):
            wl.append({"name": name, "uuid": ""})
            save_whitelist(wl)
            flash(f"{name} hinzugefügt.", "success")
        else:
            flash(f"{name} ist bereits auf der Whitelist.", "info")
    return redirect(url_for("whitelist"))


@app.route("/whitelist/remove/<name>")
def whitelist_remove(name):
    wl = [p for p in load_whitelist() if p.get("name") != name]
    save_whitelist(wl)
    flash(f"{name} entfernt.", "warning")
    return redirect(url_for("whitelist"))


@app.route("/logs")
def logs():
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE) as f:
            return "<pre>" + "".join(f.readlines()[-200:]) + "</pre>"
    return "Keine Logs gefunden."


@app.route("/diagnose")
def diagnose_page():
    data = {}
    data["minecraft_running"] = subprocess.call(["pgrep", "-f", "fabric-server-launch.jar"]) == 0
    try:
        java_ver = subprocess.check_output("java -version 2>&1 | head -n 1", shell=True).decode().strip()
    except Exception:
        java_ver = "❌ Nicht gefunden"
    data["java_version"] = java_ver
    data["cpu_usage"] = psutil.cpu_percent(interval=0.3)
    data["mem_usage"] = psutil.virtual_memory().percent
    backup_dir = "/opt/minecraft/backups"
    last_backup = "–"
    size_mb = 0
    try:
        files = sorted(
            [os.path.join(backup_dir, f) for f in os.listdir(backup_dir)],
            key=os.path.getmtime,
            reverse=True,
        )
        if files:
            latest = files[0]
            last_backup = datetime.datetime.fromtimestamp(os.path.getmtime(latest)).strftime(
                "%Y-%m-%d %H:%M:%S"
            )
            size_mb = round(os.path.getsize(latest) / (1024 * 1024), 2)
    except Exception:
        pass
    data["last_backup"] = last_backup
    data["backup_size_mb"] = size_mb
    try:
        uptime = round(time.time() - psutil.Process(os.getpid()).create_time(), 1)
    except Exception:
        uptime = 0
    data["web_uptime"] = f"{uptime}s"
    return render_template("diagnose.html", diag=data)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
