
#!/bin/bash

# Surveillance SHA-256 du VPS depuis Knox
set -euo pipefail

VPS="knoxbackup@172.105.99.9"
REFERENCE="/home/raphael/empreintes-reference.sha256"
JOURNAL="/home/raphael/monitor.log"

TEMP=$(mktemp)
trap 'rm -f "$TEMP"' EXIT

echo "===== Vérification du $(date) =====" >> "$JOURNAL"

# Récupération des empreintes actuelles
if ! ssh -p 870 \
    -i /home/raphael/.ssh/id_ed25519_knox \
    -o IdentitiesOnly=yes \
    -o BatchMode=yes \
    "$VPS" \
    "sha256sum /etc/ssh/sshd_config /etc/apache2/sites-available/securite.conf /etc/apache2/sites-available/securite-le-ssl.conf" \
    > "$TEMP"; then

    echo "ERREUR : impossible de récupérer les empreintes du VPS." | tee -a "$JOURNAL"
    exit 1
fi

# Comparaison avec les empreintes de référence
if diff -u "$REFERENCE" "$TEMP" >> "$JOURNAL"; then
    echo "OK : aucune modification détectée." | tee -a "$JOURNAL"
else
    echo "ALERTE : modification détectée dans les fichiers surveillés !" | tee -a "$JOURNAL"
    exit 2
fi
