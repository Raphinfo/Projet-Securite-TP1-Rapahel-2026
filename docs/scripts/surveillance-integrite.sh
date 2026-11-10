
#!/bin/bash
#
# ============================================================
# PROJET SÉCURITÉ TP1 — SURVEILLANCE D'INTÉGRITÉ DU VPS
# ============================================================
#
# Fichier       : surveillance-integrite.sh
# Machine       : raphael-knox (VM 110)
# Système       : Ubuntu Server 22.04.5 LTS
# VPS surveillé : 172.105.99.9
# Port SSH      : 870
#
# OBJECTIF
# --------
# Détecter les modifications des fichiers sensibles du VPS
# en comparant leurs empreintes cryptographiques SHA-256
# avec des empreintes de référence enregistrées sur Knox.
#
# FICHIERS SURVEILLÉS
# -------------------
# - /etc/ssh/sshd_config
# - /etc/apache2/sites-available/securite.conf
# - /etc/apache2/sites-available/securite-le-ssl.conf
#
# FONCTIONNEMENT
# --------------
# 1. Établir une connexion SSH vers le VPS.
# 2. Calculer les empreintes SHA-256 des fichiers surveillés.
# 3. Récupérer les empreintes actuelles sur Knox.
# 4. Comparer ces empreintes aux références enregistrées.
# 5. Journaliser les résultats et signaler les différences.
#
# FICHIERS LOCAUX
# ---------------
# Référence : /home/raphael/empreintes-reference.sha256
# Journal   : /home/raphael/monitor.log
#
# CODES DE RETOUR
# ---------------
# 0 : OK — aucune modification détectée.
# 1 : ERREUR — récupération des empreintes impossible.
# 2 : ALERTE — modification détectée.
#
# SÉCURITÉ
# --------
# - Connexion SSH sur le port 870.
# - Authentification par clé SSH.
# - Aucune clé privée ni aucun mot de passe publié.
# - Suppression automatique du fichier temporaire.
#
# REMARQUE
# --------
# Une différence SHA-256 ne signifie pas nécessairement
# une intrusion. Elle peut résulter d'une modification
# administrative autorisée.
#
# ============================================================

set -euo pipefail

# Paramètres de connexion et chemins des fichiers
VPS="knoxbackup@172.105.99.9"
REFERENCE="/home/raphael/empreintes-reference.sha256"
JOURNAL="/home/raphael/monitor.log"

# Création d'un fichier temporaire sécurisé
TEMP=$(mktemp)

# Suppression automatique du fichier temporaire à la sortie
trap 'rm -f "$TEMP"' EXIT

# Enregistrement de la date et de l'heure de vérification
echo "===== Vérification du $(date) =====" >> "$JOURNAL"

# 1. Récupération des empreintes actuelles depuis le VPS
if ! ssh -p 870 \
    -i /home/raphael/.ssh/id_ed25519_knox \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    "$VPS" \
    "sha256sum /etc/ssh/sshd_config /etc/apache2/sites-available/securite.conf /etc/apache2/sites-available/securite-le-ssl.conf" \
    > "$TEMP"; then

    # Échec de connexion ou de récupération des empreintes
    echo "ERREUR : impossible de récupérer les empreintes du VPS." | tee -a "$JOURNAL"
    exit 1
fi

# 2. Comparaison avec les empreintes de référence
if diff -u "$REFERENCE" "$TEMP" >> "$JOURNAL"; then

    # Les empreintes sont identiques
    echo "OK : aucune modification détectée." | tee -a "$JOURNAL"

else

    # Au moins une empreinte est différente
    echo "ALERTE : modification détectée dans les fichiers surveillés !" | tee -a "$JOURNAL"
    exit 2
fi
