
#!/bin/bash
#
# ============================================================
# PROJET SÉCURITÉ TP1 — SAUVEGARDE AUTOMATISÉE DU VPS
# ============================================================
#
# Fichier       : sauvegarde-vps.sh
# Machine       : raphael-knox (VM 110)
# Système       : Ubuntu Server 22.04.5 LTS
# VPS distant   : 172.105.99.9
# Port SSH      : 870
#
# OBJECTIF
# --------
# Ce script permet à Knox de récupérer les sauvegardes
# du VPS par une connexion SSH authentifiée par clé.
#
# FONCTIONNEMENT
# --------------
# 1. Sauvegarder les fichiers du serveur web (/var/www).
# 2. Sauvegarder les sources personnelles de SportPulse.
# 3. Déclencher l'export de la base MySQL sur le VPS.
# 4. Récupérer le fichier SQL sur Knox.
# 5. Déclencher la création d'une archive de /home.
# 6. Récupérer l'archive complète sur Knox.
#
# DESTINATION
# -----------
# /home/raphael/sauvegardes-vps/
#
# SÉCURITÉ
# --------
# - Connexion SSH sur le port 870.
# - Authentification par clé SSH.
# - Commandes sudo non interactives côté VPS.
# - Aucun mot de passe ni clé privée dans ce fichier.
#
# ============================================================

set -e

# Paramètres de connexion et de sauvegarde
VPS="knoxbackup@172.105.99.9"
SSH="ssh -p 870 -i /home/raphael/.ssh/id_ed25519_knox -o IdentitiesOnly=yes"
DEST="/home/raphael/sauvegardes-vps"

echo "===Debut de la sauvegarde : $(date) ==="

# 1. Sauvegarde des fichiers du serveur web
rsync -av -e "$SSH" "$VPS:/var/www/" "$DEST/www"

# 2. Sauvegarde des sources personnelles de SportPulse
rsync -av -e "$SSH" \
    "$VPS:/home/raphi/sportpulse-source/" \
    "$DEST/home/raphi/sportpulse-source/"

# 3. Déclenchement de l'export MySQL sur le VPS
$SSH "$VPS" "sudo -n /usr/local/lib/knox-backup/export-mysql.sh"

# 4. Récupération de la sauvegarde MySQL sur Knox
rsync -av -e "$SSH" \
    "$VPS:/var/backups/knox/sport.sql" \
    "$DEST/home/raphi/"

# 5. Création de l'archive complète de /home sur le VPS
$SSH "$VPS" "sudo -n /usr/local/lib/knox-backup/export-home.sh"

# 6. Récupération de l'archive complète sur Knox
rsync -av -e "$SSH" \
    "$VPS:/var/backups/knox/home-complet.tar.gz" \
    "$DEST/"

echo "=== Sauvegarde terminée : $(date) ==="
