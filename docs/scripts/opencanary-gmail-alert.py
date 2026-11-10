
#!/usr/bin/env python3
#
# ============================================================
# PROJET SÉCURITÉ TP1 — ALERTES GMAIL OPENCANARY
# ============================================================
#
# Fichier  : opencanary-gmail-alert.py
# Machine  : raphael-canary (VM 103)
# Système  : Ubuntu Server 22.04 LTS
#
# OBJECTIF
# --------
# Surveiller les événements enregistrés par OpenCanary
# et envoyer une notification Gmail lorsqu'un événement
# correspondant aux types sélectionnés est détecté.
#
# FONCTIONNEMENT
# --------------
# 1. Charger les paramètres Gmail depuis un fichier protégé.
# 2. Lire les nouveaux événements du journal OpenCanary.
# 3. Filtrer les événements selon leur type.
# 4. Préparer un courriel contenant les informations utiles.
# 5. Retirer les champs de mot de passe des détails transmis.
# 6. Envoyer l'alerte par SMTP sécurisé.
# 7. Mémoriser la position de lecture du journal.
#
# SÉCURITÉ
# --------
# Les identifiants Gmail sont conservés séparément dans :
# /etc/opencanary-alerts/gmail.env
#
# Aucun mot de passe n'est inscrit dans ce script.
#
# ============================================================

import json
import smtplib
import ssl
import sys
import time
from email.message import EmailMessage
from pathlib import Path

CONFIG = Path("/etc/opencanary-alerts/gmail.env")
LOG = Path("/var/tmp/opencanary.log")
STATE = Path("/var/lib/opencanary-alerts.offset")

ALERT_TYPES = {2000, 3001, 5001}


def load_config():
    """Charger les paramètres Gmail depuis le fichier protégé."""
    settings = {}

    for line in CONFIG.read_text().splitlines():
        line = line.strip()

        if not line or line.startswith("#"):
            continue

        key, separator, value = line.partition("=")

        if separator:
            settings[key.strip()] = value.strip().strip('"').strip("'")

    required = ("GMAIL_USER", "GMAIL_TO", "GMAIL_APP_PASSWORD")

    if any(not settings.get(key) for key in required):
        raise ValueError("Configuration Gmail incomplète")

    return settings


def send_alert(event, settings):
    """Préparer et envoyer un courriel d'alerte."""
    source = event.get("src_host", "inconnue")
    port = event.get("dst_port", "inconnu")
    event_type = event.get("logtype", "inconnu")
    timestamp = event.get("local_time", "inconnu")

    details = event.get("logdata", {})

    if not isinstance(details, dict):
        details = {"details": str(details)}

    # Ne pas transmettre les mots de passe des visiteurs.
    details = {
        key: value
        for key, value in details.items()
        if key.lower() not in ("password", "passwd", "pass")
    }

    message = EmailMessage()
    message["From"] = settings["GMAIL_USER"]
    message["To"] = settings["GMAIL_TO"]
    message["Subject"] = f"[OpenCanary] Alerte depuis {source}"

    message.set_content(
        f"Activité suspecte détectée sur Canary.\n\n"
        f"Date : {timestamp}\n"
        f"IP source : {source}\n"
        f"Port ciblé : {port}\n"
        f"Type : {event_type}\n"
        f"Détails : {json.dumps(details, ensure_ascii=False)}\n"
    )

    # Connexion SMTP avec chiffrement STARTTLS.
    context = ssl.create_default_context()

    with smtplib.SMTP("smtp.gmail.com", 587, timeout=15) as smtp:
        smtp.starttls(context=context)
        smtp.login(
            settings["GMAIL_USER"],
            settings["GMAIL_APP_PASSWORD"],
        )
        smtp.send_message(message)


def main():
    """Surveiller le journal et traiter les nouveaux événements."""
    settings = load_config()

    # Ignorer les anciens événements au premier lancement.
    offset = int(STATE.read_text()) if STATE.exists() else LOG.stat().st_size

    while True:
        try:
            size = LOG.stat().st_size

            # Réinitialiser la position si le journal a été tronqué.
            if size < offset:
                offset = 0

            with LOG.open("r", encoding="utf-8") as logfile:
                logfile.seek(offset)

                while True:
                    line = logfile.readline()

                    if not line:
                        break

                    new_offset = logfile.tell()

                    try:
                        event = json.loads(line)

                    except json.JSONDecodeError:
                        offset = new_offset
                        STATE.write_text(str(offset))
                        continue

                    if event.get("logtype") in ALERT_TYPES:
                        send_alert(event, settings)

                    offset = new_offset
                    STATE.write_text(str(offset))

        except Exception as error:
            print(
                f"Erreur de surveillance : {error}",
                file=sys.stderr,
            )

        time.sleep(3)


if __name__ == "__main__":
    main()
